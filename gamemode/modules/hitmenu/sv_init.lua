local plyMeta = FindMetaTable("Player")
local hits = {}
local questionCallback

/*---------------------------------------------------------------------------
Net messages
---------------------------------------------------------------------------*/
util.AddNetworkString("onHitAccepted")
util.AddNetworkString("onHitCompleted")
util.AddNetworkString("onHitFailed")

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
FrenchRP.getHits = fp{fn.Id, hits}

function plyMeta:requestHit(customer, target, price)
    local canRequest, msg, cost = hook.Call("canRequestHit", FrenchRP.hooks, self, customer, target, price)
    price = cost or price

    if canRequest == false then
        FrenchRP.notify(customer, 1, 4, msg)
        return false
    end

    FrenchRP.createQuestion(FrenchRP.getPhrase("accept_hit_request", customer:Nick(), target:Nick(), FrenchRP.formatMoney(price)),
        "hit" .. self:UserID() .. "|" .. customer:UserID() .. "|" .. target:UserID(),
        self,
        20,
        questionCallback,
        customer,
        target,
        price
    )

    FrenchRP.notify(customer, 1, 4, FrenchRP.getPhrase("hit_requested"))

    return true
end

function plyMeta:placeHit(customer, target, price)
    if hits[self] then FrenchRP.error("This person has an active hit!", 2) end

    if not customer:canAfford(price) then
        FrenchRP.notify(customer, 1, 4, FrenchRP.getPhrase("cant_afford", FrenchRP.getPhrase("hit")))
        return
    end

    hits[self] = {}
    hits[self].price = price -- the agreed upon price (as opposed to the price set by the hitman)

    self:setHitCustomer(customer)
    self:setHitTarget(target)

    FrenchRP.payPlayer(customer, self, price)

    hook.Call("onHitAccepted", FrenchRP.hooks, self, target, customer)
end

function plyMeta:setHitTarget(target)
    if not hits[self] then FrenchRP.error("This person has no active hit!", 2) end

    self:setSelfFrenchRPVar("hitTarget", target)
    self:setFrenchRPVar("hasHit", target and true or nil)
end

function plyMeta:setHitPrice(price)
    self:setFrenchRPVar("hitPrice", math.Min(GAMEMODE.Config.maxHitPrice or 50000, math.Max(GAMEMODE.Config.minHitPrice or 200, price)))
end

function plyMeta:setHitCustomer(customer)
    if not hits[self] then FrenchRP.error("This person has no active hit!", 2) end

    hits[self].customer = customer
end

function plyMeta:getHitCustomer()
    return hits[self] and hits[self].customer or nil
end

function plyMeta:abortHit(message)
    if not hits[self] then FrenchRP.error("This person has no active hit!", 2) end

    message = message or ""

    hook.Call("onHitFailed", FrenchRP.hooks, self, self:getHitTarget(), message)
    FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("hit_aborted", message))

    self:finishHit()
end

function plyMeta:finishHit()
    self:setHitCustomer(nil)
    self:setHitTarget(nil)
    hits[self] = nil
end

function questionCallback(answer, hitman, customer, target, price)
    if not IsValid(customer) then return end
    if not IsValid(hitman) or not hitman:isHitman() then return end

    if not IsValid(customer) then
        FrenchRP.notify(hitman, 1, 4, FrenchRP.getPhrase("customer_left_server"))
        return
    end

    if not IsValid(target) then
        FrenchRP.notify(hitman, 1, 4, FrenchRP.getPhrase("target_left_server"))
        return
    end

    if not tobool(answer) then
        FrenchRP.notify(customer, 1, 4, FrenchRP.getPhrase("hit_declined"))
        return
    end

    if hits[hitman] then return end

    FrenchRP.notify(hitman, 1, 4, FrenchRP.getPhrase("hit_accepted"))

    hitman:placeHit(customer, target, price)
end

/*---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------*/
FrenchRP.defineChatCommand("hitprice", function(ply, args)
    if not ply:isHitman() then return "" end
    local price = tonumber(args) or 0
    ply:setHitPrice(price)
    price = ply:getHitPrice()

    FrenchRP.notify(ply, 2, 4, FrenchRP.getPhrase("hit_price_set", FrenchRP.formatMoney(price)))

    return ""
end)

FrenchRP.defineChatCommand("requesthit", function(ply, args)
    args = string.Explode(' ', args)
    local target = FrenchRP.findPlayer(args[1])
    local traceEnt = ply:GetEyeTrace().Entity
    local hitman = IsValid(traceEnt) and traceEnt:IsPlayer() and traceEnt or Player(tonumber(args[2] or -1) or -1)

    if not IsValid(hitman) or not IsValid(target) or not hitman:IsPlayer() then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
        return ""
    end

    hitman:requestHit(ply, target, hitman:getHitPrice())

    return ""
end)

/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/
function FrenchRP.hooks:onHitAccepted(hitman, target, customer)
    net.Start("onHitAccepted")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteEntity(customer)
    net.Broadcast()

    FrenchRP.notify(customer, 0, 8, FrenchRP.getPhrase("hit_accepted"))
    customer.lastHitAccepted = CurTime()

    FrenchRP.log("Hitman " .. hitman:Nick() .. " accepted a hit on " .. target:Nick() .. ", ordered by " .. customer:Nick() .. " for " .. FrenchRP.formatMoney(hits[hitman].price), Color(255, 0, 255))
end

function FrenchRP.hooks:onHitCompleted(hitman, target, customer)
    net.Start("onHitCompleted")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteEntity(customer)
    net.Broadcast()

    FrenchRP.notifyAll(0, 6, FrenchRP.getPhrase("hit_complete", hitman:Nick()))

    local targetname = IsValid(target) and target:Nick() or "disconnected player"

    FrenchRP.log("Hitman " .. hitman:Nick() .. " finished a hit on " .. targetname .. ", ordered by " .. hits[hitman].customer:Nick() .. " for " .. FrenchRP.formatMoney(hits[hitman].price),
        Color(255, 0, 255))

    target:setFrenchRPVar("lastHitTime", CurTime())

    hitman:finishHit()
end

function FrenchRP.hooks:onHitFailed(hitman, target, reason)
    net.Start("onHitFailed")
        net.WriteEntity(hitman)
        net.WriteEntity(target)
        net.WriteString(reason)
    net.Broadcast()

    local targetname = IsValid(target) and target:Nick() or "disconnected player"

    FrenchRP.log("Hit on " .. targetname .. " failed. Reason: " .. reason, Color(255, 0, 255))
end

hook.Add("PlayerDeath", "FrenchRP Hitman System", function(ply, inflictor, attacker)
    if hits[ply] then -- player was hitman
        ply:abortHit(FrenchRP.getPhrase("hitman_died"))
    end

    if IsValid(attacker) and attacker:IsPlayer() and hits[attacker] and attacker:getHitTarget() == ply then
        hook.Call("onHitCompleted", FrenchRP.hooks, attacker, ply, hits[attacker].customer)
    end

    for hitman, hit in pairs(hits) do
        if not hitman or not IsValid(hitman) then hits[hitman] = nil continue end
        if hitman:getHitTarget() == ply then
            hitman:abortHit(FrenchRP.getPhrase("target_died"))
        end
    end
end)

hook.Add("PlayerDisconnected", "Hitman system", function(ply)
    if hits[ply] then
        ply:abortHit(FrenchRP.getPhrase("hitman_left_server"))
    end

    for hitman, hit in pairs(hits) do
        if hitman:getHitTarget() == ply then
            hitman:abortHit(FrenchRP.getPhrase("target_left_server"))
        end

        if hit.customer == ply then
            hitman:abortHit(FrenchRP.getPhrase("customer_left_server"))
        end
    end
end)

hook.Add("playerArrested", "Hitman system", function(ply)
    if not hits[ply] or not IsValid(hits[ply].customer) then return end

    for k, v in pairs(player.GetAll()) do
        if not GAMEMODE.CivilProtection[v:Team()] then continue end

        FrenchRP.notify(v, 0, 8, FrenchRP.getPhrase("x_had_hit_ordered_by_y", ply:Nick(), hits[ply].customer:Nick()))
    end

    ply:abortHit(FrenchRP.getPhrase("hitman_arrested"))
end)

hook.Add("OnPlayerChangedTeam", "Hitman system", function(ply, prev, new)
    if hits[ply] then
        ply:abortHit(FrenchRP.getPhrase("hitman_changed_team"))
    end
end)
