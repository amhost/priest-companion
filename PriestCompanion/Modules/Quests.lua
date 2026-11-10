local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Quests = Model

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function positiveID(value)
    local number = ns.Number(value, nil)
    if number and number > 0 and number == math.floor(number) then
        return number
    end
end

local function settings()
    return ns.ModuleDB("quests", { selectedQuestID = 0, autoAccept = false })
end

-- Ordinary quest acceptance follows the client's QUEST_DETAIL/AcceptQuest flow.
-- No Blizzard frame hooks, synthetic clicks, gossip selection or retry timers.
local autoAcceptFunctions = {
    "AcceptQuest", "GetQuestID", "IsShiftKeyDown", "InCombatLockdown",
    "UnitExists", "UnitIsPlayer", "QuestGetAutoAccept", "QuestFlagsPVP",
    "QuestIsFromAdventureMap", "QuestIsFromAreaTrigger",
}
local autoAcceptState = {}
local autoAcceptEventsAvailable = false

function Model.AutoAcceptCapable(api)
    if not readableTable(api) then return false end
    for _, name in ipairs(autoAcceptFunctions) do
        if not ns.Readable(api[name]) or type(api[name]) ~= "function" then return false end
    end
    return true
end

local function readBoolean(fn, ...)
    local value = ns.Call(fn, ...)
    if ns.Readable(value) and type(value) == "boolean" then return value end
    return nil
end

function Model.TryAutoAccept(state, enabled, api, event, questStartItemID)
    if not ns.Readable(enabled) or enabled ~= true then return false, "off" end
    if not ns.Readable(event) or event ~= "QUEST_DETAIL" then return false, "event" end
    if not readableTable(state) or not Model.AutoAcceptCapable(api) then return false, "unavailable" end
    local id = positiveID(ns.Call(api.GetQuestID))
    if not id then return false, "unavailable" end
    if state.questID == id then return false, state.status end
    -- A bypass or failed call stays manual for this displayed offer, even if a
    -- duplicate QUEST_DETAIL arrives after Shift is released or combat ends.
    state.questID, state.status = id, "unavailable"
    local shifted = readBoolean(api.IsShiftKeyDown)
    local combat = readBoolean(api.InCombatLockdown)
    if shifted == nil or combat == nil then return false, state.status end
    if shifted then state.status = "shift"; return false, state.status end
    if combat then state.status = "combat"; return false, state.status end
    if not ns.Readable(questStartItemID) then return false, state.status end
    if questStartItemID ~= nil and ns.Number(questStartItemID, nil) ~= 0 then
        state.status = "special"; return false, state.status
    end
    for _, name in ipairs({ "QuestGetAutoAccept", "QuestFlagsPVP", "QuestIsFromAdventureMap", "QuestIsFromAreaTrigger" }) do
        local special = readBoolean(api[name])
        if special == nil then return false, state.status end
        if special then state.status = "special"; return false, state.status end
    end
    -- The native quest frame uses questnpc for its giver. Require a readable,
    -- existing non-player giver; shared/remote/item offers remain manual.
    local exists = readBoolean(api.UnitExists, "questnpc")
    local player = readBoolean(api.UnitIsPlayer, "questnpc")
    if exists == nil or player == nil then return false, state.status end
    if not exists or player then state.status = "manual"; return false, state.status end
    state.status = "requested"
    local ok = pcall(api.AcceptQuest)
    if not ok then state.status = "failed" end
    -- A successful call is only a request, not proof that the server accepted it.
    return ok, state.status
end

local function autoAcceptAPI()
    local api = {}
    for _, name in ipairs(autoAcceptFunctions) do api[name] = _G[name] end
    return api
end

local autoAcceptNotes = {
    shift = "Shift bypass: accept this offer manually.",
    combat = "Skipped in combat; accept this offer manually.",
    special = "Special quest flow left for manual acceptance.",
    manual = "Shared or unknown giver; accept manually.",
    unavailable = "Quest data unavailable or restricted; accept manually.",
    requested = "Acceptance requested. Hold Shift to read future offers.",
    failed = "Acceptance request failed; use the game's Accept button.",
}

function Model.CopyObjectives(raw)
    if not readableTable(raw) then return {}, false end
    local result = {}
    for index = 1, 100 do
        local objective = raw[index]
        if not ns.Readable(objective) then return result, false end
        if objective == nil then return result, true end
        if type(objective) == "table" then
            local finished
            if ns.Readable(objective.finished) and type(objective.finished) == "boolean" then
                finished = objective.finished
            end
            local fulfilled = ns.Number(objective.numFulfilled, nil)
            local required = ns.Number(objective.numRequired, nil)
            result[#result + 1] = {
                text = ns.Text(objective.text, "Objective details unavailable"),
                kind = ns.Text(objective.type, ""),
                finished = finished,
                fulfilled = fulfilled and math.max(0, fulfilled) or nil,
                required = required and math.max(0, required) or nil,
            }
        else
            return result, false
        end
    end
    return result, false
end

function Model.CopyQuest(raw, logIndex, objectives, complete)
    if not readableTable(raw) then return nil end
    if not ns.Readable(raw.isHeader) or not ns.Readable(raw.isHidden) then return nil end
    if raw.isHeader == true or raw.isHidden == true then return nil end
    local id = positiveID(raw.questID)
    if not id then return nil end
    local copied, available = Model.CopyObjectives(objectives)
    local isComplete
    if ns.Readable(complete) and type(complete) == "boolean" then isComplete = complete end
    return {
        id = id,
        logIndex = ns.Number(logIndex, 0),
        title = ns.Text(raw.title, "Quest " .. id),
        level = ns.Number(raw.level, nil),
        complete = isComplete,
        objectives = copied,
        objectivesAvailable = available,
    }
end

function Model.Waypoint(mapID, x, y)
    local id = positiveID(mapID)
    local px, py = ns.Number(x, nil), ns.Number(y, nil)
    if not id or not px or not py or px < 0 or px > 1 or py < 0 or py > 1 then
        return nil
    end
    return { mapID = id, x = px, y = py }
end

function Model.FindWaypoint(rows, questID, sourceMapID)
    local id = positiveID(questID)
    if not id or not readableTable(rows) then return nil end
    for index = 1, 1000 do
        local row = rows[index]
        if not ns.Readable(row) then return nil end
        if row == nil then break end
        if type(row) == "table" and positiveID(row.questID) == id then
            local mapID = row.mapID
            if ns.Readable(mapID) and mapID == nil then mapID = sourceMapID end
            local point = Model.Waypoint(mapID, row.x, row.y)
            if point then return point end
        end
    end
end

function Model.ObjectiveText(quest)
    local lines = {}
    for _, objective in ipairs(quest.objectives) do
        local prefix = objective.finished == true and "[Done] " or ""
        lines[#lines + 1] = prefix .. objective.text
    end
    if not quest.objectivesAvailable then
        lines[#lines + 1] = "Objective data unavailable."
    elseif #lines == 0 then
        lines[1] = quest.complete and "Ready to turn in." or "Open quest details for instructions."
    end
    return table.concat(lines, "\n")
end

local function questAPI()
    if readableTable(C_QuestLog) then return C_QuestLog end
    return nil
end

function Model.ReadLog(api)
    if not readableTable(api) or type(api.GetNumQuestLogEntries) ~= "function" or type(api.GetInfo) ~= "function" then
        return {}, "Quest log API unavailable."
    end
    local entries = ns.Number(ns.Call(api.GetNumQuestLogEntries), nil)
    if not entries or entries < 0 then return {}, "Quest log unavailable or restricted." end
    local quests, unavailable = {}, 0
    local limit = math.min(math.floor(entries), 1000)
    for index = 1, limit do
        local info = ns.Call(api.GetInfo, index)
        if readableTable(info) and ns.Readable(info.isHeader) and ns.Readable(info.isHidden) then
            if info.isHeader ~= true and info.isHidden ~= true then
                local id = positiveID(info.questID)
                if id then
                    local objectives = ns.Call(api.GetQuestObjectives, id)
                    local complete = ns.Call(api.IsComplete, id)
                    local quest = Model.CopyQuest(info, index, objectives, complete)
                    if quest then quests[#quests + 1] = quest else unavailable = unavailable + 1 end
                else
                    unavailable = unavailable + 1
                end
            end
        else
            unavailable = unavailable + 1
        end
    end
    if entries > limit then return quests, "Showing the first 1,000 log entries." end
    if unavailable > 0 then
        if #quests == 0 then return quests, "Quest log entries unavailable or restricted." end
        return quests, #quests .. " logged quests. Some entries are unavailable."
    end
    if #quests == 0 then return quests, "No visible quests in your current log." end
    return quests, #quests .. " logged quests. Select one below."
end

local function selectedQuest(self)
    local db = settings()
    local selected = positiveID(db.selectedQuestID)
    for _, quest in ipairs(self.quests or {}) do
        if quest.id == selected then return quest end
    end
    return nil
end

local function ensureMapLoaded()
    if not WorldMapFrame and readableTable(C_AddOns) then
        ns.Call(C_AddOns.LoadAddOn, "Blizzard_WorldMap")
    end
end

local function openDetails(self)
    if ns.IsCombat() then ns.Notify("Open quest details after combat."); return end
    local quest = selectedQuest(self)
    if not quest then ns.Notify("Select a logged quest first."); return end
    ensureMapLoaded()
    if type(QuestMapFrame_OpenToQuestDetails) == "function" then
        ns.Call(QuestMapFrame_OpenToQuestDetails, quest.id)
        return
    end
    -- The copy panel remains useful when this client has no compatible map helper.
    ns.UI.MakeCopyBox(quest.title, Model.ObjectiveText(quest))
end

local function findLiveWaypoint(id)
    local api = questAPI()
    if not api then return nil end
    local mapID, x, y = ns.Call(api.GetNextWaypoint, id)
    local point = Model.Waypoint(mapID, x, y)
    if point then return point end
    if readableTable(C_Map) then
        local currentMap = positiveID(ns.Call(C_Map.GetBestMapForUnit, "player"))
        if currentMap then
            return Model.FindWaypoint(ns.Call(api.GetQuestsOnMap, currentMap), id, currentMap)
        end
    end
end

local function openMap(self)
    if ns.IsCombat() then ns.Notify("Open quest navigation after combat."); return end
    local quest = selectedQuest(self)
    if not quest then ns.Notify("Select a logged quest first."); return end
    local point = findLiveWaypoint(quest.id)
    if not point then
        ns.Notify("This quest has no readable client-provided location. Open Details for its instructions.")
        return
    end
    ensureMapLoaded()
    local placed = false
    if readableTable(C_Map) and type(C_Map.SetUserWaypoint) == "function"
        and readableTable(UiMapPoint) and type(UiMapPoint.CreateFromCoordinates) == "function" then
        local mapPoint = ns.Call(UiMapPoint.CreateFromCoordinates, point.mapID, point.x, point.y)
        if readableTable(mapPoint) then
            local ok = pcall(C_Map.SetUserWaypoint, mapPoint)
            placed = ok
            if placed and readableTable(C_SuperTrack) then ns.Call(C_SuperTrack.SetSuperTrackedUserWaypoint, true) end
        end
    end
    if WorldMapFrame and type(WorldMapFrame.SetMapID) == "function" then
        ns.Call(WorldMapFrame.SetMapID, WorldMapFrame, point.mapID)
        ns.Call(WorldMapFrame.Show, WorldMapFrame)
    elseif not placed then
        ns.Notify("Map location: " .. string.format("%.1f, %.1f", point.x * 100, point.y * 100)
            .. " (map " .. point.mapID .. "). Map controls are unavailable.")
    end
end

local function updateWidths(self)
    if not self.scroll then return end
    local width = math.max(220, ns.Number(self.scroll:GetWidth(), 350) - 20)
    self.content:SetWidth(width)
    local bodyWidth = math.max(220, ns.Number(self.body:GetWidth(), 380) - 20)
    self.summary:SetWidth(bodyWidth)
    self.autoAccept.label:SetWidth(bodyWidth - 26)
    self.autoAcceptNote:SetWidth(bodyWidth)
    for _, row in ipairs(self.rows) do
        row.button:SetWidth(width - 12)
        if row.button.label then row.button.label:SetWidth(width - 22) end
        row.text:SetWidth(width - 16)
    end
end

local Module = {
    id = "quests", title = "Quest Helper",
    description = "Current quest objectives and the map locations supplied by your client.",
    width = 400, height = 430, minWidth = 320, minHeight = 300,
    defaultEnabled = { Healing = false, Leveling = true },
}

function Module:Create()
    self.rows = {}
    self.summary = ns.UI.Text(self.body, "Loading quest log...", 8, 6, 12, 370)
    self.autoAccept = ns.UI.Check(self.body, "Auto-accept NPC quests", 6, 32, function(checked)
        settings().autoAccept = checked == true
        autoAcceptState = {}
        ns.Refresh("quests")
    end)
    self.autoAcceptNote = ns.UI.Text(self.body, "Hold Shift when opening an offer to read it.", 8, 58, 10, 370, { 0.68, 0.73, 0.8 })
    ns.UI.Tooltip(self.autoAccept, "Off by default. Accepts an ordinary NPC quest when its offer opens, outside combat. Hold Shift while opening it to keep it manual. Shared/unknown givers, special offers, PvP confirmations, turn-ins, rewards and gossip choices stay manual. This setting applies in both layouts, even when this panel is hidden.")
    self.scroll, self.content = ns.UI.ScrollArea(self.body, 90, 66)
    self.details = ns.UI.Button(self.body, "Details", 8, 0, 90, 24, function() openDetails(self) end)
    self.map = ns.UI.Button(self.body, "Map", 104, 0, 90, 24, function() openMap(self) end)
    self.refresh = ns.UI.Button(self.body, "Refresh", 200, 0, 90, 24, function() ns.Refresh("quests") end)
    for index, button in ipairs({ self.details, self.map, self.refresh }) do
        button:ClearAllPoints()
        button:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 8 + (index - 1) * 96, 31)
    end
    self.note = ns.UI.Text(self.body, "Locations come from the game; some quests have none.", 8, 0, 10, 370, { 0.68, 0.73, 0.8 })
    self.note:ClearAllPoints()
    self.note:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 8, 6)
    self.note:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -8, 6)
    ns.UI.Tooltip(self.map, "Show this quest's next location from the game. This replaces your personal map waypoint when supported.")
    self.body:HookScript("OnSizeChanged", function() ns.Refresh("quests") end)
end

function Module:Refresh()
    if not self.summary then return end
    local quests, status = Model.ReadLog(questAPI())
    self.quests = quests
    local db = settings()
    if not selectedQuest(self) then db.selectedQuestID = quests[1] and quests[1].id or 0 end
    local selected = positiveID(db.selectedQuestID)
    self.summary:SetText(status)
    local enabled = ns.Readable(db.autoAccept) and db.autoAccept == true
    local capable = autoAcceptEventsAvailable and Model.AutoAcceptCapable(autoAcceptAPI())
    self.autoAccept:SetChecked(enabled)
    if capable or enabled then self.autoAccept:Enable() else self.autoAccept:Disable() end
    self.autoAcceptNote:SetText(not capable and "Unavailable on this client; use the game's Accept button."
        or (enabled and autoAcceptNotes[autoAcceptState.status]) or "Hold Shift when opening an offer to read it.")
    updateWidths(self)
    local checkY = ns.Number(self.summary:GetStringHeight(), 25) + 14
    self.autoAccept:ClearAllPoints()
    self.autoAccept:SetPoint("TOPLEFT", self.body, "TOPLEFT", 6, -checkY)
    local noteY = checkY + math.max(24, ns.Number(self.autoAccept.label:GetStringHeight(), 15) + 8)
    self.autoAcceptNote:ClearAllPoints()
    self.autoAcceptNote:SetPoint("TOPLEFT", self.body, "TOPLEFT", 8, -noteY)
    local scrollTop = noteY + ns.Number(self.autoAcceptNote:GetStringHeight(), 16) + 12
    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -scrollTop)
    self.scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, 66)
    local width = math.max(220, ns.Number(self.scroll:GetWidth(), 350) - 20)
    local y = 0
    for index, quest in ipairs(quests) do
        local row = self.rows[index]
        if not row then
            row = {}
            row.button = ns.UI.Button(self.content, "", 6, 0, width - 12, 26, function()
                if row.questID then
                    settings().selectedQuestID = row.questID
                    ns.Refresh("quests")
                end
            end)
            row.text = ns.UI.Text(self.content, "", 8, 0, 11, width - 16)
            if row.button.label then
                row.button.label:SetWordWrap(false)
                ns.Call(row.button.label.SetMaxLines, row.button.label, 1)
            end
            ns.UI.Tooltip(row.button, function() return row.tooltip end)
            self.rows[index] = row
        end
        row.questID = quest.id
        row.button:ClearAllPoints()
        row.button:SetPoint("TOPLEFT", self.content, "TOPLEFT", 6, -y)
        row.button:SetWidth(width - 12)
        if row.button.label then row.button.label:SetWidth(width - 22) end
        local prefix = quest.id == selected and "> " or ""
        local suffix = quest.complete == true and " [Done]" or ""
        row.button:SetText(prefix .. quest.title .. suffix)
        row.button:Show()
        row.tooltip = quest.title .. "\n" .. Model.ObjectiveText(quest)
        row.text:ClearAllPoints()
        row.text:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, -(y + 30))
        row.text:SetWidth(width - 16)
        row.text:SetText(Model.ObjectiveText(quest))
        row.text:Show()
        local textHeight = ns.Number(row.text:GetStringHeight(), 24)
        y = y + 40 + math.max(20, textHeight)
    end
    for index = #quests + 1, #self.rows do
        self.rows[index].button:Hide()
        self.rows[index].text:Hide()
    end
    self.content:SetHeight(math.max(1, y))
    if selected then self.details:Enable(); self.map:Enable() else self.details:Disable(); self.map:Disable() end
end

ns.RegisterModule(Module)
local detailEvent = ns.On("QUEST_DETAIL", function(event, questStartItemID)
    if not ns.ready or not autoAcceptEventsAvailable then return end
    Model.TryAutoAccept(autoAcceptState, settings().autoAccept, autoAcceptAPI(), event, questStartItemID)
    ns.Refresh("quests")
end)
local finishedEvent = ns.On("QUEST_FINISHED", function()
    autoAcceptState = {}
    ns.Refresh("quests")
end)
autoAcceptEventsAvailable = detailEvent and finishedEvent
ns.On("PLAYER_ENTERING_WORLD", function() autoAcceptState = {} end)
for _, event in ipairs({ "QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_WATCH_UPDATE",
    "QUEST_TURNED_IN", "QUEST_DATA_LOAD_RESULT", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
    ns.On(event, function() ns.Refresh("quests") end)
end
