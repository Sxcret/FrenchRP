local maxId = 0
local FrenchRPVars = {}
local FrenchRPVarById = {}

-- the amount of bits assigned to the value that determines which FrenchRPVar we're sending/receiving
local DARKRP_ID_BITS = 8
local UNKNOWN_DARKRPVAR = 255 -- Should be equal to 2^DARKRP_ID_BITS - 1
FrenchRP.DARKRP_ID_BITS = DARKRP_ID_BITS

function FrenchRP.registerFrenchRPVar(name, writeFn, readFn)
    maxId = maxId + 1

    -- UNKNOWN_DARKRPVAR is reserved for unknown values
    if maxId >= UNKNOWN_DARKRPVAR then FrenchRP.error(string.format("Too many FrenchRPVar registrations! FrenchRPVar '%s' triggered this error", name), 2) end

    FrenchRPVars[name] = {id = maxId, name = name, writeFn = writeFn, readFn = readFn}
    FrenchRPVarById[maxId] = FrenchRPVars[name]
end

-- Unknown values have unknown types and unknown identifiers, so this is sent inefficiently
local function writeUnknown(name, value)
    net.WriteUInt(UNKNOWN_DARKRPVAR, 8)
    net.WriteString(name)
    net.WriteType(value)
end

-- Read the value of a FrenchRPVar that was not registered
local function readUnknown()
    return net.ReadString(), net.ReadType(net.ReadUInt(8))
end

local warningsShown = {}
local function warnRegistration(name)
    if warningsShown[name] then return end
    warningsShown[name] = true

    FrenchRP.errorNoHalt(string.format([[Warning! FrenchRPVar '%s' wasn't registered!
        Please contact the author of the FrenchRP Addon to fix this.
        Until this is fixed you don't need to worry about anything. Everything will keep working.
        It's just that registering FrenchRPVars would make FrenchRP faster.]], name), 4)
end

function FrenchRP.writeNetFrenchRPVar(name, value)
    local FrenchRPVar = FrenchRPVars[name]
    if not FrenchRPVar then
        warnRegistration(name)

        return writeUnknown(name, value)
    end

    net.WriteUInt(FrenchRPVar.id, DARKRP_ID_BITS)
    return FrenchRPVar.writeFn(value)
end

function FrenchRP.writeNetFrenchRPVarRemoval(name)
    local FrenchRPVar = FrenchRPVars[name]
    if not FrenchRPVar then
        warnRegistration(name)

        net.WriteUInt(UNKNOWN_DARKRPVAR, 8)
        net.WriteString(name)
        return
    end

    net.WriteUInt(FrenchRPVar.id, DARKRP_ID_BITS)
end

function FrenchRP.readNetFrenchRPVar()
    local FrenchRPVarId = net.ReadUInt(DARKRP_ID_BITS)
    local FrenchRPVar = FrenchRPVarById[FrenchRPVarId]

    if FrenchRPVarId == UNKNOWN_DARKRPVAR then
        local name, value = readUnknown()

        return name, value
    end

    local val = FrenchRPVar.readFn(value)

    return FrenchRPVar.name, val
end

function FrenchRP.readNetFrenchRPVarRemoval()
    local id = net.ReadUInt(DARKRP_ID_BITS)
    return id == 255 and net.ReadString() or FrenchRPVarById[id].name
end

-- The money is a double because it accepts higher values than Int and UInt, which are undefined for >32 bits
FrenchRP.registerFrenchRPVar("money",         net.WriteDouble, net.ReadDouble)
FrenchRP.registerFrenchRPVar("salary",        fp{fn.Flip(net.WriteInt), 32}, fp{net.ReadInt, 32})
FrenchRP.registerFrenchRPVar("rpname",        net.WriteString, net.ReadString)
FrenchRP.registerFrenchRPVar("job",           net.WriteString, net.ReadString)
FrenchRP.registerFrenchRPVar("HasGunlicense", net.WriteBit, fc{tobool, net.ReadBit})
FrenchRP.registerFrenchRPVar("Arrested",      net.WriteBit, fc{tobool, net.ReadBit})
FrenchRP.registerFrenchRPVar("wanted",        net.WriteBit, fc{tobool, net.ReadBit})
FrenchRP.registerFrenchRPVar("wantedReason",  net.WriteString, net.ReadString)
FrenchRP.registerFrenchRPVar("agenda",        net.WriteString, net.ReadString)

/*---------------------------------------------------------------------------
RP name override
---------------------------------------------------------------------------*/
local pmeta = FindMetaTable("Player")
pmeta.SteamName = pmeta.SteamName or pmeta.Name
function pmeta:Name()
    if not self:IsValid() then FrenchRP.error("Attempt to call Name/Nick/GetName on a non-existing player!", SERVER and 1 or 2) end
    return GAMEMODE.Config.allowrpnames and self:getFrenchRPVar("rpname")
        or self:SteamName()
end
pmeta.GetName = pmeta.Name
pmeta.Nick = pmeta.Name
