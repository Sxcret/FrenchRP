AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:initVars()

    self:SetModel(self.model)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE)

    local phys = self:GetPhysicsObject()
    phys:Wake()

    self.sparking = false
    self.damage = 100
    self:Setprice(math.Clamp(self.initialPrice, (GAMEMODE.Config.pricemin ~= 0 and GAMEMODE.Config.pricemin) or self.initialPrice, (GAMEMODE.Config.pricecap ~= 0 and GAMEMODE.Config.pricecap) or self.initialPrice))
end

function ENT:OnTakeDamage(dmg)
    self:TakePhysicsDamage(dmg)

    self.damage = self.damage - dmg:GetDamage()
    if self.damage <= 0 and not self.Destructed then
        self.Destructed = true
        self:Destruct()
        self:Remove()
    end
end

function ENT:Destruct()
    local vPoint = self:GetPos()

    util.BlastDamage(self, self, vPoint, 200, 200)
    local effectdata = EffectData()
    effectdata:SetStart(vPoint)
    effectdata:SetOrigin(vPoint)
    effectdata:SetScale(1)
    util.Effect("Explosion", effectdata)
end

function ENT:SalePrice(activator)
    local owner = self:Getowning_ent()

    if activator == owner then
        if self.allowed and type(self.allowed) == "table" and table.HasValue(self.allowed, activator:Team()) then
            return math.ceil(self:Getprice() * 0.8)
        else
            return math.ceil(self:Getprice() * 0.9)
        end
    else
        return self:Getprice()
    end
end

ENT.Once = false
function ENT:Use(activator, caller)
    -- The lab cannot be used by non-players (e.g. wire user)
    -- The player must be known for the lab to work.
    if not activator:IsPlayer() then return end

    if self.Once then return end

    local owner = self:Getowning_ent()

    if not IsValid(owner) then
        FrenchRP.notify(activator, 1, 3, FrenchRP.getPhrase("cant_afford", FrenchRP.getPhrase("disabled", self.labPhrase, FrenchRP.getPhrase("disconnected_player"))))
        return
    end

    local cost = self:SalePrice(activator)

    if not activator:canAfford(cost) then
        FrenchRP.notify(activator, 1, 3, FrenchRP.getPhrase("cant_afford", self.itemPhrase))
        return
    end

    local diff = cost - self:SalePrice(owner)
    if not self.noIncome and diff < 0 and not owner:canAfford(math.abs(diff)) then
        FrenchRP.notify(activator, 1, 3, FrenchRP.getPhrase("owner_poor", self.labPhrase))
        return
    end

    if not self:canUse(activator) then return end

    self.Once = true
    self.sparking = true

    activator:addMoney(-cost)
    FrenchRP.notify(activator, 0, 3, FrenchRP.getPhrase("you_bought", self.itemPhrase, FrenchRP.formatMoney(cost)))

    if activator ~= owner and not self.noIncome then
        if diff == 0 then
            FrenchRP.notify(owner, 0, 3, FrenchRP.getPhrase("you_received_x", FrenchRP.formatMoney(0) .. " " .. FrenchRP.getPhrase("profit"), self.itemPhrase))
        else
            owner:addMoney(diff)
            local word = FrenchRP.getPhrase("profit")
            if diff < 0 then word = FrenchRP.getPhrase("loss") end
            FrenchRP.notify(owner, 0, 3, FrenchRP.getPhrase("you_received_x", FrenchRP.formatMoney(math.abs(diff)) .. " " .. word, self.itemPhrase))
        end
    end

    timer.Create(self:EntIndex() .. self.itemPhrase, 1, 1, function()
        if not IsValid(self) then return end
        if IsValid(activator) then
            self:createItem(activator)
        end
        self.Once = false
        self.sparking = false
    end)
end

function ENT:canUse(owner, activator)
    return true
end

function ENT:createItem(activator)
    -- Implement this function
end

function ENT:Think()
    if self.sparking then
        local effectdata = EffectData()
        effectdata:SetOrigin(self:GetPos())
        effectdata:SetMagnitude(1)
        effectdata:SetScale(1)
        effectdata:SetRadius(2)
        util.Effect("Sparks", effectdata)
    end
end

function ENT:OnRemove()
    timer.Remove(self:EntIndex() .. self.itemPhrase)
end
