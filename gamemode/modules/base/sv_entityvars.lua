local meta = FindMetaTable("Player")

/*---------------------------------------------------------------------------
Pooled networking strings
---------------------------------------------------------------------------*/
util.AddNetworkString("FrenchRP_InitializeVars")
util.AddNetworkString("FrenchRP_PlayerVar")
util.AddNetworkString("FrenchRP_PlayerVarRemoval")
util.AddNetworkString("FrenchRP_FrenchRPVarDisconnect")

/*---------------------------------------------------------------------------
Player vars
---------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------
Remove a player's FrenchRPVar
---------------------------------------------------------------------------*/
function meta:removeFrenchRPVar(var, target)
    hook.Call("FrenchRPVarChanged", nil, self, var, (self.FrenchRPVars and self.FrenchRPVars[var]) or nil, nil)
    target = target or player.GetAll()
    self.FrenchRPVars = self.FrenchRPVars or {}
    self.FrenchRPVars[var] = nil


    net.Start("FrenchRP_PlayerVarRemoval")
        net.WriteUInt(self:UserID(), 16)
        FrenchRP.writeNetFrenchRPVarRemoval(var)
    net.Send(target)
end

/*---------------------------------------------------------------------------
Set a player's FrenchRPVar
---------------------------------------------------------------------------*/
function meta:setFrenchRPVar(var, value, target)
    if not IsValid(self) then return end
    target = target or player.GetAll()

    if value == nil then return self:removeFrenchRPVar(var, target) end
    hook.Call("FrenchRPVarChanged", nil, self, var, (self.FrenchRPVars and self.FrenchRPVars[var]) or nil, value)

    self.FrenchRPVars = self.FrenchRPVars or {}
    self.FrenchRPVars[var] = value

    net.Start("FrenchRP_PlayerVar")
        net.WriteUInt(self:UserID(), 16)
        FrenchRP.writeNetFrenchRPVar(var, value)
    net.Send(target)
end

/*---------------------------------------------------------------------------
Set a private FrenchRPVar
---------------------------------------------------------------------------*/
function meta:setSelfFrenchRPVar(var, value)
    self.privateDRPVars = self.privateDRPVars or {}
    self.privateDRPVars[var] = true

    self:setFrenchRPVar(var, value, self)
end

/*---------------------------------------------------------------------------
Get a FrenchRPVar
---------------------------------------------------------------------------*/
function meta:getFrenchRPVar(var)
    self.FrenchRPVars = self.FrenchRPVars or {}
    return self.FrenchRPVars[var]
end

/*---------------------------------------------------------------------------
Send the FrenchRPVars to a client
---------------------------------------------------------------------------*/
function meta:sendFrenchRPVars()
    if self:EntIndex() == 0 then return end

    local plys = player.GetAll()

    net.Start("FrenchRP_InitializeVars")
        net.WriteUInt(#plys, 8)
        for _, target in pairs(plys) do
            net.WriteUInt(target:UserID(), 16)

            local FrenchRPVars = {}
            for var, value in pairs(target.FrenchRPVars) do
                if self ~= target and (target.privateDRPVars or {})[var] then continue end
                table.insert(FrenchRPVars, var)
            end

            net.WriteUInt(#FrenchRPVars, FrenchRP.DARKRP_ID_BITS + 2) -- Allow for three times as many unknown FrenchRPVars than the limit
            for i = 1, #FrenchRPVars, 1 do
                FrenchRP.writeNetFrenchRPVar(FrenchRPVars[i], target.FrenchRPVars[FrenchRPVars[i]])
            end
        end
    net.Send(self)
end
concommand.Add("_sendFrenchRPvars", function(ply)
    if ply.FrenchRPVarsSent and ply.FrenchRPVarsSent > (CurTime() - 3) then return end -- prevent spammers
    ply.FrenchRPVarsSent = CurTime()
    ply:sendFrenchRPVars()
end)

/*---------------------------------------------------------------------------
Admin FrenchRPVar commands
---------------------------------------------------------------------------*/
local function setRPName(ply, args)
    if not args[2] or string.len(args[2]) < 2 or string.len(args[2]) > 30 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), "<2/>30"))
        return
    end

    local name = table.concat(args, " ", 2)

    local target = FrenchRP.findPlayer(args[1])

    if not target then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", args[1]))
        return
    end

    local oldname = target:Nick()

    FrenchRP.retrieveRPNames(name, function(taken)
        if taken then
            FrenchRP.notify(ply, 1, 5, FrenchRP.getPhrase("unable", "RPname", FrenchRP.getPhrase("already_taken")))
            return
        end

        FrenchRP.storeRPName(target, name)
        target:setFrenchRPVar("rpname", name)

        FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("you_set_x_name", oldname, name))

        local nick = ""
        if ply:EntIndex() == 0 then
            nick = "Console"
        else
            nick = ply:Nick()
        end
        FrenchRP.notify(target, 0, 4, FrenchRP.getPhrase("x_set_your_name", nick, name))
        if ply:EntIndex() == 0 then
            FrenchRP.log("Console set " .. target:SteamName() .. "'s name to " .. name, Color(30, 30, 30))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") set " .. target:SteamName() .. "'s name to " .. name, Color(30, 30, 30))
        end
    end)
end
FrenchRP.definePrivilegedChatCommand("forcerpname", "FrenchRP_AdminCommands", setRPName)

local function freerpname(ply, args)
    local name = args ~= "" and args or IsValid(ply) and ply:Nick() or ""

    MySQLite.query(("UPDATE frenchrp_player SET rpname = NULL WHERE rpname = %s"):format(MySQLite.SQLStr(name)))

    local nick = IsValid(ply) and ply:Nick() or "Console"
    FrenchRP.log(("%s has freed the rp name '%s'"):format(nick, name), Color(30, 30, 30))
    FrenchRP.notify(ply, 0, 4, ("'%s' has been freed"):format(name))
end
FrenchRP.definePrivilegedChatCommand("freerpname", "FrenchRP_AdminCommands", freerpname)

local function RPName(ply, args)
    if ply.LastNameChange and ply.LastNameChange > (CurTime() - 5) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("have_to_wait",  math.ceil(5 - (CurTime() - ply.LastNameChange)), "/rpname"))
        return ""
    end

    if not GAMEMODE.Config.allowrpnames then
        FrenchRP.notify(ply, 1, 6, FrenchRP.getPhrase("disabled", "RPname", ""))
        return ""
    end

    args = args:find"^%s*$" and '' or args:match"^%s*(.*%S)"

    local canChangeName, reason = hook.Call("CanChangeRPName", GAMEMODE, ply, args)
    if canChangeName == false then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "RPname", reason or ""))
        return ""
    end

    ply:setRPName(args)
    ply.LastNameChange = CurTime()
    return ""
end
FrenchRP.defineChatCommand("rpname", RPName)
FrenchRP.defineChatCommand("name", RPName)
FrenchRP.defineChatCommand("nick", RPName)

/*---------------------------------------------------------------------------
Setting the RP name
---------------------------------------------------------------------------*/
function meta:setRPName(name, firstRun)
    -- Make sure nobody on this server already has this RP name
    local lowername = string.lower(tostring(name))
    FrenchRP.retrieveRPNames(name, function(taken)
        if string.len(lowername) < 2 and not firstrun then return end
        -- If we found that this name exists for another player
        if taken then
            if firstRun then
                -- If we just connected and another player happens to be using our steam name as their RP name
                -- Put a 1 after our steam name
                FrenchRP.storeRPName(self, name .. " 1")
                FrenchRP.notify(self, 0, 12, FrenchRP.getPhrase("someone_stole_steam_name"))
            else
                FrenchRP.notify(self, 1, 5, FrenchRP.getPhrase("unable", "RPname", FrenchRP.getPhrase("already_taken")))
                return ""
            end
        else
            if not firstRun then -- Don't save the steam name in the database
                FrenchRP.notifyAll(2, 6, FrenchRP.getPhrase("rpname_changed", self:SteamName(), name))
                FrenchRP.storeRPName(self, name)
            end
        end
    end)
end


/*---------------------------------------------------------------------------
Maximum entity values
---------------------------------------------------------------------------*/
local maxEntities = {}
function meta:addCustomEntity(entTable)
    if not entTable then return end

    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] + 1
end

function meta:removeCustomEntity(entTable)
    if not entTable.cmd then return end

    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] - 1
end

function meta:customEntityLimitReached(entTable)
    maxEntities[self] = maxEntities[self] or {}
    maxEntities[self][entTable.cmd] = maxEntities[self][entTable.cmd] or 0

    return maxEntities[self][entTable.cmd] >= (entTable.getMax and entTable.getMax(self) or entTable.max)
end

hook.Add("PlayerDisconnected", "removeLimits", function(ply)
    maxEntities[ply] = nil
    net.Start("FrenchRP_FrenchRPVarDisconnect")
        net.WriteUInt(ply:UserID(), 16)
    net.Broadcast()
end)
