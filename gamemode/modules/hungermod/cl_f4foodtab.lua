local PANEL = {}

local function canBuyFood(food)
    local ply = LocalPlayer()

    if (food.requiresCook == nil or food.requiresCook == true) and not ply:isCook() then return false, true end
    if food.customCheck and not food.customCheck(LocalPlayer()) then return false, false end

    if not ply:canAfford(food.price) then return false, false end

    return true
end

function PANEL:generateButtons()
    for k,v in pairs(FoodItems) do
        local pnl = vgui.Create("F4MenuEntityButton", self)
        pnl:setFrenchRPItem(v)
        pnl.DoClick = fn.Partial(RunConsoleCommand, "FrenchRP", "buyfood", v.name)
        self:AddItem(pnl)
    end
end

function PANEL:shouldHide()
    for k,v in pairs(FoodItems) do
        local canBuy, important = canBuyFood(v)
        if not self:isItemHidden(not canBuy, important) then return false end
    end
    return true
end

function PANEL:PerformLayout()
    for k,v in pairs(self.Items) do
        local canBuy, important = canBuyFood(v.FrenchRPItem)
        v:SetDisabled(not canBuy, important)
    end
    self.BaseClass.PerformLayout(self)
end

derma.DefineControl("F4MenuFood", "FrenchRP F4 Food Tab", PANEL, "F4MenuEntitiesBase")

hook.Add("F4MenuTabs", "HungerMod_F4Tabs", function()
    if #FoodItems > 0 then
        FrenchRP.addF4MenuTab(FrenchRP.getPhrase("food"), vgui.Create("F4MenuFood"))
    end
end)
