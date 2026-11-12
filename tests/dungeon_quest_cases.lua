-- Synthetic state fixtures. No fixture invents a runtime quest record.
return function(T, ns, Mock)
    local M, catalog = ns.Models.DungeonQuests, ns.DungeonQuestCatalog
    local function snapshot(overrides, faction, level)
        local api = {
            GetTitleForQuestID = function(id) return "Client title " .. id end,
            IsOnQuest = function() return false end,
            IsQuestFlaggedCompleted = function() return false end,
            IsQuestFlaggedCompletedOnAccount = function() error("Account API must not be used") end,
            IsComplete = function() return false end,
        }
        for key, value in pairs(overrides or {}) do api[key] = value end
        return M.Snapshot(api, faction or "Alliance", level or 20)
    end
    local function fixture()
        return { id = 999001, title = "Synthetic quest", faction = "Alliance", minLevel = 10,
            requirementsComplete = true, prerequisites = { all = {}, complete = true } }
    end
    local q = fixture()
    T.eq(M.Evaluate(q, snapshot()).status, "Missing", "resolved ID absent from log and history")
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Meets catalog rules", "explicit known empty prerequisites")
    T.eq(M.Evaluate(q, snapshot({ IsOnQuest = function() return true end })).status, "In Log", "accepted quest")
    local ready = M.Evaluate(q, snapshot({ IsOnQuest = function() return true end, IsComplete = function() return true end }))
    T.eq(ready.status, "In Log", "ready to turn in is not completed history")
    T.eq(ready.ready, true, "ready to turn in annotation")
    T.eq(M.Evaluate(q, snapshot({ IsQuestFlaggedCompleted = function() return true end })).status, "Completed", "character completion")
    T.eq(M.Evaluate(q, snapshot({ IsOnQuest = function() return true end,
        IsQuestFlaggedCompleted = function() return true end })).status, "In Log", "active repeat beats historical completion")
    -- Every tri-state log/completion combination, with and without a title.
    local states = {false, true, "unknown"}
    for _, log in ipairs(states) do
        for _, completed in ipairs(states) do
            for _, titled in ipairs({false, true}) do
                local api = {
                    IsOnQuest = function() if log ~= "unknown" then return log end end,
                    IsQuestFlaggedCompleted = function() if completed ~= "unknown" then return completed end end,
                    GetTitleForQuestID = function() if titled then return "Quest" end end,
                }
                local expected = log == true and "In Log" or completed == true and "Completed"
                    or (log == false and completed == false and titled and "Missing") or "Unknown"
                T.eq(M.Evaluate(q, M.Snapshot(api, "Alliance", 20)).status, expected, "tri-state progress truth table")
            end
        end
    end
    for _, title in ipairs({"", "   ", "|cffffffff|r", 123, Mock.Secret()}) do
        T.eq(M.Evaluate(q, snapshot({GetTitleForQuestID = function() return title end})).status, "Unknown",
            "invalid/missing title cannot establish valid negative status")
    end
    for _, name in ipairs({"IsOnQuest", "IsQuestFlaggedCompleted"}) do
        for _, value in ipairs({Mock.Secret(), 0, "false"}) do
            T.eq(M.Evaluate(q, snapshot({[name] = function() return value end})).status, "Unknown",
                "non-boolean progress never coerced")
        end
        T.eq(M.Evaluate(q, snapshot({[name] = function() error("unsupported") end})).status, "Unknown", "failed API unknown")
        T.eq(M.Evaluate(q, snapshot({[name] = false})).status, "Unknown", "missing function unknown")
    end
    T.eq(M.Evaluate(q, M.Snapshot(nil)).status, "Unknown", "absent namespace")
    T.eq(M.Evaluate(q, M.Snapshot(Mock.Secret())).status, "Unknown", "restricted namespace not indexed")
    T.eq(M.Evaluate(q, snapshot({IsOnQuest = false, GetLogIndexForQuestID = function() return 2 end})).status, "In Log", "positive index fallback")
    T.eq(M.Evaluate(q, snapshot({IsOnQuest = false, GetLogIndexForQuestID = function() return 0 end})).status, "Unknown", "index zero not proof of absence")
    T.eq(M.Evaluate(q, snapshot({IsOnQuest = false, GetLogIndexForQuestID = function() return nil end})).status, "Unknown", "nil index not proof of absence")
    local calls = 0
    local cached = snapshot({IsOnQuest = function() calls = calls + 1; return false end})
    cached.read(q.id); cached.read(q.id)
    T.eq(calls, 1, "one read per ID per snapshot")
    for _, id in ipairs({0, -1, 1.5, math.huge, 0/0, Mock.Secret(), "123"}) do cached.read(id) end
    T.eq(calls, 1, "invalid IDs never query client")
    T.eq(M.Evaluate(q, snapshot(nil, "Horde")).eligibility, "Blocked (catalog)", "faction filter remains explicit")
    T.eq(M.Evaluate(q, snapshot(nil, "Alliance", 9)).eligibility, "Blocked (catalog)", "level below minimum")
    T.eq(M.Evaluate(q, snapshot(nil, "Alliance", 10)).eligibility, "Meets catalog rules", "level boundary")
    T.eq(M.Evaluate(q, snapshot(nil, "Neutral")).eligibility, "Unknown", "unknown player faction")
    T.eq(M.Evaluate(q, snapshot(nil, "Alliance", Mock.Secret())).eligibility, "Unknown", "restricted player level")
    q.faction = nil
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "missing faction is not unrestricted")
    q = fixture(); q.minLevel = nil
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "missing minimum is not zero")
    q = fixture(); q.prerequisites = nil
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "absent prerequisites not no prerequisites")
    q = fixture(); q.prerequisites = {complete = true}
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "unspecified groups not empty all")
    q = fixture(); q.requirementsComplete = false
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "additional class/race/reputation/item/exclusive gates unknown")

    local completions = {}
    local function prereqSnapshot()
        return snapshot({ IsQuestFlaggedCompleted = function(id) return completions[id] end })
    end
    q = fixture(); q.prerequisites.all = {999002, 999003}
    completions = {[999002] = true, [999003] = false}
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Blocked (catalog)", "all requires every completion")
    completions[999003] = nil
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Unknown", "all unknown not missing")
    completions[999003] = true
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Meets catalog rules", "all satisfied")
    q.prerequisites = {any = {999002, 999003}, complete = true}
    completions = {[999002] = true}
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Meets catalog rules", "any true beats unknown")
    completions = {[999002] = false, [999003] = false}
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Blocked (catalog)", "all alternatives false")
    completions[999003] = nil
    T.eq(M.Evaluate(q, prereqSnapshot()).eligibility, "Unknown", "any false plus unknown stays unknown")
    q.prerequisites = {all = {999002}, complete = true}
    T.eq(M.Evaluate(q, snapshot({GetTitleForQuestID = function() return nil end})).eligibility, "Unknown",
        "unresolved prerequisite ID false is not proof of unmet prerequisite")
    T.eq(M.Evaluate(q, snapshot({IsOnQuest = function() return true end})).eligibility, "Blocked (catalog)",
        "in-log prerequisite is not turned in")
    q.prerequisites = {all = {q.id}, complete = true}
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Blocked (catalog)", "self-reference never recursively traversed")
    q.prerequisites = {all = {0}, complete = true}
    T.eq(M.Evaluate(q, snapshot()).eligibility, "Unknown", "invalid prerequisite unknown")
    q = fixture(); q.reportedPrior = {999002}; q.prerequisites = nil
    local advisory = M.Evaluate(q, snapshot())
    T.eq(advisory.eligibility, "Unknown", "reported predecessor not assumed mandatory")
    T.ok(advisory.prior:find("Relationship unverified", 1, true), "advisory relationship visible")
    T.eq(M.Build({quests = {}}, snapshot()).counts.Missing, 0, "empty catalog counts")
    T.ok(M.Build({quests = {}}, snapshot()).coverage:find("coverage unknown", 1, true), "empty is not all done")

    local total, seen = 0, {}
    for _, dungeon in ipairs(catalog.dungeons) do
        T.eq(dungeon.coverage, "partial", "no exhaustive catalog claims")
        T.eq(dungeon.source.license, "MIT", "per-dungeon license recorded")
        T.eq(dungeon.source.verification, "provisional", "no live-verified seed data")
        T.eq(#dungeon.source.revision, 40, "pinned provenance")
        for _, record in ipairs(dungeon.quests) do
            total = total + 1
            T.ok(M.PositiveID(record.id) and not seen[record.id], "unique real catalog IDs")
            seen[record.id] = true
            T.eq(record.requirementsComplete, false, "source omissions remain unknown")
            T.eq(record.prerequisites, nil, "unreviewed sourceQuest is advisory")
        end
        local built = M.Build(dungeon, snapshot({IsQuestFlaggedCompleted = function() return true end}))
        T.ok(built.coverage:find("other quests may exist", 1, true), "all completed still partial")
        T.ok(#M.QueryIDs(dungeon) <= 64, "client requests bounded")
    end
    T.eq(total, 18, "small reviewed seed size")
    T.eq(#M.QueryIDs(catalog.dungeons[1]), 12, "IDs deduplicate in-catalog predecessors")
    T.ok(catalog.dungeons[1].quests[7].pickup:find("not a pre-entry pickup", 1, true), "drop quest not pre-run task")

    -- Actual new module, real event routing and bounded UI/API doubles.
    local module = ns.modules.dungeons
    T.eq(ns.PanelSettings("dungeons").shown, false, "new panel opt-in")
    local originalAPI, originalFaction = C_QuestLog, UnitFactionGroup
    local originalSelection = ns.db.modules.dungeons.selected
    local checklist = ns.Copy(ns.db.modules.prep.checklist)
    local autoAccept = ns.db.modules.quests.autoAccept
    local observed, titles, requests, apiCalls = {}, {}, {}, 0
    C_QuestLog = {
        IsOnQuest = function(id) apiCalls = apiCalls + 1; return observed[id] == "log" end,
        IsQuestFlaggedCompleted = function(id) return observed[id] == "done" end,
        IsComplete = function() return true end,
        GetTitleForQuestID = function(id) return titles[id] end,
        RequestLoadQuestByID = function(id)
            requests[id] = (requests[id] or 0) + 1
            -- Synchronous failure must settle without a retry loop.
            Mock.Trigger(ns.eventFrame, "OnEvent", "QUEST_DATA_LOAD_RESULT", id, false)
        end,
    }
    UnitFactionGroup = function() return "Alliance" end
    ns.RunCommand("dungeons deadmines"); Mock.Flush()
    T.eq(#module.result.rows, 8, "selection renders actual Deadmines catalog")
    T.eq(module.result.counts.Unknown, 8, "unresolved IDs not classified missing")
    T.eq(requests[168], 1, "asynchronous load requested once")
    T.eq(requests[155], 1, "reported prerequisite titles loaded too")
    Mock.Fire("QUEST_LOG_UPDATE")
    T.eq(requests[168], 1, "event storms do not retry failed loads")
    module.refresh:Click(); Mock.Flush()
    T.eq(requests[168], 2, "explicit refresh retries failed data request")
    Mock.Fire("QUEST_DATA_LOAD_RESULT", Mock.Secret(), true)
    T.eq(requests[168], 2, "restricted event ID ignored")
    local requestsBeforeHide = apiCalls
    ns.SetPanelVisible("dungeons", false); Mock.Flush(); Mock.Fire("QUEST_LOG_UPDATE")
    T.eq(apiCalls, requestsBeforeHide, "hidden panel does no progress reads")
    ns.SetPanelVisible("dungeons", true); Mock.Flush()
    for _, id in ipairs(M.QueryIDs(catalog.dungeons[1])) do titles[id] = "Localized title " .. id end
    Mock.Fire("QUEST_DATA_LOAD_RESULT", 168, true)
    T.eq(module.result.counts.Missing, 8, "late title result updates statuses")
    T.ok(module.rows[1]:GetText():find("Localized title 168", 1, true), "client title displayed")
    observed[168] = "log"; Mock.Fire("QUEST_ACCEPTED", 168)
    T.eq(module.result.rows[1].status, "In Log", "accept event updates list")
    T.ok(module.rows[1]:GetText():find("Ready to turn in", 1, true), "ready stays in-log UI")
    observed[168] = "done"; Mock.Fire("QUEST_TURNED_IN", 168)
    T.eq(module.result.rows[1].status, "Completed", "turn-in event updates list")
    observed[168] = nil; Mock.Fire("QUEST_REMOVED", 168)
    T.eq(module.result.rows[1].status, "Missing", "removal/re-query does not persist stale completion")
    local before = apiCalls
    Mock.combat = true; Mock.Fire("PLAYER_REGEN_DISABLED")
    T.eq(apiCalls, before, "no new progress reads during combat")
    T.ok(module.summary:GetText():find("Paused in combat", 1, true), "stale results labeled")
    module.next:Click(); ns.RunCommand("dungeons thanes"); Mock.Flush()
    T.eq(ns.db.modules.dungeons.selected, "deadmines", "combat selection cannot mismatch stale rows and provenance")
    Mock.combat = false; Mock.Fire("PLAYER_REGEN_ENABLED")
    T.ok(apiCalls > before, "refresh after combat")
    module.next:Click(); Mock.Flush()
    T.eq(ns.db.modules.dungeons.selected, "thanes", "next dungeon persists selection")
    T.eq(#module.result.rows, 5, "switch discards old rows")
    T.eq(module.rows[8]:IsShown(), false, "unused labels hidden")
    module.previous:Click(); Mock.Flush()
    T.eq(ns.db.modules.dungeons.selected, "deadmines", "previous dungeon")
    ns.RunCommand("dungeons missing-dungeon"); Mock.Flush()
    T.eq(ns.db.modules.dungeons.selected, "deadmines", "unsupported dungeon not guessed")
    ns.RunCommand("dungeons ragefire"); Mock.Flush()
    T.eq(#module.result.rows, 5, "Horde catalog selectable for Alliance")
    T.eq(module.result.rows[1].eligibility, "Blocked (catalog)", "other-faction rows explicit")
    T.eq(ns.db.modules.quests.autoAccept, autoAccept, "auto-accept preference preserved")
    T.eq(#ns.db.modules.prep.checklist, #checklist, "manual checklist unchanged")
    for i, item in ipairs(checklist) do
        T.eq(ns.db.modules.prep.checklist[i].text, item.text, "manual checklist text preserved")
        T.eq(ns.db.modules.prep.checklist[i].checked, item.checked, "manual checks preserved")
    end
    T.eq(ns.db.modules.dungeons.completed, nil, "no persisted completion cache")
    ns.Models.Core.InitializeDatabase()
    T.eq(ns.db.modules.dungeons.selected, "ragefire", "saved-variable normalization preserves selection")
    local frame = ns.frames.dungeons
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", 31, -47)
    ns.SavePlacement("dungeons")
    T.near(ns.PanelSettings("dungeons").x, 31, "new panel uses shared movable placement")
    ns.ApplyLayout("Healing"); ns.ApplyLayout("Leveling")
    T.near(ns.PanelSettings("dungeons").x, 31, "new panel placement survives layout switch")
    ns.db.modules.dungeons.selected = "obsolete-key"
    ns.SetPanelVisible("dungeons", true); Mock.Flush()
    T.eq(ns.db.modules.dungeons.selected, "deadmines", "invalid saved choice repairs to known catalog")
    C_QuestLog = Mock.Secret()
    module:Refresh()
    T.eq(module.result.counts.Unknown, 8, "restricted live namespace degrades to unknown")
    C_QuestLog = {
        IsOnQuest = function() return false end,
        IsQuestFlaggedCompleted = function() return false end,
        RequestLoadQuestByID = function() error("unavailable") end,
    }
    module.refresh:Click(); Mock.Flush()
    T.eq(module.result.counts.Unknown, 8, "failed load request leaves status unknown")
    C_QuestLog, UnitFactionGroup = originalAPI, originalFaction
    ns.db.modules.dungeons.selected = originalSelection
    ns.SetPanelVisible("dungeons", false); Mock.Flush()
end
