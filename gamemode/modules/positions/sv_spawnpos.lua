local function SetSpawnPos(ply, args)
    local pos = ply:GetPos()
    local t

    for k,v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("created_spawnpos", v.name))
        end
    end

    if t then
        FrenchRP.storeTeamSpawnPos(t, {pos.x, pos.y, pos.z})
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args)))
    end
end
FrenchRP.definePrivilegedChatCommand("setspawn", "FrenchRP_AdminCommands", SetSpawnPos)

local function AddSpawnPos(ply, args)
    local pos = ply:GetPos()
    local t

    for k,v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("updated_spawnpos", v.name))
        end
    end

    if t then
        FrenchRP.addTeamSpawnPos(t, {pos.x, pos.y, pos.z})
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args)))
    end
end
FrenchRP.definePrivilegedChatCommand("addspawn", "FrenchRP_AdminCommands", AddSpawnPos)

local function RemoveSpawnPos(ply, args)
    local t

    for k,v in pairs(RPExtraTeams) do
        if args == v.command then
            t = k
            FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("updated_spawnpos", v.name))
            break
        end
    end

    if t then
        FrenchRP.removeTeamSpawnPos(t)
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args)))
    end
end
FrenchRP.definePrivilegedChatCommand("removespawn", "FrenchRP_AdminCommands", RemoveSpawnPos)
