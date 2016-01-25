FrenchRP.getAvailableVehicles = FrenchRP.stub{
    name = "getAvailableVehicles",
    description = "Get the available vehicles that FrenchRP supports.",
    parameters = {
    },
    returns = {
        {
            name = "vehicles",
            description = "Names, models and classnames of all supported vehicles.",
            type = "table"
        }
    },
    metatable = FrenchRP
}
