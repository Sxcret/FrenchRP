-- How to use:
-- If a player uses /afk, they go into AFK mode, they will not be autodemoted and their salary is set to $0 (you can still be killed/vote demoted though!).
-- If a player does not use /afk, and they don't do anything for the demote time specified, they will be automatically demoted to hobo.

local function AFKDemote(ply)
    local shouldDemote, demoteTeam, suppressMsg, msg = hook.Call("playerAFKDemoted", nil, ply)
    demoteTeam = demoteTeam or GAMEMODE.DefaultTeam

    if ply:Team() ~= demoteTeam and shouldDemote ~= false then
        local rpname = ply:getFrenchRPVar("rpname")
        ply:changeTeam(demoteTeam, true)
        if not suppressMsg then FrenchRP.notifyAll(0, 5, msg or FrenchRP.getPhrase("hes_afk_demoted", rpname)) end
    end
    ply:setSelfFrenchRPVar("AFKDemoted", true)
    ply:setFrenchRPVar("job", "AFK")
end

local function SetAFK(ply)
    local rpname = ply:getFrenchRPVar("rpname")
    ply:setSelfFrenchRPVar("AFK", not ply:getFrenchRPVar("AFK"))

    SendUserMessage("blackScreen", ply, ply:getFrenchRPVar("AFK"))

    if ply:getFrenchRPVar("AFK") then
        FrenchRP.retrieveSalary(ply, function(amount) ply.OldSalary = amount end)
        ply.OldJob = ply:getFrenchRPVar("job")
        ply.lastHealth = ply:Health()
        FrenchRP.notifyAll(0, 5, FrenchRP.getPhrase("player_now_afk", rpname))

        ply.AFKDemote = math.huge

        ply:KillSilent()
        ply:Lock()
    else
        ply.AFKDemote = CurTime() + GAMEMODE.Config.afkdemotetime
        FrenchRP.notifyAll(1, 5, FrenchRP.getPhrase("player_no_longer_afk", rpname))
        FrenchRP.notify(ply, 0, 5, FrenchRP.getPhrase("salary_restored"))
        ply:Spawn()
        ply:UnLock()

        ply:SetHealth(ply.lastHealth and ply.lastHealth > 0 and ply.lastHealth or 100)
        ply.lastHealth = nil
    end
    ply:setFrenchRPVar("job", ply:getFrenchRPVar("AFK") and "AFK" or ply:getFrenchRPVar("AFKDemoted") and team.GetName(ply:Team()) or ply.OldJob)
    ply:setSelfFrenchRPVar("salary", ply:getFrenchRPVar("AFK") and 0 or ply.OldSalary or 0)

    hook.Run("playerSetAFK", ply, ply:getFrenchRPVar("AFK"))
end

FrenchRP.defineChatCommand("afk", function(ply)
    if ply.FrenchRPLastAFK and not ply:getFrenchRPVar("AFK") and ply.FrenchRPLastAFK > CurTime() - GAMEMODE.Config.AFKDelay then
        FrenchRP.notify(ply, 0, 5, FrenchRP.getPhrase("unable", "go AFK", "Spam prevention."))
        return ""
    end

    ply.FrenchRPLastAFK = CurTime()
    SetAFK(ply)

    return ""
end)

local function StartAFKOnPlayer(ply)
    ply.AFKDemote = CurTime() + GAMEMODE.Config.afkdemotetime
end
hook.Add("PlayerInitialSpawn", "StartAFKOnPlayer", StartAFKOnPlayer)

local function AFKTimer(ply, key)
    ply.AFKDemote = CurTime() + GAMEMODE.Config.afkdemotetime
    if ply:getFrenchRPVar("AFKDemoted") then
        ply:setFrenchRPVar("job", team.GetName(ply:Team()))
        timer.Simple(3, function() if IsValid(ply) then ply:setSelfFrenchRPVar("AFKDemoted", nil) end end)
    end
end
hook.Add("KeyPress", "FrenchRPKeyReleasedCheck", AFKTimer)

local function KillAFKTimer()
    for id, ply in pairs(player.GetAll()) do
        if ply.AFKDemote and CurTime() > ply.AFKDemote and not ply:getFrenchRPVar("AFK") then
            SetAFK(ply)
            AFKDemote(ply)
            ply.AFKDemote = math.huge
        end
    end
end
hook.Add("Think", "FrenchRPKeyPressedCheck", KillAFKTimer)

local function BlockAFKTeamChange(ply, t, force)
    if ply:getFrenchRPVar("AFK") and (not force or t ~= GAMEMODE.DefaultTeam) then
        local TEAM = RPExtraTeams[t]
        if TEAM then FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. TEAM.command, FrenchRP.getPhrase("afk_mode"))) end
        return false
    end
end
hook.Add("playerCanChangeTeam", "AFKCanChangeTeam", BlockAFKTeamChange)

-- For when a player's team is changed by force
hook.Add("OnPlayerChangedTeam", "AFKCanChangeTeam", function(ply)
    if not ply:getFrenchRPVar("AFK") then return end

    ply.OldSalary = ply:getFrenchRPVar("salary")
    ply.OldJob = nil
    ply:setSelfFrenchRPVar("salary", 0)
end)
