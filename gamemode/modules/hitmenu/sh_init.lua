local plyMeta = FindMetaTable("Player")
local hitmanTeams = {}

function plyMeta:isHitman()
    return hitmanTeams[self:Team()]
end

function plyMeta:hasHit()
    return self:getFrenchRPVar("hasHit") or false
end

function plyMeta:getHitTarget()
    return self:getFrenchRPVar("hitTarget")
end

function plyMeta:getHitPrice()
    return self:getFrenchRPVar("hitPrice") or GAMEMODE.Config.minHitPrice
end

function FrenchRP.addHitmanTeam(job)
    if not job or not RPExtraTeams[job] then return end
    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["hitmen"][RPExtraTeams[job].command] then return end

    hitmanTeams[job] = true
end

FrenchRP.getHitmanTeams = fp{fn.Id, hitmanTeams}

function FrenchRP.hooks:canRequestHit(hitman, customer, target, price)
    if not hitman:isHitman() then return false, FrenchRP.getPhrase("player_not_hitman") end
    if customer:GetPos():Distance(hitman:GetPos()) > GAMEMODE.Config.minHitDistance then return false, FrenchRP.getPhrase("distance_too_big") end
    if hitman == target then return false, FrenchRP.getPhrase("hitman_no_suicide") end
    if hitman == customer then return false, FrenchRP.getPhrase("hitman_no_self_order") end
    if not customer:canAfford(price) then return false, FrenchRP.getPhrase("cant_afford", FrenchRP.getPhrase("hit")) end
    if price < GAMEMODE.Config.minHitPrice then return false, FrenchRP.getPhrase("price_too_low") end
    if hitman:hasHit() then return false, FrenchRP.getPhrase("hitman_already_has_hit") end
    if IsValid(target) and ((target:getFrenchRPVar("lastHitTime") or -GAMEMODE.Config.hitTargetCooldown) > CurTime() - GAMEMODE.Config.hitTargetCooldown) then return false, FrenchRP.getPhrase("hit_target_recently_killed_by_hit") end
    if IsValid(customer) and ((customer.lastHitAccepted or -GAMEMODE.Config.hitCustomerCooldown) > CurTime() - GAMEMODE.Config.hitCustomerCooldown) then return false, FrenchRP.getPhrase("customer_recently_bought_hit") end

    return true
end

hook.Add("onJobRemoved", "hitmenuUpdate", function(i, job)
    hitmanTeams[i] = nil
end)

/*---------------------------------------------------------------------------
FrenchRPVars
---------------------------------------------------------------------------*/
FrenchRP.registerFrenchRPVar("hasHit", net.WriteBit, fn.Compose{tobool, net.ReadBit})
FrenchRP.registerFrenchRPVar("hitTarget", net.WriteEntity, net.ReadEntity)
FrenchRP.registerFrenchRPVar("hitPrice", fn.Curry(fn.Flip(net.WriteInt), 2)(32), fn.Partial(net.ReadInt, 32))
FrenchRP.registerFrenchRPVar("lastHitTime", fn.Curry(fn.Flip(net.WriteInt), 2)(32), fn.Partial(net.ReadInt, 32))

/*---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------*/
FrenchRP.declareChatCommand{
    command = "hitprice",
    description = "Set the price of your hits",
    condition = plyMeta.isHitman,
    delay = 10
}

FrenchRP.declareChatCommand{
    command = "requesthit",
    description = "Request a hit from the player you're looking at",
    delay = 5,
    condition = fn.Compose{fn.Not, fn.Null, fn.Curry(fn.Filter, 2)(plyMeta.isHitman), player.GetAll}
}
