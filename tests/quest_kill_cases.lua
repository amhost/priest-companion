return function(T, ns)
    local Quests, Kills = ns.Models.Quests, ns.Models.Kills
    T.ok(Quests and Kills, "quest and kill models are exported")

    local objectives, available = Quests.CopyObjectives({
        { text = "Wolves: 2/4", type = "monster", finished = false, numFulfilled = 2, numRequired = 4 },
        { text = "Talk to the guard", type = "event", finished = true },
    })
    T.eq(#objectives, 2, "all readable objectives copied")
    T.eq(objectives[1].fulfilled, 2, "numeric progress copied")
    T.eq(objectives[2].finished, true, "completed objective retained")
    T.eq(available, true, "complete objective snapshot")
    local quest = Quests.CopyQuest({ questID = 33, title = "Wolves", level = 4 }, 2, {}, false)
    T.eq(quest.id, 33, "quest ID copied")
    T.eq(quest.complete, false, "incomplete distinguished from unavailable")
    T.eq(Quests.CopyQuest({ questID = 33, isHeader = true }, 1, {}, false), nil, "headers excluded")
    T.eq(Quests.CopyQuest({ questID = 33, isHidden = true }, 1, {}, false), nil, "hidden entries excluded")
    T.eq(Quests.CopyQuest({ questID = -2 }, 1, {}, false), nil, "invalid IDs excluded")
    T.eq(Quests.CopyQuest({ questID = 1.5 }, 1, {}, false), nil, "fractional IDs excluded")
    local incomplete = Quests.CopyQuest({ questID = 33, title = "Wolves" }, 2, nil, nil)
    T.eq(incomplete.objectivesAvailable, false, "missing data is not an empty completed quest")
    T.eq(incomplete.complete, nil, "unknown completion remains unknown")
    T.ok(Quests.ObjectiveText(incomplete):find("unavailable", 1, true), "unavailable objective text visible")
    T.eq(Quests.Waypoint(37, 0.2, 0.8).x, 0.2, "valid waypoint accepted")
    T.eq(Quests.Waypoint(37, 1.01, 0.8), nil, "invalid coordinate rejected")
    T.eq(Quests.Waypoint(37, 0/0, 0.8), nil, "NaN coordinate rejected")
    T.eq(Quests.Waypoint(0, 0.2, 0.8), nil, "invalid map rejected")
    local point = Quests.FindWaypoint({ { questID = 2, mapID = 37, x = 0.1, y = 0.2 },
        { questID = 33, mapID = 37, x = 0.3, y = 0.4 } }, 33)
    T.eq(point.x, 0.3, "waypoint is associated with the selected quest")
    T.eq(Quests.FindWaypoint({ { questID = 33, x = 0.3, y = 0.4 } }, 33), nil, "map ID is never guessed")
    T.eq(Quests.FindWaypoint({ { questID = 33, x = 0.3, y = 0.4 } }, 33, 37).mapID, 37,
        "map-scoped response uses the known query map when no row map is present")
    local emptyLog, emptyStatus = Quests.ReadLog({ GetNumQuestLogEntries = function() return 0 end,
        GetInfo = function() return nil end })
    T.eq(#emptyLog, 0, "empty live log")
    T.ok(emptyStatus:find("No visible quests", 1, true), "empty log reports emptiness")
    local failedLog, failedStatus = Quests.ReadLog({ GetNumQuestLogEntries = function() return 3 end,
        GetInfo = function() return nil end })
    T.eq(#failedLog, 0, "failed live reads produce no invented quests")
    T.ok(failedStatus:find("unavailable", 1, true), "failed reads are distinguished from empty log")

    local function acceptanceAPI()
        local calls = { count = 0 }
        local api = {
            AcceptQuest = function() calls.count = calls.count + 1 end,
            GetQuestID = function() return 33 end,
            IsShiftKeyDown = function() return false end,
            InCombatLockdown = function() return false end,
            UnitExists = function(unit) calls.giver = unit; return true end,
            UnitIsPlayer = function(unit) calls.checkedPlayer = unit; return false end,
            QuestGetAutoAccept = function() return false end,
            QuestFlagsPVP = function() return false end,
            QuestIsFromAdventureMap = function() return false end,
            QuestIsFromAreaTrigger = function() return false end,
        }
        return api, calls
    end
    local acceptAPI, acceptCalls = acceptanceAPI()
    T.ok(Quests.AutoAcceptCapable(acceptAPI), "ordinary acceptance API recognized")
    T.eq(Quests.TryAutoAccept({}, nil, acceptAPI, "QUEST_DETAIL", 0), false,
        "missing opt-in leaves acceptance off")
    T.eq(Quests.TryAutoAccept({}, false, acceptAPI, "QUEST_DETAIL", 0), false,
        "explicit off never accepts")
    for _, event in ipairs({ "GOSSIP_SHOW", "QUEST_GREETING", "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_ACCEPT_CONFIRM" }) do
        T.eq(Quests.TryAutoAccept({}, true, acceptAPI, event, 0), false,
            "only QUEST_DETAIL can accept: " .. event)
    end
    T.eq(acceptCalls.count, 0, "disabled and unrelated events make no acceptance call")
    local offerState = {}
    local sent, acceptStatus = Quests.TryAutoAccept(offerState, true, acceptAPI, "QUEST_DETAIL", 0)
    T.eq(sent, true, "ordinary readable NPC offer requests acceptance")
    T.eq(acceptStatus, "requested", "call success is not claimed as server acceptance")
    T.eq(acceptCalls.count, 1, "exactly one acceptance request")
    T.eq(acceptCalls.giver, "questnpc", "giver check uses native quest frame unit")
    T.eq(acceptCalls.checkedPlayer, "questnpc", "player giver excluded on same unit token")
    T.eq(Quests.TryAutoAccept(offerState, true, acceptAPI, "QUEST_DETAIL", 0), false,
        "duplicate quest detail never repeats acceptance")
    T.eq(acceptCalls.count, 1, "duplicate request not sent")
    acceptAPI.GetQuestID = function() return 34 end
    T.eq(Quests.TryAutoAccept(offerState, true, acceptAPI, "QUEST_DETAIL", nil), true,
        "different ordinary offer can be accepted")

    for _, guard in ipairs({ "IsShiftKeyDown", "InCombatLockdown" }) do
        local guardedAPI, calls = acceptanceAPI()
        local state = {}
        guardedAPI[guard] = function() return true end
        T.eq(Quests.TryAutoAccept(state, true, guardedAPI, "QUEST_DETAIL", 0), false, guard .. " bypasses")
        guardedAPI[guard] = function() return false end
        T.eq(Quests.TryAutoAccept(state, true, guardedAPI, "QUEST_DETAIL", 0), false,
            guard .. " bypass stays manual for repeated offer")
        T.eq(calls.count, 0, guard .. " never queues a later acceptance")
        T.eq(Quests.TryAutoAccept({}, true, guardedAPI, "QUEST_DETAIL", 0), true,
            "fresh offer can proceed after " .. guard)
    end
    for _, special in ipairs({ "QuestGetAutoAccept", "QuestFlagsPVP", "QuestIsFromAdventureMap", "QuestIsFromAreaTrigger" }) do
        local guardedAPI, calls = acceptanceAPI()
        guardedAPI[special] = function() return true end
        local result, reason = Quests.TryAutoAccept({}, true, guardedAPI, "QUEST_DETAIL", 0)
        T.eq(result, false, "special flow stays manual: " .. special)
        T.eq(reason, "special", "special flow identified: " .. special)
        T.eq(calls.count, 0, "no action for " .. special)
    end
    local itemAPI, itemCalls = acceptanceAPI()
    T.eq(Quests.TryAutoAccept({}, true, itemAPI, "QUEST_DETAIL", 123), false, "item-started offer stays manual")
    T.eq(itemCalls.count, 0, "item offer not accepted")
    local sharedAPI, sharedCalls = acceptanceAPI()
    sharedAPI.UnitIsPlayer = function() return true end
    T.eq(Quests.TryAutoAccept({}, true, sharedAPI, "QUEST_DETAIL", 0), false, "player-shared giver stays manual")
    sharedAPI.UnitIsPlayer = function() return false end
    sharedAPI.UnitExists = function() return false end
    T.eq(Quests.TryAutoAccept({}, true, sharedAPI, "QUEST_DETAIL", 0), false, "absent giver stays manual")
    T.eq(sharedCalls.count, 0, "shared and unknown giver cause no acceptance")
    local missingAPI, missingCalls = acceptanceAPI()
    missingAPI.AcceptQuest = nil
    T.eq(Quests.AutoAcceptCapable(missingAPI), false, "missing acceptance function disables capability")
    T.eq(Quests.TryAutoAccept({}, true, missingAPI, "QUEST_DETAIL", 0), false, "missing API does not error")
    T.eq(missingCalls.count, 0, "missing API makes no request")
    local failedAPI, failedCalls = acceptanceAPI()
    failedAPI.AcceptQuest = function() failedCalls.count = failedCalls.count + 1; error("client rejected") end
    local failedState = {}
    local accepted, failure = Quests.TryAutoAccept(failedState, true, failedAPI, "QUEST_DETAIL", 0)
    T.eq(accepted, false, "client rejection fails closed")
    T.eq(failure, "failed", "client rejection remains visible")
    T.eq(Quests.TryAutoAccept(failedState, true, failedAPI, "QUEST_DETAIL", 0), false,
        "rejected request never retried on duplicate event")
    T.eq(failedCalls.count, 1, "single failed request only")
    local unknownAPI, unknownCalls = acceptanceAPI()
    unknownAPI.IsShiftKeyDown = function() return nil end
    T.eq(Quests.TryAutoAccept({}, true, unknownAPI, "QUEST_DETAIL", 0), false,
        "unknown Shift state cannot waive bypass")
    T.eq(unknownCalls.count, 0, "unavailable bypass data makes no request")

    -- Exercise the registered event and checkbox with reversible injected APIs.
    local questModule = ns.modules and ns.modules.quests
    if ns.db and questModule and questModule.autoAccept then
        local globals, original = acceptanceAPI(), {}
        local liveCalls = 0
        globals.AcceptQuest = function() liveCalls = liveCalls + 1 end
        for name, fn in pairs(globals) do original[name] = { value = _G[name] }; _G[name] = fn end
        local db = ns.ModuleDB("quests", {})
        local oldPreference = db.autoAccept
        local function fire(event, ...)
            for _, callback in ipairs(ns.events[event] or {}) do callback(event, ...) end
        end
        local success, failureMessage = pcall(function()
            T.eq(db.autoAccept, false, "new installation defaults auto-accept off")
            fire("QUEST_DETAIL", 0)
            T.eq(liveCalls, 0, "real event handler respects default off")
            questModule:Refresh()
            T.eq(questModule.autoAccept:GetChecked(), false, "toggle reflects off setting")
            questModule.autoAccept:Click()
            T.eq(db.autoAccept, true, "checkbox persists explicit opt-in")
            fire("QUEST_DETAIL", 0)
            T.eq(liveCalls, 1, "registered event accepts after opt-in")
            fire("QUEST_DETAIL", 0)
            T.eq(liveCalls, 1, "registered event ignores repeated offer")
            fire("QUEST_FINISHED")
            globals.IsShiftKeyDown = function() return true end
            _G.IsShiftKeyDown = globals.IsShiftKeyDown
            fire("QUEST_DETAIL", 0)
            _G.IsShiftKeyDown = function() return false end
            fire("QUEST_DETAIL", 0)
            T.eq(liveCalls, 1, "Shift bypass persists until offer closes")
            fire("QUEST_FINISHED")
            local shown = questModule.frame:IsShown()
            questModule.frame:Hide()
            fire("QUEST_DETAIL", 0)
            T.eq(liveCalls, 2, "enabled preference works while quest panel hidden")
            if shown then questModule.frame:Show() end
            questModule:Refresh()
            questModule.autoAccept:Click()
            T.eq(db.autoAccept, false, "checkbox disables auto-accept again")
        end)
        for name, value in pairs(original) do _G[name] = value.value end
        db.autoAccept = oldPreference
        fire("QUEST_FINISHED")
        questModule:Refresh()
        if not success then error(failureMessage) end
    end

    local normalName = "COMBATLOG_XPGAIN_FIRSTPERSON"
    local normal = Kills.CompileTemplate(normalName, "%s dies, you gain %d experience.")
    T.ok(normal, "normal kill template compiles")
    local record = Kills.MatchMessage("Forest Wolf dies, you gain 60 experience.", { normal })
    T.eq(record.label, "Forest Wolf", "creature label parsed")
    T.eq(record.xp, 60, "kill XP parsed")
    T.eq(Kills.MatchMessage("You gain 60 experience.", { normal }), nil, "unnamed XP cannot count as a kill")
    T.eq(Kills.MatchMessage("Forest Wolf dies, you gain 0 experience.", { normal }), nil, "zero XP does not count")
    T.eq(Kills.MatchMessage("Forest Wolf dies, you gain 60 experience. extra", { normal }), nil, "matching is anchored")
    T.eq(Kills.CompileTemplate("COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED", "You gain %d experience."), nil,
        "unnamed template name is explicitly unsupported")
    T.eq(Kills.CompileTemplate("UNKNOWN_KILL_FORMAT", "%s dies, %d XP"), nil, "unknown template refused")
    T.eq(Kills.CompileTemplate(normalName, "%s %f"), nil, "unsupported numeric format refused")
    T.eq(Kills.CompileTemplate(normalName, "%1$s %d"), nil, "mixed positional formats refused")
    T.eq(Kills.CompileTemplate(normalName, "%2$s %1$d"), nil, "semantic argument kinds required")
    T.eq(Kills.CompileTemplate(normalName, "%s %d %"), nil, "trailing percent refused")
    T.eq(Kills.CompileTemplate(normalName, "%s %02d"), nil, "unimplemented width syntax refused")

    local positional = Kills.CompileTemplate(normalName, "%2$d XP from %1$s.")
    local reversed = Kills.MatchMessage("120 XP from Boar.", { positional })
    T.eq(reversed.label, "Boar", "positional creature capture")
    T.eq(reversed.xp, 120, "positional numeric capture")
    local escaped = Kills.CompileTemplate(normalName, "[%s] dies. +%d XP (100%%): ^$?*-")
    T.ok(escaped, "literal pattern metacharacters and percent compile")
    local escapeMatch = Kills.MatchMessage("[Boar] dies. +45 XP (100%): ^$?*-", { escaped })
    T.eq(escapeMatch.xp, 45, "literal special characters matched exactly")
    T.eq(Kills.MatchMessage("[Boar] diesX +45 XP (100%): ^$?*-", { escaped }), nil,
        "literal dot is not a wildcard")

    local group = Kills.CompileTemplate("COMBATLOG_XPGAIN_FIRSTPERSON_GROUP", "%s dies, you gain %d experience. (+%d group bonus)")
    local groupRecord = Kills.MatchMessage("Boar dies, you gain 55 experience. (+5 group bonus)", { group })
    T.eq(groupRecord.xp, 55, "group bonus is not added twice")
    local rested = Kills.CompileTemplate("COMBATLOG_XPGAIN_EXHAUSTION1", "%s dies, you gain %d experience. (%s exp %s bonus)")
    local restedRecord = Kills.MatchMessage("Boar dies, you gain 100 experience. (50 exp rested bonus)", { rested })
    T.eq(restedRecord.xp, 100, "rested amount is the reported total")
    local repeated = Kills.CompileTemplate(normalName, "%1$s %2$d %1$s")
    T.ok(Kills.MatchMessage("Boar 50 Boar", { repeated }), "consistent repeated positional argument")
    T.eq(Kills.MatchMessage("Boar 50 Wolf", { repeated }), nil, "inconsistent repeated argument refused")

    local patterns = Kills.BuildPatterns({ [normalName] = "%s dies, you gain %d experience.",
        COMBATLOG_XPGAIN_FIRSTPERSON_UNNAMED = "You gain %d experience.", UNKNOWN = "%s %d" })
    T.eq(#patterns, 1, "only supported available templates compiled")
    local stats = Kills.NewStats()
    T.ok(Kills.AddAutomatic(stats, record), "automatic record accepted")
    T.ok(Kills.AddAutomatic(stats, record), "identical later kill counted again")
    T.eq(stats.automatic, 2, "identical text is never deduplicated")
    T.eq(stats.xp, 120, "automatic XP accumulates")
    T.eq(stats.manual, 0, "automatic kills do not inflate manual totals")
    T.ok(Kills.AddManual(stats, "Skeletons", "North road"), "manual labeled record accepted")
    T.eq(stats.manual, 1, "manual counter independent")
    T.eq(stats.automatic, 2, "manual entries do not inflate automatic totals")
    T.eq(stats.targets.Skeletons.note, "North road", "manual notes preserved")
    T.eq(Kills.AddManual(stats, "   ", ""), false, "blank manual label refused")
    T.eq(Kills.AddAutomatic(stats, { label = "Boar", xp = math.huge }), false, "nonfinite XP refused")
    local freshSession = Kills.NewStats()
    T.eq(freshSession.automatic, 0, "new session empty")
    T.eq(stats.automatic, 2, "new session leaves lifetime untouched")
    local rows = Kills.Rows(stats, freshSession)
    T.eq(rows[1].label, "Forest Wolf", "target history sorted by total count")
    T.eq(rows[1].sessionAutomatic, 0, "fresh session no inherited counts")
    local repaired = Kills.NormalizeStats({ automatic = -4, manual = "bad", xp = math.huge,
        targets = { Boar = { automatic = 2, manual = -3, note = "ok" } } })
    T.eq(repaired.automatic, 0, "negative saved count repaired")
    T.eq(repaired.manual, 0, "invalid saved count repaired")
    T.eq(repaired.xp, 0, "nonfinite saved XP repaired")
    T.eq(repaired.targets.Boar.automatic, 2, "valid saved target survives")

    local secret = {}
    local oldReadable = ns.Readable
    ns.Readable = function(value) return value ~= secret and oldReadable(value) end
    local ok, err = pcall(function()
        local missing, reason = Kills.MatchMessage(secret, { normal })
        T.eq(missing, nil, "secret XP message never parsed")
        T.eq(reason, "restricted", "restriction distinguished from unmatched data")
        T.eq(Kills.CompileTemplate(normalName, secret), nil, "secret template refused")
        T.eq(Quests.CopyQuest({ questID = secret, title = "hidden" }, 1, {}, false), nil,
            "secret quest ID never used")
        T.eq(Quests.Waypoint(37, secret, 0.4), nil, "secret coordinate never compared")
        local guarded = Quests.CopyQuest({ questID = 33, title = secret }, 1,
            { { text = secret, finished = secret } }, secret)
        T.eq(guarded.title, "Quest 33", "secret quest title replaced")
        T.eq(guarded.objectives[1].text, "Objective details unavailable", "secret objective text replaced")
        T.eq(guarded.complete, nil, "secret completion not interpreted")
        local secretAPI, calls = acceptanceAPI()
        T.eq(Quests.TryAutoAccept({}, secret, secretAPI, "QUEST_DETAIL", 0), false,
            "secret opt-in cannot enable acceptance")
        T.eq(Quests.TryAutoAccept({}, true, secretAPI, secret, 0), false, "secret event is not compared")
        T.eq(Quests.TryAutoAccept({}, true, secretAPI, "QUEST_DETAIL", secret), false,
            "secret item-offer payload is not compared")
        for _, field in ipairs({ "GetQuestID", "IsShiftKeyDown", "InCombatLockdown", "UnitExists", "UnitIsPlayer",
            "QuestGetAutoAccept", "QuestFlagsPVP", "QuestIsFromAdventureMap", "QuestIsFromAreaTrigger" }) do
            local secretResultAPI = acceptanceAPI()
            secretResultAPI[field] = function() return secret end
            T.eq(Quests.TryAutoAccept({}, true, secretResultAPI, "QUEST_DETAIL", 0), false,
                "secret acceptance guard fails closed: " .. field)
        end
        T.eq(calls.count, 0, "secret inputs never send an acceptance request")
    end)
    ns.Readable = oldReadable
    if not ok then error(err) end
end
