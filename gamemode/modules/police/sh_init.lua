local plyMeta = FindMetaTable("Player")

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
function plyMeta:isArrested()
    return self:getFrenchRPVar("Arrested")
end

function plyMeta:isWanted()
    return self:getFrenchRPVar("wanted")
end

function plyMeta:getWantedReason()
    return self:getFrenchRPVar("wantedReason")
end

function plyMeta:isCP()
    if not IsValid(self) then return false end
    local Team = self:Team()
    return GAMEMODE.CivilProtection and GAMEMODE.CivilProtection[Team] or false
end

plyMeta.isMayor = fn.Compose{fn.Curry(fn.GetValue, 2)("mayor"), plyMeta.getJobTable}
plyMeta.isChief = fn.Compose{fn.Curry(fn.GetValue, 2)("chief"), plyMeta.getJobTable}


/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/

function FrenchRP.hooks:canRequestWarrant(target, actor, reason)
    if not reason or string.len(reason) == 0 then return false, FrenchRP.getPhrase("vote_specify_reason") end
    if not IsValid(target) then return false, FrenchRP.getPhrase("suspect_doesnt_exist") end
    if not IsValid(actor) then return false, FrenchRP.getPhrase("actor_doesnt_exist") end
    if not actor:Alive() then return false, FrenchRP.getPhrase("must_be_alive_to_do_x", FrenchRP.getPhrase("get_a_warrant")) end
    if target.warranted then return false, FrenchRP.getPhrase("already_a_warrant") end
    if not actor:isCP() then return false, FrenchRP.getPhrase("incorrect_job", FrenchRP.getPhrase("get_a_warrant")) end

    return true
end

function FrenchRP.hooks:canWanted(target, actor, reason)
    if not reason or string.len(reason) == 0 then return false, FrenchRP.getPhrase("vote_specify_reason") end
    if not IsValid(target) then return false, FrenchRP.getPhrase("suspect_doesnt_exist") end
    if not IsValid(actor) then return false, FrenchRP.getPhrase("actor_doesnt_exist") end
    if not actor:Alive() then return false, FrenchRP.getPhrase("must_be_alive_to_do_x", FrenchRP.getPhrase("make_someone_wanted")) end
    if not actor:isCP() then return false, FrenchRP.getPhrase("incorrect_job", FrenchRP.getPhrase("make_someone_wanted")) end
    if target:isWanted() then return false, FrenchRP.getPhrase("already_wanted") end
    if not target:Alive() then return false, FrenchRP.getPhrase("suspect_must_be_alive_to_do_x", FrenchRP.getPhrase("make_someone_wanted")) end
    if target:isArrested() then return false, FrenchRP.getPhrase("suspect_already_arrested") end

    return true
end

function FrenchRP.hooks:canUnwant(target, actor)
    if not IsValid(target) then return false, FrenchRP.getPhrase("suspect_doesnt_exist") end
    if not IsValid(actor) then return false, FrenchRP.getPhrase("actor_doesnt_exist") end
    if not actor:Alive() then return false, FrenchRP.getPhrase("must_be_alive_to_do_x", FrenchRP.getPhrase("remove_wanted_status")) end
    if not actor:isCP() then return false, FrenchRP.getPhrase("incorrect_job", FrenchRP.getPhrase("remove_wanted_status")) end
    if not target:isWanted() then return false, FrenchRP.getPhrase("not_wanted") end
    if not target:Alive() then return false, FrenchRP.getPhrase("suspect_must_be_alive_to_do_x", FrenchRP.getPhrase("remove_wanted_status")) end

    return true
end

/*---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------*/
FrenchRP.declareChatCommand{
    command = "cr",
    description = "Cry for help, the police will come (hopefully)!",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "warrant",
    description = "Get a search warrant for a certain player. With this warrant you can search their house.",
    delay = 1.5,
    condition = fn.FAnd{plyMeta.Alive, plyMeta.isCP, fn.Compose{fn.Not, plyMeta.isArrested}},
    tableArgs = true
}

FrenchRP.declareChatCommand{
    command = "wanted",
    description = "Make a player wanted. This is needed to get them arrested.",
    delay = 1.5,
    condition = fn.FAnd{plyMeta.Alive, plyMeta.isCP, fn.Compose{fn.Not, plyMeta.isArrested}},
    tableArgs = true
}

FrenchRP.declareChatCommand{
    command = "unwanted",
    description = "Remove a player's wanted status.",
    delay = 1.5,
    condition = fn.FAnd{plyMeta.Alive, plyMeta.isCP, fn.Compose{fn.Not, plyMeta.isArrested}}
}

FrenchRP.declareChatCommand{
    command = "agenda",
    description = "Set the agenda.",
    delay = 1.5,
    condition = fn.Compose{fn.Not, fn.Curry(fn.Eq, 2)(nil), plyMeta.getAgenda}
}

FrenchRP.declareChatCommand{
    command = "addagenda",
    description = "Add a line of text to the agenda.",
    delay = 1.5,
    condition = fn.Compose{fn.Not, fn.Curry(fn.Eq, 2)(nil), plyMeta.getAgenda}
}

FrenchRP.declareChatCommand{
    command = "lottery",
    description = "Start a lottery.",
    delay = 1.5,
    condition = plyMeta.isMayor
}

FrenchRP.declareChatCommand{
    command = "lockdown",
    description = "Start a lockdown. Everyone will have to stay inside.",
    delay = 1.5,
    condition = plyMeta.isMayor
}

FrenchRP.declareChatCommand{
    command = "unlockdown",
    description = "Stop a lockdown.",
    delay = 1.5,
    condition = plyMeta.isMayor
}

FrenchRP.declareChatCommand{
    command = "arrest",
    description = "Forcefully arrest a player.",
    delay = 0.5,
    tableArgs = true
}

FrenchRP.declareChatCommand{
    command = "unarrest",
    description = "Forcefully unarrest a player.",
    delay = 0.5,
    tableArgs = true
}

local noMayorExists = fn.Compose{fn.Null, fn.Curry(fn.Filter, 2)(plyMeta.isMayor), player.GetAll}
local noChiefExists = fn.Compose{fn.Null, fn.Curry(fn.Filter, 2)(plyMeta.isChief), player.GetAll}

FrenchRP.declareChatCommand{
    command = "requestlicense",
    description = "Request a gun license.",
    delay = 1.5,
    condition = fn.FAnd {
        fn.FOr {
            fn.Curry(fn.Not, 2)(noMayorExists),
            fn.Curry(fn.Not, 2)(noChiefExists),
            fn.Compose{fn.Not, fn.Null, fn.Curry(fn.Filter, 2)(plyMeta.isCP), player.GetAll}
        },
        fn.Compose{fn.Not, fn.Curry(fn.Flip(plyMeta.getFrenchRPVar), 2)("HasGunlicense")},
        fn.Compose{fn.Not, fn.Curry(fn.GetValue, 2)("LicenseRequested")}
    }
}

FrenchRP.declareChatCommand{
    command = "givelicense",
    description = "Give someone a gun license",
    delay = 1.5,
    condition = fn.FOr{
        plyMeta.isMayor, -- Mayors can hand out licenses
        fn.FAnd{plyMeta.isChief, noMayorExists}, -- Chiefs can if there is no mayor
        fn.FAnd{plyMeta.isCP, noChiefExists, noMayorExists} -- CP's can if there are no chiefs nor mayors
    }
}

FrenchRP.declareChatCommand{
    command = "demotelicense",
    description = "Start a vote to get someone's license revoked.",
    delay = 1.5,
    tableArgs = true
}

FrenchRP.declareChatCommand{
    command = "setlicense",
    description = "Forcefully give a player a license.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "unsetlicense",
    description = "Forcefully revoke a player's license.",
    delay = 1.5
}
