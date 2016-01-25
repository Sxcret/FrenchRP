local function checkFrenchRP(ply, target, t)
    if not FrenchRP then return true end

    local TEAM = RPExtraTeams[t]
    if not TEAM then return true end

    if TEAM.customCheck and not TEAM.customCheck(target) then
        return false
    end

    local hookValue = hook.Call("playerCanChangeTeam", nil, target, t, true)
    if hookValue == false then return false end

    local a = TEAM.admin
    if a > 0 and not target:IsAdmin()
    or a > 1 and not target:IsSuperAdmin()
    then return false end

    return true
end

local function SetTeam(ply, cmd, args)
    local targets = FAdmin.FindPlayer(args[1])
    if not targets or #targets == 1 and not IsValid(targets[1]) then
        FAdmin.Messages.SendMessage(ply, 1, "Player not found")
        return false
    end

    for k,v in pairs(team.GetAllTeams()) do
        if k == tonumber(args[2]) or string.lower(v.Name) == string.lower(args[2] or "") then
            for _, target in pairs(targets) do
                if not FAdmin.Access.PlayerHasPrivilege(ply, "SetTeam", target) then FAdmin.Messages.SendMessage(ply, 5, "No access!") return false end
                local SetTeam = target.changeTeam or target.SetTeam -- FrenchRP compatibility
                if IsValid(target) and checkFrenchRP(ply, target, k) then
                    SetTeam(target, k, true)
                end
            end

            FAdmin.Messages.FireNotification("setteam", ply, targets, {k})

            break
        end
    end

    return true, targets
end

FAdmin.StartHooks["zzSetTeam"] = function()
    FAdmin.Messages.RegisterNotification{
        name = "setteam",
        hasTarget = true,
        receivers = "everyone",
        writeExtraInfo = function(info) net.WriteUInt(info[1], 16) end,
        message = {"instigator", " set the team of ", "targets", " to ", "extraInfo.1"},
    }

    FAdmin.Commands.AddCommand("SetTeam", SetTeam)

    FAdmin.Access.AddPrivilege("SetTeam", 2)
end