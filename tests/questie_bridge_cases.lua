return function(T, common, Mock)
    -- An isolated model of the inspected Questie interfaces. These checks prove
    -- adapter decisions/restoration, not WoW taint safety or live addon compatibility.
    local names = {"QuestieLoader", "C_AddOns", "GetAddOnMetadata", "WorldMapFrame", "InputUtil", "C_Timer",
        "hooksecurefunc", "IsShiftKeyDown", "IsControlKeyDown", "IsAltKeyDown", "IsMetaKeyDown", "IsModifiedClick"}
    local saved = {}
    for _, name in ipairs(names) do saved[name] = _G[name] end
    local unpackValues = unpack or table.unpack

    local function fixture(version)
        local f = {events = {}, timers = {}, icons = {}, lines = {}, quests = {}, calls = 0, maps = {}, hooks = 0,
            combat = false, gamepad = false, modified = false, hiddenPreference = false, opened = true, serial = 0}
        local localNS = {db = {modules = {}}, Models = {}, Readable = common.Readable,
            Number = common.Number, Call = common.Call, IsCombat = function() return f.combat end}
        function localNS.ModuleDB(id, defaults)
            local value = localNS.db.modules[id]
            if not value then value = {}; localNS.db.modules[id] = value end
            for key, item in pairs(defaults) do if value[key] == nil then value[key] = item end end
            return value
        end
        function localNS.On(event, callback)
            f.events[event] = f.events[event] or {}
            table.insert(f.events[event], callback)
        end
        function f:Fire(event, ...)
            for _, callback in ipairs(self.events[event] or {}) do callback(event, ...) end
        end
        function f:Flush()
            local guard = 0
            while #self.timers > 0 do
                guard = guard + 1
                assert(guard < 20, "timer loop")
                local batch = self.timers; self.timers = {}
                for _, callback in ipairs(batch) do callback() end
            end
        end
        C_AddOns = {GetAddOnMetadata = function(name)
            if name == "Questie" then return version or "12.9.0" end
            if name == "QuestieDB" then return "1.1.1" end
        end}
        GetAddOnMetadata = nil
        InputUtil = {IsGamepadUIEnabled = function() return f.gamepad end}
        C_Timer = {After = function(_, callback) table.insert(f.timers, callback) end}
        IsShiftKeyDown = function() return f.shift end
        IsControlKeyDown = function() return f.control end
        IsAltKeyDown = function() return f.alt end
        IsMetaKeyDown = function() return false end
        IsModifiedClick = function() return f.modified end
        hooksecurefunc = function(object, name, callback)
            f.hooks = f.hooks + 1
            if f.failHookAt == f.hooks then error("synthetic hook failure") end
            local original = object[name]
            object[name] = function(...)
                local result = {original(...)}
                callback(...)
                return unpackValues(result)
            end
        end
        WorldMapFrame = {shown = false, hooks = {}}
        function WorldMapFrame:HookScript(name, callback)
            self.hooks[name] = self.hooks[name] or {}
            table.insert(self.hooks[name], callback)
        end
        function WorldMapFrame:IsShown() return self.shown end
        function WorldMapFrame:Hide()
            self.shown = false
            for _, callback in ipairs(self.hooks.OnHide or {}) do callback(self) end
        end
        f.worldMap = WorldMapFrame
        local function normalShow(frame)
            frame.wantsShow = true
            if not frame.hidden then frame.visible = true end
        end
        local function normalHide(frame)
            frame.wantsShow, frame.visible = false, false
        end
        local function fakeHide(frame) frame.hidden = true; frame.visible = false end
        local function fakeShow(frame) frame.hidden = false; frame.visible = frame.wantsShow end
        local function shouldHide(frame)
            return f.hiddenPreference or frame.nativeHidden == true
                or (frame.data and frame.data.ObjectiveData and frame.data.ObjectiveData.HideIcons) or false
        end
        function f:NewIcon(id, quest, objective, x, y, map, mini, shared)
            self.serial = self.serial + 1
            local icon = {frameId = self.serial, data = shared or {Id = id, QuestData = quest,
                ObjectiveData = objective, Type = objective and "monster" or "complete"},
                x = x, y = y, AreaID = 500 + (map or 100), UiMapID = map or 100,
                miniMapIcon = mini == true, visible = true, hidden = false, wantsShow = true, _loaded = true,
                Show = normalShow, Hide = normalHide, FakeHide = fakeHide, FakeShow = fakeShow,
                ShouldBeHidden = shouldHide, IsShown = function(self) return self.visible end}
            self.icons[#self.icons + 1] = icon
            return icon
        end
        function f:Pair(id, quest, objective, x, y, map)
            local icon = self:NewIcon(id, quest, objective, x, y, map, false)
            local twin = self:NewIcon(id, quest, objective, x, y, map, true, icon.data)
            icon.minimapTwin = twin
            return icon, twin
        end
        function f:AddQuest(id)
            local objective = {Completed = false, Needed = 3, Collected = 0}
            local completeObjective = {Completed = true, Needed = 1, Collected = 1}
            local special = {Completed = false}
            local original = {Id = id, Objectives = {objective, completeObjective}, SpecialObjectives = {special}}
            local display = {Id = id, enrichment = original, isComplete = false,
                Objectives = {{enrichment = objective, Completed = false, Needed = 3, Collected = 0},
                    {enrichment = completeObjective, Completed = true, Needed = 1, Collected = 1}},
                SpecialObjectives = {special}}
            function display:IsComplete() return self.isComplete and 1 or 0 end
            self.quests[id] = {display = display, original = original, objective = objective,
                done = completeObjective, special = special,
                capabilities = {quest = original, objectives = {[objective] = true, [completeObjective] = true, [special] = true}}}
            return self.quests[id]
        end
        function f:Line(quest)
            local line = {mode = "quest", Quest = quest.display, scripts = {}}
            function line:GetScript(name) return self.scripts[name] end
            function line:SetScript(name, callback) self.scripts[name] = callback end
            line.original = function(_, button, extra) f.calls = f.calls + 1; f.lastButton = button; f.lastExtra = extra end
            line.scripts.OnClick = line.original
            self.lines[#self.lines + 1] = line
            return line
        end
        function f:Click(line, button, extra) line:GetScript("OnClick")(line, button or "LeftButton", extra) end
        function f:Visible(id, mini)
            local count = 0
            for _, icon in ipairs(self.icons) do
                if icon.data and icon.data.Id == id and icon.miniMapIcon == mini and icon.visible then count = count + 1 end
            end
            return count
        end
        local registry = {}
        registry.TrackerMapEligibility = {RefreshAndGetCapabilities = function(id, expected)
            local quest = f.quests[id]
            if not quest or (expected and expected ~= quest.original) then return nil, nil end
            return quest.display, quest.capabilities
        end}
        registry.TrackerLinePool = {
            GetCurrentLine = function() return f.currentLine end,
            ForEachQuestTitleLine = function(callback)
                for _, line in ipairs(f.lines) do if line.mode == "quest" then callback(line) end end
            end,
        }
        registry.LineBuilder = {AddTitle = function(options)
            local line = options.line
            f.currentLine = line
            line.mode, line.Quest = options.clickMode, options.target
            line:SetScript("OnClick", line.original)
            return line
        end}
        registry.QuestieMap = {
            GetFramesForQuest = function(_, id)
                local result = {}
                for _, icon in ipairs(f.icons) do if icon.data and icon.data.Id == id then result[icon.frameId] = icon end end
                return result
            end,
            QueueDraw = function() end,
            ProcessQueue = function()
                for _, icon in ipairs(f.icons) do if icon.data then icon._loaded = true; icon:Show() end end
            end,
        }
        registry.QuestieFramePool = {UnloadFrame = function(_, icon)
            if icon.deferUnload then icon._needsUnload = true; return end
            icon.data, icon.hidden, icon._loaded, icon._needsUnload = nil, nil, nil, nil
            icon.visible, icon.wantsShow = false, false
            icon.minimapTwin = nil
        end}
        registry.QuestieCompat = {
            OpenWorldMap = function(map)
                f.maps[#f.maps + 1] = map
                if not f.opened then return false end
                f.worldMap.shown = true
                for _, icon in ipairs(f.icons) do if icon.data then icon:Show() end end
                return true
            end,
            GetQuestUiMapID = function() return 100 end,
        }
        registry.HBD = {
            GetPlayerWorldPosition = function() if not f.noPosition then return 0, 0, 1 end end,
            GetWorldCoordinatesFromZone = function(_, x, y, map)
                if map == 999 then return nil end
                return x * 100, y * 100, map == 200 and 2 or 1
            end,
        }
        QuestieLoader = {_modules = registry}
        f.registry, f.ns = registry, localNS
        assert(loadfile(TEST_ROOT .. "/PriestCompanion/QuestieBridge.lua"))("PriestCompanion", localNS)
        f.bridge = localNS.QuestieBridge
        return f
    end

    local function populated(version)
        local f = fixture(version)
        f.q = f:AddQuest(101)
        f.other = f:AddQuest(202)
        f.near, f.nearMini = f:Pair(101, f.q.original, f.q.objective, 10, 10)
        f.far, f.farMini = f:Pair(101, f.q.original, f.q.objective, 40, 40)
        f.done = f:Pair(101, f.q.original, f.q.done, 1, 1)
        f.special = f:Pair(101, f.q.original, f.q.special, 20, 20)
        f.unmapped = f:Pair(101, f.q.original, {}, 2, 2)
        f.invalid = f:Pair(101, f.q.original, f.q.objective, -1, -1)
        f.badMap = f:Pair(101, f.q.original, f.q.objective, 1, 1, 999)
        f.foreign = f:Pair(202, f.other.original, f.other.objective, 30, 30)
        f.line = f:Line(f.q)
        return f
    end

    local function run()
        for _, supported in ipairs({"12.8.0", "12.9.0"}) do
            local f = populated(supported)
            local originalShow, originalShould = f.near.FakeShow, f.near.ShouldBeHidden
            T.ok(f.bridge.Install(), "inspected Questie minor version installs")
            T.eq(f.bridge.GetMode(), "next", "next is the saved default")
            T.eq(f:Visible(101, false), 7, "install leaves existing map icons untouched")
            T.ok(f.bridge.Status():find(supported, 1, true), "status reports actual metadata version")
            f:Click(f.line)
            T.eq(f.calls, 0, "successful plain left click bypasses quest-log cycling")
            T.eq(f.maps[1], 100, "navigation uses actual UiMapID, not area ID")
            T.eq(f:Visible(101, false), 1, "Next has exactly one selected-quest world pin")
            T.eq(f:Visible(101, true), 1, "Next has exactly its one minimap twin")
            T.eq(f.near.visible, true, "nearest unfinished supported checkpoint wins")
            T.eq(f.done.visible, false, "closer completed objective is excluded")
            T.eq(f.unmapped.visible, false, "unverified objective is excluded")
            T.eq(f.badMap.visible, false, "unconvertible coordinates are excluded")
            T.eq(f.foreign.visible, true, "unrelated quest visibility is untouched")
            T.eq(f.serial, 16, "bridge adds no duplicate pin layer")
            f.far:FakeShow(); f.far:Show()
            T.eq(f.far.visible, false, "native FakeShow and HBD Show cannot bypass the filter")
            T.eq(f.far:ShouldBeHidden(), true, "native visibility checks include temporary filter")
            T.ok(f.bridge.SetMode("all"), "All accepted while map is open")
            T.eq(f:Visible(101, false), 3, "All reveals every supported unfinished rendered checkpoint")
            T.eq(f:Visible(101, true), 3, "All mirrors supported twins")
            T.eq(f.done.visible, false, "All still excludes completed objectives")
            T.ok(f.bridge.SetMode("hide"), "Hide accepted")
            T.eq(f:Visible(101, false), 0, "Hide actually suppresses selected quest locations")
            T.eq(f:Visible(101, true), 0, "Hide also suppresses selected minimap locations")
            T.eq(f.foreign.visible, true, "Hide does not claim to filter other quests")
            f.worldMap:Hide()
            T.eq(f:Visible(101, false), 7, "map close restores original visual state")
            T.eq(f.near.FakeShow, originalShow, "map close restores exact original FakeShow method")
            T.eq(f.near.ShouldBeHidden, originalShould, "map close restores exact original predicate")
            T.eq(f.bridge.GetMode(), "hide", "restoration retains user's selected mode")
            T.ok(f.bridge.SetEnabled(false), "adapter can be disabled independently")
            T.eq(f.line:GetScript("OnClick"), f.line.original, "Off restores normal title action")
            f:Click(f.line)
            T.eq(f.calls, 1, "Off uses original quest click")
            T.eq(f.bridge.GetMode(), "hide", "Off does not turn Hide into another mode")
            T.ok(f.bridge.SetEnabled(true), "adapter can be re-enabled")
            f:Click(f.line)
            T.eq(f:Visible(101, false), 0, "re-enabled adapter uses retained Hide mode")
        end

        local f = populated()
        T.ok(f.bridge.Install())
        for _, modifier in ipairs({"shift", "control", "alt", "modified", "combat", "gamepad"}) do
            f[modifier] = true
            local before = f.calls
            f:Click(f.line, "LeftButton", "preserve")
            T.eq(f.calls, before + 1, "preserve original click for " .. modifier)
            T.eq(f.lastExtra, "preserve", "original click receives all extra arguments")
            f[modifier] = false
        end
        f:Click(f.line, "RightButton")
        T.eq(f.lastButton, "RightButton", "right-click menu is preserved")
        T.eq(#f.maps, 0, "modified/combat/controller clicks do not open our map")
        f.combat = true
        T.eq(f.bridge.SetMode("hide"), false, "settings action is combat guarded")
        T.eq(f.bridge.GetMode(), "next", "combat action cannot silently change mode")
        f.combat = false
        f:Click(f.line)
        local newNear = f:Pair(101, f.q.original, f.q.objective, 5, 5)
        f.registry.QuestieMap:QueueDraw("world", {}, newNear)
        f.registry.QuestieMap:QueueDraw("mini", {}, newNear.minimapTwin)
        T.eq(newNear.visible, false, "new selected-quest pins are suppressed before draw")
        f.registry.QuestieMap.ProcessQueue(); f:Flush()
        T.eq(newNear.visible, true, "redraw recomputes nearest supported checkpoint")
        T.eq(f:Visible(101, false), 1, "redraw never leaves a duplicate selected layer")
        f.registry.LineBuilder.AddTitle({line = f.line, clickMode = "quest", target = f.other.display})
        f:Click(f.line)
        T.eq(f.foreign.visible, true, "pooled title reads its current quest")
        T.eq(f:Visible(101, false), 8, "changing selected quest restores previous icons")
        T.eq(f:Visible(202, false), 1, "new selected quest is filtered independently")
        local laterScript = function() f.later = true end
        f.line:SetScript("OnClick", laterScript)
        f.bridge.SetEnabled(false)
        T.eq(f.line:GetScript("OnClick"), laterScript, "Off does not replace another addon's later title script")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        local oldShow, oldPredicate = f.far.FakeShow, f.far.ShouldBeHidden
        f.registry.QuestieFramePool:UnloadFrame(f.far)
        T.ok(f.far.FakeShow ~= oldShow and f.far.ShouldBeHidden ~= oldPredicate, "unload removes our wrappers")
        f.far.data = {Id = 202, QuestData = f.other.original, ObjectiveData = f.other.objective, Type = "monster"}
        f.far.miniMapIcon, f.far.x, f.far.y, f.far.UiMapID = false, 12, 12, 100
        f.far:FakeShow(); f.far:Show()
        T.eq(f.far.visible, true, "recycled frame does not inherit previous quest filter")
        f.q.display.isComplete = true
        local turnin = f:Pair(101, f.q.original, nil, 50, 50)
        f:Fire("QUEST_LOG_UPDATE"); f:Flush()
        T.eq(turnin.visible, true, "live completed quest changes target to turn-in")
        T.eq(f.near.visible, false, "completed quest no longer shows objective checkpoint")
        T.eq(f:Visible(101, false), 1, "completed quest retains strict Next count")
        f.quests[101] = nil
        f:Fire("QUEST_LOG_UPDATE"); f:Flush()
        T.eq(f.near.hidden, false, "quest removal releases filter")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        f.q.display.Objectives[1].Completed = true
        f:Fire("QUEST_LOG_UPDATE"); f:Flush()
        T.eq(f.near.visible, false, "live completion overrides stale original objective metadata")
        T.eq(f.special.visible, true, "next unfinished special checkpoint replaces newly completed objective")
        T.eq(f:Visible(101, false), 1, "objective progress preserves strict Next count")
        T.eq(f.bridge.Navigate(Mock.Secret()), false, "restricted quest ID is rejected")
        T.eq(f.bridge.Navigate(101, Mock.Secret()), false, "restricted expected quest is rejected")

        f = populated()
        f.near:FakeHide()
        f.bridge.Install(); f:Click(f.line)
        T.eq(f.special.visible, true, "native-hidden closest pin is not promised as the visible checkpoint")
        T.eq(f:Visible(101, false), 1, "Next uses one actually available native pin")
        f.worldMap:Hide()
        T.eq(f.near.hidden, true, "a pre-existing native hide survives restoration")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        f.hiddenPreference = true
        f.bridge.SetEnabled(false)
        T.eq(f.far.hidden, true, "restoration respects current native hide preference")
        T.eq(f.hiddenPreference, true, "bridge never rewrites native hide preference")
        f.hiddenPreference = false
        f.far:FakeShow()
        T.eq(f.far.visible, true, "restored native method remains usable")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        local otherPredicate = function() return false end
        f.far.ShouldBeHidden = otherPredicate
        f.bridge.SetEnabled(false)
        T.eq(f.far.ShouldBeHidden, otherPredicate, "restoration preserves another addon's predicate replacement")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        local changedShape = f:Pair(101, f.q.original, f.q.objective, 3, 3)
        changedShape.FakeShow = nil
        f.registry.QuestieMap:QueueDraw("world", {}, changedShape)
        T.eq(f.far.hidden, false, "unsupported new icon releases strict filtering instead of leaving duplicates")
        T.ok(f.bridge.Status():find("shape changed", 1, true), "unsupported redraw is visible in diagnostics")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        f.combat = true
        f.far:FakeShow(); f.far:Show()
        T.eq(f.far.visible, true, "native icon behavior is preserved during combat")
        f.combat = false; f:Fire("PLAYER_REGEN_ENABLED"); f:Flush()
        T.eq(f:Visible(101, false), 1, "combat exit reapplies active selection without another quest event")
        T.eq(f.far.visible, false, "combat redraw cannot leave extra selected-quest checkpoints")

        f = populated()
        f.bridge.Install(); f:Click(f.line)
        f.combat = true
        f.worldMap:Hide()
        T.eq(f.far.hidden, true, "combat map-close restoration is deferred without UI mutation")
        f.combat = false; f:Fire("PLAYER_REGEN_ENABLED")
        T.eq(f.far.hidden, false, "deferred map-close restoration finishes after combat")

        for _, reason in ipairs({"position", "icons", "open", "stale", "shape", "exception"}) do
            f = populated()
            f.bridge.Install()
            if reason == "position" then f.noPosition = true
            elseif reason == "icons" then f.icons = {}
            elseif reason == "open" then f.opened = false
            elseif reason == "stale" then f.line.Quest.enrichment = {}
            elseif reason == "shape" then f.far.FakeShow = nil
            elseif reason == "exception" then f.far.FakeHide = function() error("synthetic frame failure") end end
            f:Click(f.line)
            T.eq(f.calls, 1, "unavailable " .. reason .. " falls back to original title action")
            T.eq(f.near.hidden, false, "failed " .. reason .. " does not leave partial filtering")
            T.ok(#f.bridge.Status() > 0, "failure has a controlled readable status")
        end

        for _, unsupported in ipairs({"11.9.0", "12.7.9", "12.10.0", "unavailable"}) do
            f = populated(unsupported)
            T.eq(f.bridge.Install(), false, "unsupported version does not install hooks")
            T.eq(f.hooks, 0, "unsupported version has no hook mutation")
            T.eq(f.line:GetScript("OnClick"), f.line.original, "unsupported version keeps original script")
        end
        f = populated()
        f.registry.LineBuilder.AddTitle = nil
        T.eq(f.bridge.Install(), false, "missing method shape blocks installation")
        T.eq(f.hooks, 0, "shape check runs before hooks")
        f = populated()
        QuestieLoader = nil
        T.eq(f.bridge.Install(), false, "missing loader is handled")
        f = populated()
        f.failHookAt = 2
        T.eq(f.bridge.Install(), false, "partial secure-hook failure is reported")
        local hooks = f.hooks
        T.eq(f.bridge.Install(), false, "partial hook failure cannot be reinstalled in place")
        T.eq(f.hooks, hooks, "retry never stacks partial secure hooks")
    end

    local ok, err = pcall(run)
    for _, name in ipairs(names) do _G[name] = saved[name] end
    if not ok then error(err, 0) end
end
