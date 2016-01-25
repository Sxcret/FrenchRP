hook.Run("FrenchRPStartedLoading")

GM.Version = "1.0.0"
GM.Name = "FrenchRP"
GM.Author = "Sxcret (With PePe_Klinex)"

DeriveGamemode("sandbox")
DEFINE_BASECLASS("gamemode_sandbox")
GM.Sandbox = BaseClass


local function LoadModules()
    local root = GM.FolderName .. "/gamemode/modules/"
    local _, folders = file.Find(root .. "*", "LUA")

    for _, folder in SortedPairs(folders, true) do
        if FrenchRP.disabledDefaults["modules"][folder] then continue end

        for _, File in SortedPairs(file.Find(root .. folder .. "/sh_*.lua", "LUA"), true) do
            if File == "sh_interface.lua" then continue end
            include(root .. folder .. "/" .. File)
        end

        for _, File in SortedPairs(file.Find(root .. folder .. "/cl_*.lua", "LUA"), true) do
            if File == "cl_interface.lua" then continue end
            include(root .. folder .. "/" .. File)
        end
    end
end

GM.Config = {} -- config table
GM.NoLicense = GM.NoLicense or {}

include("config/config.lua")
include("libraries/sh_cami.lua")
include("libraries/simplerr.lua")
include("libraries/fn.lua")
include("libraries/tablecheck.lua")
include("libraries/interfaceloader.lua")
include("libraries/disjointset.lua")

include("libraries/modificationloader.lua")
LoadModules()

FrenchRP.DARKRP_LOADING = true
include("config/jobrelated.lua")
include("config/addentities.lua")
include("config/ammotypes.lua")
FrenchRP.DARKRP_LOADING = nil

FrenchRP.finish()

hook.Call("FrenchRPFinishedLoading", GM)
