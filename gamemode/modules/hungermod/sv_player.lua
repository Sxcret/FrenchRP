local meta = FindMetaTable("Player")

function meta:newHungerData()
    if not IsValid(self) then return end
    self:setSelfFrenchRPVar("Energy", 100)
end

function meta:hungerUpdate()
    if not IsValid(self) then return end
    if not GAMEMODE.Config.hungerspeed then return end

    local energy = self:getFrenchRPVar("Energy")
    local override = hook.Call("hungerUpdate", nil, self, energy)

    if override then return end

    self:setSelfFrenchRPVar("Energy", energy and math.Clamp(energy - GAMEMODE.Config.hungerspeed, 0, 100) or 100)

    if self:getFrenchRPVar("Energy") == 0 then
        self:SetHealth(self:Health() - GAMEMODE.Config.starverate)
        if self:Health() <= 0 then
            self.Slayed = true
            self:Kill()
            hook.Call("playerStarved", nil, self)
        end
    end
end
