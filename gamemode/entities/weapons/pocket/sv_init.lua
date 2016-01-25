local meta = FindMetaTable("Player")

/*---------------------------------------------------------------------------
Stubs
---------------------------------------------------------------------------*/
FrenchRP.stub{
    name = "dropPocketItem",
    description = "Make the player drop an item from the pocket.",
    parameters = {
        {
            name = "ent",
            description = "The entity to drop.",
            type = "Entity",
            optional = false
        }
    },
    returns = {
    },
    metatable = meta
}

FrenchRP.stub{
    name = "addPocketItem",
    description = "Add an item to the pocket of the player.",
    parameters = {
        {
            name = "ent",
            description = "The entity to add.",
            type = "Entity",
            optional = false
        }
    },
    returns = {
    },
    metatable = meta
}

FrenchRP.stub{
    name = "removePocketItem",
    description = "Remove an item from the pocket of the player.",
    parameters = {
        {
            name = "item",
            description = "The index of the entity to remove from pocket.",
            type = "number",
            optional = false
        }
    },
    returns = {
    },
    metatable = meta
}

FrenchRP.hookStub{
    name = "canPocket",
    description = "Whether a player can pocket a certain item.",
    parameters = {
        {
            name = "ply",
            description = "The player.",
            type = "Player"
        },
        {
            name = "item",
            description = "The item to be pocketed.",
            type = "Entity"
        }
    },
    returns = {
        {
            name = "answer",
            description = "Whether the entity can be pocketed.",
            type = "boolean"
        },
        {
            name = "message",
            description = "The message to send to the player when the answer is false.",
            type = "string"
        }
    }
}

FrenchRP.hookStub{
    name = "onPocketItemAdded",
    description = "Called when an entity is added to the pocket.",
    parameters = {
        {
            name = "ply",
            description = "The pocket holder.",
            type = "Player"
        },
        {
            name = "ent",
            description = "The entity.",
            type = "Entity"
        },
        {
            name = "serialized",
            description = "The serialized version of the pocketed entity.",
            type = "table"
        }
    },
    returns = {
    }
}

FrenchRP.hookStub{
    name = "onPocketItemRemoved",
    description = "Called when an item is removed from the pocket.",
    parameters = {
        {
            name = "ply",
            description = "The pocket holder.",
            type = "Player"
        },
        {
            name = "item",
            description = "The index of the pocket item.",
            type = "number"
        }
    },
    returns = {
    }
}

/*---------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------*/
-- workaround: GetNetworkVars doesn't give entities because the /duplicator/ doesn't want to save entities
local function getDTVars(ent)
    if not ent.GetNetworkVars then return nil end
    local name, value = debug.getupvalue(ent.GetNetworkVars, 1)
    if name ~= "datatable" then
        ErrorNoHalt("Warning: Datatable cannot be stored properly in pocket. Tell a developer!")
    end

    local res = {}

    for k,v in pairs(value) do
        res[k] = v.GetFunc(ent, v.index)
    end

    return res
end

local function serialize(ent)
    local serialized = duplicator.CopyEntTable(ent)
    serialized.DT = getDTVars(ent)

    return serialized
end

local function deserialize(ply, item)
    local ent = ents.Create(item.Class)
    duplicator.DoGeneric(ent, item)
    ent:Spawn()
    ent:Activate()

    duplicator.DoGenericPhysics(ent, ply, item)
    table.Merge(ent:GetTable(), item)

    local pos, mins = ent:GetPos(), ent:WorldSpaceAABB()
    local offset = pos.z - mins.z

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 85
    trace.filter = ply

    local tr = util.TraceLine(trace)
    ent:SetPos(tr.HitPos + Vector(0, 0, offset))

    local phys = ent:GetPhysicsObject()
    timer.Simple(0, function() if phys:IsValid() then phys:Wake() end end)

    return ent
end

local function dropAllPocketItems(ply)
    for k,v in pairs(ply.frenchRPPocket or {}) do
        ply:dropPocketItem(k)
    end
end

util.AddNetworkString("FrenchRP_Pocket")
local function sendPocketItems(ply)
    net.Start("FrenchRP_Pocket")
        net.WriteTable(ply:getPocketItems())
    net.Send(ply)
end

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
function meta:addPocketItem(ent)
    if not IsValid(ent) then FrenchRP.error("Entity not valid", 2) end
    if ent.USED then return end

    -- This item cannot be used until it has been removed
    ent.USED = true

    local serialized = serialize(ent)

    hook.Call("onPocketItemAdded", nil, self, ent, serialized)

    ent:Remove()

    self.frenchRPPocket = self.frenchRPPocket or {}

    local id = table.insert(self.frenchRPPocket, serialized)
    sendPocketItems(self)
    return id
end

function meta:removePocketItem(item)
    if not self.frenchRPPocket or not self.frenchRPPocket[item] then FrenchRP.error("Player does not contain " .. item .. " in their pocket.", 2) end

    hook.Call("onPocketItemRemoved", nil, self, item)

    self.frenchRPPocket[item] = nil
    sendPocketItems(self)
end

function meta:dropPocketItem(item)
    if not self.frenchRPPocket or not self.frenchRPPocket[item] then FrenchRP.error("Player does not contain " .. item .. " in their pocket.", 2) end

    local id = self.frenchRPPocket[item]
    local ent = deserialize(self, id)

    -- reset USED status
    ent.USED = nil

    hook.Call("onPocketItemDropped", nil, self, ent, item, id)

    self:removePocketItem(item)

    return ent
end

-- serverside implementation
function meta:getPocketItems()
    self.frenchRPPocket = self.frenchRPPocket or {}

    local res = {}
    for k,v in pairs(self.frenchRPPocket) do
        res[k] = {
            model = v.Model,
            class = v.Class
        }
    end

    return res
end

/*---------------------------------------------------------------------------
Commands
---------------------------------------------------------------------------*/
util.AddNetworkString("FrenchRP_spawnPocket")
net.Receive("FrenchRP_spawnPocket", function(len, ply)
    local item = net.ReadFloat()
    if not ply.frenchRPPocket or not ply.frenchRPPocket[item] then return end
    ply:dropPocketItem(item)
end)

/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/

local function onAdded(ply, ent, serialized)
    if not ent:IsValid() or not ent.FrenchRPItem or not ent.Getowning_ent or not IsValid(ent:Getowning_ent()) then return end

    ply = ent:Getowning_ent()

    ply:addCustomEntity(ent.FrenchRPItem)
end
hook.Add("onPocketItemAdded", "defaultImplementation", onAdded)

function GAMEMODE:canPocket(ply, item)
    if not IsValid(item) then return false end
    local class = item:GetClass()

    if item.Removed then return false, FrenchRP.getPhrase("cannot_pocket_x") end
    if not item:CPPICanPickup(ply) then return false, FrenchRP.getPhrase("cannot_pocket_x") end
    if item.jailWall then return false, FrenchRP.getPhrase("cannot_pocket_x") end
    if GAMEMODE.Config.PocketBlacklist[class] then return false, FrenchRP.getPhrase("cannot_pocket_x") end
    if string.find(class, "func_") then return false, FrenchRP.getPhrase("cannot_pocket_x") end
    if item:IsRagdoll() then return false, FrenchRP.getPhrase("cannot_pocket_x") end

    local trace = ply:GetEyeTrace()
    if ply:EyePos():Distance(trace.HitPos) > 150 then return false end

    local phys = trace.Entity:GetPhysicsObject()
    if not phys:IsValid() then return false end

    local mass = trace.Entity.RPOriginalMass and trace.Entity.RPOriginalMass or phys:GetMass()
    if mass > 100 then return false, FrenchRP.getPhrase("object_too_heavy") end

    local job = ply:Team()
    local max = RPExtraTeams[job].maxpocket or GAMEMODE.Config.pocketitems
    if table.Count(ply.frenchRPPocket or {}) >= max then return false, FrenchRP.getPhrase("pocket_full") end

    return true
end


-- Drop pocket items on death
hook.Add("PlayerDeath", "DropPocketItems", function(ply)
    if not GAMEMODE.Config.droppocketdeath or not ply.frenchRPPocket then return end
    dropAllPocketItems(ply)
end)

hook.Add("playerArrested", "DropPocketItems", function(ply)
    if not GAMEMODE.Config.droppocketarrest then return end
    dropAllPocketItems(ply)
end)
