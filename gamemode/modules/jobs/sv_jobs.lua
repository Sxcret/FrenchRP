/*---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------*/
local meta = FindMetaTable("Player")
function meta:changeTeam(t, force, suppressNotification)
    local prevTeam = self:Team()
    local notify = suppressNotification and fn.Id or FrenchRP.notify
    local notifyAll = suppressNotification and fn.Id or FrenchRP.notifyAll

    if self:isArrested() and not force then
        notify(self, 1, 4, FrenchRP.getPhrase("unable", team.GetName(t), ""))
        return false
    end

    local allowed, time = self:changeAllowed(t)
    if t ~= GAMEMODE.DefaultTeam and not allowed and not force then
        local notif = time and FrenchRP.getPhrase("have_to_wait",  math.ceil(time), "/job, " .. FrenchRP.getPhrase("banned_or_demoted")) or FrenchRP.getPhrase("unable", team.GetName(t), FrenchRP.getPhrase("banned_or_demoted"))
        notify(self, 1, 4, notif)
        return false
    end

    if self.LastJob and GAMEMODE.Config.changejobtime - (CurTime() - self.LastJob) >= 0 and not force then
        notify(self, 1, 4, FrenchRP.getPhrase("have_to_wait",  math.ceil(GAMEMODE.Config.changejobtime - (CurTime() - self.LastJob)), "/job"))
        return false
    end

    if self.IsBeingDemoted then
        self:teamBan()
        self.IsBeingDemoted = false
        self:changeTeam(GAMEMODE.DefaultTeam, true)
        FrenchRP.destroyVotesWithEnt(self)
        notify(self, 1, 4, FrenchRP.getPhrase("tried_to_avoid_demotion"))

        return false
    end


    if prevTeam == t then
        notify(self, 1, 4, FrenchRP.getPhrase("unable", team.GetName(t), ""))
        return false
    end

    local TEAM = RPExtraTeams[t]
    if not TEAM then return false end

    if TEAM.customCheck and not TEAM.customCheck(self) and (not force or force and not GAMEMODE.Config.adminBypassJobRestrictions) then
        local message = isfunction(TEAM.CustomCheckFailMsg) and TEAM.CustomCheckFailMsg(self, TEAM) or
            TEAM.CustomCheckFailMsg or
            FrenchRP.getPhrase("unable", team.GetName(t), "")
        notify(self, 1, 4, message)
        return false
    end

    if not force then
        if type(TEAM.NeedToChangeFrom) == "number" and prevTeam ~= TEAM.NeedToChangeFrom then
            notify(self, 1,4, FrenchRP.getPhrase("need_to_be_before", team.GetName(TEAM.NeedToChangeFrom), TEAM.name))
            return false
        elseif type(TEAM.NeedToChangeFrom) == "table" and not table.HasValue(TEAM.NeedToChangeFrom, prevTeam) then
            local teamnames = ""
            for a, b in pairs(TEAM.NeedToChangeFrom) do
                teamnames = teamnames .. " or " .. team.GetName(b)
            end
            notify(self, 1,4, string.format(string.sub(teamnames, 5), team.GetName(TEAM.NeedToChangeFrom), TEAM.name))
            return false
        end
        local max = TEAM.max
        if max ~= 0 and -- No limit
        (max >= 1 and team.NumPlayers(t) >= max or -- absolute maximum
        max < 1 and (team.NumPlayers(t) + 1) / #player.GetAll() > max) then -- fractional limit (in percentages)
            notify(self, 1, 4,  FrenchRP.getPhrase("team_limit_reached", TEAM.name))
            return false
        end
    end

    if TEAM.PlayerChangeTeam then
        local val = TEAM.PlayerChangeTeam(self, prevTeam, t)
        if val ~= nil then
            return val
        end
    end

    local hookValue, reason = hook.Call("playerCanChangeTeam", nil, self, t, force)
    if hookValue == false then
        if reason then
            notify(self, 1, 4, reason)
        end
        return false
    end

    local isMayor = RPExtraTeams[prevTeam] and RPExtraTeams[prevTeam].mayor
    if isMayor and GetGlobalBool("FrenchRP_LockDown") then
        FrenchRP.unLockdown(self)
    end
    self:updateJob(TEAM.name)
    self:setSelfFrenchRPVar("salary", TEAM.salary)
    notifyAll(0, 4, FrenchRP.getPhrase("job_has_become", self:Nick(), TEAM.name))


    if self:getFrenchRPVar("HasGunlicense") and GAMEMODE.Config.revokeLicenseOnJobChange then
        self:setFrenchRPVar("HasGunlicense", nil)
    end
    if TEAM.hasLicense then
        self:setFrenchRPVar("HasGunlicense", true)
    end

    self.LastJob = CurTime()

    if GAMEMODE.Config.removeclassitems then
        for k, v in pairs(FrenchRPEntities) do
            if GAMEMODE.Config.preventClassItemRemoval[v.ent] then continue end
            if not v.allowed then continue end
            if type(v.allowed) == "table" and (table.HasValue(v.allowed, t) or not table.HasValue(v.allowed, prevTeam)) then continue end
            for _, e in pairs(ents.FindByClass(v.ent)) do
                if e.SID == self.SID then e:Remove() end
            end
        end

        if not GAMEMODE.Config.preventClassItemRemoval["spawned_shipment"] then
            for k,v in pairs(ents.FindByClass("spawned_shipment")) do
                if v.allowed and type(v.allowed) == "table" and table.HasValue(v.allowed, t) then continue end
                if v.SID == self.SID then v:Remove() end
            end
        end
    end

    if isMayor then
        for _, ent in pairs(self.lawboards or {}) do
            if IsValid(ent) then
                ent:Remove()
            end
        end
    end

    if isMayor and GAMEMODE.Config.shouldResetLaws then
        FrenchRP.resetLaws()
    end

    self:SetTeam(t)
    hook.Call("OnPlayerChangedTeam", GAMEMODE, self, prevTeam, t)
    FrenchRP.log(self:Nick() .. " (" .. self:SteamID() .. ") changed to " .. team.GetName(t), nil, Color(100, 0, 255))
    if self:InVehicle() then self:ExitVehicle() end
    if GAMEMODE.Config.norespawn and self:Alive() then
        self:StripWeapons()
        local vPoint = self:GetShootPos() + Vector(0,0,50)
        local effectdata = EffectData()
        effectdata:SetEntity(self)
        effectdata:SetStart(vPoint) -- Not sure if we need a start and origin (endpoint) for this effect, but whatever
        effectdata:SetOrigin(vPoint)
        effectdata:SetScale(1)
        util.Effect("entity_remove", effectdata)
        player_manager.SetPlayerClass(self, TEAM.playerClass or "player_frenchrp")
        self:applyPlayerClassVars(false)
        gamemode.Call("PlayerSetModel", self)
        gamemode.Call("PlayerLoadout", self)
    else
        self:KillSilent()
    end

    umsg.Start("OnChangedTeam", self)
        umsg.Short(prevTeam)
        umsg.Short(t)
    umsg.End()
    return true
end

function meta:updateJob(job)
    self:setFrenchRPVar("job", job)
    self.LastJob = CurTime()

    timer.Create(self:UniqueID() .. "jobtimer", GAMEMODE.Config.paydelay, 0, function()
        if not IsValid(self) then return end
        self:payDay()
    end)
end

function meta:teamUnBan(Team)
    if not IsValid(self) then return end
    self.bannedfrom = self.bannedfrom or {}

    local group = FrenchRP.getDemoteGroup(Team)
    self.bannedfrom[group] = nil
end

function meta:teamBan(t, time)
    if not self.bannedfrom then self.bannedfrom = {} end
    t = t or self:Team()

    local group = FrenchRP.getDemoteGroup(t)
    self.bannedfrom[group] = true

    local timerid = "teamban" .. self:UserID() .. "," .. group.value

    timer.Remove(timerid)

    if time == 0 then return end

    timer.Create(timerid, time or GAMEMODE.Config.demotetime, 1, function()
        if not IsValid(self) then return end
        self:teamUnBan(t)
    end)
end

function meta:teamBanTimeLeft(t)
    local group = FrenchRP.getDemoteGroup(t or self:Team())
    return timer.TimeLeft("teamban" .. self:UserID() .. "," .. (group and group.value or ""))
end

function meta:changeAllowed(t)
    local group = FrenchRP.getDemoteGroup(t)
    if self.bannedfrom and self.bannedfrom[group] then return false, self:teamBanTimeLeft(t) end

    return true
end

function GM:canChangeJob(ply, args)
    if ply:isArrested() then return false end
    if ply.LastJob and 10 - (CurTime() - ply.LastJob) >= 0 then return false, FrenchRP.getPhrase("have_to_wait", math.ceil(10 - (CurTime() - ply.LastJob)), "/job") end
    if not ply:Alive() then return false end

    local len = string.len(args)

    if len < 3 then return false, FrenchRP.getPhrase("unable", "/job", ">2") end
    if len > 25 then return false, FrenchRP.getPhrase("unable", "/job", "<26") end

    return true
end

/*---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------*/
local function ChangeJob(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    if not GAMEMODE.Config.customjobs then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("disabled", "/job", ""))
        return ""
    end

    local canChangeJob, message, replace = gamemode.Call("canChangeJob", ply, args)
    if canChangeJob == false then
        FrenchRP.notify(ply, 1, 4, message or FrenchRP.getPhrase("unable", "/job", ""))
        return ""
    end

    local job = replace or args
    FrenchRP.notifyAll(2, 4, FrenchRP.getPhrase("job_has_become", ply:Nick(), job))
    ply:updateJob(job)
    return ""
end
FrenchRP.defineChatCommand("job", ChangeJob)

local function FinishDemote(vote, choice)
    local target = vote.target

    target.IsBeingDemoted = nil
    if choice == 1 then
        target:teamBan()
        if target:Alive() then
            target:changeTeam(GAMEMODE.DefaultTeam, true)
            if target:isArrested() then
                target:arrest()
            end
        else
            target.demotedWhileDead = true
        end

        hook.Call("onPlayerDemoted", nil, vote.info.source, target, vote.info.reason)
        FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("demoted", target:Nick()))
    else
        FrenchRP.notifyAll(1, 4, FrenchRP.getPhrase("demoted_not", target:Nick()))
    end
end

local function Demote(ply, args)
    if #args == 1 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("vote_specify_reason"))
        return ""
    end
    local reason = table.concat(args, ' ', 2)

    if string.len(reason) > 99 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/demote", "<100"))
        return ""
    end
    local p = FrenchRP.findPlayer(args[1])
    if p == ply then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_demote_self"))
        return ""
    end

    local canDemote, message = hook.Call("canDemote", GAMEMODE, ply, p, reason)
    if canDemote == false then
        FrenchRP.notify(ply, 1, 4, message or FrenchRP.getPhrase("unable", "demote", ""))
        return ""
    end

    if not p then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args)))
        return ""
    end

    if CurTime() - ply.LastVoteCop < 80 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("have_to_wait", math.ceil(80 - (CurTime() - ply:GetTable().LastVoteCop)), "/demote"))
        return ""
    end

    if not RPExtraTeams[p:Team()] or RPExtraTeams[p:Team()].candemote == false then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/demote", ""))
    else
        FrenchRP.talkToPerson(p, team.GetColor(ply:Team()), FrenchRP.getPhrase("demote") .. " " .. ply:Nick(), Color(255, 0, 0, 255), FrenchRP.getPhrase("i_want_to_demote_you", reason), p)

        local voteInfo = FrenchRP.createVote(p:Nick() .. ":\n" .. FrenchRP.getPhrase("demote_vote_text", reason), "demote", p, 20, FinishDemote, {
            [p] = true,
            [ply] = true
        }, function(vote)
            if not IsValid(vote.target) then return end
            vote.target.IsBeingDemoted = nil
        end, {
            source = ply,
            reason = reason
        })

        if voteInfo then
            -- Vote has started
            FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("demote_vote_started", ply:Nick(), p:Nick()))
            FrenchRP.log(FrenchRP.getPhrase("demote_vote_started", string.format("%s(%s)[%s]", ply:Nick(), ply:SteamID(), team.GetName(ply:Team())), string.format("%s(%s)[%s] for %s", p:Nick(), p:SteamID(), team.GetName(p:Team()), reason)), Color(255, 128, 255, 255))
            p.IsBeingDemoted = true
        end
        ply.LastVoteCop = CurTime()
    end
    return ""
end
FrenchRP.defineChatCommand("demote", Demote)

local function ExecSwitchJob(answer, ent, ply, target)
    ply.RequestedJobSwitch = nil
    if not tobool(answer) then return end
    local Pteam = ply:Team()
    local Tteam = target:Team()

    if not ply:changeTeam(Tteam) then return end
    if not target:changeTeam(Pteam) then
        ply:changeTeam(Pteam, true) -- revert job change
        return
    end
    FrenchRP.notify(ply, 2, 4, FrenchRP.getPhrase("job_switch"))
    FrenchRP.notify(target, 2, 4, FrenchRP.getPhrase("job_switch"))
end

local function SwitchJob(ply) --Idea by Godness.
    if not GAMEMODE.Config.allowjobswitch then return "" end

    if ply.RequestedJobSwitch then return end

    local eyetrace = ply:GetEyeTrace()
    if not eyetrace or not eyetrace.Entity or not eyetrace.Entity:IsPlayer() then return "" end

    local team1 = RPExtraTeams[ply:Team()]
    local team2 = RPExtraTeams[eyetrace.Entity:Team()]

    if not team1 or not team2 then return "" end
    if team1.customCheck and not team1.customCheck(eyetrace.Entity) or team2.customCheck and not team2.customCheck(ply) then
        -- notify only the player trying to switch
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "switch jobs", ""))
        return ""
    end

    ply.RequestedJobSwitch = true
    FrenchRP.createQuestion(FrenchRP.getPhrase("job_switch_question", ply:Nick()), "switchjob" .. tostring(ply:EntIndex()), eyetrace.Entity, 30, ExecSwitchJob, ply, eyetrace.Entity)
    FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("job_switch_requested"))

    return ""
end
FrenchRP.defineChatCommand("switchjob", SwitchJob)
FrenchRP.defineChatCommand("switchjobs", SwitchJob)
FrenchRP.defineChatCommand("jobswitch", SwitchJob)


local function DoTeamBan(ply, args)
    local ent = args[1]
    local Team = args[2]

    if not Team then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "arguments", ""))
        return
    end

    local target = FrenchRP.findPlayer(ent)
    if not target or not IsValid(target) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", ent or ""))
        return
    end

    local found = false
    for k,v in pairs(RPExtraTeams) do
        if string.lower(v.name) == string.lower(Team) or string.lower(v.command) == string.lower(Team) or k == tonumber(Team or -1) then
            Team = k
            found = true
            break
        end
    end

    if not found then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", Team or ""))
        return
    end

    target:teamBan(tonumber(Team), tonumber(args[3] or 0))

    local nick
    if ply:EntIndex() == 0 then
        nick = "Console"
    else
        nick = ply:Nick()
    end
    FrenchRP.notifyAll(0, 5, FrenchRP.getPhrase("x_teambanned_y", nick, target:Nick(), team.GetName(tonumber(Team))))
end
FrenchRP.definePrivilegedChatCommand("teamban", "FrenchRP_AdminCommands", DoTeamBan)

local function DoTeamUnBan(ply, args)
    if #args < 2 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "arguments", ""))
        return
    end

    local ent = args[1]
    local Team = args[2]

    local target = FrenchRP.findPlayer(ent)
    if not target or not IsValid(target) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", ent or ""))
        return
    end

    local found = false
    for k,v in pairs(RPExtraTeams) do
        if string.lower(v.name) == string.lower(Team) or  string.lower(v.command) == string.lower(Team) then
            Team = k
            found = true
            break
        end
        if k == tonumber(Team or -1) then
            found = true
            break
        end
    end

    if not found then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", Team or ""))
        return
    end

    target:teamUnBan(tonumber(Team))

    local nick
    if ply:EntIndex() == 0 then
        nick = "Console"
    else
        nick = ply:Nick()
    end
    FrenchRP.notifyAll(0, 5, FrenchRP.getPhrase("x_teamunbanned_y", nick, target:Nick(), team.GetName(tonumber(Team))))
end
FrenchRP.definePrivilegedChatCommand("teamunban", "FrenchRP_AdminCommands", DoTeamUnBan)
