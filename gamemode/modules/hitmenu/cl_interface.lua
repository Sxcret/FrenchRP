FrenchRP.openHitMenu = FrenchRP.stub{
    name = "openHitMenu",
    description = "Open the menu that requests a hit.",
    parameters = {
        {
            name = "hitman",
            description = "The hitman to request the hit to.",
            type = "Player",
            optional = false
        }
    },
    returns = {
    },
    metatable = FrenchRP
}

FrenchRP.PLAYER.drawHitInfo = FrenchRP.stub{
    name = "drawHitInfo",
    description = "Start drawing the hit information above a hitman.",
    parameters = {
    },
    returns = {
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.stopHitInfo = FrenchRP.stub{
    name = "stopHitInfo",
    description = "Stop drawing the hit information above a hitman.",
    parameters = {
    },
    returns = {
    },
    metatable = FrenchRP.PLAYER
}
