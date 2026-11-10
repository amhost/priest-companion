local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Priest = Model

local MAX_REFERENCES = 12

function Model.ResourceText(current, maximum)
    if not ns.Readable(current) or not ns.Readable(maximum) then
        return "Protected display", "protected"
    end
    local value, limit = ns.Number(current), ns.Number(maximum)
    if not value or not limit or limit <= 0 then
        return "Unavailable", "unavailable"
    end
    return string.format("%d / %d", math.floor(value), math.floor(limit)), "readable"
end

function Model.NormalizeSpellInput(value)
    if not ns.Readable(value) or type(value) ~= "string" then
        return nil, "Enter a spell name or spell ID."
    end
    value = value:match("^%s*(.-)%s*$")
    if #value == 0 or #value > 120 or value:find("[%c|/;%[%]]") then
        return nil, "Use a spell name or numeric spell ID only."
    end
    local id = tonumber(value)
    if id then
        if id ~= math.floor(id) or id < 1 or id > 1000000000 then
            return nil, "Spell IDs must be positive whole numbers."
        end
        return id
    end
    return value
end

function Model.IsSpellLearned(id)
    if C_SpellBook and type(C_SpellBook.IsSpellInSpellBook) == "function" and Enum and Enum.SpellBookSpellBank then
        local bank = ns.Number(Enum.SpellBookSpellBank.Player)
        if bank then
            local known = ns.Call(C_SpellBook.IsSpellInSpellBook, id, bank, true)
            if ns.Readable(known) and type(known) == "boolean" then return known end
        end
    end
    local known = ns.Call(IsPlayerSpell, id)
    if ns.Readable(known) and type(known) == "boolean" then return known end
    return nil
end

function Model.ResolveSpell(value)
    local query, problem = Model.NormalizeSpellInput(value)
    if not query then return nil, problem end
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then
        return nil, "Spell lookup is unavailable in this client."
    end
    local info = ns.Call(C_Spell.GetSpellInfo, query)
    if not ns.Readable(info) or type(info) ~= "table" then
        return nil, "Spell lookup is unavailable or that spell was not found."
    end
    local name = ns.Text(info.name)
    local id = ns.Number(info.spellID)
    if not name or not id or name == "" then
        return nil, "The client did not provide readable spell details."
    end
    local known = Model.IsSpellLearned(id)
    local state = "Learning check unavailable"
    if ns.Readable(known) and type(known) == "boolean" then
        state = known and "Learned" or "Not learned"
    end
    return { id = id, name = name, learning = state }
end

local function resourceBar(parent, y, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    bar:SetHeight(19)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(color[1], color[2], color[3])
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(0.13, 0.14, 0.19, 0.9)
    return bar
end

local function updateResource(bar, label, title, current, maximum)
    local text, status = Model.ResourceText(current, maximum)
    -- Secret values are forwarded only into documented display setters. They
    -- are never compared, formatted, stored in saved variables, or used as keys.
    local currentUsable = not ns.Readable(current) or ns.Number(current) ~= nil
    local maximumUsable = not ns.Readable(maximum) or ns.Number(maximum) ~= nil
    local displayed = false
    if currentUsable and maximumUsable then
        local rangeOK = pcall(bar.SetMinMaxValues, bar, 0, maximum)
        local valueOK = rangeOK and pcall(bar.SetValue, bar, current)
        displayed = rangeOK and valueOK
    end
    if not displayed then
        pcall(bar.SetMinMaxValues, bar, 0, 1)
        pcall(bar.SetValue, bar, 0)
        text = "Unavailable"
    end
    label:SetText(title .. ": " .. text)
    return displayed, status
end

local function addReference(self, text)
    if ns.IsCombat() then
        ns.Notify("Add spell references after combat.")
        return
    end
    local spell, problem = Model.ResolveSpell(text)
    if not spell then ns.Notify(problem); return end
    local db = ns.ModuleDB("priest", { spells = {} })
    for _, entry in ipairs(db.spells) do
        if entry.id == spell.id then
            ns.Notify("That spell is already in your references.")
            return
        end
    end
    if #db.spells >= MAX_REFERENCES then
        ns.Notify("Remove a reference before adding another (12 maximum).")
        return
    end
    -- These are readable out-of-combat display fields, never raw API tables.
    db.spells[#db.spells + 1] = { id = spell.id, name = ns.CleanText(spell.name, 120) }
    self.spellInput:SetText("")
    ns.Refresh("priest")
end

ns.RegisterModule({
    id = "priest", title = "Priest information",
    description = "Your health, mana, and chosen spell references.",
    width = 350, height = 370, minWidth = 320, minHeight = 320,
    defaultEnabled = { Healing = true, Leveling = true },
    Create = function(self)
        ns.ModuleDB("priest", { spells = {} })
        self.identity = ns.UI.Text(self.body, "Character information", 0, 0, 12, 300)
        self.healthLabel = ns.UI.Text(self.body, "Health", 0, 25, 12, 300)
        self.health = resourceBar(self.body, 44, { 0.38, 0.75, 0.58 })
        self.manaLabel = ns.UI.Text(self.body, "Mana", 0, 72, 12, 300)
        self.mana = resourceBar(self.body, 91, { 0.49, 0.57, 0.92 })
        self.mode = ns.UI.Text(self.body, "", 0, 119, 11, 300, { 0.72, 0.74, 0.82 })
        self.heading = ns.UI.Text(self.body, "Chosen spell references", 0, 151, 12, 300)
        self.spellInput = ns.UI.Input(self.body, 6, 172, 218, 24, "Spell name or ID", function(text)
            addReference(self, text)
        end)
        self.addButton = ns.UI.Button(self.body, "Add", 235, 172, 65, 24, function()
            addReference(self, self.spellInput:GetText())
        end)
        self.scroll, self.content = ns.UI.ScrollArea(self.body, 205, 4)
        self.rows = {}
        for _, event in ipairs({ "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "PLAYER_LEVEL_UP", "SPELLS_CHANGED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }) do
            ns.On(event, function(_, unit)
                if not ns.Readable(unit) then return end
                if unit == nil or unit == "player" or type(unit) ~= "string" then ns.Refresh("priest") end
            end)
        end
        self.body:HookScript("OnSizeChanged", function() ns.Refresh("priest") end)
    end,
    Refresh = function(self)
        local class = ns.Text(ns.Call(UnitClass, "player"), "Character")
        local level = ns.Number(ns.Call(UnitLevel, "player"))
        self.identity:SetText(class .. (level and "  |  Level " .. math.floor(level) or ""))
        updateResource(self.health, self.healthLabel, "Health", ns.Call(UnitHealth, "player"), ns.Call(UnitHealthMax, "player"))
        updateResource(self.mana, self.manaLabel, "Mana", ns.Call(UnitPower, "player", 0), ns.Call(UnitPowerMax, "player", 0))
        self.mode:SetText(ns.IsCombat() and "Combat: display only. Spell references stay unchanged." or "Out of combat. Spell references are chosen by you.")
        local width = math.max(250, self.body:GetWidth())
        self.identity:SetWidth(width)
        self.healthLabel:SetWidth(width)
        self.manaLabel:SetWidth(width)
        self.mode:SetWidth(width)
        self.spellInput:SetWidth(width - 89)
        self.addButton:ClearAllPoints()
        self.addButton:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, -172)
        local db = ns.ModuleDB("priest", { spells = {} })
        local count = #db.spells
        local y = 0
        for i = 1, math.max(count, 1) do
            local row = self.rows[i]
            if not row then
                row = {}
                row.label = ns.UI.Text(self.content, "", 0, 0, 12, width - 60)
                row.remove = ns.UI.Button(self.content, "x", 0, 0, 24, 24, function()
                    if ns.IsCombat() then ns.Notify("Edit spell references after combat."); return end
                    table.remove(db.spells, row.index)
                    ns.Refresh("priest")
                end)
                self.rows[i] = row
            end
            row.index = i
            row.label:ClearAllPoints()
            row.label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y)
            row.label:SetWidth(math.max(160, self.content:GetWidth() - 34))
            row.label:Show()
            row.remove:ClearAllPoints()
            row.remove:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -y)
            local entry = db.spells[i]
            if entry then
                local known
                if not ns.IsCombat() then known = Model.IsSpellLearned(entry.id) end
                local state = "Saved reference"
                if ns.Readable(known) and type(known) == "boolean" then state = known and "Learned" or "Not learned" end
                row.label:SetText(entry.name .. "\n|cffacb0c8" .. state .. "|r")
                row.remove:Show()
            else
                row.label:SetText("Add spells you want to keep in view. This does not recommend or cast spells.")
                row.remove:Hide()
            end
            y = y + math.max(39, row.label:GetStringHeight() + 12)
        end
        for i = math.max(count, 1) + 1, #self.rows do
            self.rows[i].label:Hide()
            self.rows[i].remove:Hide()
        end
        self.content:SetHeight(math.max(55, y))
    end,
})
