local TextColor = Color(GetConVar("Healthforeground1"):GetFloat(), GetConVar("Healthforeground2"):GetFloat(), GetConVar("Healthforeground3"):GetFloat(), GetConVar("Healthforeground4"):GetFloat())

local function AFKHUDPaint()
    if not LocalPlayer():getFrenchRPVar("AFK") then return end
    draw.DrawNonParsedSimpleText(FrenchRP.getPhrase("afk_mode"), "FrenchRPHUD2", ScrW() / 2, (ScrH() / 2) - 100, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.DrawNonParsedSimpleText(FrenchRP.getPhrase("salary_frozen"), "FrenchRPHUD2", ScrW() / 2, (ScrH() / 2) - 60, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    if not LocalPlayer():getFrenchRPVar("AFKDemoted") then
        draw.DrawNonParsedSimpleText(FrenchRP.getPhrase("no_auto_demote"), "FrenchRPHUD2", ScrW() / 2, (ScrH() / 2) - 20, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        draw.DrawNonParsedSimpleText(FrenchRP.getPhrase("youre_afk_demoted"), "FrenchRPHUD2", ScrW() / 2, (ScrH() / 2) - 20, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    draw.DrawNonParsedSimpleText(FrenchRP.getPhrase("afk_cmd_to_exit"), "FrenchRPHUD2", ScrW() / 2, (ScrH() / 2) + 20, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "AFK_HUD", AFKHUDPaint)
