local plyMeta = FindMetaTable("Player")

-----------------------------------------------------------
-- Job commands --
-----------------------------------------------------------
local function declareTeamCommands(CTeam)
    local k = 0
    for num,v in pairs(RPExtraTeams) do
        if v.command == CTeam.command then
            k = num
        end
    end

    if CTeam.vote or CTeam.RequiresVote then
        FrenchRP.declareChatCommand{
            command = "vote" .. CTeam.command,
            description = "Vote to become " .. CTeam.name .. ".",
            delay = 1.5,
            condition = fn.FAnd
            {
                fn.If(
                    fn.Curry(isfunction, 2)(CTeam.RequiresVote),
                    fn.Curry(fn.Flip(fn.FOr{fn.Curry(fn.Const, 2)(CTeam.RequiresVote), fn.Curry(fn.Const, 2)(-1)}()), 2)(k),
                    fn.Curry(fn.Const, 2)(true)
                )(),
                fn.If(
                    fn.Curry(isnumber, 2)(CTeam.NeedToChangeFrom),
                    fn.Compose{fn.Curry(fn.Eq, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                    fn.If(
                        fn.Curry(istable, 2)(CTeam.NeedToChangeFrom),
                        fn.Compose{fn.Curry(table.HasValue, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                        fn.Curry(fn.Const, 2)(true)
                    )()
                )(),
                fn.If(
                    fn.Curry(isfunction, 2)(CTeam.customCheck),
                    CTeam.customCheck,
                    fn.Curry(fn.Const, 2)(true)
                )(),
                fn.Compose{fn.Curry(fn.Neq, 2)(k), plyMeta.Team},
                fn.FOr {
                    fn.Curry(fn.Lte, 3)(CTeam.admin)(0),
                    fn.FAnd{fn.Curry(fn.Eq, 3)(CTeam.admin)(1), plyMeta.IsAdmin},
                    fn.FAnd{fn.Curry(fn.Gte, 3)(CTeam.admin)(2), plyMeta.IsSuperAdmin}
                }
            }
        }

        FrenchRP.declareChatCommand{
            command = CTeam.command,
            description = "Become " .. CTeam.name .. " and skip the vote.",
            delay = 1.5,
            condition = fn.FAnd {
                fn.FOr {
                    fn.FAnd {
                        fn.FOr {
                            fn.Curry(fn.Lte, 3)(CTeam.admin)(0),
                            fn.FAnd{fn.Curry(fn.Eq, 3)(CTeam.admin)(1), plyMeta.IsAdmin},
                            fn.FAnd{fn.Curry(fn.Gte, 3)(CTeam.admin)(2), plyMeta.IsSuperAdmin}
                        },
                        fn.If(
                            fn.Curry(isfunction, 2)(CTeam.RequiresVote),
                            fn.Curry(fn.Flip(fn.FOr{fn.Curry(fn.Const, 2)(CTeam.RequiresVote), fn.Curry(fn.Const, 2)(-1)}()), 2)(k),
                            fn.FOr {
                                fn.FAnd{fn.Curry(fn.Eq, 3)(CTeam.admin)(0), plyMeta.IsAdmin},
                                fn.FAnd{fn.Curry(fn.Eq, 3)(CTeam.admin)(1), plyMeta.IsSuperAdmin}
                            }
                        )()
                    }
                },
                fn.Compose{fn.Not, plyMeta.isArrested},
                fn.If(
                    fn.Curry(isnumber, 2)(CTeam.NeedToChangeFrom),
                    fn.Compose{fn.Curry(fn.Eq, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                    fn.If(
                        fn.Curry(istable, 2)(CTeam.NeedToChangeFrom),
                        fn.Compose{fn.Curry(table.HasValue, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                        fn.Curry(fn.Const, 2)(true)
                    )()
                )(),
                fn.If(
                    fn.Curry(isfunction, 2)(CTeam.customCheck),
                    CTeam.customCheck,
                    fn.Curry(fn.Const, 2)(true)
                )(),
                fn.Compose{fn.Curry(fn.Neq, 2)(k), plyMeta.Team}
            }
        }
    else
        FrenchRP.declareChatCommand{
            command = CTeam.command,
            description = "Become " .. CTeam.name .. ".",
            delay = 1.5,
            condition = fn.FAnd
            {
                fn.Compose{fn.Not, plyMeta.isArrested},
                fn.If(
                    fn.Curry(isnumber, 2)(CTeam.NeedToChangeFrom),
                    fn.Compose{fn.Curry(fn.Eq, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                    fn.If(
                        fn.Curry(istable, 2)(CTeam.NeedToChangeFrom),
                        fn.Compose{fn.Curry(table.HasValue, 2)(CTeam.NeedToChangeFrom), plyMeta.Team},
                        fn.Curry(fn.Const, 2)(true)
                    )()
                )(),
                fn.If(
                    fn.Curry(isfunction, 2)(CTeam.customCheck),
                    CTeam.customCheck,
                    fn.Curry(fn.Const, 2)(true)
                )(),
                fn.Compose{fn.Curry(fn.Neq, 2)(k), plyMeta.Team},
                fn.FOr {
                    fn.Curry(fn.Lte, 3)(CTeam.admin)(0),
                    fn.FAnd{fn.Curry(fn.Eq, 3)(CTeam.admin)(1), plyMeta.IsAdmin},
                    fn.FAnd{fn.Curry(fn.Gte, 3)(CTeam.admin)(2), plyMeta.IsSuperAdmin}
                }
            }
        }
    end
end

local function addTeamCommands(CTeam, max)
    if CLIENT then return end

    if not GAMEMODE:CustomObjFitsMap(CTeam) then return end
    local k = 0
    for num,v in pairs(RPExtraTeams) do
        if v.command == CTeam.command then
            k = num
        end
    end

    if CTeam.vote or CTeam.RequiresVote then
        FrenchRP.defineChatCommand("vote" .. CTeam.command, function(ply)
            if CTeam.RequiresVote and not CTeam.RequiresVote(ply, k) then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("job_doesnt_require_vote_currently"))

                return ""
            end

            if CTeam.canStartVote and not CTeam.canStartVote(ply) then
                local reason = isfunction(CTeam.canStartVoteReason) and CTeam.canStartVoteReason(ply, CTeam) or CTeam.canStartVoteReason or ""
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", "/vote" .. CTeam.command, reason))

                return ""
            end

            if CTeam.admin == 1 and not ply:IsAdmin() then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_admin", "/" .. "vote" .. CTeam.command))

                return ""
            elseif CTeam.admin > 1 and not ply:IsSuperAdmin() then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_sadmin", "/" .. "vote" .. CTeam.command))

                return ""
            end

            if type(CTeam.NeedToChangeFrom) == "number" and ply:Team() ~= CTeam.NeedToChangeFrom then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_to_be_before", team.GetName(CTeam.NeedToChangeFrom), CTeam.name))

                return ""
            elseif type(CTeam.NeedToChangeFrom) == "table" and not table.HasValue(CTeam.NeedToChangeFrom, ply:Team()) then
                local teamnames = ""

                for a, b in pairs(CTeam.NeedToChangeFrom) do
                    teamnames = teamnames .. " or " .. team.GetName(b)
                end

                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_to_be_before", string.sub(teamnames, 5), CTeam.name))

                return ""
            end

            if CTeam.customCheck and not CTeam.customCheck(ply) then
                local message = isfunction(CTeam.CustomCheckFailMsg) and CTeam.CustomCheckFailMsg(ply, CTeam) or CTeam.CustomCheckFailMsg or FrenchRP.getPhrase("unable", team.GetName(t), "")
                FrenchRP.notify(ply, 1, 4, message)

                return ""
            end

            local allowed, time = ply:changeAllowed(k)
            if not allowed then
                local notif = time and FrenchRP.getPhrase("have_to_wait",  math.ceil(time), "/job, " .. FrenchRP.getPhrase("banned_or_demoted")) or FrenchRP.getPhrase("unable", team.GetName(k), FrenchRP.getPhrase("banned_or_demoted"))
                FrenchRP.notify(ply, 1, 4, notif)

                return ""
            end

            if ply:Team() == k then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("unable", CTeam.command, ""))

                return ""
            end

            if max ~= 0 and ((max % 1 == 0 and team.NumPlayers(k) >= max) or (max % 1 ~= 0 and (team.NumPlayers(k) + 1) / #player.GetAll() > max)) then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("team_limit_reached", CTeam.name))

                return ""
            end

            if ply.LastJob and 10 - (CurTime() - ply.LastJob) >= 0 then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("have_to_wait", math.ceil(10 - (CurTime() - ply.LastJob)), GAMEMODE.Config.chatCommandPrefix .. CTeam.command))

                return ""
            end

            ply.LastVoteCop = ply.LastVoteCop or -80

            if CurTime() - ply.LastVoteCop < 80 then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("have_to_wait", math.ceil(80 - (CurTime() - ply:GetTable().LastVoteCop)), GAMEMODE.Config.chatCommandPrefix .. CTeam.command))

                return ""
            end

            FrenchRP.createVote(FrenchRP.getPhrase("wants_to_be", ply:Nick(), CTeam.name), "job", ply, 20, function(vote, choice)
                local target = vote.target
                if not IsValid(target) then return end

                if choice >= 0 then
                    target:changeTeam(k)
                else
                    FrenchRP.notifyAll(1, 4, FrenchRP.getPhrase("has_not_been_made_team", target:Nick(), CTeam.name))
                end
            end, nil, nil, {
                targetTeam = k
            })

            ply.LastVoteCop = CurTime()

            return ""
        end)

        local function onJobCommand(ply, hasPriv)
            if hasPriv then
                ply:changeTeam(k)
                return
            end

            local a = CTeam.admin
            if a > 0 and not ply:IsAdmin()
            or a > 1 and not ply:IsSuperAdmin()
            then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_admin", CTeam.name))
                return
            end

            if not CTeam.RequiresVote and
                (a == 0 and not ply:IsAdmin()
                or a == 1 and not ply:IsSuperAdmin()
                or a == 2)
            or CTeam.RequiresVote and CTeam.RequiresVote(ply, k)
            then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_to_make_vote", CTeam.name))
                return
            end

            ply:changeTeam(k)
        end
        FrenchRP.defineChatCommand(CTeam.command, function(ply)
            CAMI.PlayerHasAccess(ply, "FrenchRP_GetJob_" .. CTeam.command, fp{onJobCommand, ply})

            return ""
        end)
    else
        FrenchRP.defineChatCommand(CTeam.command, function(ply)
            if CTeam.admin == 1 and not ply:IsAdmin() then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_admin", "/" .. CTeam.command))

                return ""
            end

            if CTeam.admin > 1 and not ply:IsSuperAdmin() then
                FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("need_sadmin", "/" .. CTeam.command))

                return ""
            end

            ply:changeTeam(k)

            return ""
        end)
    end

    concommand.Add("rp_" .. CTeam.command, function(ply, cmd, args)
        if ply:EntIndex() ~= 0 and not ply:IsAdmin() then
            ply:PrintMessage(HUD_PRINTCONSOLE, FrenchRP.getPhrase("need_admin", cmd))
            return
        end

        if CTeam.admin > 1 and not ply:IsSuperAdmin() and ply:EntIndex() ~= 0 then
            ply:PrintMessage(HUD_PRINTCONSOLE, FrenchRP.getPhrase("need_sadmin", cmd))
            return
        end

        if CTeam.vote then
            if CTeam.admin >= 1 and ply:EntIndex() ~= 0 and not ply:IsSuperAdmin() then
                ply:PrintMessage(HUD_PRINTCONSOLE, FrenchRP.getPhrase("need_sadmin", cmd))
                return
            elseif CTeam.admin > 1 and ply:IsSuperAdmin() and ply:EntIndex() ~= 0 then
                ply:PrintMessage(HUD_PRINTCONSOLE, FrenchRP.getPhrase("need_to_make_vote", CTeam.name))
                return
            end
        end

        if not args or not args[1] then
            FrenchRP.printConsoleMessage(ply, FrenchRP.getPhrase("invalid_x", FrenchRP.getPhrase("arguments"), ""))
            return
        end

        local target = FrenchRP.findPlayer(args[1])

        if (target) then
            target:changeTeam(k, true)
            local nick
            if (ply:EntIndex() ~= 0) then
                nick = ply:Nick()
            else
                nick = "Console"
            end
            FrenchRP.notify(target, 0, 4, FrenchRP.getPhrase("x_made_you_a_y", nick, CTeam.name))
        else
            FrenchRP.printConsoleMessage(ply, FrenchRP.getPhrase("could_not_find", tostring(args[1])))
        end
    end)
end

local function addEntityCommands(tblEnt)
    FrenchRP.declareChatCommand{
        command = tblEnt.cmd,
        description = "Purchase a " .. tblEnt.name,
        delay = 2,
        condition = fn.FAnd
        {
            fn.Compose{fn.Not, plyMeta.isArrested},
            fn.If(
                fn.Curry(istable, 2)(tblEnt.allowed),
                fn.Compose{fn.Curry(table.HasValue, 2)(tblEnt.allowed), plyMeta.Team},
                fn.Curry(fn.Const, 2)(true)
            )(),
            fn.If(
                fn.Curry(isfunction, 2)(tblEnt.customCheck),
                tblEnt.customCheck,
                fn.Curry(fn.Const, 2)(true)
            )(),
            fn.Curry(fn.Flip(plyMeta.canAfford), 2)(tblEnt.price)
        }
    }
    if CLIENT then return end

    -- Default spawning function of an entity
    -- used if tblEnt.spawn is not defined
    local function defaultSpawn(ply, tr, tblE)
        local ent = ents.Create(tblE.ent)
        if not ent:IsValid() then error("Entity '" .. tblE.ent .. "' does not exist or is not valid.") end
        ent.dt = ent.dt or {}
        ent.dt.owning_ent = ply
        if ent.Setowning_ent then ent:Setowning_ent(ply) end
        ent:SetPos(tr.HitPos)
        -- These must be set before :Spawn()
        ent.SID = ply.SID
        ent.allowed = tblE.allowed
        ent.FrenchRPItem = tblE
        ent:Spawn()

        local phys = ent:GetPhysicsObject()
        if phys:IsValid() then phys:Wake() end

        return ent
    end

    local function buythis(ply, args)
        if ply:isArrested() then return "" end
        if type(tblEnt.allowed) == "table" and not table.HasValue(tblEnt.allowed, ply:Team()) then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("incorrect_job", tblEnt.cmd))
            return ""
        end

        if tblEnt.customCheck and not tblEnt.customCheck(ply) then
            local message = isfunction(tblEnt.CustomCheckFailMsg) and tblEnt.CustomCheckFailMsg(ply, tblEnt) or
                tblEnt.CustomCheckFailMsg or
                FrenchRP.getPhrase("not_allowed_to_purchase")
            FrenchRP.notify(ply, 1, 4, message)
            return ""
        end

        if ply:customEntityLimitReached(tblEnt) then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("limit", tblEnt.cmd))
            return ""
        end

        local canbuy, suppress, message, price = hook.Call("canBuyCustomEntity", nil, ply, tblEnt)

        local cost = price or tblEnt.getPrice and tblEnt.getPrice(ply, tblEnt.price) or tblEnt.price

        if not ply:canAfford(cost) then
            FrenchRP.notify(ply, 1, 4, FrenchRP.getPhrase("cant_afford", tblEnt.cmd))
            return ""
        end

        if canbuy == false then
            if not suppress and message then FrenchRP.notify(ply, 1, 4, message) end
            return ""
        end

        ply:addMoney(-cost)

        local trace = {}
        trace.start = ply:EyePos()
        trace.endpos = trace.start + ply:GetAimVector() * 85
        trace.filter = ply

        local tr = util.TraceLine(trace)

        local ent = (tblEnt.spawn or defaultSpawn)(ply, tr, tblEnt)
        ent.onlyremover = true
        -- Repeat these properties to alleviate work in tblEnt.spawn:
        ent.SID = ply.SID
        ent.allowed = tblEnt.allowed
        ent.FrenchRPItem = tblEnt

        hook.Call("playerBoughtCustomEntity", nil, ply, tblEnt, ent, cost)

        FrenchRP.notify(ply, 0, 4, FrenchRP.getPhrase("you_bought", tblEnt.name, FrenchRP.formatMoney(cost), ""))

        ply:addCustomEntity(tblEnt)
        return ""
    end
    FrenchRP.defineChatCommand(tblEnt.cmd, buythis)
end

RPExtraTeams = {}
local jobByCmd = {}
FrenchRP.getJobByCommand = function(cmd)
    if not jobByCmd[cmd] then return nil, nil end
    return RPExtraTeams[jobByCmd[cmd]], jobByCmd[cmd]
end
plyMeta.getJobTable = function(ply) return RPExtraTeams[ply:Team()] end
local jobCount = 0
function FrenchRP.createJob(Name, colorOrTable, model, Description, Weapons, command, maximum_amount_of_this_class, Salary, admin, Vote, Haslicense, NeedToChangeFrom, CustomCheck)
    local tableSyntaxUsed = not IsColor(colorOrTable)

    local CustomTeam = tableSyntaxUsed and colorOrTable or
        {color = colorOrTable, model = model, description = Description, weapons = Weapons, command = command,
            max = maximum_amount_of_this_class, salary = Salary, admin = admin or 0, vote = tobool(Vote), hasLicense = Haslicense,
            NeedToChangeFrom = NeedToChangeFrom, customCheck = CustomCheck
        }
    CustomTeam.name = Name
    CustomTeam.default = FrenchRP.DARKRP_LOADING

    -- Disabled job
    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["jobs"][CustomTeam.command] then return end

    local valid, err, hints = FrenchRP.validateJob(CustomTeam)
    if not valid then FrenchRP.error(string.format("Corrupt team: %s!\n%s", CustomTeam.name or "", err), 2, hints) end

    jobCount = jobCount + 1
    CustomTeam.team = jobCount

    CustomTeam.salary = math.floor(CustomTeam.salary)

    CustomTeam.customCheck           = CustomTeam.customCheck           and fp{FrenchRP.simplerrRun, CustomTeam.customCheck}
    CustomTeam.CustomCheckFailMsg = isfunction(CustomTeam.CustomCheckFailMsg) and fp{FrenchRP.simplerrRun, CustomTeam.CustomCheckFailMsg} or CustomTeam.CustomCheckFailMsg
    CustomTeam.CanPlayerSuicide      = CustomTeam.CanPlayerSuicide      and fp{FrenchRP.simplerrRun, CustomTeam.CanPlayerSuicide}
    CustomTeam.PlayerCanPickupWeapon = CustomTeam.PlayerCanPickupWeapon and fp{FrenchRP.simplerrRun, CustomTeam.PlayerCanPickupWeapon}
    CustomTeam.PlayerDeath           = CustomTeam.PlayerDeath           and fp{FrenchRP.simplerrRun, CustomTeam.PlayerDeath}
    CustomTeam.PlayerLoadout         = CustomTeam.PlayerLoadout         and fp{FrenchRP.simplerrRun, CustomTeam.PlayerLoadout}
    CustomTeam.PlayerSelectSpawn     = CustomTeam.PlayerSelectSpawn     and fp{FrenchRP.simplerrRun, CustomTeam.PlayerSelectSpawn}
    CustomTeam.PlayerSetModel        = CustomTeam.PlayerSetModel        and fp{FrenchRP.simplerrRun, CustomTeam.PlayerSetModel}
    CustomTeam.PlayerSpawn           = CustomTeam.PlayerSpawn           and fp{FrenchRP.simplerrRun, CustomTeam.PlayerSpawn}
    CustomTeam.PlayerSpawnProp       = CustomTeam.PlayerSpawnProp       and fp{FrenchRP.simplerrRun, CustomTeam.PlayerSpawnProp}
    CustomTeam.RequiresVote          = CustomTeam.RequiresVote          and fp{FrenchRP.simplerrRun, CustomTeam.RequiresVote}
    CustomTeam.ShowSpare1            = CustomTeam.ShowSpare1            and fp{FrenchRP.simplerrRun, CustomTeam.ShowSpare1}
    CustomTeam.ShowSpare2            = CustomTeam.ShowSpare2            and fp{FrenchRP.simplerrRun, CustomTeam.ShowSpare2}
    CustomTeam.canStartVote          = CustomTeam.canStartVote          and fp{FrenchRP.simplerrRun, CustomTeam.canStartVote}

    jobByCmd[CustomTeam.command] = table.insert(RPExtraTeams, CustomTeam)
    FrenchRP.addToCategory(CustomTeam, "jobs", CustomTeam.category)
    team.SetUp(#RPExtraTeams, Name, CustomTeam.color)
    local Team = #RPExtraTeams

    timer.Simple(0, function()
        declareTeamCommands(CustomTeam)
        addTeamCommands(CustomTeam, CustomTeam.max)
    end)

    -- Precache model here. Not right before the job change is done
    if type(CustomTeam.model) == "table" then
        for k,v in pairs(CustomTeam.model) do util.PrecacheModel(v) end
    else
        util.PrecacheModel(CustomTeam.model)
    end
    return Team
end
AddExtraTeam = FrenchRP.createJob

local function removeCustomItem(tbl, category, hookName, reloadF4, i)
    local item = tbl[i]
    tbl[i] = nil
    if category then FrenchRP.removeFromCategory(item, category) end
    if istable(item) and (item.command or item.cmd) then FrenchRP.removeChatCommand(item.command or item.cmd) end
    hook.Run(hookName, i, item)
    if CLIENT and reloadF4 and IsValid(FrenchRP.getF4MenuPanel()) then FrenchRP.getF4MenuPanel():Remove() end -- Rebuild entire F4 menu frame
end

function FrenchRP.removeJob(i)
    local job = RPExtraTeams[i]
    jobByCmd[job.command] = nil
    jobCount = jobCount - 1

    FrenchRP.removeChatCommand("vote" .. job.command)
    removeCustomItem(RPExtraTeams, "jobs", "onJobRemoved", true, i)
end

RPExtraTeamDoors = {}
RPExtraTeamDoorIDs = {}
local maxTeamDoorID = 0
function FrenchRP.createEntityGroup(name, ...)
    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["doorgroups"][name] then return end
    RPExtraTeamDoors[name] = {...}
    RPExtraTeamDoors[name].name = name

    maxTeamDoorID = maxTeamDoorID + 1
    RPExtraTeamDoorIDs[name] = maxTeamDoorID
end
AddDoorGroup = FrenchRP.createEntityGroup

FrenchRP.removeEntityGroup = fp{removeCustomItem, RPExtraTeamDoors, nil, "onEntityGroupRemoved", false}

CustomVehicles = {}
CustomShipments = {}
local shipByName = {}
FrenchRP.getShipmentByName = function(name)
    name = string.lower(name or "")

    if not shipByName[name] then return nil, nil end
    return CustomShipments[shipByName[name]], shipByName[name]
end

function FrenchRP.createShipment(name, model, entity, price, Amount_of_guns_in_one_shipment, Sold_separately, price_separately, noshipment, classes, shipmodel, CustomCheck)
    local tableSyntaxUsed = type(model) == "table"

    price = tonumber(price)
    local shipmentmodel = shipmodel or "models/Items/item_item_crate.mdl"

    local customShipment = tableSyntaxUsed and model or
        {model = model, entity = entity, price = price, amount = Amount_of_guns_in_one_shipment,
        seperate = Sold_separately, pricesep = price_separately, noship = noshipment, allowed = classes,
        shipmodel = shipmentmodel, customCheck = CustomCheck, weight = 5}

    -- The pains of backwards compatibility when dealing with ancient spelling errors...
    if customShipment.separate ~= nil then
        customShipment.seperate = customShipment.separate
    end
    customShipment.separate = customShipment.seperate

    if customShipment.allowed == nil then
        customShipment.allowed = {}
        for k,v in pairs(team.GetAllTeams()) do
            table.insert(customShipment.allowed, k)
        end
    end

    customShipment.name = name
    customShipment.default = FrenchRP.DARKRP_LOADING
    customShipment.shipmodel = customShipment.shipmodel or shipmentmodel

    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["shipments"][customShipment.name] then return end

    local valid, err, hints = FrenchRP.validateShipment(customShipment)
    if not valid then FrenchRP.error(string.format("Corrupt shipment: %s!\n%s", name or "", err), 2, hints) end

    customShipment.spawn = customShipment.spawn and fp{FrenchRP.simplerrRun, customShipment.spawn}
    customShipment.allowed = isnumber(customShipment.allowed) and {customShipment.allowed} or customShipment.allowed
    customShipment.customCheck = customShipment.customCheck   and fp{FrenchRP.simplerrRun, customShipment.customCheck}
    customShipment.CustomCheckFailMsg = isfunction(customShipment.CustomCheckFailMsg) and fp{FrenchRP.simplerrRun, customShipment.CustomCheckFailMsg} or customShipment.CustomCheckFailMsg

    if not customShipment.noship then FrenchRP.addToCategory(customShipment, "shipments", customShipment.category) end
    if customShipment.separate then FrenchRP.addToCategory(customShipment, "weapons", customShipment.category) end

    shipByName[string.lower(name or "")] = table.insert(CustomShipments, customShipment)
    util.PrecacheModel(customShipment.model)
end
AddCustomShipment = FrenchRP.createShipment

function FrenchRP.removeShipment(i)
    local ship = CustomShipments[i]
    shipByName[ship.name] = nil
    removeCustomItem(CustomShipments, "shipments", "onShipmentRemoved", true, i)
end

function FrenchRP.createVehicle(Name_of_vehicle, model, price, Jobs_that_can_buy_it, customcheck)
    local vehicle = istable(Name_of_vehicle) and Name_of_vehicle or
        {name = Name_of_vehicle, model = model, price = price, allowed = Jobs_that_can_buy_it, customCheck = customcheck}

    vehicle.default = FrenchRP.DARKRP_LOADING

    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["vehicles"][vehicle.name] then return end

    local found = false
    for k,v in pairs(FrenchRP.getAvailableVehicles()) do
        if string.lower(k) == string.lower(vehicle.name) then found = true break end
    end

    local valid, err, hints = FrenchRP.validateVehicle(vehicle)
    if not valid then FrenchRP.error(string.format("Corrupt vehicle: %s!\n%s", vehicle.name or "", err), 2, hints) end

    if not found then FrenchRP.error("Vehicle invalid: " .. vehicle.name .. ". Unknown vehicle name.", 2) end

    vehicle.customCheck = vehicle.customCheck and fp{FrenchRP.simplerrRun, vehicle.customCheck}
    vehicle.CustomCheckFailMsg = isfunction(vehicle.CustomCheckFailMsg) and fp{FrenchRP.simplerrRun, vehicle.CustomCheckFailMsg} or vehicle.CustomCheckFailMsg

    table.insert(CustomVehicles, vehicle)
    FrenchRP.addToCategory(vehicle, "vehicles", vehicle.category)
end
AddCustomVehicle = FrenchRP.createVehicle

FrenchRP.removeVehicle = fp{removeCustomItem, CustomVehicles, "vehicles", "onVehicleRemoved", true}

/*---------------------------------------------------------------------------
Decides whether a custom job or shipmet or whatever can be used in a certain map
---------------------------------------------------------------------------*/
function GM:CustomObjFitsMap(obj)
    if not obj or not obj.maps then return true end

    local map = string.lower(game.GetMap())
    for k,v in pairs(obj.maps) do
        if string.lower(v) == map then return true end
    end
    return false
end

FrenchRPEntities = {}
function FrenchRP.createEntity(name, entity, model, price, max, command, classes, CustomCheck)
    local tableSyntaxUsed = type(entity) == "table"

    local tblEnt = tableSyntaxUsed and entity or
        {ent = entity, model = model, price = price, max = max,
        cmd = command, allowed = classes, customCheck = CustomCheck}
    tblEnt.name = name
    tblEnt.default = FrenchRP.DARKRP_LOADING

    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["entities"][tblEnt.name] then return end

    if type(tblEnt.allowed) == "number" then
        tblEnt.allowed = {tblEnt.allowed}
    end

    local valid, err, hints = FrenchRP.validateEntity(tblEnt)
    if not valid then FrenchRP.error(string.format("Corrupt entity: %s!\n%s", name or "", err), 2, hints) end

    tblEnt.customCheck = tblEnt.customCheck and fp{FrenchRP.simplerrRun, tblEnt.customCheck}
    tblEnt.CustomCheckFailMsg = isfunction(tblEnt.CustomCheckFailMsg) and fp{FrenchRP.simplerrRun, tblEnt.CustomCheckFailMsg} or tblEnt.CustomCheckFailMsg
    tblEnt.getPrice    = tblEnt.getPrice    and fp{FrenchRP.simplerrRun, tblEnt.getPrice}
    tblEnt.getMax      = tblEnt.getMax      and fp{FrenchRP.simplerrRun, tblEnt.getMax}
    tblEnt.spawn       = tblEnt.spawn       and fp{FrenchRP.simplerrRun, tblEnt.spawn}

    -- if SERVER and FPP then
    --  FPP.AddDefaultBlocked(blockTypes, tblEnt.ent)
    -- end

    table.insert(FrenchRPEntities, tblEnt)
    FrenchRP.addToCategory(tblEnt, "entities", tblEnt.category)
    timer.Simple(0, function() addEntityCommands(tblEnt) end)
end
AddEntity = FrenchRP.createEntity

FrenchRP.removeEntity = fp{removeCustomItem, FrenchRPEntities, "entities", "onEntityRemoved", true}

-- here for backwards compatibility
FrenchRPAgendas = {}

local agendas = {}
-- Returns the agenda managed by the player
plyMeta.getAgenda = fn.Compose{fn.Curry(fn.Flip(fn.GetValue), 2)(FrenchRPAgendas), plyMeta.Team}

-- Returns the agenda this player is member of
function plyMeta:getAgendaTable()
    return agendas[self:Team()]
end

FrenchRP.getAgendas = fp{fn.Id, agendas}

function FrenchRP.createAgenda(Title, Manager, Listeners)
    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["agendas"][Title] then return end

    local agenda = {Manager = Manager, Title = Title, Listeners = Listeners, ManagersByKey = {}}
    agenda.default = FrenchRP.DARKRP_LOADING

    local valid, err, hints = FrenchRP.validateAgenda(agenda)
    if not valid then FrenchRP.error(string.format("Corrupt agenda: %s!\n%s", agenda.Title or "", err), 2, hints) end

    for k,v in pairs(agenda.Listeners) do
        agendas[v] = agenda
    end

    for k,v in pairs(istable(agenda.Manager) and agenda.Manager or {agenda.Manager}) do
        agendas[v] = agenda
        FrenchRPAgendas[v] = agenda -- backwards compat
        agenda.ManagersByKey[v] = true
    end

    if SERVER then
        timer.Simple(0, function()
            -- Run after scripts have loaded
            agenda.text = hook.Run("agendaUpdated", nil, agenda, "")
        end)
    end
end
AddAgenda = FrenchRP.createAgenda

function FrenchRP.removeAgenda(title)
    local agenda
    for k,v in pairs(agendas) do
        if v.Title == title then
            agenda = v
            agendas[k] = nil
        end
    end

    for k,v in pairs(FrenchRPAgendas) do
        if v.Title == title then agendas[k] = nil end
    end
    hook.Run("onAgendaRemoved", title, agenda)
end

GM.FrenchRPGroupChats = {}
local groupChatNumber = 0
function FrenchRP.createGroupChat(funcOrTeam, ...)
    local gm = GM or GAMEMODE
    gm.FrenchRPGroupChats = gm.FrenchRPGroupChats or {}
    if FrenchRP.DARKRP_LOADING then
        groupChatNumber = groupChatNumber + 1
        if FrenchRP.disabledDefaults["groupchat"][groupChatNumber] then return end
    end
    -- People can enter either functions or a list of teams as parameter(s)
    if type(funcOrTeam) == "function" then
        table.insert(gm.FrenchRPGroupChats, fp{FrenchRP.simplerrRun, funcOrTeam})
    else
        local teams = {funcOrTeam, ...}
        table.insert(gm.FrenchRPGroupChats, function(ply) return table.HasValue(teams, ply:Team()) end)
    end
end
GM.AddGroupChat = function(_, ...) FrenchRP.createGroupChat(...) end

FrenchRP.removeGroupChat = fp{removeCustomItem, GM.FrenchRPGroupChats, nil, "onGroupChatRemoved", false}

FrenchRP.getGroupChats = fp{fn.Id, GM.FrenchRPGroupChats}

GM.AmmoTypes = {}

function FrenchRP.createAmmoType(ammoType, name, model, price, amountGiven, customCheck)
    local gm = GM or GAMEMODE
    gm.AmmoTypes = gm.AmmoTypes or {}
    local ammo = istable(name) and name or {
        name = name,
        model = model,
        price = price,
        amountGiven = amountGiven,
        customCheck = customCheck
    }
    ammo.ammoType = ammoType
    ammo.default = FrenchRP.DARKRP_LOADING

    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["ammo"][ammo.name] then return end

    ammo.customCheck = ammo.customCheck and fp{FrenchRP.simplerrRun, ammo.customCheck}
    ammo.CustomCheckFailMsg = isfunction(ammo.CustomCheckFailMsg) and fp{FrenchRP.simplerrRun, ammo.CustomCheckFailMsg} or ammo.CustomCheckFailMsg
    ammo.id = table.insert(gm.AmmoTypes, ammo)

    FrenchRP.addToCategory(ammo, "ammo", ammo.category)
end
GM.AddAmmoType = function(_, ...) FrenchRP.createAmmoType(...) end

FrenchRP.removeAmmoType = fp{removeCustomItem, GM.AmmoTypes, "ammo", "onAmmoTypeRemoved", true}

local demoteGroups = {}
function FrenchRP.createDemoteGroup(name, tbl)
    if FrenchRP.DARKRP_LOADING and FrenchRP.disabledDefaults["demotegroups"][name] then return end
    if not tbl or not tbl[1] then error("No members in the demote group!") end

    local set = demoteGroups[tbl[1]] or disjoint.MakeSet(tbl[1])
    set.name = name
    for i = 2, #tbl do
        set = (demoteGroups[tbl[i]] or disjoint.MakeSet(tbl[i])) + set
        set.name = name
    end

    for _, teamNr in pairs(tbl) do
        if demoteGroups[teamNr] then
            -- Unify the sets if there was already one there
            demoteGroups[teamNr] = demoteGroups[teamNr] + set
        else
            demoteGroups[teamNr] = set
        end
    end
end

function FrenchRP.removeDemoteGroup(name)
    local foundSet
    for k,v in pairs(demoteGroups) do
        local set = disjoint.FindSet(v)
        if set.name == name then
            foundSet = set
            demoteGroups[k] = nil
        end
    end
    hook.Run("onDemoteGroupRemoved", name, foundSet)
end

function FrenchRP.getDemoteGroup(teamNr)
    demoteGroups[teamNr] = demoteGroups[teamNr] or disjoint.MakeSet(teamNr)
    return disjoint.FindSet(demoteGroups[teamNr])
end

FrenchRP.getDemoteGroups = fp{fn.Id, demoteGroups}

local categories = {
    jobs = {},
    entities = {},
    shipments = {},
    weapons = {},
    vehicles = {},
    ammo = {},
}
local categoriesMerged = false -- whether categories and custom items are merged.

FrenchRP.getCategories = fp{fn.Id, categories}

local categoryOrder = function(a, b)
    local aso = a.sortOrder or 100
    local bso = b.sortOrder or 100
    return aso < bso or aso == bso and a.name < b.name
end

local function insertCategory(destination, tbl)
    -- Override existing category of applicable
    for k, cat in pairs(destination) do
        if cat.name ~= tbl.name then continue end

        destination[k] = tbl
        tbl.members = cat.members
        return
    end

    table.insert(destination, tbl)
    local i = #destination

    while i > 1 do
        if categoryOrder(destination[i - 1], tbl) then break end
        destination[i - 1], destination[i] = destination[i], destination[i - 1]
        i = i - 1
    end
end

function FrenchRP.createCategory(tbl)
    local valid, err, hints = FrenchRP.validateCategory(tbl)
    if not valid then FrenchRP.error(string.format("Corrupt category: %s!\n%s", tbl.name or "", err), 2, hints) end
    tbl.members = {}

    local destination = categories[tbl.categorises]
    insertCategory(destination, tbl)

    -- Too many people made the mistake of not creating a category for weapons as well as shipments
    -- when having shipments that can also be sold separately.
    if tbl.categorises == "shipments" then
        insertCategory(categories.weapons, table.Copy(tbl))
    end
end

function FrenchRP.addToCategory(item, kind, cat)
    cat = cat or "Other"
    item.category = cat

    -- The merge process will take care of the category:
    if not categoriesMerged then return end

    -- Post-merge: manual insertion into category
    local cats = categories[kind]
    for _, c in ipairs(cats) do
        if c.name ~= cat then continue end

        insertCategory(c.members, item)
        return
    end

    FrenchRP.errorNoHalt(string.format([[The category of "%s" ("%s") does not exist!]], item.name, cat), 2, {
        "Make sure the category is created with FrenchRP.createCategory.",
        "The category name is case sensitive!",
        "Categories must be created before FrenchRP finished loading.",
    })
end

function FrenchRP.removeFromCategory(item, kind)
    local cats = categories[kind]
    if not cats then FrenchRP.error(string.format("Invalid category kind '%s'.", kind), 2) end
    local cat = item.category
    if not cat then return end
    for _, v in pairs(cats) do
        if v.name ~= item.category then continue end
        for k, mem in pairs(v.members) do
            if mem ~= item then continue end
            table.remove(v.members, k)
            break
        end
        break
    end
end

-- Assign custom stuff to their categories
local function mergeCategories(customs, catKind, path)
    local cats = categories[catKind]
    local catByName = {}
    for k,v in pairs(cats) do catByName[v.name] = v end
    for k,v in pairs(customs) do
        -- Override default thing categories:
        local catName = v.default and GAMEMODE.Config.CategoryOverride[catKind][v.name] or v.category or "Other"
        local cat = catByName[catName]
        if not cat then
            FrenchRP.errorNoHalt(string.format([[The category of "%s" ("%s") does not exist!]], v.name, catName), 3, {
                "Make sure the category is created with FrenchRP.createCategory.",
                "The category name is case sensitive!",
                "Categories must be created before FrenchRP finished loading."
            }, path, -1, path)
            cat = catByName.Other
        end

        cat.members = cat.members or {}
        table.insert(cat.members, v)
    end

    -- Sort category members
    for k,v in pairs(cats) do table.sort(v.members, categoryOrder) end
end

hook.Add("loadCustomFrenchRPItems", "mergeCategories", function()
    local shipments = fn.Filter(fc{fn.Not, fp{fn.GetValue, "noship"}}, CustomShipments)
    local guns = fn.Filter(fp{fn.GetValue, "separate"}, CustomShipments)

    mergeCategories(RPExtraTeams, "jobs", "your jobs")
    mergeCategories(FrenchRPEntities, "entities", "your custom entities")
    mergeCategories(shipments, "shipments", "your custom shipments")
    mergeCategories(guns, "weapons", "your custom weapons")
    mergeCategories(CustomVehicles, "vehicles", "your custom vehicles")
    mergeCategories(GAMEMODE.AmmoTypes, "ammo", "your custom ammo")

    categoriesMerged = true
end)
