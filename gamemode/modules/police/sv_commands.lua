local function updateAgenda(ply, agenda, text)
    local txt = hook.Run("agendaUpdated", ply, agenda, text)

    agenda.text = txt or text

    for k,v in pairs(player.GetAll()) do
        if v:getAgendaTable() ~= agenda then continue end

        v:setSelfFrenchRPVar("agenda", agenda.text)
        FrenchRP.notify(v, 2, 4, FrenchRP.getPhrase("agenda_updated"))
    end
end

local function CreateAgenda(ply, args)
    local agenda = ply:getAgendaTable()
    local plyTeam = ply:Team()

    if not agenda or not agenda.ManagersByKey[plyTeam] then
        FrenchRP.notify(ply, 1, 6, FrenchRP.getPhrase("unable", "agenda", "Incorrect team"))
        return ""
    end

    updateAgenda(ply, agenda, args)

    return ""
end
FrenchRP.defineChatCommand("agenda", CreateAgenda, 0.1)

local function addAgenda(ply, args)
    local agenda = ply:getAgendaTable()
    local plyTeam = ply:Team()

    if not agenda or not agenda.ManagersByKey[plyTeam] then
        FrenchRP.notify(ply, 1, 6, FrenchRP.getPhrase("unable", "agenda", "Incorrect team"))
        return ""
    end

    agenda.text = agenda.text or ""
    args = args or ""

    updateAgenda(ply, agenda, agenda.text .. '\n' .. args)

    return ""
end
FrenchRP.defineChatCommand("addagenda", addAgenda, 0.1)

/*---------------------------------------------------------
 Mayor stuff
 ---------------------------------------------------------*/
local LotteryPeople = {}
local LotteryON = false
local LotteryAmount = 0
local CanLottery = CurTime()
local function EnterLottery(answer, ent, initiator, target, TimeIsUp)
    if tobool(answer) and not table.HasValue(LotteryPeople, target) then
        if not target:canAfford(LotteryAmount) then
            FrenchRP.notify(target, 1,4, FrenchRP.getPhrase("cant_afford", "lottery"))

            return
        end
        table.insert(LotteryPeople, target)
        target:addMoney(-LotteryAmount)
        FrenchRP.notify(target, 0,4, FrenchRP.getPhrase("lottery_entered", FrenchRP.formatMoney(LotteryAmount)))
        hook.Run("playerEnteredLottery", target)
    elseif IsValid(target) and answer ~= nil and not table.HasValue(LotteryPeople, target) then
        FrenchRP.notify(target, 1,4, FrenchRP.getPhrase("lottery_not_entered", "You"))
    end

    if TimeIsUp then
        LotteryON = false
        CanLottery = CurTime() + 60

        if table.Count(LotteryPeople) == 0 then
            FrenchRP.notifyAll(1, 4, FrenchRP.getPhrase("lottery_noone_entered"))
            hook.Run("lotteryEnded", LotteryPeople, nil)
            return
        end
        local chosen = LotteryPeople[math.random(1, #LotteryPeople)]
        hook.Run("lotteryEnded", LotteryPeople, chosen, #LotteryPeople * LotteryAmount)
        chosen:addMoney(#LotteryPeople * LotteryAmount)
        FrenchRP.notifyAll(0, 10, FrenchRP.getPhrase("lottery_won", chosen:Nick(), FrenchRP.formatMoney(#LotteryPeople * LotteryAmount)))
    end
end

local function DoLottery(ply, amount)
    if not ply:isMayor() then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("incorrect_job", "/lottery"))
        return ""
    end

    if not GAMEMODE.Config.lottery then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("disabled", "/lottery", ""))
        return ""
    end

    if #player.GetAll() <= 2 or LotteryON then
        FrenchRP.notify(ply, 1, 6, FrenchRP.getPhrase("unable", "/lottery", ""))
        return ""
    end

    if CanLottery > CurTime() then
        FrenchRP.notify(ply, 1, 5, FrenchRP.getPhrase("have_to_wait", tostring(CanLottery - CurTime()), "/lottery"))
        return ""
    end

    amount = tonumber(amount)
    if not amount then
        FrenchRP.notify(ply, 1, 5, string.format("Please specify an entry cost ($%i-%i)", GAMEMODE.Config.minlotterycost, GAMEMODE.Config.maxlotterycost))
        return ""
    end

    LotteryAmount = math.Clamp(math.floor(amount), GAMEMODE.Config.minlotterycost, GAMEMODE.Config.maxlotterycost)

    hook.Run("lotteryStarted", ply, LotteryAmount)

    LotteryON = true
    LotteryPeople = {}
    for k,v in pairs(player.GetAll()) do
        if v ~= ply then
            FrenchRP.createQuestion(FrenchRP.getPhrase("lottery_has_started", FrenchRP.formatMoney(LotteryAmount)), "lottery" .. tostring(k), v, 30, EnterLottery, ply, v)
        end
    end
    timer.Create("Lottery", 30, 1, function() EnterLottery(nil, nil, nil, nil, true) end)
    return ""
end
FrenchRP.defineChatCommand("lottery", DoLottery, 1)


local lastLockdown = -math.huge
function FrenchRP.lockdown(ply)
    local show = ply:EntIndex() == 0 and print or fp{FrenchRP.notify, ply, 1, 4}
    if GetGlobalBool("FrenchRP_LockDown") then
        show(FrenchRP.getPhrase("unable", "/lockdown", FrenchRP.getPhrase("stop_lockdown")))
        return ""
    end

    if ply:EntIndex() ~= 0 and not ply:isMayor() then
        show(FrenchRP.getPhrase("incorrect_job", "/lockdown", ""))
        return ""
    end

    if not GAMEMODE.Config.lockdown then
        show(ply, 1, 4, FrenchRP.getPhrase("disabled", "lockdown", ""))
        return ""
    end

    if lastLockdown > CurTime() - GAMEMODE.Config.lockdowndelay then
        show(FrenchRP.getPhrase("wait_with_that"))
        return ""
    end

    for _, v in pairs(player.GetAll()) do
        v:ConCommand("play " .. GAMEMODE.Config.lockdownsound .. "\n")
    end

    FrenchRP.printMessageAll(HUD_PRINTTALK, FrenchRP.getPhrase("lockdown_started"))
    SetGlobalBool("FrenchRP_LockDown", true)
    FrenchRP.notifyAll(0, 3, FrenchRP.getPhrase("lockdown_started"))

    return ""
end
FrenchRP.defineChatCommand("lockdown", FrenchRP.lockdown)

function FrenchRP.unLockdown(ply)
    local show = ply:EntIndex() == 0 and print or fp{FrenchRP.notify, ply, 1, 4}

    if not GetGlobalBool("FrenchRP_LockDown") then
        show(FrenchRP.getPhrase("unable", "/unlockdown", FrenchRP.getPhrase("lockdown_ended")))
        return ""
    end

    if ply:EntIndex() ~= 0 and not ply:isMayor() then
        show(FrenchRP.getPhrase("incorrect_job", "/unlockdown", ""))
        return ""
    end

    FrenchRP.printMessageAll(HUD_PRINTTALK, FrenchRP.getPhrase("lockdown_ended"))
    FrenchRP.notifyAll(0, 3, FrenchRP.getPhrase("lockdown_ended"))
    SetGlobalBool("FrenchRP_LockDown", false)

    lastLockdown = CurTime()

    return ""
end
FrenchRP.defineChatCommand("unlockdown", FrenchRP.unLockdown)

/*---------------------------------------------------------
 License
 ---------------------------------------------------------*/
local function GrantLicense(answer, Ent, Initiator, Target)
    Initiator.LicenseRequested = nil
    if tobool(answer) then
        FrenchRP.notify(Initiator, 0, 4, FrenchRP.getPhrase("gunlicense_granted", Target:Nick(), Initiator:Nick()))
        FrenchRP.notify(Target, 0, 4, FrenchRP.getPhrase("gunlicense_granted", Target:Nick(), Initiator:Nick()))
        Initiator:setFrenchRPVar("HasGunlicense", true)
    else
        FrenchRP.notify(Initiator, 1, 4, FrenchRP.getPhrase("gunlicense_denied", Target:Nick(), Initiator:Nick()))
    end
end

local function RequestLicense(ply)
    if ply:getFrenchRPVar("HasGunlicense") or ply.LicenseRequested then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/requestlicense", ""))
        return ""
    end
    local LookingAt = ply:GetEyeTrace().Entity

    local ismayor--first look if there's a mayor
    local ischief-- then if there's a chief
    local iscop-- and then if there's a cop to ask
    for k,v in pairs(player.GetAll()) do
        if v:isMayor() and not v:getFrenchRPVar("AFK") then
            ismayor = true
            break
        end
    end

    if not ismayor then
        for k,v in pairs(player.GetAll()) do
            if v:isChief() and not v:getFrenchRPVar("AFK") then
                ischief = true
                break
            end
        end
    end

    if not ischief and not ismayor then
        for k,v in pairs(player.GetAll()) do
            if v:isCP() then
                iscop = true
                break
            end
        end
    end

    if not ismayor and not ischief and not iscop then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/requestlicense", ""))
        return ""
    end

    if not IsValid(LookingAt) or not LookingAt:IsPlayer() or LookingAt:GetPos():Distance(ply:GetPos()) > 100 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "mayor/chief/cop"))
        return ""
    end

    if ismayor and not LookingAt:isMayor() then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "mayor"))
        return ""
    elseif ischief and not LookingAt:isChief() then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "chief"))
        return ""
    elseif iscop and not LookingAt:isCP() then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "cop"))
        return ""
    end

    ply.LicenseRequested = true
    FrenchRP.notify(ply, 3, 4, FrenchRP.getPhrase("gunlicense_requested", ply:Nick(), LookingAt:Nick()))
    FrenchRP.createQuestion(FrenchRP.getPhrase("gunlicense_question_text", ply:Nick()), "Gunlicense" .. ply:EntIndex(), LookingAt, 20, GrantLicense, ply, LookingAt)
    return ""
end
FrenchRP.defineChatCommand("requestlicense", RequestLicense)

local function GiveLicense(ply)
    local noMayorExists = fn.Compose{fn.Null, fn.Curry(fn.Filter, 2)(ply.isMayor), player.GetAll}
    local noChiefExists = fn.Compose{fn.Null, fn.Curry(fn.Filter, 2)(ply.isChief), player.GetAll}

    local canGiveLicense = fn.FOr{
        ply.isMayor, -- Mayors can hand out licenses
        fn.FAnd{ply.isChief, noMayorExists}, -- Chiefs can if there is no mayor
        fn.FAnd{ply.isCP, noChiefExists, noMayorExists} -- CP's can if there are no chiefs nor mayors
    }

    if not canGiveLicense(ply) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("incorrect_job", "/givelicense"))
        return ""
    end

    local LookingAt = ply:GetEyeTrace().Entity
    if not IsValid(LookingAt) or not LookingAt:IsPlayer() or LookingAt:GetPos():Distance(ply:GetPos()) > 100 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", "player"))
        return ""
    end

    FrenchRP.notify(LookingAt, 0, 4, FrenchRP.getPhrase("gunlicense_granted", ply:Nick(), LookingAt:Nick()))
    FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("gunlicense_granted", ply:Nick(), LookingAt:Nick()))
    LookingAt:setFrenchRPVar("HasGunlicense", true)

    return ""
end
FrenchRP.defineChatCommand("givelicense", GiveLicense)

local function rp_GiveLicense(ply, arg)
    local target = FrenchRP.findPlayer(arg)

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(arg)))
        return
    end

    target:setFrenchRPVar("HasGunlicense", true)

    local nick, steamID
    if ply:EntIndex() ~= 0 then
        nick = ply:Nick()
        steamID = ply:SteamID()
    else
        nick = "Console"
        steamID = "Console"
    end

    FrenchRP.notify(target, 0, 4, FrenchRP.getPhrase("gunlicense_granted", nick, target:Nick()))
    if ply ~= target then
        FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("gunlicense_granted", nick, target:Nick()))
    end
    FrenchRP.log(nick .. " (" .. steamID .. ") force-gave " .. target:Nick() .. " a gun license", Color(30, 30, 30))
end
FrenchRP.definePrivilegedChatCommand("setlicense", "FrenchRP_SetLicense", rp_GiveLicense)

local function rp_RevokeLicense(ply, arg)
    local target = FrenchRP.findPlayer(arg)

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(arg)))
        return
    end

    target:setFrenchRPVar("HasGunlicense", nil)

    local nick, steamID
    if ply:EntIndex() ~= 0 then
        nick = ply:Nick()
        steamID = ply:SteamID()
    else
        nick = "Console"
        steamID = "Console"
    end

    FrenchRP.notify(target, 1, 4, FrenchRP.getPhrase("gunlicense_denied", nick, target:Nick()))
    if ply ~= target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("gunlicense_denied", nick, target:Nick()))
    end
    FrenchRP.log(nick .. " (" .. steamID .. ") force-removed " .. target:Nick() .. "'s gun license", Color(30, 30, 30))
end
FrenchRP.definePrivilegedChatCommand("unsetlicense", "FrenchRP_SetLicense", rp_RevokeLicense)

local function FinishRevokeLicense(vote, win)
    if choice == 1 then
        vote.target:setFrenchRPVar("HasGunlicense", nil)
        vote.target:StripWeapons()
        gamemode.Call("PlayerLoadout", vote.target)
        FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("gunlicense_removed", vote.target:Nick()))
    else
        FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("gunlicense_not_removed", vote.target:Nick()))
    end
end

local function VoteRemoveLicense(ply, args)
    if #args == 1 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("vote_specify_reason"))
        return ""
    end
    local reason = ""
    for i = 2, #args, 1 do
        reason = reason .. " " .. args[i]
    end
    reason = string.sub(reason, 2)
    if string.len(reason) > 22 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/demotelicense", "<23"))
        return ""
    end
    local p = FrenchRP.findPlayer(args[1])
    if p then
        if CurTime() - ply.LastVoteCop < 80 then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("have_to_wait", math.ceil(80 - (CurTime() - ply:GetTable().LastVoteCop)), "/demotelicense"))
            return ""
        end
        if ply:getFrenchRPVar("HasGunlicense") then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/demotelicense", ""))
        else
            local voteInfo = FrenchRP.createVote(p:Nick() .. ":\n" .. FrenchRP.getPhrase("gunlicense_remove_vote_text2", reason), "removegunlicense", p, 20, FinishRevokeLicense, {
                [p] = true,
                [ply] = true
            }, nil, nil, {
                source = ply
            })

            if voteInfo then
                -- Vote has started
                FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("gunlicense_remove_vote_text", ply:Nick(), p:Nick()))
            end
            ply.LastVoteCop = CurTime()
        end
        return ""
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args[1])))
        return ""
    end
end
FrenchRP.defineChatCommand("demotelicense", VoteRemoveLicense)
