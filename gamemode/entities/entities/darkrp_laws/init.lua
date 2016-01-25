AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local Laws = {}
local FixedLaws = {}

timer.Simple(0, function()
    Laws = table.Copy(GAMEMODE.Config.DefaultLaws)
    FixedLaws = table.Copy(Laws)
end)

local hookCanEditLaws = {canEditLaws = function(_, ply, action, args)
    if not RPExtraTeams[ply:Team()] or not RPExtraTeams[ply:Team()].mayor then
        return false, FrenchRP.getPhrase("incorrect_job", GAMEMODE.Config.chatCommandPrefix .. action)
    end
    return true
end}

function ENT:Initialize()
    self:SetModel("models/props/cs_assault/Billboard.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)

    local phys = self:GetPhysicsObject()

    if phys and phys:IsValid() then
        phys:Wake()
        phys:EnableMotion(false)
    end
end

local function addLaw(ply, args)
    local canEdit, message = hook.Call("canEditLaws", hookCanEditLaws, ply, "addLaw", args)

    if not canEdit then
        FrenchRP.notify(ply, 1, 4, message ~= nil and message or FrenchRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. "addLaw", ""))
        return ""
    end

    if not args or args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
        return ""
    end

    if string.len(args) < 3 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("law_too_short"))
        return ""
    end

    if #Laws >= 12 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("laws_full"))
        return ""
    end

    local num = table.insert(Laws, args)

    umsg.Start("DRP_AddLaw")
        umsg.String(args)
    umsg.End()

    hook.Run("addLaw", num, args)

    FrenchRP.notify(ply, 0, 2, FrenchRP.getPhrase("law_added"))

    return ""
end
FrenchRP.defineChatCommand("addLaw", addLaw)

local function removeLaw(ply, args)
    local canEdit, message = hook.Call("canEditLaws", hookCanEditLaws, ply, "removeLaw", args)

    if not canEdit then
        FrenchRP.notify(ply, 1, 4, message ~= nil and message or FrenchRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. "removeLaw", ""))
        return ""
    end

    local i = tonumber(args)

    if not i or not Laws[i] then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
        return ""
    end

    if FixedLaws[i] then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("default_law_change_denied"))
        return ""
    end

    local law = Laws[i]

    table.remove(Laws, i)

    umsg.Start("DRP_RemoveLaw")
        umsg.Short(i)
    umsg.End()

    hook.Run("removeLaw", i, law)

    FrenchRP.notify(ply, 0, 2, FrenchRP.getPhrase("law_removed"))

    return ""
end
FrenchRP.defineChatCommand("removeLaw", removeLaw)

function FrenchRP.resetLaws()
    Laws = table.Copy(FixedLaws)

    umsg.Start("DRP_ResetLaws")
    umsg.End()
end

local function resetLaws(ply, args)
    local canEdit, message = hook.Call("canEditLaws", hookCanEditLaws, ply, "resetLaws", args)

    if not canEdit then
        FrenchRP.notify(ply, 1, 4, message ~= nil and message or FrenchRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. "resetLaws", ""))
        return ""
    end

    hook.Run("resetLaws", ply)

    FrenchRP.resetLaws()

    FrenchRP.notify(ply, 0, 2, FrenchRP.getPhrase("law_reset"))

    return ""
end
FrenchRP.defineChatCommand("resetLaws", resetLaws)

local numlaws = 0
local function placeLaws(ply, args)
    local canEdit, message = hook.Call("canEditLaws", hookCanEditLaws, ply, "placeLaws", args)

    if not canEdit then
        FrenchRP.notify(ply, 1, 4, message ~= nil and message or FrenchRP.getPhrase("unable", GAMEMODE.Config.chatCommandPrefix .. "placeLaws", ""))
        return ""
    end

    if numlaws >= GAMEMODE.Config.maxlawboards then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("limit", GAMEMODE.Config.chatCommandPrefix .. "placeLaws"))
        return ""
    end

    local trace = {}
    trace.start = ply:EyePos()
    trace.endpos = trace.start + ply:GetAimVector() * 85
    trace.filter = ply

    local tr = util.TraceLine(trace)

    local ent = ents.Create("frenchrp_laws")
    ent:SetPos(tr.HitPos + Vector(0, 0, 100))

    local ang = ply:GetAngles()
    ang:RotateAroundAxis(ang:Up(), 180)
    ent:SetAngles(ang)

    ent:CPPISetOwner(ply)
    ent.SID = ply.SID

    ent:Spawn()
    ent:Activate()

    if IsValid(ent) then
        numlaws = numlaws + 1
    end

    ply.lawboards = ply.lawboards or {}
    table.insert(ply.lawboards, ent)

    return ""
end
FrenchRP.defineChatCommand("placeLaws", placeLaws)

function ENT:OnRemove()
    numlaws = numlaws - 1
end

hook.Add("PlayerInitialSpawn", "SendLaws", function(ply)
    for i, law in pairs(Laws) do
        if FixedLaws[i] then continue end

        umsg.Start("DRP_AddLaw", ply)
            umsg.String(law)
        umsg.End()
    end
end)

function FrenchRP.getLaws()
    return Laws
end
