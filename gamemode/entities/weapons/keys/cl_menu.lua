local function AddButtonToFrame(Frame)
    Frame:SetTall(Frame:GetTall() + 110)

    local button = vgui.Create("DButton", Frame)
    button:SetPos(10, Frame:GetTall() - 110)
    button:SetSize(180, 100)

    Frame.buttonCount = (Frame.buttonCount or 0) + 1
    Frame.lastButton = button
    return button
end

FrenchRP.stub{
    name = "openKeysMenu",
    description = "Open the keys/F2 menu.",
    parameters = {},
    realm = "Client",
    returns = {},
    metatable = FrenchRP
}

FrenchRP.hookStub{
    name = "onKeysMenuOpened",
    description = "Called when the keys menu is opened.",
    parameters = {
        {
            name = "ent",
            description = "The door entity.",
            type = "Entity"
        },
        {
            name = "Frame",
            description = "The keys menu frame.",
            type = "Panel"
        }
    },
    returns = {
    },
    realm = "Client"
}

local KeyFrameVisible = false

local function openMenu(setDoorOwnerAccess, doorSettingsAccess)
    if KeyFrameVisible then return end

    local ent = LocalPlayer():GetEyeTrace().Entity
    -- Don't open the menu if the entity is not ownable, the entity is too far away or the door settings are not loaded yet
    if not IsValid(ent) or not ent:isKeysOwnable() or ent:GetPos():Distance(LocalPlayer():GetPos()) > 200 then return end

    KeyFrameVisible = true
    local Frame = vgui.Create("DFrame")
    Frame:SetSize(200, 30) -- base size
    Frame:SetVisible(true)
    Frame:MakePopup()

    function Frame:Think()
        local LAEnt = LocalPlayer():GetEyeTrace().Entity
        if not IsValid(LAEnt) or not LAEnt:isKeysOwnable() or LAEnt:GetPos():Distance(LocalPlayer():GetPos()) > 200 then
            self:Close()
        end
        if not self.Dragging then return end
        local x = gui.MouseX() - self.Dragging[1]
        local y = gui.MouseY() - self.Dragging[2]
        x = math.Clamp(x, 0, ScrW() - self:GetWide())
        y = math.Clamp(y, 0, ScrH() - self:GetTall())
        self:SetPos(x, y)
    end

    local entType = FrenchRP.getPhrase(ent:IsVehicle() and "vehicle" or "door")
    Frame:SetTitle(FrenchRP.getPhrase("x_options", entType:gsub("^%a", string.upper)))

    function Frame:Close()
        KeyFrameVisible = false
        self:SetVisible(false)
        self:Remove()
    end

    -- All the buttons

    if ent:isKeysOwnedBy(LocalPlayer()) then
        local Owndoor = AddButtonToFrame(Frame)
        Owndoor:SetText(FrenchRP.getPhrase("sell_x", entType))
        Owndoor.DoClick = function() RunConsoleCommand("frenchrp", "toggleown") Frame:Close() end

        local AddOwner = AddButtonToFrame(Frame)
        AddOwner:SetText(FrenchRP.getPhrase("add_owner"))
        AddOwner.DoClick = function()
            local menu = DermaMenu()
            menu.found = false
            for k,v in pairs(FrenchRP.nickSortedPlayers()) do
                if not ent:isKeysOwnedBy(v) and not ent:isKeysAllowedToOwn(v) then
                    local steamID = v:SteamID()
                    menu.found = true
                    menu:AddOption(v:Nick(), function() RunConsoleCommand("frenchrp", "ao", steamID) end)
                end
            end
            if not menu.found then
                menu:AddOption(FrenchRP.getPhrase("noone_available"), function() end)
            end
            menu:Open()
        end

        local RemoveOwner = AddButtonToFrame(Frame)
        RemoveOwner:SetText(FrenchRP.getPhrase("remove_owner"))
        RemoveOwner.DoClick = function()
            local menu = DermaMenu()
            for k,v in pairs(FrenchRP.nickSortedPlayers()) do
                if (ent:isKeysOwnedBy(v) and not ent:isMasterOwner(v)) or ent:isKeysAllowedToOwn(v) then
                    local steamID = v:SteamID()
                    menu.found = true
                    menu:AddOption(v:Nick(), function() RunConsoleCommand("frenchrp", "ro", steamID) end)
                end
            end
            if not menu.found then
                menu:AddOption(FrenchRP.getPhrase("noone_available"), function() end)
            end
            menu:Open()
        end
        if not ent:isMasterOwner(LocalPlayer()) then
            RemoveOwner:SetDisabled(true)
        end
    end

    if doorSettingsAccess then
        local DisableOwnage = AddButtonToFrame(Frame)
        DisableOwnage:SetText(FrenchRP.getPhrase(ent:getKeysNonOwnable() and "allow_ownership" or "disallow_ownership"))
        DisableOwnage.DoClick = function() Frame:Close() RunConsoleCommand("frenchrp", "toggleownable") end
    end

    if doorSettingsAccess and (ent:isKeysOwned() or ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or hasTeams) or ent:isKeysOwnedBy(LocalPlayer()) then
        local DoorTitle = AddButtonToFrame(Frame)
        DoorTitle:SetText(FrenchRP.getPhrase("set_x_title", entType))
        DoorTitle.DoClick = function()
            Derma_StringRequest(FrenchRP.getPhrase("set_x_title", entType), FrenchRP.getPhrase("set_x_title_long", entType), "", function(text)
                RunConsoleCommand("frenchrp", "title", text)
                if IsValid(Frame) then
                    Frame:Close()
                end
            end,
            function() end, FrenchRP.getPhrase("ok"), FrenchRP.getPhrase("cancel"))
        end
    end

    if not ent:isKeysOwned() and not ent:getKeysNonOwnable() and not ent:getKeysDoorGroup() and not ent:getKeysDoorTeams() or not ent:isKeysOwnedBy(LocalPlayer()) and ent:isKeysAllowedToOwn(LocalPlayer()) then
        local Owndoor = AddButtonToFrame(Frame)
        Owndoor:SetText(FrenchRP.getPhrase("buy_x", entType))
        Owndoor.DoClick = function() RunConsoleCommand("frenchrp", "toggleown") Frame:Close() end
    end

    if doorSettingsAccess then
        local EditDoorGroups = AddButtonToFrame(Frame)
        EditDoorGroups:SetText(FrenchRP.getPhrase("edit_door_group"))
        EditDoorGroups.DoClick = function()
            local menu = DermaMenu()
            local groups = menu:AddSubMenu(FrenchRP.getPhrase("door_groups"))
            local teams = menu:AddSubMenu(FrenchRP.getPhrase("jobs"))
            local add = teams:AddSubMenu(FrenchRP.getPhrase("add"))
            local remove = teams:AddSubMenu(FrenchRP.getPhrase("remove"))

            menu:AddOption(FrenchRP.getPhrase("none"), function() RunConsoleCommand("frenchrp", "togglegroupownable") Frame:Close() end)
            for k,v in pairs(RPExtraTeamDoors) do
                groups:AddOption(k, function()
                    RunConsoleCommand("frenchrp", "togglegroupownable", k)
                    Frame:Close()
                end)
            end

            local doorTeams = ent:getKeysDoorTeams()
            for k,v in pairs(RPExtraTeams) do
                local which = (not doorTeams or not doorTeams[k]) and add or remove
                which:AddOption(v.name, function()
                    RunConsoleCommand("frenchrp", "toggleteamownable", k)
                    Frame:Close()
                end)
            end

            menu:Open()
        end
    end

    if Frame.buttonCount == 1 then
        Frame.lastButton:DoClick()
    elseif Frame.buttonCount == 0 or not Frame.buttonCount then
        Frame:Close()
        KeyFrameVisible = true
        timer.Simple(0.3, function() KeyFrameVisible = false end)
    end


    hook.Call("onKeysMenuOpened", nil, ent, Frame)

    Frame:Center()
    Frame:SetSkin(GAMEMODE.Config.FrenchRPSkin)
end

function FrenchRP.openKeysMenu(um)
    CAMI.PlayerHasAccess(LocalPlayer(), "FrenchRP_SetDoorOwner", function(setDoorOwnerAccess)
        CAMI.PlayerHasAccess(LocalPlayer(), "FrenchRP_ChangeDoorSettings", fp{openMenu, setDoorOwnerAccess})
    end)
end
usermessage.Hook("KeysMenu", FrenchRP.openKeysMenu)
