local f4Frame

/*---------------------------------------------------------------------------
Interface functions
---------------------------------------------------------------------------*/
function FrenchRP.openF4Menu()
    if IsValid(f4Frame) then
        f4Frame:Show()
        f4Frame:InvalidateLayout()
    else
        f4Frame = vgui.Create("F4MenuFrame")
        f4Frame:generateTabs()
    end
end

function FrenchRP.closeF4Menu()
    if f4Frame then
        f4Frame:Hide()
    end
end

function FrenchRP.toggleF4Menu()
    if not IsValid(f4Frame) or not f4Frame:IsVisible() then
        FrenchRP.openF4Menu()
    else
        FrenchRP.closeF4Menu()
    end
end

GM.ShowSpare2 = FrenchRP.toggleF4Menu

function FrenchRP.getF4MenuPanel()
    return f4Frame
end

function FrenchRP.addF4MenuTab(name, panel)
    if not f4Frame then FrenchRP.error("FrenchRP.addF4MenuTab called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    return f4Frame:createTab(name, panel)
end

function FrenchRP.removeF4MenuTab(name)
    if not f4Frame then FrenchRP.error("FrenchRP.addF4MenuTab called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    f4Frame:removeTab(name)
end

function FrenchRP.switchTabOrder(tab1, tab2)
    if not f4Frame then FrenchRP.error("FrenchRP.addF4MenuTab called at the wrong time. Please call in the F4MenuTabs hook.", 2) end

    f4Frame:switchTabOrder(tab1, tab2)
end


/*---------------------------------------------------------------------------
Hooks
---------------------------------------------------------------------------*/
function FrenchRP.hooks.F4MenuTabs()
    FrenchRP.addF4MenuTab(FrenchRP.getPhrase("jobs"), vgui.Create("F4MenuJobs"))
    FrenchRP.addF4MenuTab(FrenchRP.getPhrase("F4entities"), vgui.Create("F4MenuEntities"))

    local shipments = fn.Filter(fn.Compose{fn.Not, fn.Curry(fn.GetValue, 2)("noship")}, CustomShipments)
    if #shipments > 0 then
        FrenchRP.addF4MenuTab(FrenchRP.getPhrase("shipments"), vgui.Create("F4MenuShipments"))
    end

    local guns = fn.Filter(fn.Curry(fn.GetValue, 2)("separate"), CustomShipments)
    if #guns > 0 then
        FrenchRP.addF4MenuTab(FrenchRP.getPhrase("F4guns"), vgui.Create("F4MenuGuns"))
    end

    if #GAMEMODE.AmmoTypes > 0 then
        FrenchRP.addF4MenuTab(FrenchRP.getPhrase("F4ammo"), vgui.Create("F4MenuAmmo"))
    end

    if #CustomVehicles > 0 then
        FrenchRP.addF4MenuTab(FrenchRP.getPhrase("F4vehicles"), vgui.Create("F4MenuVehicles"))
    end
end

hook.Add("FrenchRPVarChanged", "RefreshF4Menu", function(ply, varname)
    if ply ~= LocalPlayer() or varname ~= "money" or not IsValid(f4Frame) or not f4Frame:IsVisible() then return end

    f4Frame:InvalidateLayout()
end)

/*---------------------------------------------------------------------------
Fonts
---------------------------------------------------------------------------*/
surface.CreateFont("Roboto Light", { -- font is not found otherwise
        size = 19,
        weight = 300,
        antialias = true,
        shadow = false,
        font = "Roboto Light"})

surface.CreateFont("F4MenuFont01", {
        size = 23,
        weight = 400,
        antialias = true,
        shadow = false,
        font = "Roboto Light"})

surface.CreateFont("F4MenuFont02", {
        size = 30,
        weight = 800,
        antialias = true,
        shadow = false,
        font = "Roboto Light"})
