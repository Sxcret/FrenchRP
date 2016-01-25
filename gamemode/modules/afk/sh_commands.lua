FrenchRP.registerFrenchRPVar("AFK", net.WriteBit, fn.Compose{tobool, net.ReadBit})
FrenchRP.registerFrenchRPVar("AFKDemoted", net.WriteBit, fn.Compose{tobool, net.ReadBit})

FrenchRP.declareChatCommand{
    command = "afk",
    description = "Go AFK",
    delay = 1.5
}
