/*---------------------------------------------------------------------------
functions
---------------------------------------------------------------------------*/
local meta = FindMetaTable("Player")
function meta:addMoney(amount)
    if not amount then return false end
    local total = self:getFrenchRPVar("money") + math.floor(amount)
    total = hook.Call("playerWalletChanged", GAMEMODE, self, amount, self:getFrenchRPVar("money")) or total

    self:setFrenchRPVar("money", total)

    if self.FrenchRPUnInitialized then return end
    FrenchRP.storeMoney(self, total)
end

function FrenchRP.payPlayer(ply1, ply2, amount)
    if not IsValid(ply1) or not IsValid(ply2) then return end
    ply1:addMoney(-amount)
    ply2:addMoney(amount)
end

function meta:payDay()
    if not IsValid(self) then return end
    if not self:isArrested() then
        FrenchRP.retrieveSalary(self, function(amount)
            amount = math.floor(amount or GAMEMODE.Config.normalsalary)
            local suppress, message, hookAmount = hook.Call("playerGetSalary", GAMEMODE, self, amount)
            amount = hookAmount or amount

            if amount == 0 or not amount then
                if not suppress then FrenchRP.notify(self, 4, 4, message or FrenchRP.getPhrase("payday_unemployed")) end
            else
                self:addMoney(amount)
                if not suppress then FrenchRP.notify(self, 4, 4, message or FrenchRP.getPhrase("payday_message", FrenchRP.formatMoney(amount))) end
            end
        end)
    else
        FrenchRP.notify(self, 4, 4, FrenchRP.getPhrase("payday_missed"))
    end
end

function FrenchRP.createMoneyBag(pos, amount)
    local moneybag = ents.Create(GAMEMODE.Config.MoneyClass)
    moneybag:SetPos(pos)
    moneybag:Setamount(math.Min(amount, 2147483647))
    moneybag:Spawn()
    moneybag:Activate()
    if GAMEMODE.Config.moneyRemoveTime and  GAMEMODE.Config.moneyRemoveTime ~= 0 then
        timer.Create("RemoveEnt" .. moneybag:EntIndex(), GAMEMODE.Config.moneyRemoveTime, 1, fn.Partial(SafeRemoveEntity, moneybag))
    end
    return moneybag
end

/*---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------*/
local function GiveMoney(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    if not tonumber(args) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end
    local trace = ply:GetEyeTrace()

    if IsValid(trace.Entity) and trace.Entity:IsPlayer() and trace.Entity:GetPos():Distance(ply:GetPos()) < 150 then
        local amount = math.floor(tonumber(args))

        if amount < 1 then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ">=1"))
            return ""
        end

        if not ply:canAfford(amount) then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", ""))

            return ""
        end

        local RP = RecipientFilter()
        RP:AddAllPlayers()

        umsg.Start("anim_giveitem", RP)
            umsg.Entity(ply)
        umsg.End()
        ply.anim_GivingItem = true

        timer.Simple(1.2, function()
            if IsValid(ply) then
                local trace2 = ply:GetEyeTrace()
                if IsValid(trace2.Entity) and trace2.Entity:IsPlayer() and trace2.Entity:GetPos():Distance(ply:GetPos()) < 150 then
                    if not ply:canAfford(amount) then
                        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", ""))

                        return ""
                    end
                    FrenchRP.payPlayer(ply, trace2.Entity, amount)

                    FrenchRP.notify(trace2.Entity, 0, 4, FrenchRP.getPhrase("has_given", ply:Nick(), FrenchRP.formatMoney(amount)))
                    FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("you_gave", trace2.Entity:Nick(), FrenchRP.formatMoney(amount)))
                    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") has given " .. FrenchRP.formatMoney(amount) .. " to " .. trace2.Entity:Nick() .. " (" .. trace2.Entity:SteamID() .. ")")
                end
            else
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/give", ""))
            end
        end)
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "player"))
    end
    return ""
end
FrenchRP.defineChatCommand("give", GiveMoney, 0.2)

local function DropMoney(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    if not tonumber(args) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end
    local amount = math.floor(tonumber(args))

    if amount < 1 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ">0"))
        return ""
    end

    if amount >= 2147483647 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", "<2,147,483,647"))
        return ""
    end

    if not ply:canAfford(amount) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", ""))

        return ""
    end

    ply:addMoney(-amount)
    local RP = RecipientFilter()
    RP:AddAllPlayers()

    umsg.Start("anim_dropitem", RP)
        umsg.Entity(ply)
    umsg.End()
    ply.anim_DroppingItem = true

    timer.Simple(1, function()
        if not IsValid(ply) then return end

        local trace = {}
        trace.start = ply:EyePos()
        trace.endpos = trace.start + ply:GetAimVector() * 85
        trace.filter = ply

        local tr = util.TraceLine(trace)
        FrenchRP.createMoneyBag(tr.HitPos, amount)
        FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") has dropped " .. FrenchRP.formatMoney(amount))
    end)

    return ""
end
FrenchRP.defineChatCommand("dropmoney", DropMoney, 0.3)
FrenchRP.defineChatCommand("moneydrop", DropMoney, 0.3)

local function CreateCheque(ply, args)
    local recipient = FrenchRP.findPlayer(args[1])
    local amount = tonumber(args[2]) or 0

    if not recipient then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", "recipient (1)"))
        return ""
    end

    if amount <= 1 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", "amount (2)"))
        return ""
    end

    if not ply:canAfford(amount) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", ""))

        return ""
    end

    if IsValid(ply) and IsValid(recipient) then
        ply:addMoney(-amount)
    end

    umsg.Start("anim_dropitem", RecipientFilter():AddAllPlayers())
        umsg.Entity(ply)
    umsg.End()
    ply.anim_DroppingItem = true

    timer.Simple(1, function()
        if IsValid(ply) and IsValid(recipient) then
            local trace = {}
            trace.start = ply:EyePos()
            trace.endpos = trace.start + ply:GetAimVector() * 85
            trace.filter = ply

            local tr = util.TraceLine(trace)
            local Cheque = ents.Create("frenchrp_cheque")
            Cheque:SetPos(tr.HitPos)
            Cheque:Setowning_ent(ply)
            Cheque:Setrecipient(recipient)

            Cheque:Setamount(math.Min(amount, 2147483647))
            Cheque:Spawn()
        else
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/cheque", ""))
        end
    end)
    return ""
end
FrenchRP.defineChatCommand("cheque", CreateCheque, 0.3)
FrenchRP.defineChatCommand("check", CreateCheque, 0.3) -- for those of you who can't spell

local function ccSetMoney(ply, args)
    if not tonumber(args[2]) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
        return
    end

    local target = FrenchRP.findPlayer(args[1])

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args[1])))
        return
    end

    local amount = math.floor(tonumber(args[2]))

    if target then
        FrenchRP.storeMoney(target, amount)
        target:setFrenchRPVar("money", amount)

        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("you_set_x_money", target:Nick(), FrenchRP.formatMoney(amount), ""))

        FrenchRP.notify(target, 0, 4, FrenchRP.getPhrase("x_set_your_money", ply:EntIndex() == 0 and "Console" or ply:Nick(), FrenchRP.formatMoney(amount), ""))
        if ply:EntIndex() == 0 then
            FrenchRP.log("Console set " .. target:SteamName() .. "'s money to " .. FrenchRP.formatMoney(amount), Color(30, 30, 30))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") set " .. target:SteamName() .. "'s money to " ..  FrenchRP.formatMoney(amount), Color(30, 30, 30))
        end
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args[1]))
    end
end
FrenchRP.definePrivilegedChatCommand("setmoney", "FrenchRP_SetMoney", ccSetMoney)

local function ccAddMoney(ply, args)
    if not tonumber(args[2]) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
        return
    end

    local target = FrenchRP.findPlayer(args[1])

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args[1])))
        return
    end

    local amount = math.floor(tonumber(args[2]))

    if target then
        target:addMoney(amount)

        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("you_gave", target:Nick(), FrenchRP.formatMoney(amount)))

        FrenchRP.notify(target, 0, 4, FrenchRP.getPhrase("x_set_your_money", ply:EntIndex() == 0 and "Console" or ply:Nick(), FrenchRP.formatMoney(target:getFrenchRPVar("money")), ""))
        if ply:EntIndex() == 0 then
            FrenchRP.log("Console added " .. FrenchRP.formatMoney(amount) .. " to " .. target:SteamName() .. "'s wallet", Color(30, 30, 30))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") added " .. FrenchRP.formatMoney(amount) .. " to " .. target:SteamName() .. "'s wallet", Color(30, 30, 30))
        end
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args[1]))
    end
end
FrenchRP.definePrivilegedChatCommand("addmoney", "FrenchRP_SetMoney", ccAddMoney)
