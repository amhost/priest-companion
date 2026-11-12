local addonName, ns = ...
local Model, catalog = ns.Models.DungeonQuests, ns.DungeonQuestCatalog
local UI = ns.UI
local defaults = { selected = "deadmines" }

local function selected()
    local db = ns.ModuleDB("dungeons", defaults)
    local dungeon = Model.Find(catalog, db.selected)
    if not dungeon then dungeon = catalog.dungeons[1]; db.selected = dungeon.key end
    return dungeon
end

local function api()
    if ns.Readable(C_QuestLog) and type(C_QuestLog) == "table" then return C_QuestLog end
end

local Module = {
    id = "dungeons", title = "Dungeon quests (prototype)",
    description = "Partial community catalog with live character progress. Pickup eligibility may be unknown.",
    width = 470, height = 580, minWidth = 390, minHeight = 450,
    defaultEnabled = { Healing = false, Leveling = false },
}

local function choose(self, offset)
    if ns.IsCombat() then ns.Notify("Select a dungeon after combat."); return end
    local _, index = Model.Find(catalog, selected().key)
    ns.ModuleDB("dungeons", defaults).selected = catalog.dungeons[(index - 1 + offset) % #catalog.dungeons + 1].key
    self.scroll:SetVerticalScroll(0)
    ns.Refresh("dungeons")
end

local function sources()
    local dungeon = selected()
    UI.MakeCopyBox("Dungeon quest provenance", dungeon.name .. "\n"
        .. "Partial community catalog. No dungeon data verified in a live client by this project.\n"
        .. "Source: " .. dungeon.source.name .. "\nLicense: MIT (LICENSE-ATT.txt)\n"
        .. "Revision: " .. dungeon.source.revision .. "\n" .. dungeon.source.url .. "\n\n"
        .. "Client progress does not validate dungeon assignment, pickup location, or prerequisites.\n"
        .. "Missing means absent from log and completion history for a client-resolved ID. It does not mean available to pick up.\n"
        .. "All sourceQuest annotations remain advisory; additional requirements may exist.\n"
        .. "Only The Deadmines, Hall of Thanes and Ragefire Chasm have prototype records.")
end

function Module:Create()
    ns.ModuleDB("dungeons", defaults)
    self.rows, self.requested = {}, {}
    self.heading = UI.Text(self.body, "", 8, 4, 14, 410)
    self.previous = UI.Button(self.body, "Previous", 8, 32, 84, 24, function() choose(self, -1) end)
    self.next = UI.Button(self.body, "Next", 98, 32, 70, 24, function() choose(self, 1) end)
    self.refresh = UI.Button(self.body, "Refresh", 174, 32, 82, 24, function()
        if ns.IsCombat() then ns.Notify("Refresh dungeon quests after combat."); return end
        self.requested = {}
        ns.Refresh("dungeons")
    end)
    self.source = UI.Button(self.body, "Sources", 262, 32, 80, 24, sources)
    self.summary = UI.Text(self.body, "", 8, 65, 11, 410)
    self.scroll, self.content = UI.ScrollArea(self.body, 160, 48)
    self.note = UI.Text(self.body, "Missing does not mean available. Only 3 dungeons covered.\nProvisional ATT Forever data; not live-verified.", 8, 0, 10, 410, {0.9, 0.76, 0.5})
    self.note:ClearAllPoints()
    self.note:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 8, 4)
    self.note:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -8, 4)
    self.body:HookScript("OnSizeChanged", function() ns.Refresh("dungeons") end)
end

function Module:Refresh()
    if ns.IsCombat() then
        self.summary:SetText("Paused in combat. Any rows below are the last out-of-combat snapshot.")
        return
    end
    local dungeon = selected()
    local currentAPI = api()
    local snapshot = Model.Snapshot(currentAPI, ns.Call(UnitFactionGroup, "player"), ns.Call(UnitLevel, "player"))
    local result = Model.Build(dungeon, snapshot)
    self.result = result
    local width = math.max(320, ns.Number(self.body:GetWidth(), 440) - 20)
    self.heading:SetWidth(width)
    self.heading:SetText(dungeon.name)
    self.summary:SetWidth(width)
    self.summary:SetText(result.coverage .. "\n"
        .. string.format("Catalog rows: %d Missing | %d In Log | %d Completed | %d Unknown",
            result.counts.Missing, result.counts["In Log"], result.counts.Completed, result.counts.Unknown))
    self.scroll:ClearAllPoints()
    local top = 65 + self.summary:GetStringHeight() + 12
    self.scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -top)
    self.scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, 48)
    local rowWidth = math.max(280, ns.Number(self.scroll:GetWidth(), 400) - 16)
    self.content:SetWidth(rowWidth + 8)
    local y = 0
    for index, row in ipairs(result.rows) do
        local label = self.rows[index]
        if not label then label = UI.Text(self.content, "", 8, 0, 11, rowWidth); self.rows[index] = label end
        local lines = { "[" .. row.status .. "] " .. row.title .. " (#" .. row.id .. ")" }
        if row.status == "In Log" then
            lines[#lines + 1] = row.ready and "Ready to turn in; still in quest log." or "Already accepted."
        elseif row.status == "Completed" then lines[#lines + 1] = "Client reports character completion."
        else
            lines[#lines + 1] = "Pickup: " .. row.eligibility .. " - " .. row.reason
            if row.status == "Unknown" then lines[#lines + 1] = "Log/completion data or client quest title unavailable." end
        end
        if row.giver then lines[#lines + 1] = "Community pickup: " .. row.giver end
        if row.pickup then lines[#lines + 1] = row.pickup end
        if row.prior then lines[#lines + 1] = row.prior end
        lines[#lines + 1] = "Provisional dungeon data" .. (row.clientTitle and "; title resolved by client." or "; community title.")
        label:SetWidth(rowWidth)
        label:SetText(table.concat(lines, "\n"))
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 8, -y)
        label:Show()
        y = y + label:GetStringHeight() + 18
    end
    for index = #result.rows + 1, #self.rows do self.rows[index]:Hide() end
    self.content:SetHeight(math.max(1, y))
    -- Mark BEFORE calling: QUEST_DATA_LOAD_RESULT may be synchronous.
    -- One attempt per unresolved ID, including reported predecessors.
    -- Explicit Refresh retries failures. Never scan arbitrary quest IDs.
    for _, id in ipairs(Model.QueryIDs(dungeon)) do
        if not snapshot.read(id).title and not self.requested[id] and currentAPI then
            self.requested[id] = true
            if ns.Readable(currentAPI.RequestLoadQuestByID) then ns.Call(currentAPI.RequestLoadQuestByID, id) end
        end
    end
end

ns.RegisterModule(Module)
ns.RegisterCommand("dungeons", function(rest)
    local key = ns.Text(rest):lower()
    if key ~= "" then
        if ns.IsCombat() then ns.Notify("Select a dungeon after combat."); return end
        if not Model.Find(catalog, key) then
            ns.Notify("Prototype choices: /pc dungeons deadmines | thanes | ragefire. Other dungeons are not covered.")
            return
        end
        ns.ModuleDB("dungeons", defaults).selected = key
    end
    ns.SetPanelVisible("dungeons", true)
    ns.Refresh("dungeons")
end)
for _, event in ipairs({"QUEST_LOG_UPDATE", "QUEST_ACCEPTED", "QUEST_REMOVED", "QUEST_TURNED_IN",
    "PLAYER_ENTERING_WORLD", "PLAYER_LEVEL_UP", "UNIT_FACTION", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}) do
    ns.On(event, function() ns.Refresh("dungeons") end)
end
ns.On("QUEST_DATA_LOAD_RESULT", function(_, questID)
    local id = Model.PositiveID(questID)
    if id and Module.requested and Module.requested[id] then ns.Refresh("dungeons") end
end)
