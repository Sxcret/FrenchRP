-- Modification loader.
-- Dependencies:
--     - fn
--     - simplerr

/*---------------------------------------------------------------------------
Disabled defaults
---------------------------------------------------------------------------*/
FrenchRP.disabledDefaults = {}
FrenchRP.disabledDefaults["modules"] = {
    ["afk"]              = true,
    ["chatsounds"]       = false,
    ["events"]           = false,
    ["fpp"]              = false,
    ["hitmenu"]          = false,
    ["hud"]              = false,
    ["hungermod"]        = true,
    ["playerscale"]      = false,
    ["sleep"]            = false,
}

FrenchRP.disabledDefaults["agendas"]          = {}
FrenchRP.disabledDefaults["ammo"]             = {}
FrenchRP.disabledDefaults["demotegroups"]     = {}
FrenchRP.disabledDefaults["doorgroups"]       = {}
FrenchRP.disabledDefaults["entities"]         = {}
FrenchRP.disabledDefaults["food"]             = {}
FrenchRP.disabledDefaults["groupchat"]        = {}
FrenchRP.disabledDefaults["hitmen"]           = {}
FrenchRP.disabledDefaults["jobs"]             = {}
FrenchRP.disabledDefaults["shipments"]        = {}
FrenchRP.disabledDefaults["vehicles"]         = {}

-- The client cannot use simplerr.runLuaFile because of restrictions in GMod.
local doInclude = CLIENT and include or fc{simplerr.wrapError, simplerr.wrapLog, simplerr.runFile}

if file.Exists("frenchrp_config/disabled_defaults.lua", "LUA") then
    if SERVER then AddCSLuaFile("frenchrp_config/disabled_defaults.lua") end
    doInclude("frenchrp_config/disabled_defaults.lua")
end

/*---------------------------------------------------------------------------
Config
---------------------------------------------------------------------------*/
local configFiles = {
    "frenchrp_config/settings.lua",
    "frenchrp_config/licenseweapons.lua",
}

for _, File in pairs(configFiles) do
    if not file.Exists(File, "LUA") then continue end

    if SERVER then AddCSLuaFile(File) end
    doInclude(File)
end
if SERVER and file.Exists("frenchrp_config/mysql.lua", "LUA") then doInclude("frenchrp_config/mysql.lua") end

/*---------------------------------------------------------------------------
Modules
---------------------------------------------------------------------------*/
local function loadModules()
    local fol = "frenchrp_modules/"

    local _, folders = file.Find(fol .. "*", "LUA")

    for _, folder in SortedPairs(folders, true) do
        if folder == "." or folder == ".." or GAMEMODE.Config.DisabledCustomModules[folder] then continue end
        -- Sound but incomplete way of detecting the error of putting addons in the frenchrp modifications folder
        if file.Exists(fol .. folder .. "/addon.txt", "LUA") or file.Exists(fol .. folder .. "/addon.json", "LUA") then
            FrenchRP.errorNoHalt("Addon detected in the frenchrp_modules folder.", 2, {
                "This addon is not supposed to be in the frenchrp_modules folder.",
                "It is supposed to be in garrysmod/addons/ instead.",
                "Whether a mod is to be installed in frenchrp_modules or addons is the author's decision.",
                "Please read the readme of the addons you're installing next time."
            },
            "<frenchrpmod addon>/lua/frenchrp_modules/" .. folder, -1)
            continue
        end

        for _, File in SortedPairs(file.Find(fol .. folder .. "/sh_*.lua", "LUA"), true) do
            if SERVER then
                AddCSLuaFile(fol .. folder .. "/" .. File)
            end

            if File == "sh_interface.lua" then continue end
            doInclude(fol .. folder .. "/" .. File)
        end

        if SERVER then
            for _, File in SortedPairs(file.Find(fol .. folder .. "/sv_*.lua", "LUA"), true) do
                if File == "sv_interface.lua" then continue end
                doInclude(fol .. folder .. "/" .. File)
            end
        end

        for _, File in SortedPairs(file.Find(fol .. folder .. "/cl_*.lua", "LUA"), true) do
            if File == "cl_interface.lua" then continue end

            if SERVER then
                AddCSLuaFile(fol .. folder .. "/" .. File)
            else
                doInclude(fol .. folder .. "/" .. File)
            end
        end
    end
end

local function loadLanguages()
    local fol = "frenchrp_language/"

    local files, _ = file.Find(fol .. "*", "LUA")
    for _, File in pairs(files) do
        if SERVER then AddCSLuaFile(fol .. File) end
        doInclude(fol .. File)
    end
end

local customFiles = {
    "frenchrp_customthings/jobs.lua",
    "frenchrp_customthings/shipments.lua",
    "frenchrp_customthings/entities.lua",
    "frenchrp_customthings/vehicles.lua",
    "frenchrp_customthings/food.lua",
    "frenchrp_customthings/ammo.lua",
    "frenchrp_customthings/groupchats.lua",
    "frenchrp_customthings/categories.lua",
    "frenchrp_customthings/agendas.lua", -- has to be run after jobs.lua
    "frenchrp_customthings/doorgroups.lua", -- has to be run after jobs.lua
    "frenchrp_customthings/demotegroups.lua", -- has to be run after jobs.lua
}
local function loadCustomFrenchRPItems()
    for _, File in pairs(customFiles) do
        if not file.Exists(File, "LUA") then continue end
        if File == "frenchrp_customthings/food.lua" and FrenchRP.disabledDefaults["modules"]["hungermod"] then continue end

        if SERVER then AddCSLuaFile(File) end
        doInclude(File)
    end
end


function GM:FrenchRPFinishedLoading()
    -- GAMEMODE gets set after the last statement in the gamemode files is run. That is not the case in this hook
    GAMEMODE = GAMEMODE or GM

    loadLanguages()
    loadModules()
    loadCustomFrenchRPItems()
    hook.Call("loadCustomFrenchRPItems", GAMEMODE)
end
