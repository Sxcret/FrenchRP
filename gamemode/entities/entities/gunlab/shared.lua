ENT.Base = "lab_base"
ENT.PrintName = "Gun Lab"

function ENT:initVars()
    self.model = "models/props_c17/TrapPropeller_Engine.mdl"
    self.initialPrice = 200
    self.labPhrase = FrenchRP.getPhrase("gun_lab")
    self.itemPhrase = FrenchRP.getPhrase("gun")
end
