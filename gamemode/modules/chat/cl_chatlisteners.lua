-----------------------------------------------------------------------------[[
/*---------------------------------------------------------------------------
This module finds out for you who can see you talk or speak through the microphone
---------------------------------------------------------------------------*/
-----------------------------------------------------------------------------]]

/*---------------------------------------------------------------------------
Variables
---------------------------------------------------------------------------*/
local receivers
local currentChatText = {}
local receiverConfigs = {}
local currentConfig = {text = "", hearFunc = fn.Id} -- Default config is not loaded yet

/*---------------------------------------------------------------------------
addChatReceiver
Add a chat command with specific receivers

prefix: the chat command itself ("/pm", "/ooc", "/me" are some examples)
text: the text that shows up when it says "Some people can hear you X"
hearFunc: a function(ply, splitText) that decides whether this player can or cannot hear you.
    return true if the player can hear you
           false if the player cannot
           nil if you want to prevent the text from showing up temporarily
---------------------------------------------------------------------------*/
function FrenchRP.addChatReceiver(prefix, text, hearFunc)
    receiverConfigs[prefix] = {
        text = text,
        hearFunc = hearFunc
    }
end

/*---------------------------------------------------------------------------
removeChatReceiver
Remove a chat command.

prefix: the command, like in addChatReceiver
---------------------------------------------------------------------------*/
function FrenchRP.removeChatReceiver(prefix)
    receiverConfigs[prefix] = nil
end

/*---------------------------------------------------------------------------
Draw the results to the screen
---------------------------------------------------------------------------*/
local function drawChatReceivers()
    if not receivers then return end

    local x, y = chat.GetChatBoxPos()
    y = y - 21

    -- No one hears you
    if #receivers == 0 then
        draw.WordBox(2, x, y, FrenchRP.getPhrase("hear_noone", currentConfig.text), "FrenchRPHUD1", Color(0,0,0,160), Color(255,0,0,255))
        return
    -- Everyone hears you
    elseif #receivers == #player.GetAll() - 1 then
        draw.WordBox(2, x, y, FrenchRP.getPhrase("hear_everyone"), "FrenchRPHUD1", Color(0,0,0,160), Color(0,255,0,255))
        return
    end

    draw.WordBox(2, x, y - (#receivers * 21), FrenchRP.getPhrase("hear_certain_persons", currentConfig.text), "FrenchRPHUD1", Color(0,0,0,160), Color(0,255,0,255))
    for i = 1, #receivers, 1 do
        if not IsValid(receivers[i]) then
            receivers[i] = receivers[#receivers]
            receivers[#receivers] = nil
            continue
        end

        draw.WordBox(2, x, y - (i - 1) * 21, receivers[i]:Nick(), "FrenchRPHUD1", Color(0, 0, 0, 160), Color(255, 255, 255, 255))
    end
end

/*---------------------------------------------------------------------------
Find out who could hear the player if they were to speak now
---------------------------------------------------------------------------*/
local function chatGetRecipients()
    if not currentConfig then return end

    receivers = {}
    for _, ply in pairs(player.GetAll()) do
        if not IsValid(ply) or ply == LocalPlayer() then continue end
        if ply:GetNoDraw() then continue end

        local val = currentConfig.hearFunc(ply, currentChatText)

        -- Return nil to disable the chat recipients temporarily.
        if val == nil then
            receivers = nil
            return
        elseif val == true then
            table.insert(receivers, ply)
        end
    end
end

/*---------------------------------------------------------------------------
Called when the player starts typing
---------------------------------------------------------------------------*/
local function startFind()
    currentConfig = receiverConfigs[""]
    hook.Add("Think", "FrenchRP_chatRecipients", chatGetRecipients)
    hook.Add("HUDPaint", "FrenchRP_DrawChatReceivers", drawChatReceivers)
end
hook.Add("StartChat", "FrenchRP_StartFindChatReceivers", startFind)

/*---------------------------------------------------------------------------
Called when the player stops typing
---------------------------------------------------------------------------*/
local function stopFind()
    hook.Remove("Think", "FrenchRP_chatRecipients")
    hook.Remove("HUDPaint", "FrenchRP_DrawChatReceivers")
end
hook.Add("FinishChat", "FrenchRP_StopFindChatReceivers", stopFind)

/*---------------------------------------------------------------------------
Find out which chat command the user is typing
---------------------------------------------------------------------------*/
local function findConfig(text)
    local split = string.Explode(' ', text)
    local prefix = string.lower(split[1])

    currentChatText = split

    currentConfig = receiverConfigs[prefix] or receiverConfigs[""]
end
hook.Add("ChatTextChanged", "FrenchRP_FindChatRecipients", findConfig)


/*---------------------------------------------------------------------------
Default chat receievers. If you want to add your own ones, don't add them to this file. Add them to a clientside module file instead.
---------------------------------------------------------------------------*/
-- Load after the custom languages have been loaded
local function loadChatReceivers()
    -- Default talk chat receiver has no prefix
    FrenchRP.addChatReceiver("", FrenchRP.getPhrase("talk"), function(ply)
        if GAMEMODE.Config.alltalk then return nil end

        return LocalPlayer():GetPos():Distance(ply:GetPos()) < 250
    end)

    FrenchRP.addChatReceiver("/ooc", FrenchRP.getPhrase("speak_in_ooc"), function(ply) return true end)
    FrenchRP.addChatReceiver("//", FrenchRP.getPhrase("speak_in_ooc"), function(ply) return true end)
    FrenchRP.addChatReceiver("/a", FrenchRP.getPhrase("speak_in_ooc"), function(ply) return true end)
    FrenchRP.addChatReceiver("/w", FrenchRP.getPhrase("whisper"), function(ply) return LocalPlayer():GetPos():Distance(ply:GetPos()) < 90 end)
    FrenchRP.addChatReceiver("/y", FrenchRP.getPhrase("yell"), function(ply) return LocalPlayer():GetPos():Distance(ply:GetPos()) < 550 end)
    FrenchRP.addChatReceiver("/me", FrenchRP.getPhrase("perform_your_action"), function(ply) return LocalPlayer():GetPos():Distance(ply:GetPos()) < 250 end)
    FrenchRP.addChatReceiver("/g", FrenchRP.getPhrase("talk_to_your_group"), function(ply)
        for _, func in pairs(GAMEMODE.FrenchRPGroupChats) do
            if func(LocalPlayer()) and func(ply) then
                return true
            end
        end
        return false
    end)


    FrenchRP.addChatReceiver("/pm", "PM", function(ply, text)
        if not isstring(text[2]) then return false end
        text[2] = string.lower(tostring(text[2]))

        return string.find(string.lower(ply:Nick()), text[2], 1, true) ~= nil or
            string.find(string.lower(ply:SteamName()), text[2], 1, true) ~= nil or
            string.lower(ply:SteamID()) == text[2]
    end)

    /*---------------------------------------------------------------------------
    Voice chat receivers
    ---------------------------------------------------------------------------*/
    FrenchRP.addChatReceiver("speak", FrenchRP.getPhrase("speak"), function(ply)
        if not LocalPlayer().DRPIsTalking then return nil end
        if LocalPlayer():GetPos():Distance(ply:GetPos()) > 550 then return false end

        return not GAMEMODE.Config.dynamicvoice or ply:isInRoom()
    end)
end
hook.Add("loadCustomFrenchRPItems", "loadChatListeners", loadChatReceivers)

/*---------------------------------------------------------------------------
Called when the player starts using their voice
---------------------------------------------------------------------------*/
local function startFindVoice(ply)
    if ply ~= LocalPlayer() then return end

    currentConfig = receiverConfigs["speak"]
    hook.Add("Think", "FrenchRP_chatRecipients", chatGetRecipients)
    hook.Add("HUDPaint", "FrenchRP_DrawChatReceivers", drawChatReceivers)
end
hook.Add("PlayerStartVoice", "FrenchRP_VoiceChatReceiverFinder", startFindVoice)

/*---------------------------------------------------------------------------
Called when the player stops using their voice
---------------------------------------------------------------------------*/
local function stopFindVoice(ply)
    if ply ~= LocalPlayer() then return end

    stopFind()
end
hook.Add("PlayerEndVoice", "FrenchRP_VoiceChatReceiverFinder", stopFindVoice)
