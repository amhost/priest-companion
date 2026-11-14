local addonName, ns = ...

-- Runtime-only guide pins. The user's route is not a quest-availability check.
-- Coordinates come from explicit guide points or the loaded, corrected Questie
-- data. HBD owns placement; this module owns only frames under its unique ref.
local Waypoints = {}
ns.GuideWaypoints = Waypoints
local OWNER, MAX_PINS, MAX_STEPS = {}, 24, 128
local pool, currentProvider, pending, desired = {}, nil, nil, nil
local lastMessage, lastInfo = "Guide markers hidden.", {rendered=0, unmapped=0, capped=0}

local function readableTable(value) return ns.Readable(value) and type(value) == "table" end
local function id(value)
    value = ns.Number(value)
    return value and value > 0 and value % 1 == 0 and value or nil
end
local function text(value, fallback)
    local clean = ns.CleanText(value, 240)
    return clean ~= "" and clean or fallback
end
local function provider()
    local bridge = ns.QuestieBridge
    if not readableTable(bridge) or type(bridge.GetMapProvider) ~= "function" then
        return nil, "Questie map support is unavailable. Enable Questie and QuestieDB in AddOns."
    end
    local ok, value, reason = pcall(bridge.GetMapProvider)
    if not ok or not readableTable(value) then
        return nil, reason or "Questie map support is still loading. Try Map again after login."
    end
    return value
end

local function point(p, uiMapID, x, y, label, provenance, areaID)
    uiMapID, x, y = id(uiMapID), ns.Number(x), ns.Number(y)
    if not uiMapID or not x or not y or x < 0 or x > 1 or y < 0 or y > 1 then return nil end
    local wx, wy, instance = ns.Call(p.hbd.GetWorldCoordinatesFromZone, p.hbd, x, y, uiMapID)
    wx, wy, instance = ns.Number(wx), ns.Number(wy), ns.Number(instance)
    if not wx or not wy or not instance then return nil end
    return {uiMapID=uiMapID, x=x, y=y, worldX=wx, worldY=wy, instance=instance,
        label=label, provenance=provenance, areaID=areaID}
end

local function mapForArea(p, area)
    area = id(area)
    if not area or not readableTable(p.zones) then return nil end
    return id(ns.Call(p.zones.GetUiMapIdByAreaId, p.zones, area))
end

local function playerPosition(p)
    local x, y, instance = ns.Call(p.hbd.GetPlayerWorldPosition, p.hbd)
    x, y, instance = ns.Number(x), ns.Number(y), ns.Number(instance)
    if x and y and instance then return {worldX=x, worldY=y, instance=instance} end
end

local function nearest(points, anchor)
    table.sort(points, function(a, b)
        if a.uiMapID ~= b.uiMapID then return a.uiMapID < b.uiMapID end
        if a.x ~= b.x then return a.x < b.x end
        return a.y < b.y
    end)
    local best, bestDistance, bestSame
    for _, candidate in ipairs(points) do
        local same = anchor and candidate.instance == anchor.instance or false
        local distance = same and ((candidate.worldX-anchor.worldX)^2 + (candidate.worldY-anchor.worldY)^2) or math.huge
        if not best or (same and not bestSame) or (same == bestSame and distance < bestDistance) then
            best, bestDistance, bestSame = candidate, distance, same
        end
    end
    return best
end

local function query(p, kind, entityID, field)
    entityID = id(entityID)
    if not entityID or not readableTable(p.db) then return nil end
    -- Questie aliases these directly to LibQuestieDB.*.Get: no implicit self.
    local value = ns.Call(p.db["Query" .. kind .. "Single"], entityID, field)
    return ns.Readable(value) and value or nil
end

local function phaseVisible(p, phase)
    if not ns.Readable(phase) then return false end
    if phase == nil then return true end
    if not ns.Number(phase) or not readableTable(p.phasing) then return false end
    local visible = ns.Call(p.phasing.IsSpawnVisible, phase)
    return ns.Readable(visible) and visible == true
end

local function entityPoints(p, kind, entityID, result)
    local spawns = query(p, kind, entityID, "spawns")
    if not readableTable(spawns) then return end
    for area, coordinates in pairs(spawns) do
        local map = mapForArea(p, area)
        if map and readableTable(coordinates) then
            for _, tuple in ipairs(coordinates) do
                if readableTable(tuple) and phaseVisible(p, tuple[3]) then
                    local x, y = ns.Number(tuple[1]), ns.Number(tuple[2])
                    local value = x and y and point(p, map, x/100, y/100, nil, "QuestieDB", area)
                    if value then result[#result + 1] = value end
                end
            end
        end
    end
end

local function entityList(p, kind, list, result)
    if not readableTable(list) then return end
    for _, entityID in ipairs(list) do entityPoints(p, kind, entityID, result) end
end

local function itemPoints(p, itemID, result, seen, depth)
    itemID = id(itemID)
    if not itemID or seen[itemID] or depth > 3 then return end
    seen[itemID] = true
    entityList(p, "NPC", query(p, "Item", itemID, "npcDrops"), result)
    entityList(p, "Object", query(p, "Item", itemID, "objectDrops"), result)
    entityList(p, "NPC", query(p, "Item", itemID, "vendors"), result)
    local containers = query(p, "Item", itemID, "itemDrops")
    if readableTable(containers) then
        for _, container in ipairs(containers) do itemPoints(p, container, result, seen, depth + 1) end
    end
end

local function actionGroup(p, questID, kind)
    local values = query(p, "Quest", questID, kind == "accept" and "startedBy" or "finishedBy")
    local result = {}
    if readableTable(values) then
        entityList(p, "NPC", values[1], result)
        entityList(p, "Object", values[2], result)
        if kind == "accept" and readableTable(values[3]) then
            for _, itemID in ipairs(values[3]) do itemPoints(p, itemID, result, {}, 0) end
        end
    end
    return result
end

local function objectiveGroups(p, questID)
    local bridge = ns.QuestieBridge
    local live = readableTable(bridge) and ns.Call(bridge.GetObjectiveLocations, questID)
    if readableTable(live) then
        local result = {}
        for _, locations in ipairs(live) do
            local group = {}
            if readableTable(locations) then
                for _, value in ipairs(locations) do
                    if readableTable(value) then
                        local mapped = point(p, value.uiMapID, value.x, value.y, nil, "Questie")
                        if mapped then group[#group + 1] = mapped end
                    end
                end
            end
            result[#result + 1] = group
        end
        return result
    end
    local objectives = query(p, "Quest", questID, "objectives")
    if not readableTable(objectives) then return {} end
    local result = {}
    for _, category in ipairs({1, 2, 3, 5}) do
        local entries = objectives[category]
        if readableTable(entries) then
            for _, entry in ipairs(entries) do
                local group = {}
                if readableTable(entry) then
                    if category == 1 then entityPoints(p, "NPC", entry[1], group)
                    elseif category == 2 then entityPoints(p, "Object", entry[1], group)
                    elseif category == 3 then itemPoints(p, entry[1], group, {}, 0)
                    else entityList(p, "NPC", entry[1], group) end
                end
                result[#result + 1] = group
            end
        end
    end
    -- Reputation and spell objectives do not identify a reliable destination.
    if not ns.Readable(objectives[4]) or objectives[4] ~= nil then result[#result + 1] = {} end
    if readableTable(objectives[6]) then
        for _ in ipairs(objectives[6]) do result[#result + 1] = {} end
    end
    return result
end

local function resolve(step, p, anchor)
    local result, missing = {}, 0
    if not readableTable(step) then return result, "The guide step is unreadable.", {unmapped=1} end
    local label = text(step.text, "Guide step")
    local function choose(candidates)
        local selected = nearest(candidates, anchor)
        if selected then
            selected.stepID, selected.label = text(step.id, "step"), selected.label or label
            result[#result + 1] = selected
            anchor = selected
        else missing = missing + 1 end
    end
    -- A supplied location describes this exact action. Never substitute a broad
    -- whole-quest location when that explicit point cannot be converted.
    if readableTable(step.points) and #step.points > 0 then
        for _, supplied in ipairs(step.points) do
            local mapped
            if readableTable(supplied) then
                mapped = point(p, mapForArea(p, supplied.areaID), supplied.x, supplied.y,
                    text(supplied.label, label), "user", id(supplied.areaID))
            end
            choose(mapped and {mapped} or {})
        end
    elseif readableTable(step.questIDs) and ns.Readable(step.kind)
        and (step.kind == "accept" or step.kind == "turnin" or step.kind == "objective") then
        for _, questID in ipairs(step.questIDs) do
            if step.kind == "objective" then
                local groups = objectiveGroups(p, questID)
                if #groups == 0 then missing = missing + 1 end
                for _, group in ipairs(groups) do choose(group) end
            else choose(actionGroup(p, questID, step.kind)) end
        end
    end
    local reason
    if #result == 0 then reason = "No mapped location for this step in the loaded Questie data. Follow the written instruction."
    elseif missing > 0 then reason = "Some objectives have no mapped location. Follow the written instruction for those actions." end
    return result, reason, {unmapped=missing, anchor=anchor}
end

-- Resolves a step without opening a map, making frames, or changing progress.
function Waypoints.ResolveStep(step)
    if ns.IsCombat() then return {}, "Map locations will resolve after combat.", {unmapped=1, deferred=true} end
    local p, reason = provider()
    if not p then return {}, reason, {unmapped=1} end
    local ok, points, why, info = pcall(resolve, step, p, playerPosition(p))
    if not ok then return {}, "Questie location data changed or is not ready. Try Map again after login.", {unmapped=1} end
    return points, why, info
end

local function clearOwned()
    if ns.IsCombat() then return false end
    local ok = true
    if currentProvider then
        local pins = currentProvider.hbdPins
        local world = pcall(pins.RemoveAllWorldMapIcons, pins, OWNER)
        local mini = pcall(pins.RemoveAllMinimapIcons, pins, OWNER)
        ok = world and mini
    end
    local owner = GameTooltip and ns.Call(GameTooltip.GetOwner, GameTooltip)
    for _, pair in ipairs(pool) do
        pair.world:Hide(); pair.mini:Hide()
        if owner == pair.world or owner == pair.mini then GameTooltip:Hide() end
    end
    if ok then currentProvider = nil end
    return ok
end

local function tooltip(frame)
    if not GameTooltip or not frame.guidePoint then return end
    local value = frame.guidePoint
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Guide location " .. value.ordinal)
    if type(GameTooltip.AddLine) == "function" then
        for _, visit in ipairs(value.visits) do GameTooltip:AddLine(visit, 1, 1, 1, true) end
        GameTooltip:AddLine(value.provenance == "user" and "User route coordinate; confirm in game."
            or "Route hint from loaded Questie data; quest availability is not checked.", 1, 0.82, 0, true)
    end
    GameTooltip:Show()
end

local function frame()
    local value = CreateFrame("Frame", nil, UIParent)
    value:Hide()
    value:EnableMouse(true)
    value.icon = value:CreateTexture(nil, "ARTWORK")
    value.icon:SetAllPoints(value)
    value.icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    value.label = value:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    value.label:SetPoint("CENTER", value, "CENTER", 0, -8)
    value.label:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    value:SetScript("OnEnter", tooltip)
    value:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    return value
end

local function marker(index, value)
    if not pool[index] then pool[index] = {world=frame(), mini=frame()} end
    local pair = pool[index]
    for _, icon in ipairs({pair.world, pair.mini}) do
        icon.guidePoint = value
        icon:SetSize(value.current and 24 or 19, value.current and 24 or 19)
        icon.icon:SetVertexColor(1, value.current and 1 or 0.85, value.current and 1 or 0.55)
        icon.label:SetText(tostring(value.ordinal))
        icon.label:SetTextColor(value.current and 1 or 0.9, value.current and 0.82 or 0.9, value.current and 0 or 0.9)
        icon.UiMapID, icon.x, icon.y = value.uiMapID, value.x * 100, value.y * 100
    end
    return pair
end

local function summary(info)
    local result = tostring(info.rendered) .. " guide location(s)"
    if info.unmapped > 0 then result = result .. "; " .. info.unmapped .. " step(s) unmapped" end
    if info.partial > 0 then result = result .. "; " .. info.partial .. " step(s) partly mapped" end
    if info.capped > 0 then result = result .. "; " .. info.capped .. " step(s) beyond the 24-marker limit" end
    return result .. ". Route hints; follow the checklist."
end

local function showNow(steps, options)
    if not clearOwned() then return false, "Guide markers could not be cleared. Reload before retrying.", {rendered=0, unmapped=0, capped=0} end
    local p, reason = provider()
    if not p then return false, reason, {rendered=0, unmapped=0, capped=0} end
    local info = {rendered=0, unmapped=0, capped=0, partial=0, unmappedIDs={}, cappedIDs={}, mappedSteps=0}
    local points, byPosition = {}, {}
    local anchor, focus = playerPosition(p), options.focusStepID or (steps[1] and steps[1].id)
    local limit = options.mode == "current" and math.min(1, #steps) or math.min(MAX_STEPS, #steps)
    for index = 1, limit do
        local step = steps[index]
        local resolved, _, detail = resolve(step, p, anchor)
        local stepID = readableTable(step) and text(step.id, tostring(index)) or tostring(index)
        if #resolved == 0 then
            info.unmapped = info.unmapped + 1; info.unmappedIDs[#info.unmappedIDs + 1] = stepID
        else
            local capped = false
            info.mappedSteps = info.mappedSteps + 1
            if detail.unmapped > 0 then info.partial = info.partial + 1 end
            for _, value in ipairs(resolved) do
                local key = string.format("%d:%.8f:%.8f", value.uiMapID, value.x, value.y)
                local existing = byPosition[key]
                if existing then
                    existing.visits[#existing.visits + 1] = value.label
                    existing.current = existing.current or value.stepID == focus
                elseif #points < MAX_PINS then
                    value.ordinal, value.current, value.visits = #points + 1, value.stepID == focus, {value.label}
                    points[#points + 1], byPosition[key] = value, value
                else capped = true end
            end
            if capped then info.capped = info.capped + 1; info.cappedIDs[#info.cappedIDs + 1] = stepID end
            anchor = detail.anchor or anchor
        end
    end
    if options.mode == "route" and #steps > MAX_STEPS then info.capped = info.capped + #steps - MAX_STEPS end
    if #points == 0 then return false, "No guide locations are mapped. Use the written steps and check that QuestieDB loaded.", info end
    currentProvider = p
    for index, value in ipairs(points) do
        local pair = marker(index, value)
        p.hbdPins:AddWorldMapIconMap(OWNER, pair.world, value.uiMapID, value.x, value.y, -1, "PIN_FRAME_LEVEL_AREA_POI")
        p.hbdPins:AddMinimapIconMap(OWNER, pair.mini, value.uiMapID, value.x, value.y, false, false)
    end
    info.rendered = #points
    if options.openMap then
        local destination = points[1]
        for _, value in ipairs(points) do if value.current then destination = value; break end end
        if ns.Call(p.compat.OpenWorldMap, destination.uiMapID) ~= true then
            clearOwned(); info.rendered = 0
            return false, "The world map could not be opened. Try Map again outside combat.", info
        end
    end
    return true, summary(info), info
end

function Waypoints.Clear()
    desired = nil
    if ns.IsCombat() then
        pending = {hide=true}
        lastMessage, lastInfo = "Guide marker cleanup waits until combat ends.", {rendered=lastInfo.rendered, deferred=true, unmapped=0, capped=0}
        return false
    end
    pending = nil
    local ok = clearOwned()
    lastMessage = ok and "Guide markers hidden." or "Guide markers could not be cleared. Reload before retrying."
    lastInfo = {rendered=0, unmapped=0, capped=0}
    return ok
end

function Waypoints.Show(steps, options)
    options = readableTable(options) and options or {}
    local mode = ns.Readable(options.mode) and options.mode or "current"
    if mode == "hide" then local ok = Waypoints.Clear(); return ok, lastMessage, lastInfo end
    if mode ~= "current" and mode ~= "route" then
        Waypoints.Clear(); lastMessage = "Choose Current, Route, or Hide for guide locations."
        return false, lastMessage, lastInfo
    end
    if not readableTable(steps) then
        Waypoints.Clear(); lastMessage = "Choose a readable guide step first."
        return false, lastMessage, lastInfo
    end
    local focus = ns.Readable(options.focusStepID) and type(options.focusStepID) == "string" and options.focusStepID or nil
    local request = {steps=steps, options={mode=mode, openMap=ns.Readable(options.openMap) and options.openMap == true,
        focusStepID=focus}}
    desired = request
    if ns.IsCombat() then
        pending = request
        lastMessage, lastInfo = "Guide markers will update after combat.", {rendered=lastInfo.rendered, unmapped=0, capped=0, deferred=true}
        return false, lastMessage, lastInfo
    end
    pending = nil
    local ok, success, message, info = pcall(showNow, request.steps, request.options)
    if not ok then
        pcall(clearOwned)
        success, message, info = false, "Guide marker data changed or could not be drawn. Check Questie, then try Map again.", {rendered=0, unmapped=0, capped=0}
    end
    lastMessage, lastInfo = message, info
    return success, message, info
end

function Waypoints.Status() return lastMessage, lastInfo end

ns.On("PLAYER_REGEN_ENABLED", function()
    local request = pending
    pending = nil
    if request then
        if request.hide then Waypoints.Clear() else Waypoints.Show(request.steps, request.options) end
        if type(ns.Refresh) == "function" then ns.Refresh("guide") end
    end
end)

-- Re-read phase and objective data after world/quest changes. Never reopen the
-- map during automatic refresh and never create a competing personal waypoint.
local function refresh()
    if not desired then return end
    local request = desired
    Waypoints.Show(request.steps, {mode=request.options.mode, focusStepID=request.options.focusStepID, openMap=false})
end
ns.On("PLAYER_ENTERING_WORLD", refresh)
ns.On("QUEST_LOG_UPDATE", refresh)
