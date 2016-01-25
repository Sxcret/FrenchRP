local function ccDoorUnOwn(ply, args)
    if ply:EntIndex() == 0 then
        print(FrenchRP.getPhrase("cmd_cant_be_run_server_console"))
        return
    end

    local trace = ply:GetEyeTrace()

    if not IsValid(trace.Entity) or not trace.Entity:isKeysOwnable() or not trace.Entity:getDoorOwner() or ply:EyePos():Distance(trace.Entity:GetPos()) > 200 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", FrenchRP.getPhrase("door_or_vehicle")))
        return
    end

    trace.Entity:Fire("unlock", "", 0)
    trace.Entity:keysUnOwn()
    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-unowned a door with forceunown", Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, "Forcefully unowned")
end
FrenchRP.definePrivilegedChatCommand("forceunown", "FrenchRP_SetDoorOwner", ccDoorUnOwn)

local function unownAll(ply, args)
    local target = FrenchRP.findPlayer(args[1])

    if not IsValid(target) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args))
        return
    end
    target:keysUnOwnAll()

    if ply:EntIndex() == 0 then
        FrenchRP.log("Console force-unowned all doors owned by " .. target:Nick(), Color(30, 30, 30))
    else
        FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-unowned all doors owned by " .. target:Nick(), Color(30, 30, 30))
    end

    FrenchRP.notify(ply, 0, 4, "All doors of " .. target:Nick() .. " are now unowned")
end
FrenchRP.definePrivilegedChatCommand("forceunownall", "FrenchRP_SetDoorOwner", unownAll)

local function ccAddOwner(ply, args)
    if ply:EntIndex() == 0 then
        print(FrenchRP.getPhrase("cmd_cant_be_run_server_console"))
        return
    end

    local trace = ply:GetEyeTrace()

    if not IsValid(trace.Entity) or not trace.Entity:isKeysOwnable() or trace.Entity:getKeysNonOwnable() or trace.Entity:getKeysDoorGroup() or trace.Entity:getKeysDoorTeams() or ply:EyePos():Distance(trace.Entity:GetPos()) > 200 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", FrenchRP.getPhrase("door_or_vehicle")))
        return
    end

    local target = FrenchRP.findPlayer(args)

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args))
        return
    end

    if trace.Entity:isKeysOwned() then
        if not trace.Entity:isKeysOwnedBy(target) and not trace.Entity:isKeysAllowedToOwn(target) then
            trace.Entity:addKeysAllowedToOwn(target)
        else
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("rp_addowner_already_owns_door", target))
        end
        return
    end
    trace.Entity:keysOwn(target)

    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-added a door owner with forceown", Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, "Forcefully added " .. target:Nick())
end
FrenchRP.definePrivilegedChatCommand("forceown", "FrenchRP_SetDoorOwner", ccAddOwner)

local function ccRemoveOwner(ply, args)
    if ply:EntIndex() == 0 then
        print(FrenchRP.getPhrase("cmd_cant_be_run_server_console"))
        return
    end

    local trace = ply:GetEyeTrace()

    if not IsValid(trace.Entity) or not trace.Entity:isKeysOwnable() or trace.Entity:getKeysNonOwnable() or trace.Entity:getKeysDoorGroup() or trace.Entity:getKeysDoorTeams() or ply:EyePos():Distance(trace.Entity:GetPos()) > 200 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", FrenchRP.getPhrase("door_or_vehicle")))
        return
    end

    local target = FrenchRP.findPlayer(args)

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args))
        return
    end

    if trace.Entity:isKeysAllowedToOwn(target) then
        trace.Entity:removeKeysAllowedToOwn(target)
    end

    if trace.Entity:isMasterOwner(target) then
        trace.Entity:keysUnOwn()
    elseif trace.Entity:isKeysOwnedBy(target) then
        trace.Entity:removeKeysDoorOwner(target)
    end

    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-removed a door owner with forceremoveowner", Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, "Forcefully removed " .. target:Nick())
end
FrenchRP.definePrivilegedChatCommand("forceremoveowner", "FrenchRP_SetDoorOwner", ccRemoveOwner)

local function ccLock(ply, args)
    if ply:EntIndex() == 0 then
        print(FrenchRP.getPhrase("cmd_cant_be_run_server_console"))
        return
    end

    local trace = ply:GetEyeTrace()

    if not IsValid(trace.Entity) or not trace.Entity:isKeysOwnable() or ply:EyePos():Distance(trace.Entity:GetPos()) > 200 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", FrenchRP.getPhrase("door_or_vehicle")))
        return
    end

    FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("locked"))

    trace.Entity:keysLock()

    if not trace.Entity:CreatedByMap() then return end
    MySQLite.query(string.format([[REPLACE INTO frenchrp_door VALUES(%s, %s, %s, 1, %s);]],
        MySQLite.SQLStr(trace.Entity:doorIndex()),
        MySQLite.SQLStr(string.lower(game.GetMap())),
        MySQLite.SQLStr(trace.Entity:getKeysTitle() or ""),
        trace.Entity:getKeysNonOwnable() and 1 or 0
        ))

    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-locked a door with forcelock (locked door is saved)", Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, "Forcefully locked")
end
FrenchRP.definePrivilegedChatCommand("forcelock", "FrenchRP_ChangeDoorSettings", ccLock)

local function ccUnLock(ply, args)
    if ply:EntIndex() == 0 then
        print(FrenchRP.getPhrase("cmd_cant_be_run_server_console"))
        return
    end

    local trace = ply:GetEyeTrace()

    if not IsValid(trace.Entity) or not trace.Entity:isKeysOwnable() or ply:EyePos():Distance(trace.Entity:GetPos()) > 200 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("must_be_looking_at", FrenchRP.getPhrase("door_or_vehicle")))
        return
    end

    FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("unlocked"))
    trace.Entity:keysUnLock()

    if not trace.Entity:CreatedByMap() then return end
    MySQLite.query(string.format([[REPLACE INTO frenchrp_door VALUES(%s, %s, %s, 0, %s);]],
        MySQLite.SQLStr(trace.Entity:doorIndex()),
        MySQLite.SQLStr(string.lower(game.GetMap())),
        MySQLite.SQLStr(trace.Entity:getKeysTitle() or ""),
        trace.Entity:getKeysNonOwnable() and 1 or 0
        ))

    FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") force-unlocked a door with forcelock (unlocked door is saved)", Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, "Forcefully unlocked")
end
FrenchRP.definePrivilegedChatCommand("forceunlock", "FrenchRP_ChangeDoorSettings", ccUnLock)
