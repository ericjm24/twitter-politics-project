indexFile = "data/twitter_index"
friendsFile = "data/friends_small"
followersFile = "data/followers_small"

struct twitterID
    id::UInt32
    followers::UInt32
    followersPosition::UInt64
    friends::UInt32
    friendsPosition::UInt64
end

function readIndexFile()
    file = open(indexFile, "r")
    numElements = Int64(read(file, UInt32))
    out = Vector{twitterID}(undef, numElements)
    temp = Vector{UInt32}(undef, 7)
    for k = 1:numElements
        read!(file, temp)
        out[k] = twitterID(temp[1], temp[2], reinterpret(UInt64, temp[3:4])[1], temp[5], reinterpret(UInt64, temp[6:7])[1])
    end
    return out
end

function printUser(user::twitterID)
    println("User ID: " * string(user.id, base=10))
    println("Followers: " * string(user.followers, base=10))
    println("Friends: " * string(user.friends, base=10))
end

function randUser(userArray::Vector{twitterID})
    numUsers = length(userArray)
    return userArray[Int64(ceil(rand()*numUsers))]
end

function readFollowers(user::twitterID)
    file = open(followersFile, "r")
    seek(file, user.followersPosition)
    output = Vector{UInt32}(undef, user.followers)
    read!(file, output)
    close(file)
    return output
end

function readFriends(user::twitterID)
    file = open(friendsFile, "r")
    seek(file, user.friendsPosition)
    output = Vector{UInt32}(undef, user.friends)
    read!(file, output)
    close(file)
    return output
end

function writeIndexFile(filename, out::Vector{twitterID})
    out32 = Vector{UInt32}(undef, Int64(7*length(out)))
    for k = 1:length(out)
        out32[7*k-6] = out[k].id
        out32[7*k-5] = out[k].followers
        out32[7*k-4:7*k-3] = reinterpret(UInt32, [out[k].followersPosition])
        out32[7*k-2] = out[k].friends
        out32[7*k-1:7*k] = reinterpret(UInt32, [out[k].friendsPosition])
    end
    file = open(filename, "w")
    write(file, UInt32(length(out)))
    write(file, out32)
    close(file)
end

function mergeIndexFiles(friendsIndexFile, followersIndexFile)
    #TO DO: Clean up this function, remove the hardcoded number of users before the while loop
    file1 = open(friendsIndexFile, "r")
    seekend(file1)
    file1Length = Int64(position(file1)/4)
    seekstart(file1)
    friends = Vector{UInt32}(undef, file1Length)
    read!(file1, friends)
    close(file1)

    file2 = open(followersIndexFile, "r")
    seekend(file2)
    file2Length = Int64(position(file2)/4)
    followers = Vector{UInt32}(undef, file2Length)
    seekstart(file2)
    read!(file2, followers)
    close(file2)

    k1 = 1
    k2 = 1
    k = 1
    out = Vector{twitterID}(undef, 41652229) #TO DO: Remove this hardcoded number
    while true
        if k1 > file1Length && k2>file2Length
            break
        end
        if k1 > file1Length || friends[k1] > followers[k2]
            temp = twitterID(followers[k2], followers[k2+1], reinterpret(UInt64, followers[k2+2:k2+3])[1], 0, 0)
            out[k] = temp
            k += 1
            k2 += 4
            continue
        end
        if k2 > file2Length || followers[k2] > friends[k1]
            temp = twitterID(friends[k1], 0, 0, friends[k1+1], reinterpret(UInt64, friends[k1+2:k1+3])[1])
            out[k] = temp
            k += 1
            k1+= 4
            continue
        end
        temp = twitterID(friends[k1], followers[k2+1], reinterpret(UInt64, followers[k2+2:k2+3])[1], friends[k1+1], reinterpret(UInt64, friends[k1+2:k1+3])[1])
        out[k] = temp
        k += 1
        k1+=4
        k2 += 4
    end
    followers = nothing
    friends = nothing
    k -= 1
    println(k)
end

function makeSmallFile(filename, bReverse::Bool)
    temp = Array{UInt64,1}(undef,1)
    file = open(filename, "r")
    temp[1] = read(file, UInt64)
    if bReverse
        yStart,xStart = reinterpret(UInt32, temp)
    else
        xStart,yStart = reinterpret(UInt32, temp)
    end
    seekstart(file)
    outFileName = filename*"_small"
    outFile = open(outFileName, "w")
    write(outFile, xStart)
    write(outFile, yStart)
    while !eof(file)
        temp[1] = read(file, UInt64)
        if bReverse
            y,x = reinterpret(UInt32, temp)
            if x == xStart
                if y != yStart
                    write(outFile, y)
                    yStart = y
                end
            else
                write(outFile, UInt32(0))
                write(outFile, x)
                write(outFile, y)
                xStart = x
                yStart = y
            end
        else
            x,y = reinterpret(UInt32, temp)
            if y == xStart
                if x != yStart
                    write(outFile, x)
                    xStart = x
                end
            else
                write(outFile, UInt32(0))
                write(outFile, x)
                write(outFile, y)
                xStart = x
                yStart = y
            end
        end

    end
    write(outFile, UInt32(0))
    close(file)
    close(outFile)
end

function makeIndexFile(filename)
    #Input should be the name of the LARGE file, not the _small file
    temp64 = Array{UInt64, 1}(undef, 1)
    temp128 = Array{UInt128, 1}(undef, 1)
    inFileName = filename * "_small"
    file = open(filename, "r")
    outFileName = filename * "_index"
    outFile = open(outFileName, "w")
    posStart = UInt64(position(file))
    idStart = read(file, UInt32)
    friends = UInt32(0)
    while !eof(file)
        id = read(file, UInt32)
        if id == UInt32(0)
            temp64 = reinterpret(UInt64, [idStart, friends])
            temp128 = reinterpret(UInt128, [temp64[1], posStart])
            write(outFile, temp128[1])
            if eof(file)
                break
            else
                posStart = UInt64(position(file))
                idStart = read(file, UInt32)
                friends = UInt32(0)
            end
        else
            friends += UInt32(1)
        end
    end
    close(file)
    close(outFile)
end
