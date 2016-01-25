/*---------------------------------------------------------
Talking
 ---------------------------------------------------------*/
local function PM(ply, args)
    local namepos = string.find(args, " ")
    if not namepos then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    local name = string.sub(args, 1, namepos - 1)
    local msg = string.sub(args, namepos + 1)

    if msg == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    local target = FrenchRP.findPlayer(name)

    if target then
        local col = team.GetColor(ply:Team())
        FrenchRP.talkToPerson(target, col, "(PM) " .. ply:Nick(), Color(255, 255, 255, 255), msg, ply)
        FrenchRP.talkToPerson(ply, col, "(PM) " .. ply:Nick(), Color(255, 255, 255, 255), msg, ply)
    else
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("could_not_find", tostring(name)))
    end

    return ""
end
FrenchRP.defineChatCommand("pm", PM, 1.5)

local function Whisper(ply, args)
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return ""
        end
        FrenchRP.talkToRange(ply, "(" .. FrenchRP.getPhrase("whisper") .. ") " .. ply:Nick(), text, 90)
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("w", Whisper, 1.5)

local function Yell(ply, args)
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return ""
        end
        FrenchRP.talkToRange(ply, "(" .. FrenchRP.getPhrase("yell") .. ") " .. ply:Nick(), text, 550)
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("y", Yell, 1.5)

local function Me(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return ""
        end
        if GAMEMODE.Config.alltalk then
            for _, target in pairs(player.GetAll()) do
                FrenchRP.talkToPerson(target, team.GetColor(ply:Team()), ply:Nick() .. " " .. text)
            end
        else
            FrenchRP.talkToRange(ply, ply:Nick() .. " " .. text, "", 250)
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("me", Me, 1.5)

local function OOC(ply, args)
    if not GAMEMODE.Config.ooc then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("disabled", FrenchRP.getPhrase("ooc"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return ""
        end
        local col = team.GetColor(ply:Team())
        local col2 = Color(255,255,255,255)
        if not ply:Alive() then
            col2 = Color(255,200,200,255)
            col = col2
        end
        for k,v in pairs(player.GetAll()) do
            FrenchRP.talkToPerson(v, col, "(" .. FrenchRP.getPhrase("ooc") .. ") " .. ply:Name(), col2, text, ply)
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("/", OOC, true, 1.5)
FrenchRP.defineChatCommand("a", OOC, true, 1.5)
FrenchRP.defineChatCommand("ooc", OOC, true, 1.5)

local function PlayerAdvertise(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return
        end
        for k,v in pairs(player.GetAll()) do
            local col = team.GetColor(ply:Team())
            FrenchRP.talkToPerson(v, col, FrenchRP.getPhrase("advert") .. " " .. ply:Nick(), Color(255, 255, 0, 255), text, ply)
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("advert", PlayerAdvertise, 1.5)

local function MayorBroadcast(ply, args)
    if args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end
    if not RPExtraTeams[ply:Team()] or not RPExtraTeams[ply:Team()].mayor then FrenchRP.notify(ply, 1, 4, "You have to be mayor") return "" end
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return
        end
        for k,v in pairs(player.GetAll()) do
            local col = team.GetColor(ply:Team())
            FrenchRP.talkToPerson(v, col, FrenchRP.getPhrase("broadcast") .. " " .. ply:Nick(), Color(170, 0, 0, 255), text, ply)
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("broadcast", MayorBroadcast, 1.5)

local function SetRadioChannel(ply,args)
    if tonumber(args) == nil or tonumber(args) < 0 or tonumber(args) > 100 then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", "0<channel<100"))
        return ""
    end
    FrenchRP.notify(ply, 2, 4, FrenchRP.getPhrase("channel_set_to_x", args))
    ply.RadioChannel = tonumber(args)
    return ""
end
FrenchRP.defineChatCommand("channel", SetRadioChannel)

local function SayThroughRadio(ply,args)
    if not ply.RadioChannel then ply.RadioChannel = 1 end
    if not args or args == "" then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
        return ""
    end
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return
        end
        for k,v in pairs(player.GetAll()) do
            if v.RadioChannel == ply.RadioChannel then
                FrenchRP.talkToPerson(v, Color(180,180,180,255), FrenchRP.getPhrase("radio_x", ply.RadioChannel), Color(180,180,180,255), text, ply)
            end
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("radio", SayThroughRadio, 1.5)

local function GroupMsg(ply, args)
    local DoSay = function(text)
        if text == "" then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("invalid_x", "argument", ""))
            return
        end

        local col = team.GetColor(ply:Team())

        local groupChats = {}
        for _, func in pairs(GAMEMODE.FrenchRPGroupChats) do
            -- not the group of the player
            if not func(ply) then continue end

            table.insert(groupChats, func)
        end

        if #groupChats == 0 then return "" end

        for _, target in pairs(player.GetAll()) do
            -- The target is in any of the group chats
            for k, func in pairs(groupChats) do
                if not func(target, ply) then continue end

                FrenchRP.talkToPerson(target, col, FrenchRP.getPhrase("group") .. " " .. ply:Nick(), Color(255,255,255,255), text, ply)
                break
            end
        end
    end
    return args, DoSay
end
FrenchRP.defineChatCommand("g", GroupMsg, 0)

-- here's the new easter egg. Easier to find, more subtle, doesn't only credit FPtje and unib5
-- WARNING: DO NOT EDIT THIS
-- You can edit FrenchRP but you HAVE to credit the original authors!
-- You even have to credit all the previous authors when you rename the gamemode.
local CreditsWait = true
local function GetFrenchRPAuthors(ply, args)
    local target = FrenchRP.findPlayer(args); -- Only send to one player. Prevents spamming
    if not IsValid(target) then
        FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("player_doesnt_exist"))
        return ""
    end

    if not CreditsWait then FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("wait_with_that")) return "" end
    CreditsWait = false
    timer.Simple(60, function() CreditsWait = true end) -- so people don't spam it

    local rf = RecipientFilter()
    rf:AddPlayer(target)
    if ply ~= target then
        rf:AddPlayer(ply)
    end

    umsg.Start("FrenchRP_Credits", rf)
    umsg.End()

    return ""
end
FrenchRP.defineChatCommand("credits", GetFrenchRPAuthors, 50)
