local MotdMessage =
[[


---------------------------------------------------------------------------
            FrenchRP Message of the day!
---------------------------------------------------------------------------
]]

local endMOTD = "---------------------------------------------------------------------------\n"

local function drawMOTD(text)
    MsgC(Color(255, 20, 20, 255), MotdMessage, Color(255, 255, 255, 255), text, Color(255, 20, 20, 255), endMOTD)
end

local function receiveMOTD(html, len, headers, code)
    if not headers or headers.Status and string.sub(headers.Status, 1, 3) ~= "200" then return end
    drawMOTD(html)
end

local function showMOTD()
    http.Fetch("https://raw.github.com/FPtje/FrenchRPMotd/master/motd.txt", receiveMOTD, fn.Id)
end
timer.Simple(5, showMOTD)

concommand.Add("FrenchRP_motd", showMOTD)
