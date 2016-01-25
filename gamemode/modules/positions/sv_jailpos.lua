local function storeJail(ply, add, hasAccess)
    if not IsValid(ply) then return end

    -- Admin or Chief can set the Jail Position
    if (RPExtraTeams[ply:Team()] and RPExtraTeams[ply:Team()].chief and GAMEMODE.Config.chiefjailpos) or hasAccess then
        FrenchRP.storeJailPos(ply, add)
    else
        local str = FrenchRP.getPhrase("admin_only")
        if GAMEMODE.Config.chiefjailpos then
            str = FrenchRP.getPhrase("chief_or") .. str
        end

        FrenchRP.notify(ply, 1, 4, str)
    end
end
local function JailPos(ply)
    CAMI.PlayerHasAccess(ply, "FrenchRP_AdminCommands", fp{storeJail, ply, false})

    return ""
end
FrenchRP.defineChatCommand("jailpos", JailPos)
FrenchRP.defineChatCommand("setjailpos", JailPos)

local function AddJailPos(ply)
    CAMI.PlayerHasAccess(ply, "FrenchRP_AdminCommands", fp{storeJail, ply, true})

    return ""
end
FrenchRP.defineChatCommand("addjailpos", AddJailPos)
