/*---------------------------------------------------------------------------
Messages
---------------------------------------------------------------------------*/
local function ccTell(ply, args)
    local target = FrenchRP.findPlayer(args[1])

    if target then
        local msg = ""

        for n = 2, #args do
            msg = msg .. args[n] .. " "
        end

        umsg.Start("AdminTell", target)
            umsg.String(msg)
        umsg.End()

        if ply:EntIndex() == 0 then
            FrenchRP.log("Console did admintell \"" .. msg .. "\" on " .. target:SteamName(), Color(30, 30, 30))
        else
            FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") did admintell \"" .. msg .. "\" on " .. target:SteamName(), Color(30, 30, 30))
        end
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(args[1])))
    end
end
FrenchRP.definePrivilegedChatCommand("admintell", "FrenchRP_AdminCommands", ccTell)

local function ccTellAll(ply, args)
    umsg.Start("AdminTell")
        umsg.String(args)
    umsg.End()

    if ply:EntIndex() == 0 then
        FrenchRP.log("Console did admintellall \"" .. args .. "\"", Color(30, 30, 30))
    else
        FrenchRP.log(ply:Nick() .. " (" .. ply:SteamID() .. ") did admintellall \"" .. args .. "\"", Color(30, 30, 30))
    end

end
FrenchRP.definePrivilegedChatCommand("admintellall", "FrenchRP_AdminCommands", ccTellAll)
