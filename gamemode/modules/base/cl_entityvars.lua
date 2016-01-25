local FrenchRPVars = {}

/*---------------------------------------------------------------------------
interface functions
---------------------------------------------------------------------------*/
local pmeta = FindMetaTable("Player")
function pmeta:getFrenchRPVar(var)
    local vars = FrenchRPVars[self:UserID()]
    return vars and vars[var] or nil
end

/*---------------------------------------------------------------------------
Retrieve the information of a player var
---------------------------------------------------------------------------*/
local function RetrievePlayerVar(userID, var, value)
    local ply = Player(userID)
    FrenchRPVars[userID] = FrenchRPVars[userID] or {}

    hook.Call("FrenchRPVarChanged", nil, ply, var, FrenchRPVars[userID][var], value)
    FrenchRPVars[userID][var] = value

    -- Backwards compatibility
    if IsValid(ply) then
        ply.FrenchRPVars = FrenchRPVars[userID]
    end
end

/*---------------------------------------------------------------------------
Retrieve a player var.
Read the usermessage and attempt to set the FrenchRP var
---------------------------------------------------------------------------*/
local function doRetrieve()
    local userID = net.ReadUInt(16)
    local var, value = FrenchRP.readNetFrenchRPVar()

    RetrievePlayerVar(userID, var, value)
end
net.Receive("FrenchRP_PlayerVar", doRetrieve)

/*---------------------------------------------------------------------------
Retrieve the message to remove a FrenchRPVar
---------------------------------------------------------------------------*/
local function doRetrieveRemoval()
    local userID = net.ReadUInt(16)
    local vars = FrenchRPVars[userID] or {}
    local var = FrenchRP.readNetFrenchRPVarRemoval()
    local ply = Player(userID)

    hook.Call("FrenchRPVarChanged", nil, ply, var, vars[var], nil)

    vars[var] = nil
end
net.Receive("FrenchRP_PlayerVarRemoval", doRetrieveRemoval)

/*---------------------------------------------------------------------------
Initialize the FrenchRPVars at the start of the game
---------------------------------------------------------------------------*/
local function InitializeFrenchRPVars(len)
    local plyCount = net.ReadUInt(8)

    for i = 1, plyCount, 1 do
        local userID = net.ReadUInt(16)
        local varCount = net.ReadUInt(FrenchRP.DARKRP_ID_BITS + 2)

        for j = 1, varCount, 1 do
            local var, value = FrenchRP.readNetFrenchRPVar()
            RetrievePlayerVar(userID, var, value)
        end
    end
end
net.Receive("FrenchRP_InitializeVars", InitializeFrenchRPVars)
timer.Simple(0, fp{RunConsoleCommand, "_sendFrenchRPvars"})

net.Receive("FrenchRP_FrenchRPVarDisconnect", function(len)
    local userID = net.ReadUInt(16)
    FrenchRPVars[userID] = nil
end)

/*---------------------------------------------------------------------------
Request the FrenchRPVars when they haven't arrived
---------------------------------------------------------------------------*/
timer.Create("FrenchRPCheckifitcamethrough", 15, 0, function()
    for k,v in pairs(player.GetAll()) do
        if v:getFrenchRPVar("rpname") then continue end

        RunConsoleCommand("_sendFrenchRPvars")
        return
    end

    timer.Remove("FrenchRPCheckifitcamethrough")
end)
