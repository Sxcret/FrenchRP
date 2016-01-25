local PANEL = {}

function PANEL:Init()
    self:SetWide(300)
    self:SetKeyboardInputEnabled(true)
    self.BaseClass.Init(self)
    self.F1Down = true
    self:SetFont("FrenchRPHUD2")
    self:SetTextColor(Color(255,255,255,255))
    self:SetCursorColor(Color(255,255,255,255))

    self.lblSearch = vgui.Create("DLabel", self)
    self.lblSearch:SetFont("FrenchRPHUD2")
    self.lblSearch:SetColor(Color(200, 200, 200, 200))
    self.lblSearch:SetText(FrenchRP.getPhrase("f1Search"))
    self.lblSearch:SizeToContents()
    self.lblSearch:SetPos(5)
end

function PANEL:OnLoseFocus()

end

local F1Bind
function PANEL:Think()
    F1Bind = F1Bind or input.KeyNameToNumber(input.LookupBinding("gm_showhelp"))
    if not F1Bind then return end

    if self.F1Down and not input.IsKeyDown(F1Bind) then
        self.F1Down = false
        return
    elseif not self.F1Down and input.IsKeyDown(F1Bind) then
        self.F1Down = true
        self:GetParent():slideOut()
    end
end

hook.Add("PlayerBindPress", "FrenchRPF1Bind", function(ply, bind, pressed)
    if string.find(bind, "gm_showhelp", 1, true) then
        F1Bind = input.KeyNameToNumber(input.LookupBinding(bind))
    end
end)

function PANEL:OnTextChanged()
    self.BaseClass.OnTextChanged(self)
    if self:GetText() == "" then
        self.lblSearch:SetVisible(true)
    else
        self.lblSearch:SetVisible(false)
    end
end

derma.DefineControl("F1SearchBox", "The search box to search chat commands", PANEL, "DTextEntry")