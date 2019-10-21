import numpy as np
from random import randint
from math import floor
indexFileName = "data/twitter_index"
friendsFileName = "data/friends_small"
followersFileName = "data/followers_small"

twitterID = np.dtype([
    ("id", np.uint32),
    ("followers", np.uint32),
    ("followersPosition", np.uint64),
    ("friends", np.uint32),
    ("friendsPosition", np.uint64)
    ])

class twitterGraph():

    def __init__(self):
        with open(indexFileName, "r") as file:
            self.numUsers = np.fromfile(file, np.uint32, count=1)[0]
            self.userData = np.fromfile(file, twitterID, count=self.numUsers)

        self._indexFileName = indexFileName
        self._friendsFileName = friendsFileName
        self._followersFileName = followersFileName
        self.userIDs = [int(x["id"]) for x in self.userData]

    def getUser(self, id):
        kStart = 0
        kEnd = self.numUsers - 1
        if self.userIDs[0] == id:
            return self.userData[0]
        if self.userIDs[kEnd] == id:
            return self.userData[kEnd]

        n = 1
        while n < 10000:
            kTemp = floor((kStart+kEnd)/2)
            if self.userIDs[kTemp] == id:
                return self.userData[kTemp]
            elif kTemp == kStart:
                return None
            elif self.userIDs[kTemp] > id:
                kEnd = kTemp
            else:
                kStart = kTemp
            n += 1
        return None

    def getFollowers(self, user):
        if user["followers"] == 0:
            return []
        with open(self._followersFileName, "r") as file:
            file.seek(user["followersPosition"])
            assert user["id"] == np.fromfile(file, np.uint32, count=1)[0]
            out = np.fromfile(file, np.uint32, count=user["followers"])
            assert np.fromfile(file, np.uint32, count=1)[0] == 0
        return out

    def getFriends(self, user):
        if user["friends"]==0:
            return []
        with open(self._friendsFileName, "r") as file:
            file.seek(user["friendsPosition"])
            assert user["id"] == np.fromfile(file, np.uint32, count=1)[0]
            out = np.fromfile(file, np.uint32, count=user["friends"])
            assert np.fromfile(file, np.uint32, count=1)[0] == 0
        return out

    def getRandomUser(self):
        return self.userData[randint(1,self.numUsers)-1]
