local function HMPlayerSpawn(ply)
    ply:setSelfFrenchRPVar("Energy", 100)
end
hook.Add("PlayerSpawn", "HMPlayerSpawn", HMPlayerSpawn)

local function HMThink()
    for k, v in pairs(player.GetAll()) do
        if not v:Alive() then continue end
        v:hungerUpdate()
    end
end
timer.Create("HMThink", 10, 0, HMThink)

local function HMPlayerInitialSpawn(ply)
    ply:newHungerData()
end
hook.Add("PlayerInitialSpawn", "HMPlayerInitialSpawn", HMPlayerInitialSpawn)

local function HMAFKHook(ply, afk)
    if afk then
        ply.preAFKHunger = ply:getFrenchRPVar("Energy")
    else
        ply:setFrenchRPVar("Energy", ply.preAFKHunger or 100)
        ply.preAFKHunger = nil
    end
end
hook.Add("playerSetAFK", "Hungermod", HMAFKHook)

timer.Simple(0, function()
    for k, v in pairs(player.GetAll()) do
        if v:getFrenchRPVar("Energy") ~= nil then continue end
        v:newHungerData()
    end
end)

local function BuyFood(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 85
    trace.filter = ply

    local tr = util.TraceLine(trace)

    for _,v in pairs(FoodItems) do
        if string.lower(args) ~= string.lower(v.name) then continue end

        if (v.requiresCook == nil or v.requiresCook == true) and not ply:isCook() then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/buyfood", FrenchRP.getPhrase("cooks_only")))
            return ""
        end

        if v.customCheck and not v.customCheck(ply) then
            if v.customCheckMessage then
                FrenchRP.notify(ply, 1, 4, v.customCheckMessage)
            end
            return ""
        end

        local cost = v.price

        if not ply:canAfford(cost) then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", string.lower(FrenchRP.getPhrase("food"))))
            return ""
        end
        ply:addMoney(-cost)
        FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("you_bought", v.name, FrenchRP.formatMoney(cost), ""))

        local SpawnedFood = ents.Create("spawned_food")
        SpawnedFood:Setowning_ent(ply)
        SpawnedFood:SetPos(tr.HitPos)
        SpawnedFood.onlyremover = true
        SpawnedFood.SID = ply.SID
        SpawnedFood:SetModel(v.model)

        -- for backwards compatibility
        SpawnedFood.FoodName = v.name
        SpawnedFood.FoodEnergy = v.energy
        SpawnedFood.FoodPrice = v.price

        SpawnedFood.foodItem = v
        SpawnedFood:Spawn()

        hook.Call("playerBoughtFood", nil, ply, v, SpawnedFood, cost)
        return ""
    end
    FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
    return ""
end
FrenchRP.defineChatCommand("buyfood", BuyFood)
