FrenchRP.PLAYER.addMoney = FrenchRP.stub{
    name = "addMoney",
    description = "Give money to a player.",
    parameters = {
        {
            name = "amount",
            description = "The amount of money to give to the player. A negative amount means you're substracting money.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = FrenchRP.PLAYER
}

FrenchRP.PLAYER.payDay = FrenchRP.stub{
    name = "payDay",
    description = "Give a player their salary.",
    parameters = {
    },
    returns = {
    },
    metatable = FrenchRP.PLAYER
}


FrenchRP.payPlayer = FrenchRP.stub{
    name = "payPlayer",
    description = "Make one player give money to the other player.",
    parameters = {
        {
            name = "sender",
            description = "The player who gives the money.",
            type = "Player",
            optional = false
        },
        {
            name = "receiver",
            description = "The player who receives the money.",
            type = "Player",
            optional = false
        },
        {
            name = "amount",
            description = "The amount of money.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = FrenchRP
}

FrenchRP.createMoneyBag = FrenchRP.stub{
    name = "createMoneyBag",
    description = "Create a money bag.",
    parameters = {
        {
            name = "pos",
            description = "The The position where the money bag is to be spawned.",
            type = "Vector",
            optional = false
        },
        {
            name = "amount",
            description = "The amount of money.",
            type = "number",
            optional = false
        }
    },
    returns = {
        {
            name = "moneybag",
            description = "The money bag entity.",
            type = "Entity"
        }
    },
    metatable = FrenchRP
}
