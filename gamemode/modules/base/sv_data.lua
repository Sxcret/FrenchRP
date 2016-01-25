/*---------------------------------------------------------------------------
Functions and variables
---------------------------------------------------------------------------*/
local setUpNonOwnableDoors,
    setUpTeamOwnableDoors,
    setUpGroupDoors,
    migrateDB

/*---------------------------------------------------------
 Database initialize
 ---------------------------------------------------------*/
function FrenchRP.initDatabase()
    MySQLite.begin()
        -- Gotta love the difference between SQLite and MySQL
        local AUTOINCREMENT = MySQLite.isMySQL() and "AUTO_INCREMENT" or "AUTOINCREMENT"

        -- Table that holds all position data (jail, spawns etc.)
        -- Queue these queries because other queries depend on the existence of the frenchrp_position table
        -- Race conditions could occur if the queries are executed simultaneously
        MySQLite.queueQuery([[
            CREATE TABLE IF NOT EXISTS frenchrp_position(
                id INTEGER NOT NULL PRIMARY KEY ]] .. AUTOINCREMENT .. [[,
                map VARCHAR(45) NOT NULL,
                type CHAR(1) NOT NULL,
                x INTEGER NOT NULL,
                y INTEGER NOT NULL,
                z INTEGER NOT NULL
            );
        ]])

        -- team spawns require extra data
        MySQLite.queueQuery([[
            CREATE TABLE IF NOT EXISTS frenchrp_jobspawn(
                id INTEGER NOT NULL PRIMARY KEY,
                team INTEGER NOT NULL
            );
        ]])

        if MySQLite.isMySQL() then
            MySQLite.queueQuery([[
                ALTER TABLE frenchrp_jobspawn ADD FOREIGN KEY(id) REFERENCES frenchrp_position(id)
                    ON UPDATE CASCADE
                    ON DELETE CASCADE;
            ]])
        end

        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS playerinformation(
                uid BIGINT NOT NULL,
                steamID VARCHAR(50) NOT NULL PRIMARY KEY
            )
        ]])

        -- Player information
        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS frenchrp_player(
                uid BIGINT NOT NULL PRIMARY KEY,
                rpname VARCHAR(45),
                salary INTEGER NOT NULL DEFAULT 45,
                wallet INTEGER NOT NULL,
                UNIQUE(rpname)
            );
        ]])

        -- Door data
        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS frenchrp_door(
                idx INTEGER NOT NULL,
                map VARCHAR(45) NOT NULL,
                title VARCHAR(25),
                isLocked BOOLEAN,
                isDisabled BOOLEAN NOT NULL DEFAULT FALSE,
                PRIMARY KEY(idx, map)
            );
        ]])

        -- Some doors are owned by certain teams
        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS frenchrp_doorjobs(
                idx INTEGER NOT NULL,
                map VARCHAR(45) NOT NULL,
                job VARCHAR(255) NOT NULL,

                PRIMARY KEY(idx, map, job)
            );
        ]])

        -- Door groups
        MySQLite.query([[
            CREATE TABLE IF NOT EXISTS frenchrp_doorgroups(
                idx INTEGER NOT NULL,
                map VARCHAR(45) NOT NULL,
                doorgroup VARCHAR(100) NOT NULL,

                PRIMARY KEY(idx, map)
            )
        ]])

        MySQLite.queueQuery([[
            CREATE TABLE IF NOT EXISTS frenchrp_dbversion(version INTEGER NOT NULL PRIMARY KEY)
        ]])

        -- Load the last DBVersion into FrenchRP.DBVersion, to allow checks to see whether migration is needed.
        MySQLite.queueQuery([[
            SELECT MAX(version) AS version FROM frenchrp_dbversion
        ]], function(data) FrenchRP.DBVersion = data and data[1] and tonumber(data[1].version) or 0 end)

        MySQLite.queueQuery([[
            REPLACE INTO frenchrp_dbversion VALUES(20150725)
        ]])

        -- SQlite doesn't really handle foreign keys strictly, neither does MySQL by default
        -- So to keep the DB clean, here's a manual partial foreign key enforcement
        -- For now it's deletion only, since updating of the common attribute doesn't happen.

        -- MySQL trigger
        if MySQLite.isMySQL() then
            MySQLite.query("show triggers", function(data)
                -- Check if the trigger exists first
                if data then
                    for k,v in pairs(data) do
                        if v.Trigger == "JobPositionFKDelete" then
                            return
                        end
                    end
                end

                MySQLite.query("SHOW PRIVILEGES", function(privs)
                    if not privs then return end

                    local found;
                    for k,v in pairs(privs) do
                        if v.Privilege == "Trigger" then
                            found = true
                            break;
                        end
                    end

                    if not found then return end
                    MySQLite.query([[
                        CREATE TRIGGER JobPositionFKDelete
                            AFTER DELETE ON frenchrp_position
                            FOR EACH ROW
                                IF OLD.type = "T" THEN
                                    DELETE FROM frenchrp_jobspawn WHERE frenchrp_jobspawn.id = OLD.id;
                                END IF
                        ;
                    ]])
                end)
            end)
        else -- SQLite triggers, quite a different syntax
            MySQLite.query([[
                CREATE TRIGGER IF NOT EXISTS JobPositionFKDelete
                    AFTER DELETE ON frenchrp_position
                    FOR EACH ROW
                    WHEN OLD.type = "T"
                    BEGIN
                        DELETE FROM frenchrp_jobspawn WHERE frenchrp_jobspawn.id = OLD.id;
                    END;
            ]])
        end
    MySQLite.commit(fp{migrateDB, -- Migrate the database
        function() -- Initialize the data after all the tables have been created
            setUpNonOwnableDoors()
            setUpTeamOwnableDoors()
            setUpGroupDoors()

            if MySQLite.isMySQL() then -- In a listen server, the connection with the external database is often made AFTER the listen server host has joined,
                                        --so he walks around with the settings from the SQLite database
                for k,v in pairs(player.GetAll()) do
                    local UniqueID = MySQLite.SQLStr(v:UniqueID())
                    MySQLite.query([[SELECT * FROM frenchrp_player WHERE uid = ]] .. UniqueID .. [[;]], function(data)
                        if not data or not data[1] then return end

                        local Data = data[1]
                        v:setFrenchRPVar("rpname", Data.rpname)
                        v:setSelfFrenchRPVar("salary", Data.salary)
                        v:setFrenchRPVar("money", Data.wallet)
                    end)
                end
            end

            hook.Call("FrenchRPDBInitialized")
        end})
end

/*---------------------------------------------------------------------------
Database migration
backwards compatibility with older versions of FrenchRP
---------------------------------------------------------------------------*/
function migrateDB(callback)
    -- migrte from frenchrp_jobown to frenchrp_doorjobs
    MySQLite.tableExists("frenchrp_jobown", function(exists)
        if not exists then return callback() end

        MySQLite.begin()
            -- Create a temporary table that links job IDs to job commands
            MySQLite.queueQuery("CREATE TABLE IF NOT EXISTS TempJobCommands(id INT NOT NULL PRIMARY KEY, cmd VARCHAR(255) NOT NULL);")
            if MySQLite.isMySQL() then
                local jobCommands = {}
                for k,v in pairs(RPExtraTeams) do
                    table.insert(jobCommands, "(" .. k .. "," .. MySQLite.SQLStr(v.command) .. ")")
                end

                -- This WOULD work with SQLite if the implementation in GMod wasn't out of date.
                MySQLite.queueQuery("INSERT IGNORE INTO TempJobCommands VALUES " .. table.concat(jobCommands, ",") .. ";")
            else
                for k,v in pairs(RPExtraTeams) do
                    MySQLite.queueQuery("INSERT INTO TempJobCommands VALUES(" .. k .. ", " .. MySQLite.SQLStr(v.command) .. ");")
                end
            end

            MySQLite.queueQuery("REPLACE INTO frenchrp_doorjobs SELECT frenchrp_jobown.idx AS idx, frenchrp_jobown.map AS map, TempJobCommands.cmd AS job FROM frenchrp_jobown JOIN TempJobCommands ON frenchrp_jobown.job = TempJobCommands.id;")

            -- Clean up the transition table and the old table
            MySQLite.queueQuery("DROP TABLE TempJobCommands;")
            MySQLite.queueQuery("DROP TABLE frenchrp_jobown;")
        MySQLite.commit(callback) -- callback
    end)
end

/*---------------------------------------------------------
Players
 ---------------------------------------------------------*/
function FrenchRP.storeRPName(ply, name)
    if not name or string.len(name) < 2 then return end
    hook.Call("onPlayerChangedName", nil, ply, ply:getFrenchRPVar("rpname"), name)
    ply:setFrenchRPVar("rpname", name)

    MySQLite.query([[UPDATE frenchrp_player SET rpname = ]] .. MySQLite.SQLStr(name) .. [[ WHERE UID = ]] .. ply:UniqueID() .. ";")
end

function FrenchRP.retrieveRPNames(name, callback)
    MySQLite.query("SELECT COUNT(*) AS count FROM frenchrp_player WHERE rpname = " .. MySQLite.SQLStr(name) .. ";", function(r)
        callback(tonumber(r[1].count) > 0)
    end)
end

function FrenchRP.retrievePlayerData(ply, callback, failed, attempts)
    attempts = attempts or 0

    if attempts > 3 then return failed() end
    MySQLite.query(string.format([[REPLACE INTO playerinformation VALUES(%s, %s);]], MySQLite.SQLStr(ply:UniqueID()), MySQLite.SQLStr(ply:SteamID())))

    MySQLite.query("SELECT rpname, wallet, salary FROM frenchrp_player WHERE uid = " .. ply:UniqueID() .. ";", callback, function()
        FrenchRP.retrievePlayerData(ply, callback, failed, attempts + 1)
    end)
end

function FrenchRP.createPlayerData(ply, name, wallet, salary)
    MySQLite.query([[REPLACE INTO frenchrp_player VALUES(]] ..
            ply:UniqueID() .. [[, ]] ..
            MySQLite.SQLStr(name)  .. [[, ]] ..
            salary  .. [[, ]] ..
            wallet .. ");")
end

function FrenchRP.storeMoney(ply, amount)
    if not IsValid(ply) then return end
    if not isnumber(amount) or amount < 0 or amount >= 1 / 0 then return end

    MySQLite.query([[UPDATE frenchrp_player SET wallet = ]] .. amount .. [[ WHERE uid = ]] .. ply:UniqueID())
end

local function resetAllMoney(ply,cmd,args)
    if ply:EntIndex() ~= 0 and not ply:IsSuperAdmin() then return end
    MySQLite.query("UPDATE frenchrp_player SET wallet = " .. GAMEMODE.Config.startingmoney .. " ;")
    for k,v in pairs(player.GetAll()) do
        v:setFrenchRPVar("money", GAMEMODE.Config.startingmoney)
    end
    if ply:IsPlayer() then
        FrenchRP.notifyAll(0,4, FrenchRP.getPhrase("reset_money", ply:Nick()))
    else
        FrenchRP.notifyAll(0,4, FrenchRP.getPhrase("reset_money", "Console"))
    end
end
concommand.Add("rp_resetallmoney", resetAllMoney)

function FrenchRP.storeSalary(ply, amount)
    ply:setSelfFrenchRPVar("salary", math.floor(amount))

    return amount
end

function FrenchRP.retrieveSalary(ply, callback)
    if not IsValid(ply) then return 0 end

    local val =
        ply:getJobTable() and ply:getJobTable().salary or
        RPExtraTeams[GAMEMODE.DefaultTeam].salary or
        (GM or GAMEMODE).Config.normalsalary

    if callback then callback(val) end

    return val
end

/*---------------------------------------------------------------------------
Players
---------------------------------------------------------------------------*/
local meta = FindMetaTable("Player")
function meta:restorePlayerData()
    if not IsValid(self) then return end
    self.FrenchRPUnInitialized = true

    FrenchRP.retrievePlayerData(self, function(data)
        if not IsValid(self) then return end

        self.FrenchRPUnInitialized = nil

        local info = data and data[1] or {}
        if not info.rpname or info.rpname == "NULL" then info.rpname = string.gsub(self:SteamName(), "\\\"", "\"") end

        info.wallet = info.wallet or GAMEMODE.Config.startingmoney
        info.salary = FrenchRP.retrieveSalary(self)

        self:setFrenchRPVar("money", tonumber(info.wallet))
        self:setSelfFrenchRPVar("salary", tonumber(info.salary))

        self:setFrenchRPVar("rpname", info.rpname)

        if not data then
            FrenchRP.createPlayerData(self, info.rpname, info.wallet, info.salary)
        end
    end, function() -- Retrieving data failed, go on without it
        self.FrenchRPUnInitialized = true -- no information should be saved from here, or the playerdata might be reset

        self:setFrenchRPVar("money", GAMEMODE.Config.startingmoney)
        self:setSelfFrenchRPVar("salary", FrenchRP.retrieveSalary(self))
        self:setFrenchRPVar("rpname", string.gsub(self:SteamName(), "\\\"", "\""))

        error("Failed to retrieve player information from MySQL server")
    end)
end

/*---------------------------------------------------------
 Doors
 ---------------------------------------------------------*/
function FrenchRP.storeDoorData(ent)
    if not ent:CreatedByMap() then return end
    local map = string.lower(game.GetMap())
    local nonOwnable = ent:getKeysNonOwnable()
    local title = ent:getKeysTitle()

    MySQLite.query([[REPLACE INTO frenchrp_door VALUES(]] .. ent:doorIndex() .. [[, ]] .. MySQLite.SQLStr(map) .. [[, ]] .. (title and MySQLite.SQLStr(title) or "NULL") .. [[, ]] .. "NULL" .. [[, ]] .. (nonOwnable and 1 or 0) .. [[);]])
end

function setUpNonOwnableDoors()
    MySQLite.query("SELECT idx, title, isLocked, isDisabled FROM frenchrp_door WHERE map = " .. MySQLite.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
        if not r then return end

        for _, row in pairs(r) do
            local e = FrenchRP.doorIndexToEnt(tonumber(row.idx))

            if not IsValid(e) then continue end
            if e:isKeysOwnable() then
                if tobool(row.isDisabled) then
                    e:setKeysNonOwnable(tobool(row.isDisabled))
                end
                if row.isLocked ~= nil then
                    if row.isLocked ~= "NULL" then e:Fire((tobool(row.isLocked) and "" or "un") .. "lock", "", 0) end
                end
                e:setKeysTitle(row.title ~= "NULL" and row.title or nil)
            end
        end
    end)
end

local keyValueActions = {
    ["FrenchRPNonOwnable"] = function(ent, val) ent:setKeysNonOwnable(tobool(val)) end,
    ["FrenchRPTitle"]      = function(ent, val) ent:setKeysTitle(val) end,
    ["FrenchRPDoorGroup"]  = function(ent, val) if RPExtraTeamDoors[val] then ent:setDoorGroup(val) end end,
    ["FrenchRPCanLockpick"] = function(ent, val) ent.FrenchRPCanLockpick = tobool(val) end
}

local function onKeyValue(ent, key, value)
    if not ent:isDoor() then return end

    if keyValueActions[key] then
        keyValueActions[key](ent, value)
    end
end
hook.Add("EntityKeyValue", "frenchrp_doors", onKeyValue)

function FrenchRP.storeTeamDoorOwnability(ent)
    if not ent:CreatedByMap() then return end
    local map = string.lower(game.GetMap())

    MySQLite.query("DELETE FROM frenchrp_doorjobs WHERE idx = " .. ent:doorIndex() .. " AND map = " .. MySQLite.SQLStr(map) .. ";")
    for k,v in pairs(ent:getKeysDoorTeams() or {}) do
        MySQLite.query("INSERT INTO frenchrp_doorjobs VALUES(" .. ent:doorIndex() .. ", " .. MySQLite.SQLStr(map) .. ", " .. MySQLite.SQLStr(RPExtraTeams[k].command) .. ");")
    end
end

function setUpTeamOwnableDoors()
    MySQLite.query("SELECT idx, job FROM frenchrp_doorjobs WHERE map = " .. MySQLite.SQLStr(string.lower(game.GetMap())) .. ";", function(r)
        if not r then return end
        local map = string.lower(game.GetMap())

        for _, row in pairs(r) do
            row.idx = tonumber(row.idx)

            local e = FrenchRP.doorIndexToEnt(row.idx)
            if not IsValid(e) then continue end

            local _, job = FrenchRP.getJobByCommand(row.job)

            if job then
                e:addKeysDoorTeam(job)
            else
                print(("can't find job %s for door %d, removing from database"):format(row.job, row.idx))
                MySQLite.query(("DELETE FROM frenchrp_doorjobs WHERE idx = %d AND map = %s AND job = %s;"):format(row.idx, MySQLite.SQLStr(map), MySQLite.SQLStr(row.job)))
            end
        end
    end)
end

function FrenchRP.storeDoorGroup(ent, group)
    if not ent:CreatedByMap() then return end
    local map = MySQLite.SQLStr(string.lower(game.GetMap()))
    local index = ent:doorIndex()

    if group == "" or not group then
        MySQLite.query("DELETE FROM frenchrp_doorgroups WHERE map = " .. map .. " AND idx = " .. index .. ";")
        return
    end

    MySQLite.query("REPLACE INTO frenchrp_doorgroups VALUES(" .. index .. ", " .. map .. ", " .. MySQLite.SQLStr(group) .. ");");
end

function setUpGroupDoors()
    local map = MySQLite.SQLStr(string.lower(game.GetMap()))
    MySQLite.query("SELECT idx, doorgroup FROM frenchrp_doorgroups WHERE map = " .. map, function(data)
        if not data then return end

        for _, row in pairs(data) do
            local ent = FrenchRP.doorIndexToEnt(tonumber(row.idx))

            if not IsValid(ent) or not ent:isKeysOwnable() then
                continue
            end

            ent:setDoorGroup(row.doorgroup)
        end
    end)
end

hook.Add("PostCleanupMap", "FrenchRP.hooks", function()
    timer.Simple(0.3, function() --Hahahhah, Gmod
        setUpNonOwnableDoors()
        setUpTeamOwnableDoors()
        setUpGroupDoors()
    end)
end)
