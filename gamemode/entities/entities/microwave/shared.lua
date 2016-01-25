ENT.Base = "lab_base"
ENT.PrintName = "Microwave"

function ENT:initVars()
    self.model = "models/props/cs_office/microwave.mdl"
    self.initialPrice = GAMEMODE.Config.microwavefoodcost
    self.labPhrase = FrenchRP.getPhrase("microwave")
    self.itemPhrase = string.lower(FrenchRP.getPhrase("food"))
end
