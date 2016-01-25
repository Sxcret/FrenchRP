util.AddNetworkString("FrenchRP_UpdateDoorData")
util.AddNetworkString("FrenchRP_RemoveDoorData")
util.AddNetworkString("FrenchRP_RemoveDoorVar")
util.AddNetworkString("FrenchRP_AllDoorData")

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
local eMeta = FindMetaTable("Entity")
function eMeta:getDoorData()
    if not self:isKeysOwnable() then return {} end

    self.DoorData = self.DoorData or {}
    return self.DoorData
end

function eMeta:setKeysNonOwnable(ownable)
    self:getDoorData().nonOwnable = ownable or nil
    FrenchRP.updateDoorData(self, "nonOwnable")
end

function eMeta:setKeysTitle(title)
    self:getDoorData().title = title ~= "" and title or nil
    FrenchRP.updateDoorData(self, "title")
end

function eMeta:setDoorGroup(group)
    self:getDoorData().groupOwn = group
    FrenchRP.updateDoorData(self, "groupOwn")
end

function eMeta:addKeysDoorTeam(t)
    local doorData = self:getDoorData()
    doorData.teamOwn = doorData.teamOwn or {}
    doorData.teamOwn[t] = true

    FrenchRP.updateDoorData(self, "teamOwn")
end

function eMeta:removeKeysDoorTeam(t)
    local doorData = self:getDoorData()
    doorData.teamOwn = doorData.teamOwn or {}
    doorData.teamOwn[t] = nil

    if fn.Null(doorData.teamOwn) then
        doorData.teamOwn = nil
    end

    FrenchRP.updateDoorData(self, "teamOwn")
end

function eMeta:removeAllKeysDoorTeams()
    local doorData = self:getDoorData()
    doorData.teamOwn = nil

    FrenchRP.updateDoorData(self, "teamOwn")
end

function eMeta:addKeysAllowedToOwn(ply)
    local doorData = self:getDoorData()
    doorData.allowedToOwn = doorData.allowedToOwn or {}
    doorData.allowedToOwn[ply:UserID()] = true

    FrenchRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:removeKeysAllowedToOwn(ply)
    local doorData = self:getDoorData()
    doorData.allowedToOwn = doorData.allowedToOwn or {}
    doorData.allowedToOwn[ply:UserID()] = nil

    if fn.Null(doorData.allowedToOwn) then
        doorData.allowedToOwn = nil
    end

    FrenchRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:removeAllKeysAllowedToOwn()
    local doorData = self:getDoorData()
    doorData.allowedToOwn = nil

    FrenchRP.updateDoorData(self, "allowedToOwn")
end

function eMeta:addKeysDoorOwner(ply)
    local doorData = self:getDoorData()
    doorData.extraOwners = doorData.extraOwners or {}
    doorData.extraOwners[ply:UserID()] = true

    FrenchRP.updateDoorData(self, "extraOwners")

    self:removeKeysAllowedToOwn(ply)
end

function eMeta:removeKeysDoorOwner(ply)
    local doorData = self:getDoorData()
    doorData.extraOwners = doorData.extraOwners or {}
    doorData.extraOwners[ply:UserID()] = nil

    if fn.Null(doorData.extraOwners) then
        doorData.extraOwners = nil
    end

    FrenchRP.updateDoorData(self, "extraOwners")
end

function eMeta:removeAllKeysExtraOwners()
    local doorData = self:getDoorData()
    doorData.extraOwners = nil

    FrenchRP.updateDoorData(self, "extraOwners")
end

function eMeta:removeDoorData()
    net.Start("FrenchRP_RemoveDoorData")
        net.WriteUInt(self:EntIndex(), 32)
    net.Send(player.GetAll())
end

/*---------------------------------------------------------------------------
Networking
---------------------------------------------------------------------------*/

local plyMeta = FindMetaTable("Player")
function plyMeta:sendDoorData()
    if self:EntIndex() == 0 then return end

    local res = {}
    for k,v in pairs(ents.GetAll()) do
        if not IsValid(v) or not v:getDoorData() or table.Count(v:getDoorData()) == 0 then continue end

        res[v:EntIndex()] = v:getDoorData()
    end

    net.Start("FrenchRP_AllDoorData")
        net.WriteUInt(table.Count(res), 16)

        for ix, vars in pairs(res) do
            net.WriteUInt(ix, 16)

            net.WriteUInt(table.Count(vars), 8)

            for varName, value in pairs(vars) do
                FrenchRP.writeNetDoorVar(varName, value)
            end
        end
    net.Send(self)
end
concommand.Add("_sendAllDoorData", fn.Id) -- Backwards compatibility

hook.Add("PlayerInitialSpawn", "FrenchRP_DoorData", plyMeta.sendDoorData)

function FrenchRP.updateDoorData(door, member)
    if not IsValid(door) or not door:getDoorData() then error("Calling updateDoorData on a door that has no data!") end

    local value = door:getDoorData()[member]

    if value == nil then
        local doorvar = FrenchRP.getDoorVarsByName()[member]
        net.Start("FrenchRP_RemoveDoorVar")
            net.WriteUInt(door:EntIndex(), 16)
            if not doorvar then
                net.WriteUInt(0, 8)
                net.WriteString(member)
            else
                net.WriteUInt(doorvar.id, 8)
            end
        net.Broadcast()

        return
    end

    net.Start("FrenchRP_UpdateDoorData")
        net.WriteUInt(door:EntIndex(), 32)
        FrenchRP.writeNetDoorVar(member, value)
    net.Broadcast()
end
