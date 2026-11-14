local addonName, ns = ...

-- Original adapter for the internal interfaces inspected in Questie 12.6.5
-- (0214175640abba697f535b2be73787a4c2f2b32b), 12.8.0
-- (968dd36747e58df157934b73d7781e8cfe560668) and 12.9.0
-- (624cb783bfc1d272aeccd3dfa353dde8452e276f). This is not a public Questie API.
-- Selected-quest navigation reuses its rendered icons, including clustering and
-- phase checks. It never writes Questie settings or persists quest objects. The
-- separate guide renderer uses its own pin reference through GetMapProvider.
local Bridge = {}
ns.QuestieBridge = Bridge
local active, modules, installed, hooksAttempted, pendingRestore, refreshPending, drawDirty
local lastFailure, version, databaseVersion = nil, "unavailable", "unavailable"
local iconRecords = setmetatable({}, {__mode = "k"})
local titleRecords = setmetatable({}, {__mode = "k"})
local refreshActive, attachTitle

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function settings()
    if not ns.db then return nil end
    local db = ns.ModuleDB("navigation", {mode = "next", enabled = true})
    if db.mode ~= "hide" and db.mode ~= "next" and db.mode ~= "all" then db.mode = "next" end
    if type(db.enabled) ~= "boolean" then db.enabled = true end
    return db
end

local function blocked()
    if ns.IsCombat() then return "Navigation waits until combat ends." end
    local input = InputUtil
    if readableTable(input) and type(input.IsGamepadUIEnabled) == "function" then
        local ok, enabled = pcall(input.IsGamepadUIEnabled)
        if not ok or not ns.Readable(enabled) or enabled then return "Controller navigation stays with Questie." end
    end
end

local function failure(reason)
    lastFailure = reason
    return false, reason
end

local function hasMethods(object, names)
    if not ns.Readable(object) or (type(object) ~= "table" and type(object) ~= "userdata") then return false end
    for _, name in ipairs(names) do
        if type(object[name]) ~= "function" then return false end
    end
    return true
end

local function getVersion(name)
    local getter = readableTable(C_AddOns) and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local value = ns.Call(getter, name, "Version")
    return ns.Readable(value) and type(value) == "string" and value:sub(1, 40) or "unavailable"
end

local function versionProfile(value)
    local major, minor, patch = value:match("^v?(%d+)%.(%d+)%.(%d+)")
    if major == "12" and minor == "6" and patch == "5" then return "libstub" end
    if major == "12" and (minor == "8" or minor == "9") then return "modules" end
end

local function unsupportedVersion()
    return "Questie version unavailable or unsupported. Supported: 12.6.5, 12.8.x and 12.9.x. Check Questie in the AddOns list."
end

local function legacyLibrary(name)
    -- LibStub is normally a callable table; ns.Call(LibStub, ...) deliberately
    -- rejects it. Use the inspected method with a silent lookup and explicit self.
    if not hasMethods(LibStub, {"GetLibrary"}) then return nil end
    return ns.Call(LibStub.GetLibrary, LibStub, name, true)
end

local function mapLibraries(profile, registry)
    if profile == "libstub" then
        return legacyLibrary("HereBeDragonsQuestie-2.0"), legacyLibrary("HereBeDragonsQuestie-Pins-2.0")
    end
    return registry.HBD, registry.HBDPins
end

-- Guide markers have separate ownership from the selected-quest filter. Reading
-- this provider does not install hooks, enable tracker interception or save data.
function Bridge.GetMapProvider()
    local detected = getVersion("Questie")
    local profile = versionProfile(detected)
    if not profile then return nil, unsupportedVersion() end
    local registry = readableTable(QuestieLoader) and QuestieLoader._modules
    if not readableTable(registry) then return nil, "Questie is still loading. Try the map button again after login." end
    local hbd, hbdPins = mapLibraries(profile, registry)
    if not hasMethods(hbd, {"GetPlayerWorldPosition", "GetWorldCoordinatesFromZone"}) then
        return nil, "Questie's map coordinate library is unavailable. Check that Questie loaded successfully."
    end
    if not hasMethods(hbdPins, {"AddWorldMapIconMap", "AddMinimapIconMap", "RemoveAllWorldMapIcons", "RemoveAllMinimapIcons"}) then
        return nil, "Questie's map marker library is unavailable. Check that Questie loaded successfully."
    end
    if not hasMethods(registry.QuestieCompat, {"OpenWorldMap"}) then
        return nil, "Questie's map-opening helper is unavailable. Use quest details until Questie is ready."
    end
    local db = hasMethods(registry.QuestieDB, {"QueryQuestSingle", "QueryNPCSingle", "QueryObjectSingle", "QueryItemSingle"})
        and registry.QuestieDB or nil
    local zones = hasMethods(registry.ZoneDB, {"GetUiMapIdByAreaId"}) and registry.ZoneDB or nil
    local phasing = hasMethods(registry.Phasing, {"IsSpawnVisible"}) and registry.Phasing or nil
    return {hbd = hbd, hbdPins = hbdPins, compat = registry.QuestieCompat, db = db, zones = zones,
        phasing = phasing, version = detected, databaseVersion = getVersion("QuestieDB"), profile = profile}
end

local function ownData(frame, record)
    return ns.Readable(frame.data) and frame.data == record.data
end

local function nativeHidden(frame)
    local record = iconRecords[frame]
    local method = record and record.originalShould or frame.ShouldBeHidden
    local ok, result = pcall(method, frame)
    if not ok or not ns.Readable(result) then return true end
    return result == true
end

local function suppressed(frame)
    if not active or blocked() then return false end
    local data = frame.data
    if not readableTable(data) or ns.Number(data.Id) ~= active.id then return false end
    return active.allowed[frame] ~= data
end

local function restoreIcon(frame, record, discarded)
    local ownsShow = frame.FakeShow == record.showWrapper
    local sameData = ownData(frame, record)
    if frame.ShouldBeHidden == record.shouldWrapper then frame.ShouldBeHidden = record.originalShould end
    if ownsShow then frame.FakeShow = record.originalShow end
    iconRecords[frame] = nil
    -- Unload clears data and HBD ownership itself. Do not show a recycled frame.
    if not discarded and sameData and ownsShow and record.hiddenByBridge and not nativeHidden(frame) then
        pcall(record.originalShow, frame)
    end
end

local function restoreIcons()
    for frame, record in pairs(iconRecords) do restoreIcon(frame, record) end
end

local function restoreTitles()
    for line, record in pairs(titleRecords) do
        if line:GetScript("OnClick") == record.wrapper then line:SetScript("OnClick", record.original) end
        titleRecords[line] = nil
    end
end

local function release()
    if blocked() then pendingRestore = true; return false end
    active, pendingRestore, drawDirty = nil, nil, nil
    restoreIcons()
    return true
end

local function filterable(frame)
    return hasMethods(frame, {"ShouldBeHidden", "FakeHide", "FakeShow", "Show", "Hide", "IsShown"})
        and readableTable(frame.data)
end

local function attachIcon(frame)
    if not filterable(frame) or blocked() then return false end
    local record = iconRecords[frame]
    if record and ownData(frame, record) then
        return frame.FakeShow == record.showWrapper and frame.ShouldBeHidden == record.shouldWrapper
    end
    if record then restoreIcon(frame, record, true) end
    record = {data = frame.data, originalShould = frame.ShouldBeHidden, originalShow = frame.FakeShow}
    record.shouldWrapper = function(self, ...)
        local result = record.originalShould(self, ...)
        if suppressed(self) then return true end
        return result
    end
    record.showWrapper = function(self, ...)
        if suppressed(self) then
            -- A native request to show supersedes an earlier native hide. Keep
            -- that intent while the temporary selected-quest filter is active.
            if not nativeHidden(self) then record.hiddenByBridge = true end
            if not self.hidden then self:FakeHide() end
            return
        end
        record.hiddenByBridge = nil
        return record.originalShow(self, ...)
    end
    iconRecords[frame] = record
    frame.ShouldBeHidden, frame.FakeShow = record.shouldWrapper, record.showWrapper
    return true
end

local function applyIcon(frame)
    if not attachIcon(frame) then return false end
    local record = iconRecords[frame]
    if suppressed(frame) then
        if not frame.hidden then
            record.hiddenByBridge = true
            frame:FakeHide()
        end
    elseif record.hiddenByBridge then
        record.hiddenByBridge = nil
        if not nativeHidden(frame) then record.originalShow(frame) end
    end
    return true
end

local function unfinished(value)
    if not readableTable(value) or not ns.Readable(value.Completed) then return false end
    if value.Completed == true then return false end
    local needed, collected = ns.Number(value.Needed), ns.Number(value.Collected)
    return not needed or not collected or collected < needed
end

local function eligibleObjectives(current, capabilities)
    local result = {}
    for _, objective in pairs(current.Objectives or {}) do
        if unfinished(objective) and readableTable(objective.enrichment)
            and capabilities.objectives[objective.enrichment] then result[objective.enrichment] = true end
    end
    for _, objective in pairs(current.SpecialObjectives or {}) do
        if unfinished(objective) and capabilities.objectives[objective] then result[objective] = true end
    end
    return result
end

local function coordinates(frame)
    local x, y, map = ns.Number(frame.x), ns.Number(frame.y), ns.Number(frame.UiMapID)
    if not x or not y or not map or map <= 0 or x < 0 or x > 100 or y < 0 or y > 100 then return nil end
    return x, y, map
end

local function makePlan(id, expected, mode)
    local current, capabilities = ns.Call(modules.eligibility.RefreshAndGetCapabilities, id, expected)
    if not readableTable(current) or not readableTable(capabilities) or not readableTable(capabilities.quest)
        or not readableTable(capabilities.objectives) then return nil, "Quest data changed or is unavailable." end
    if not readableTable(current.Objectives) or not readableTable(current.SpecialObjectives or {}) then
        return nil, "Quest objectives are unavailable."
    end
    local state = ns.Call(current.IsComplete, current)
    if not ns.Readable(state) or not ns.Readable(current.isComplete) then return nil, "Quest state is unavailable." end
    local complete = state == 1 or (state ~= -1 and current.isComplete == true)
    local objectives = eligibleObjectives(current, capabilities)
    local frames = ns.Call(modules.map.GetFramesForQuest, modules.map, id)
    if not readableTable(frames) then return nil, "Questie map icons are unavailable." end
    local plan = {id = id, expected = capabilities.quest, mode = mode, frames = {}, allowed = {}, count = 0,
        complete = complete}
    local candidates = {}
    for _, frame in pairs(frames) do
        if not filterable(frame) then return nil, "Questie icon shape changed; normal navigation is retained." end
        local data = frame.data
        if ns.Number(data.Id) == id then
            plan.frames[#plan.frames + 1] = frame
            local objective = data.ObjectiveData
            local matches = complete and data.Type == "complete"
                or (not complete and readableTable(objective) and objectives[objective] == true)
            local x, y, map = coordinates(frame)
            local prior = iconRecords[frame]
            local temporarilyHiddenByUs = prior and ownData(frame, prior) and prior.hiddenByBridge
            if matches and data.QuestData == capabilities.quest and frame.miniMapIcon == false
                and not frame._needsUnload and x and not nativeHidden(frame)
                and (not frame.hidden or temporarilyHiddenByUs) and not frame._hidden_by_flash
                and (not objective or not objective.IsPartyObjective) then
                candidates[#candidates + 1] = frame
            end
        end
    end
    if #plan.frames == 0 then return nil, "Questie has no rendered icons for this quest." end
    -- Stable tie breaking avoids switching between equal-distance pins after a redraw.
    table.sort(candidates, function(a, b)
        if a.UiMapID ~= b.UiMapID then return a.UiMapID < b.UiMapID end
        if a.x ~= b.x then return a.x < b.x end
        if a.y ~= b.y then return a.y < b.y end
        return (ns.Number(a.frameId, 0)) < (ns.Number(b.frameId, 0))
    end)
    local px, py, instance = ns.Call(modules.hbd.GetPlayerWorldPosition, modules.hbd)
    px, py = ns.Number(px), ns.Number(py)
    if not ns.Readable(instance) then instance = nil end
    local best, bestDistance, bestSameInstance
    local validCandidates = {}
    for _, frame in ipairs(candidates) do
        local x, y, map = coordinates(frame)
        local wx, wy, wi = ns.Call(modules.hbd.GetWorldCoordinatesFromZone, modules.hbd, x / 100, y / 100, map)
        wx, wy = ns.Number(wx), ns.Number(wy)
        if px and py and instance ~= nil and wx and wy and ns.Readable(wi) and wi ~= nil then
            validCandidates[#validCandidates + 1] = frame
            local sameInstance = wi == instance
            local distance = (wx - px) * (wx - px) + (wy - py) * (wy - py)
            if not best or (sameInstance and not bestSameInstance)
                or (sameInstance == bestSameInstance and distance < bestDistance) then
                best, bestDistance, bestSameInstance = frame, distance, sameInstance
            end
        end
    end
    if mode ~= "hide" and not best then return nil, "No visible checkpoint with valid map coordinates is available." end
    plan.mapID = best and best.UiMapID or ns.Number(ns.Call(modules.compat.GetQuestUiMapID, id))
    if not plan.mapID then return nil, "The quest map location is unavailable." end
    local function allow(frame)
        plan.allowed[frame] = frame.data
        local twin = frame.minimapTwin
        if filterable(twin) and twin.data == frame.data and twin.miniMapIcon == true
            and twin.x == frame.x and twin.y == frame.y and twin.UiMapID == frame.UiMapID then
            plan.allowed[twin] = twin.data
        end
        plan.count = plan.count + 1
    end
    if mode == "next" then allow(best)
    elseif mode == "all" then for _, frame in ipairs(validCandidates) do allow(frame) end end
    return plan
end

-- A read-only snapshot for guide routing. Nil means no validated live snapshot;
-- an empty list means the live quest is complete. Each group contains alternate
-- locations for one unfinished objective. No provider/frame objects escape.
function Bridge.GetObjectiveLocations(id)
    id = ns.Number(id)
    if not installed or not modules or not id or ns.IsCombat() then return nil end
    local plan = makePlan(id, nil, "all")
    if not plan then return nil end
    if plan.complete then return {} end
    local groups, byObjective = {}, {}
    for _, frame in ipairs(plan.frames) do
        if frame.miniMapIcon == false and plan.allowed[frame] == frame.data then
            local objective = frame.data.ObjectiveData
            if readableTable(objective) then
                local group = byObjective[objective]
                if not group then group = {}; byObjective[objective] = group; groups[#groups + 1] = group end
                local x, y, map = coordinates(frame)
                group[#group + 1] = {x = x / 100, y = y / 100, uiMapID = map, provenance = "Questie"}
            end
        end
    end
    local function earlier(a, b)
        if a.uiMapID ~= b.uiMapID then return a.uiMapID < b.uiMapID end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end
    for _, group in ipairs(groups) do table.sort(group, earlier) end
    table.sort(groups, function(a, b) return earlier(a[1], b[1]) end)
    return groups
end

local function applyPlan(plan)
    active = plan
    for _, frame in ipairs(plan.frames) do
        if not applyIcon(frame) then release(); return failure("Another addon changed Questie icons; normal navigation is retained.") end
    end
    return true
end

local function scheduleRefresh()
    if not active or refreshPending then return end
    refreshPending = true
    if C_Timer and type(C_Timer.After) == "function" then
        C_Timer.After(0, function()
            refreshPending = nil
            if active then refreshActive() end
        end)
    else
        refreshPending = nil
        refreshActive()
    end
end

refreshActive = function()
    if not active or blocked() then return end
    if pendingRestore then release(); return end
    local plan, reason = makePlan(active.id, active.expected, Bridge.GetMode())
    if not plan then release(); failure(reason); return end
    applyPlan(plan)
end

function Bridge.GetMode()
    local db = settings()
    return db and db.mode or "next"
end

function Bridge.IsEnabled()
    local db = settings()
    return not db or db.enabled
end

local function modifiedClick()
    return ns.Call(IsShiftKeyDown) == true or ns.Call(IsControlKeyDown) == true
        or ns.Call(IsAltKeyDown) == true or ns.Call(IsMetaKeyDown) == true
        or ns.Call(IsModifiedClick) == true
end

attachTitle = function(line, fromDraw)
    if blocked() or not Bridge.IsEnabled() or not hasMethods(line, {"GetScript", "SetScript"})
        or line.mode ~= "quest" or not readableTable(line.Quest) then return end
    local original = line:GetScript("OnClick")
    local old = titleRecords[line]
    if old and original == old.wrapper then return end
    if old and not fromDraw then return end -- respect a later third-party replacement
    if type(original) ~= "function" then return end
    local record = {original = original}
    record.wrapper = function(self, button, ...)
        if Bridge.IsEnabled() and not blocked() and ns.Readable(button) and button == "LeftButton"
            and not modifiedClick() and self.mode == "quest" and readableTable(self.Quest) then
            local quest = self.Quest
            if Bridge.Navigate(ns.Number(quest.Id), quest.enrichment) then return end
        end
        return record.original(self, button, ...)
    end
    titleRecords[line] = record
    line:SetScript("OnClick", record.wrapper)
end

function Bridge.Install()
    local reason = blocked()
    if reason then return failure(reason) end
    if not settings() then return failure("Settings are still loading.") end
    if installed then
        if pendingRestore then release() end
        if Bridge.IsEnabled() then modules.pool.ForEachQuestTitleLine(attachTitle) else restoreTitles() end
        return true
    end
    if hooksAttempted then return failure("Questie hook installation failed; reload before retrying.") end
    version, databaseVersion = getVersion("Questie"), getVersion("QuestieDB")
    local profile = versionProfile(version)
    if not profile then return failure(unsupportedVersion()) end
    -- Read the loader registry, rather than ImportModule, which creates absent modules.
    local registry = readableTable(QuestieLoader) and QuestieLoader._modules
    if not readableTable(registry) then return failure("Questie is not ready.") end
    local found = {builder = registry.LineBuilder, pool = registry.TrackerLinePool,
        eligibility = registry.TrackerMapEligibility, map = registry.QuestieMap,
        framePool = registry.QuestieFramePool, compat = registry.QuestieCompat, hbd = mapLibraries(profile, registry)}
    local shapes = {
        builder = {"AddTitle"}, pool = {"GetCurrentLine", "ForEachQuestTitleLine"},
        eligibility = {"RefreshAndGetCapabilities"}, map = {"GetFramesForQuest", "QueueDraw", "ProcessQueue"},
        framePool = {"UnloadFrame"}, compat = {"OpenWorldMap", "GetQuestUiMapID"},
        hbd = {"GetPlayerWorldPosition", "GetWorldCoordinatesFromZone"},
    }
    for key, names in pairs(shapes) do
        if not hasMethods(found[key], names) then
            return failure("Questie " .. key .. " interface is unavailable or changed. Check that Questie and QuestieDB loaded successfully.")
        end
    end
    if type(hooksecurefunc) ~= "function" or not hasMethods(WorldMapFrame, {"HookScript", "IsShown"}) then
        return failure("Map hooks are unavailable.")
    end
    modules = found
    hooksAttempted = true
    local ok = pcall(function()
        hooksecurefunc(modules.builder, "AddTitle", function(options)
            if installed and readableTable(options) and options.clickMode == "quest" then
                local line = modules.pool.GetCurrentLine()
                if line and line.Quest == options.target then attachTitle(line, true) end
            end
        end)
        hooksecurefunc(modules.map, "QueueDraw", function(_, _, _, frame)
            if not installed or not active or blocked() then return end
            if not ns.Readable(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata")
                or not readableTable(frame.data) then return end
            if ns.Number(frame.data.Id) == active.id then
                if not filterable(frame) then
                    release(); failure("Questie icon shape changed; normal navigation is retained."); return
                end
                drawDirty = true
                -- New/recycled pins start suppressed until the complete set is selected.
                if not applyIcon(frame) then
                    release(); failure("Another addon changed Questie icons; normal navigation is retained.")
                end
            end
        end)
        hooksecurefunc(modules.map, "ProcessQueue", function()
            if installed and active and drawDirty and not blocked() then
                drawDirty = nil
                scheduleRefresh()
            end
        end)
        hooksecurefunc(modules.framePool, "UnloadFrame", function(_, frame)
            if not installed or blocked() then return end
            local record = iconRecords[frame]
            if record and not frame._needsUnload then restoreIcon(frame, record, true) end
        end)
        WorldMapFrame:HookScript("OnHide", function() if installed then release() end end)
    end)
    if not ok then return failure("Questie hooks could not be installed.") end
    installed, lastFailure = true, nil
    if Bridge.IsEnabled() then modules.pool.ForEachQuestTitleLine(attachTitle) end
    return true
end

local function navigate(questID, expectedQuest)
    local reason = blocked()
    if reason then return failure(reason) end
    if not Bridge.IsEnabled() then return failure("Questie navigation adapter is disabled.") end
    questID = ns.Number(questID)
    if not questID or questID <= 0 or questID % 1 ~= 0 then return failure("Select a readable quest first.") end
    if expectedQuest ~= nil and not readableTable(expectedQuest) then return failure("Quest data is unavailable.") end
    if not installed then
        local ok, why = Bridge.Install()
        if not ok then return false, why end
    end
    if pendingRestore then release() end
    local plan, why = makePlan(questID, expectedQuest, Bridge.GetMode())
    if not plan then release(); return failure(why) end
    release()
    if not applyPlan(plan) then return false, lastFailure end
    local opened = ns.Call(modules.compat.OpenWorldMap, plan.mapID)
    if opened ~= true then release(); return failure("The world map could not be opened.") end
    lastFailure = nil
    return true
end

function Bridge.Navigate(questID, expectedQuest)
    local ok, success, reason = pcall(navigate, questID, expectedQuest)
    if not ok then
        pcall(release)
        return failure("Questie navigation failed; normal navigation is retained.")
    end
    return success, reason
end

function Bridge.SetMode(mode)
    if not ns.Readable(mode) or (mode ~= "hide" and mode ~= "next" and mode ~= "all") then
        return failure("Use locations hide, next, or all.")
    end
    local reason = blocked()
    if reason then return failure(reason) end
    local db = settings()
    if not db then return failure("Settings are still loading.") end
    db.mode = mode
    if active then return Bridge.Navigate(active.id, active.expected) end
    return true
end

function Bridge.SetEnabled(enabled)
    if type(enabled) ~= "boolean" then return failure("Navigation enabled must be true or false.") end
    local reason = blocked()
    if reason then return failure(reason) end
    local db = settings()
    if not db then return failure("Settings are still loading.") end
    db.enabled = enabled
    if not enabled then release(); restoreTitles(); lastFailure = nil; return true end
    return Bridge.Install()
end

function Bridge.Status()
    local readiness = installed and "shape guarded" or "unavailable"
    local text = "Questie " .. version .. " / DB " .. databaseVersion .. ": " .. readiness
        .. "; " .. (Bridge.IsEnabled() and "enabled" or "disabled") .. "; locations " .. Bridge.GetMode() .. "."
    local detail = active and ("Selected quest: " .. tostring(active.count) .. " rendered checkpoint(s).") or ""
    if lastFailure then detail = detail .. (detail ~= "" and " " or "") .. lastFailure end
    if detail ~= "" then text = text .. "\n" .. detail end
    return text
end

function Bridge.GetAvailability()
    return installed == true, lastFailure
end

local function resume()
    if not ns.db or blocked() then return end
    if pendingRestore then release() end
    if Bridge.Install() and active then scheduleRefresh() end
end

ns.On("PLAYER_LOGIN", resume)
ns.On("ADDON_LOADED", function(_, name)
    if ns.Readable(name) and (name == "Questie" or name == "QuestieDB") then resume() end
end)
ns.On("PLAYER_REGEN_ENABLED", resume)
ns.On("QUEST_LOG_UPDATE", function()
    if not installed then resume() elseif active then scheduleRefresh() end
end)
ns.On("GAME_PAD_ACTIVE_CHANGED", function()
    if blocked() then pendingRestore = true else resume() end
end)
