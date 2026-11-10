local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Preparation = Model

local defaults = {
    checklist = {
        { text = "Water and food packed", checked = false },
        { text = "Consumables ready", checked = false },
        { text = "Equipment repaired", checked = false },
        { text = "Dungeon quests picked up", checked = false },
    },
}

function Model.Durability(entries)
    local result = { count = 0, minimum = nil, broken = 0, restricted = false }
    for _, entry in ipairs(entries) do
        if not ns.Readable(entry[1]) or not ns.Readable(entry[2]) then
            result.restricted = true
        else
            local current, maximum = ns.Number(entry[1]), ns.Number(entry[2])
            if current and maximum and maximum > 0 and current >= 0 then
                local percentage = math.min(100, current / maximum * 100)
                result.count = result.count + 1
                result.minimum = result.minimum and math.min(result.minimum, percentage) or percentage
                if current == 0 then result.broken = result.broken + 1 end
            end
        end
    end
    return result
end

function Model.BagSpace(entries)
    local result = { free = 0, total = 0, bags = 0, restricted = false, specialty = 0 }
    for _, entry in ipairs(entries) do
        if not ns.Readable(entry.free) or not ns.Readable(entry.total) or not ns.Readable(entry.family) then
            result.restricted = true
        else
            local free, total, family = ns.Number(entry.free), ns.Number(entry.total), ns.Number(entry.family)
            if not total or total < 0 then
                result.restricted = true
            elseif total > 0 then
                if not free or not family or free < 0 or free > total then
                    result.restricted = true
                elseif family == 0 then
                    result.free = result.free + free
                    result.total = result.total + total
                    result.bags = result.bags + 1
                else
                    result.specialty = result.specialty + 1
                end
            end
        end
    end
    return result
end

function Model.AddItem(items, text)
    text = ns.CleanText(text, 120)
    text = text:match("^%s*(.-)%s*$")
    if text == "" then return false, "Enter a checklist item." end
    if #items >= 30 then return false, "The checklist holds up to 30 items." end
    items[#items + 1] = { text = text, checked = false }
    return true
end

local function snapshot(self)
    if ns.IsCombat() then return end
    local lines = {}
    if type(GetInventoryItemDurability) == "function" then
        local entries = {}
        for slot = 1, 19 do
            local current, maximum = ns.Call(GetInventoryItemDurability, slot)
            entries[#entries + 1] = { current, maximum }
        end
        local summary = Model.Durability(entries)
        if summary.minimum then
            lines[#lines + 1] = string.format("Equipment: %.0f%% minimum durability%s", summary.minimum, summary.restricted and " (partial)" or "")
            if summary.broken > 0 then lines[#lines + 1] = string.format("Broken items: %d", summary.broken) end
        else
            lines[#lines + 1] = "Durability: unavailable or no durable equipment"
        end
    else
        lines[#lines + 1] = "Durability: unavailable in this client"
    end
    local bagSlots = ns.Number(NUM_BAG_SLOTS)
    if C_Container and type(C_Container.GetContainerNumFreeSlots) == "function" and type(C_Container.GetContainerNumSlots) == "function" and bagSlots and bagSlots >= 0 and bagSlots <= 10 then
        local entries = {}
        for bag = 0, math.floor(bagSlots) do
            local free, family = ns.Call(C_Container.GetContainerNumFreeSlots, bag)
            local total = ns.Call(C_Container.GetContainerNumSlots, bag)
            entries[#entries + 1] = { free = free, total = total, family = family }
        end
        local summary = Model.BagSpace(entries)
        if summary.bags > 0 then
            lines[#lines + 1] = string.format("General bag slots: %d / %d free%s", summary.free, summary.total, summary.restricted and " (partial)" or "")
            if summary.specialty > 0 then lines[#lines + 1] = "Specialty bags excluded from this total" end
        else
            lines[#lines + 1] = "General bag space: unavailable"
        end
    else
        lines[#lines + 1] = "General bag space: unavailable in this client"
    end
    self.snapshot = table.concat(lines, "\n")
end

local function add(self, text)
    local db = ns.ModuleDB("prep", defaults)
    local ok, problem = Model.AddItem(db.checklist, text)
    if not ok then ns.Notify(problem); return end
    self.input:SetText("")
    ns.Refresh("prep")
end

ns.RegisterModule({
    id = "prep", title = "Dungeon preparation",
    description = "A personal checklist with out-of-combat equipment and bag summaries.",
    width = 350, height = 395, minWidth = 320, minHeight = 330,
    defaultEnabled = { Healing = true, Leveling = false },
    Create = function(self)
        ns.ModuleDB("prep", defaults)
        self.summary = ns.UI.Text(self.body, "Equipment and bags: awaiting a readable out-of-combat update.", 0, 0, 12, 300)
        self.state = ns.UI.Text(self.body, "", 0, 76, 11, 300, { 0.72, 0.74, 0.82 })
        self.input = ns.UI.Input(self.body, 6, 113, 218, 24, "Add a checklist item", function(text) add(self, text) end)
        self.addButton = ns.UI.Button(self.body, "Add", 235, 113, 65, 24, function() add(self, self.input:GetText()) end)
        self.clearButton = ns.UI.Button(self.body, "Clear checks", 0, 147, 108, 24, function()
            local db = ns.ModuleDB("prep", defaults)
            for _, item in ipairs(db.checklist) do item.checked = false end
            ns.Refresh("prep")
        end)
        self.refreshButton = ns.UI.Button(self.body, "Refresh status", 120, 147, 115, 24, function()
            snapshot(self)
            ns.Refresh("prep")
        end)
        self.scroll, self.content = ns.UI.ScrollArea(self.body, 183, 4)
        self.rows = {}
        for _, event in ipairs({ "UPDATE_INVENTORY_DURABILITY", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD" }) do
            ns.On(event, function() ns.Refresh("prep") end)
        end
        self.body:HookScript("OnSizeChanged", function() ns.Refresh("prep") end)
    end,
    Refresh = function(self)
        if not ns.IsCombat() then snapshot(self) end
        self.summary:SetText(self.snapshot or "Equipment and bags: awaiting a readable out-of-combat update.")
        self.state:SetText(ns.IsCombat() and "Last out-of-combat status. Checklist marks are manual." or "Current readable status. Checklist marks are manual.")
        local width = math.max(250, self.body:GetWidth())
        self.summary:SetWidth(width)
        self.state:SetWidth(width)
        self.input:SetWidth(width - 89)
        self.addButton:ClearAllPoints()
        self.addButton:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, -113)
        local db = ns.ModuleDB("prep", defaults)
        local y = 0
        for i, item in ipairs(db.checklist) do
            local row = self.rows[i]
            if not row then
                row = {}
                row.check = ns.UI.Check(self.content, "", 0, 0, function(checked)
                    local current = db.checklist[row.index]
                    if current then current.checked = checked and true or false end
                    ns.Refresh("prep")
                end)
                row.label = ns.UI.Text(self.content, "", 27, 0, 12, width - 65)
                row.remove = ns.UI.Button(self.content, "x", 0, 0, 24, 24, function()
                    table.remove(db.checklist, row.index)
                    ns.Refresh("prep")
                end)
                self.rows[i] = row
            end
            row.index = i
            row.check:ClearAllPoints(); row.check:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 27, -y - 4)
            row.label:SetWidth(math.max(150, self.content:GetWidth() - 60))
            row.label:SetText(item.text)
            row.remove:ClearAllPoints(); row.remove:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -y)
            row.check:SetChecked(item.checked and true or false)
            row.check:Show(); row.label:Show(); row.remove:Show()
            y = y + math.max(33, row.label:GetStringHeight() + 12)
        end
        for i = #db.checklist + 1, #self.rows do
            self.rows[i].check:Hide(); self.rows[i].label:Hide(); self.rows[i].remove:Hide()
        end
        self.content:SetHeight(math.max(1, y))
    end,
})
