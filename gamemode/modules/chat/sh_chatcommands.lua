local plyMeta = FindMetaTable("Player")
FrenchRP.chatCommands = FrenchRP.chatCommands or {}

local validChatCommand = {
    command = isstring,
    description = isstring,
    condition = fn.FOr{fn.Curry(fn.Eq, 2)(nil), isfunction},
    delay = isnumber,
    tableArgs = fn.FOr{fn.Curry(fn.Eq, 2)(nil), isbool},
}

local checkChatCommand = function(tbl)
    for k,v in pairs(validChatCommand) do
        if not validChatCommand[k](tbl[k]) then
            return false, k
        end
    end
    return true
end

function FrenchRP.declareChatCommand(tbl)
    local valid, element = checkChatCommand(tbl)
    if not valid then
        FrenchRP.error("Incorrect chat command! " .. element .. " is invalid!", 2)
    end

    tbl.command = string.lower(tbl.command)
    FrenchRP.chatCommands[tbl.command] = FrenchRP.chatCommands[tbl.command] or tbl
    for k, v in pairs(tbl) do
        FrenchRP.chatCommands[tbl.command][k] = v
    end
end

function FrenchRP.removeChatCommand(command)
    FrenchRP.chatCommands[string.lower(command)] = nil
end

function FrenchRP.chatCommandAlias(command, ...)
    local name
    for k, v in pairs{...} do
        name = string.lower(v)

        FrenchRP.chatCommands[name] = table.Copy(FrenchRP.chatCommands[command])
        FrenchRP.chatCommands[name].command = name
    end
end

function FrenchRP.getChatCommand(command)
    return FrenchRP.chatCommands[string.lower(command)]
end

function FrenchRP.getChatCommands()
    return FrenchRP.chatCommands
end

function FrenchRP.getSortedChatCommands()
    local tbl = fn.Compose{table.ClearKeys, table.Copy, FrenchRP.getChatCommands}()
    table.SortByMember(tbl, "command", true)

    return tbl
end

-- chat commands that have been defined, but not declared
FrenchRP.getIncompleteChatCommands = fn.Curry(fn.Filter, 3)(fn.Compose{fn.Not, checkChatCommand})(FrenchRP.chatCommands)

/*---------------------------------------------------------------------------
Chat commands
---------------------------------------------------------------------------*/
FrenchRP.declareChatCommand{
    command = "pm",
    description = "Send a private message to someone.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "w",
    description = "Say something in whisper voice.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "y",
    description = "Yell something out loud.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "me",
    description = "Chat roleplay to say you're doing things that you can't show otherwise.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "/",
    description = "Global server chat.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "a",
    description = "Global server chat.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "ooc",
    description = "Global server chat.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "advert",
    description = "Advertise something to everyone in the server.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "broadcast",
    description = "Broadcast something as a mayor.",
    delay = 1.5,
    condition = plyMeta.isMayor
}

FrenchRP.declareChatCommand{
    command = "channel",
    description = "Tune into a radio channel.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "radio",
    description = "Say something through the radio.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "g",
    description = "Group chat.",
    delay = 1.5
}

FrenchRP.declareChatCommand{
    command = "credits",
    description = "Send the FrenchRP credits to someone.",
    delay = 1.5
}
