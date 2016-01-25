local plyMeta = FindMetaTable("Player")
local finishWarrantRequest
local arrestedPlayers = {}

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
function plyMeta:warrant(warranter, reason)
    if self.warranted then return end
    local suppressMsg = hook.Call("playerWarranted", GAMEMODE, self, warranter, reason)

    self.warranted = true
    timer.Simple(GAMEMODE.Config.searchtime, function()
        if not IsValid(self) then return end
        self:unWarrant(warranter)
    end)

    if suppressMsg then return end

    local warranterNick = IsValid(warranter) and warranter:Nick() or FrenchRP.getPhrase("disconnected_player")
    local centerMessage = FrenchRP.getPhrase("warrant_approved", self:Nick(), reason, warranterNick)
    local printMessage = FrenchRP.getPhrase("warrant_ordered", warranterNick, self:Nick(), reason)

    for a, b in pairs(player.GetAll()) do
        b:PrintMessage(HUD_PRINTCENTER, centerMessage)
        b:PrintMessage(HUD_PRINTCONSOLE, printMessage)
    end

    FrenchRP.notify(warranter, 0, 4, FrenchRP.getPhrase("warrant_approved2"))
end

function plyMeta:unWarrant(unwarranter)
    if not self.warranted then return end

    local suppressMsg = hook.Call("playerUnWarranted", GAMEMODE, self, unwarranter)

    self.warranted = false

    if suppressMsg then return end

    FrenchRP.notify(unwarranter, 2, 4, FrenchRP.getPhrase("warrant_expired", self:Nick()))
end

function plyMeta:requestWarrant(suspect, actor, reason)
    local question = FrenchRP.getPhrase("warrant_request", actor:Nick(), suspect:Nick(), reason)
    FrenchRP.createQuestion(question, suspect:EntIndex() .. "warrant", self, 40, finishWarrantRequest, actor, suspect, reason)
end

function plyMeta:wanted(actor, reason, time)
    local suppressMsg = hook.Call("playerWanted", FrenchRP.hooks, self, actor, reason)

    self:setFrenchRPVar("wanted", true)
    self:setFrenchRPVar("wantedReason", reason)

    timer.Create(self:UniqueID() .. " wantedtimer", time or GAMEMODE.Config.wantedtime, 1, function()
        if not IsValid(self) then return end
        self:unWanted()
    end)

    if suppressMsg then return end

    local actorNick = IsValid(actor) and actor:Nick() or FrenchRP.getPhrase("disconnected_player")
    local centerMessage = FrenchRP.getPhrase("wanted_by_police", self:Nick(), reason, actorNick)
    local printMessage = FrenchRP.getPhrase("wanted_by_police_print", actorNick, self:Nick(), reason)

    for _, ply in pairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, centerMessage)
        ply:PrintMessage(HUD_PRINTCONSOLE, printMessage)
    end

    FrenchRP.log(string.Replace(printMessage, "\n", " "), Color(0, 150, 255))
end

function plyMeta:unWanted(actor)
    local suppressMsg = hook.Call("playerUnWanted", GAMEMODE, self, actor)
    self:setFrenchRPVar("wanted", nil)
    self:setFrenchRPVar("wantedReason", nil)

    timer.Remove(self:UniqueID() .. " wantedtimer")

    if suppressMsg then return end

    local expiredMessage = IsValid(actor) and FrenchRP.getPhrase("wanted_revoked", self:Nick(), actor:Nick() or "") or
        FrenchRP.getPhrase("wanted_expired", self:Nick())

    FrenchRP.log(string.Replace(expiredMessage, "\n", " "), Color(0, 150, 255))

    for _, ply in pairs(player.GetAll()) do
        ply:PrintMessage(HUD_PRINTCENTER, expiredMessage)
        ply:PrintMessage(HUD_PRINTCONSOLE, expiredMessage)
    end
end

function plyMeta:arrest(time, arrester)
    time = time or GAMEMODE.Config.jailtimer or 120

    hook.Call("playerArrested", FrenchRP.hooks, self, time, arrester)
    if self:InVehicle() then self:ExitVehicle() end
    self:setFrenchRPVar("Arrested", true)
    arrestedPlayers[self:SteamID()] = true

    -- Always get sent to jail when Arrest() is called, even when already under arrest
    if GAMEMODE.Config.teletojail and FrenchRP.jailPosCount() ~= 0 then
        self:Spawn()
    end
end

function plyMeta:unArrest(unarrester)
    if not self:isArrested() then return end

    self:setFrenchRPVar("Arrested", nil)
    arrestedPlayers[self:SteamID()] = nil
    hook.Call("playerUnArrested", FrenchRP.hooks, self, unarrester)
end

/*---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------*/
local function CombineRequest(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return
        end
        for k, v in pairs(player.GetAll()) do
            if v:isCP() or v == ply then
                FrenchRP.talkToPerson(v, team.GetColor(ply:Team()), FrenchRP.getPhrase("request") .. ply:Nick(), Color(255, 0, 0, 255), text, ply)
            end
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("cr", CombineRequest, 1.5)

local function warrantCommand(ply, args)
    local target = FrenchRP.findPlayer(args[1])
    local reason = table.concat(args, " ", 2)

    local canRequest, message = hook.Call("canRequestWarrant", FrenchRP.hooks, target, ply, reason)
    if not canRequest then
        FrenchRP.notify(ply, 1, 4, message)
        return ""
    end

    if not RPExtraTeams[ply:Team()] or not RPExtraTeams[ply:Team()].mayor then -- No need to search through all the teams if the player is a mayor
        local mayors = {}

        for k,v in pairs(RPExtraTeams) do
            if v.mayor then
                table.Add(mayors, team.GetPlayers(k))
            end
        end

        if #mayors > 0 then -- Request a warrant if there's a mayor
            local mayor = table.Random(mayors)
            mayor:requestWarrant(target, ply, reason)
            FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("warrant_request2", mayor:Nick()))
            return ""
        end
    end

    target:warrant(ply, reason)

    return ""
end
FrenchRP.defineChatCommand("warrant", warrantCommand)

local function wantedCommand(ply, args)
    local target = FrenchRP.findPlayer(args[1])
    local reason = table.concat(args, " ", 2)

    local canWanted, message = hook.Call("canWanted", FrenchRP.hooks, target, ply, reason)
    if not canWanted then
        FrenchRP.notify(ply, 1, 4, message)
        return ""
    end

    target:wanted(ply, reason)

    return ""
end
FrenchRP.defineChatCommand("wanted", wantedCommand)

local function unwantedCommand(ply, args)
    local target = FrenchRP.findPlayer(args)

    local canUnwant, message = hook.Call("canUnwant", FrenchRP.hooks, target, ply)
    if not canUnwant then
        FrenchRP.notify(ply, 1, 4, message)
        return ""
    end

    target:unWanted(ply)

    return ""
end
FrenchRP.defineChatCommand("unwanted", unwantedCommand)

/*---------------------------------------------------------------------------
Admin commands
---------------------------------------------------------------------------*/
local function ccArrest(ply, args)
    if FrenchRP.jailPosCount() == 0 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("no_jail_pos"))
        return
    end

    local targets = FrenchRP.findPlayers(args[1])

    if not targets then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args[1]))
        return
    end

    for k, target in pairs(targets) do
        local length = tonumber(args[2])
        if length then
            target:arrest(length, ply)
        else
            target:arrest(nil, ply)
        end

        if ply:EntIndex() == 0 then
            FrenchRP.log("Console force-arrested " .. target:SteamName(), Color(0, 255, 255))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-arrested " .. target:SteamName(), Color(0, 255, 255))
        end
    end
end
FrenchRP.definePrivilegedChatCommand("arrest", "FrenchRP_AdminCommands", ccArrest)

local function ccUnarrest(ply, args)
    local targets = FrenchRP.findPlayers(args[1])

    if not targets then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args[1]))
        return
    end

    for _, target in pairs(targets) do
        target:unArrest(ply)
        if not target:Alive() then target:Spawn() end

        if ply:EntIndex() == 0 then
            FrenchRP.log("Console force-unarrested " .. target:SteamName(), Color(0, 255, 255))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-unarrested " .. target:SteamName(), Color(0, 255, 255))
        end
    end
end
FrenchRP.definePrivilegedChatCommand("unarrest", "FrenchRP_AdminCommands", ccUnarrest)

/*---------------------------------------------------------------------------
Callback functions
---------------------------------------------------------------------------*/
function finishWarrantRequest(choice, mayor, initiator, suspect, reason)
    if not tobool(choice) then
        FrenchRP.notify(initiator, 1, 4, FrenchRP.getPhrase("warrant_denied", mayor:Nick()))
        return
    end
    if IsValid(suspect) then
        suspect:warrant(initiator, reason)
    end
end

/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/

function FrenchRP.hooks:canArrest(arrester, arrestee)
    if IsValid(arrestee) and arrestee:IsPlayer() and arrestee:isCP() and not GAMEMODE.Config.cpcanarrestcp then
        return false, FrenchRP.getPhrase("cant_arrest_other_cp")
    end

    if not GAMEMODE.Config.npcarrest and arrestee:IsNPC() then
        return false, FrenchRP.getPhrase("unable", "arrest", "NPC")
    end

    if GAMEMODE.Config.needwantedforarrest and not arrestee:IsNPC() and not arrestee:getFrenchRPVar("wanted") then
        return false, FrenchRP.getPhrase("must_be_wanted_for_arrest")
    end

    if FAdmin and arrestee:IsPlayer() and arrestee:FAdmin_GetGlobal("fadmin_jailed") then
        return false, FrenchRP.getPhrase("cant_arrest_fadmin_jailed")
    end

    local jpc = FrenchRP.jailPosCount()

    if not jpc or jpc == 0 then
        return false, FrenchRP.getPhrase("cant_arrest_no_jail_pos")
    end

    if arrestee.Babygod then
        return false, FrenchRP.getPhrase("cant_arrest_spawning_players")
    end

    return true
end

function FrenchRP.hooks:playerArrested(ply, time, arrester)
    if ply:isWanted() then ply:unWanted(arrester) end
    ply:setFrenchRPVar("HasGunlicense", nil)

    ply:StripWeapons()

    if ply:isArrested() then return end -- hasn't been arrested before

    ply:PrintMessage(HUD_PRINTCENTER, FrenchRP.getPhrase("youre_arrested", time))
    for k, v in pairs(player.GetAll()) do
        if v == ply then continue end
        v:PrintMessage(HUD_PRINTCENTER, FrenchRP.getPhrase("hes_arrested", ply:Name(), time))
    end

    local steamID = ply:SteamID()
    timer.Create(ply:UniqueID() .. "jailtimer", time, 1, function()
        if IsValid(ply) then ply:unArrest() end
        arrestedPlayers[steamID] = nil
    end)
    umsg.Start("GotArrested", ply)
        umsg.Float(time)
    umsg.End()
end

function FrenchRP.hooks:playerUnArrested(ply, actor)
    if ply.Sleeping then
        FrenchRP.toggleSleep(ply, "force")
    end

    gamemode.Call("PlayerLoadout", ply)
    if GAMEMODE.Config.telefromjail then
        local ent, pos = hook.Call("PlayerSelectSpawn", GAMEMODE, ply)
        timer.Simple(0, function() if IsValid(ply) then ply:SetPos(pos or ent:GetPos()) end end) -- workaround for SetPos in weapon event bug
    end

    timer.Remove(ply:UniqueID() .. "jailtimer")
    FrenchRP.notifyAll(0, 4, FrenchRP.getPhrase("hes_unarrested", ply:Name()))
end

hook.Add("PlayerInitialSpawn", "Arrested", function(ply)
    if not arrestedPlayers[ply:SteamID()] then return end
    local time = GAMEMODE.Config.jailtimer
    -- Delay the actual arrest by a single frame to allow
    -- the player to initialise
    timer.Simple(0, fp{ply.arrest, ply, time})
    FrenchRP.notify(ply, 0, 5, FrenchRP.getPhrase("jail_punishment", time))
end)
