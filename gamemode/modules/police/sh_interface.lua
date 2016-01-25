FrenchRP.PLAYER.isWanted = FrenchRP.stub{
    name = "isWanted",
    description = "Whether this player is wanted",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is wanted",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.getWantedReason = FrenchRP.stub{
    name = "getWantedReason",
    description = "Get the reason why someone is wanted",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "The reason",
            type = "string"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.isArrested = FrenchRP.stub{
    name = "isArrested",
    description = "Whether this player is arrested",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is arrested",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.isCP = FrenchRP.stub{
    name = "isCP",
    description = "Whether this player is part of the police force (mayor, cp, chief).",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is part of the police force.",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.isMayor = FrenchRP.stub{
    name = "isMayor",
    description = "Whether this player is a mayor.",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is a mayor.",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.isChief = FrenchRP.stub{
    name = "isChief",
    description = "Whether this player is a Chief.",
    parameters = {
    },
    returns = {
        {
            name = "answer",
            description = "Whether this player is a Chief.",
            type = "boolean"
        }
    },
    metatable = FrenchRP.PLAYER
}


FrenchRP.hookStub{
    name = "canRequestWarrant",
    description = "Whether someone can request a search warrant.",
    parameters = {
        {
            name = "target",
            description = "The player to get the search warrant for",
            type = "Player"
        },
        {
            name = "actor",
            description = "The player requesting the warrant",
            type = "Player"
        },
        {
            name = "reason",
            description = "The reason for the search warrant",
            type = "Player"
        }
    },
    returns = {
        {
            name = "canRequest",
            description = "A yes or no as to whether the search warrant can be requested",
            type = "boolean"
        },
        {
            name = "message",
            description = "The message that is shown when it can't",
            type = "string"
        }
    }
}

FrenchRP.hookStub{
    name = "canWanted",
    description = "Whether someone can make a player wanted",
    parameters = {
        {
            name = "target",
            description = "The player to make wanted by the police",
            type = "Player"
        },
        {
            name = "actor",
            description = "The player requesting the wanted status",
            type = "Player"
        },
        {
            name = "reason",
            description = "The reason",
            type = "Player"
        }
    },
    returns = {
        {
            name = "canRequest",
            description = "A yes or no as to whether the wanted can be requested",
            type = "boolean"
        },
        {
            name = "message",
            description = "The message that is shown when it can't",
            type = "string"
        }
    }
}

FrenchRP.hookStub{
    name = "canUnwant",
    description = "Whether someone can remove the wanted status from a player",
    parameters = {
        {
            name = "target",
            description = "The player to make wanted by the police",
            type = "Player"
        },
        {
            name = "actor",
            description = "The player requesting the wanted status",
            type = "Player"
        }
    },
    returns = {
        {
            name = "canUnwant",
            description = "A yes or no answer",
            type = "boolean"
        },
        {
            name = "message",
            description = "The message that is shown when the answer is no",
            type = "string"
        }
    }
}
