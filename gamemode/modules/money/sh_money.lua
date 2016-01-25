local pMeta = FindMetaTable("Player")
local entMeta = FindMetaTable("Entity")

function pMeta:canAfford(amount)
    if not amount or self.FrenchRPUnInitialized then return false end
    return math.floor(amount) >= 0 and (self:getFrenchRPVar("money") or 0) - math.floor(amount) >= 0
end

function entMeta:isMoneyBag()
    return self.IsSpawnedMoney or self:GetClass() == GAMEMODE.Config.MoneyClass
end
