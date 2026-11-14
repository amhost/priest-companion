local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.References = Model

local defaults = { notes = {} }

function Model.BuildMouseover(spellName)
    if not ns.Readable(spellName) or type(spellName) ~= "string" then
        return nil, "A readable spell name is required."
    end
    spellName = spellName:match("^%s*(.-)%s*$")
    if #spellName == 0 or #spellName > 90 or spellName:find("[%c|/;%[%]]") then
        return nil, "Use a spell name without commands or conditions."
    end
    local macro = "#showtooltip " .. spellName .. "\n/cast [@mouseover,help,nodead] [help,nodead] [@player] " .. spellName
    if #macro > 255 then return nil, "That spell name makes the macro too long." end
    return macro
end

function Model.BindingText(key1, key2)
    local first, second = ns.Text(key1), ns.Text(key2)
    if not first or first == "" then first = nil end
    if not second or second == "" then second = nil end
    if first and second and first ~= second then return first .. " / " .. second end
    return first or second or "Unbound / unavailable"
end

function Model.AddNote(notes, text)
    text = ns.CleanText(text, 160):match("^%s*(.-)%s*$")
    if text == "" then return false, "Enter a reference note." end
    if #notes >= 24 then return false, "The reference panel holds up to 24 notes." end
    notes[#notes + 1] = text
    return true
end

local function addNote(self, text)
    local db = ns.ModuleDB("keys", defaults)
    local ok, problem = Model.AddNote(db.notes, text)
    if not ok then ns.Notify(problem); return end
    self.input:SetText("")
    ns.Refresh("keys")
end

local function showMacro(self, text)
    if ns.IsCombat() then ns.Notify("Create a reference macro after combat."); return end
    if not ns.Models.Spells or not ns.Models.Spells.ResolveSpell then
        ns.Notify("Spell lookup is unavailable."); return
    end
    local spell, problem = ns.Models.Spells.ResolveSpell(text)
    if not spell then ns.Notify(problem); return end
    if spell.learning == "Not learned" then
        ns.Notify("That spell is not learned by this character."); return
    end
    local helpful = C_Spell and ns.Call(C_Spell.IsSpellHelpful, spell.id)
    if ns.Readable(helpful) and helpful == false then
        ns.Notify("Choose a helpful spell for this mouseover healing macro."); return
    end
    local macro, macroProblem = Model.BuildMouseover(spell.name)
    if not macro then ns.Notify(macroProblem); return end
    if spell.learning ~= "Learned" then
        ns.Notify("The spell exists, but this client could not confirm you learned it. Review before use.")
    end
    ns.UI.MakeCopyBox("Mouseover macro reference", macro)
end

ns.RegisterModule({
    id = "keys", title = "Keybind and mouseover references",
    description = "Main action-button bindings, your notes, and copyable mouseover macros.",
    width = 380, height = 510, minWidth = 350, minHeight = 435,
    defaultEnabled = { Healing = true, Leveling = false },
    Create = function(self)
        ns.ModuleDB("keys", defaults)
        self.heading = ns.UI.Text(self.body, "Main action-button bindings", 0, 0, 12, 325)
        self.bindingColumns = {
            ns.UI.Text(self.body, "", 0, 23, 11, 155),
            ns.UI.Text(self.body, "", 164, 23, 11, 155),
        }
        for _, column in ipairs(self.bindingColumns) do column:SetWordWrap(false) end
        self.input = ns.UI.Input(self.body, 6, 126, 245, 24, "Add your own binding or spell note", function(text) addNote(self, text) end)
        self.addButton = ns.UI.Button(self.body, "Add", 264, 126, 65, 24, function() addNote(self, self.input:GetText()) end)
        self.scroll, self.content = ns.UI.ScrollArea(self.body, 163, 123)
        self.rows = {}
        self.macroLabel = ns.UI.Text(self.body, "Mouseover macro: enter a learned spell", 0, 0, 12, 325)
        self.macroLabel:ClearAllPoints()
        self.macroLabel:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 0, 90)
        self.macroInput = ns.UI.Input(self.body, 6, 0, 210, 24, "Spell name or ID", function(text) showMacro(self, text) end)
        self.macroInput:ClearAllPoints()
        self.macroInput:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 6, 57)
        self.macroButton = ns.UI.Button(self.body, "View / copy", 0, 0, 100, 24, function()
            showMacro(self, self.macroInput:GetText())
        end)
        self.macroButton:ClearAllPoints()
        self.macroButton:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", 0, 57)
        self.footer = ns.UI.Text(self.body, "Helpful mouseover, then friendly target, then yourself. Review the spell before copying. Nothing is installed automatically.", 0, 0, 11, 325, { 0.72, 0.74, 0.82 })
        self.footer:ClearAllPoints()
        self.footer:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 0, 0)
        for _, event in ipairs({ "UPDATE_BINDINGS", "ACTIONBAR_SLOT_CHANGED", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED" }) do
            ns.On(event, function() ns.Refresh("keys") end)
        end
        self.body:HookScript("OnSizeChanged", function() ns.Refresh("keys") end)
        ns.RegisterCommand("mouseover", function(rest) showMacro(self, rest) end)
    end,
    Refresh = function(self)
        local width = math.max(285, self.body:GetWidth())
        local columnWidth = math.floor((width - 12) / 2)
        self.heading:SetWidth(width)
        local bindingTop = self.heading:GetStringHeight() + 10
        local columns = { {}, {} }
        for slot = 1, 12 do
            local first, second = ns.Call(GetBindingKey, "ACTIONBUTTON" .. slot)
            local column = slot <= 6 and 1 or 2
            columns[column][#columns[column] + 1] = string.format("%2d: %s", slot, Model.BindingText(first, second))
        end
        local bindingHeight = 0
        for i = 1, 2 do
            self.bindingColumns[i]:SetWidth(columnWidth)
            self.bindingColumns[i]:ClearAllPoints()
            self.bindingColumns[i]:SetPoint("TOPLEFT", self.body, "TOPLEFT", (i - 1) * (columnWidth + 12), -bindingTop)
            self.bindingColumns[i]:SetText(table.concat(columns[i], "\n"))
            bindingHeight = math.max(bindingHeight, self.bindingColumns[i]:GetStringHeight())
        end
        local inputTop = bindingTop + bindingHeight + 12
        self.input:SetWidth(width - 89)
        self.input:ClearAllPoints(); self.input:SetPoint("TOPLEFT", self.body, "TOPLEFT", 10, -inputTop)
        self.addButton:ClearAllPoints(); self.addButton:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, -inputTop)
        self.macroInput:SetWidth(width - 124)
        self.macroLabel:SetWidth(width)
        self.footer:SetWidth(width)
        local macroInputBottom = self.footer:GetStringHeight() + 12
        self.macroInput:ClearAllPoints(); self.macroInput:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 6, macroInputBottom)
        self.macroButton:ClearAllPoints(); self.macroButton:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", 0, macroInputBottom)
        local macroLabelBottom = macroInputBottom + 36
        self.macroLabel:ClearAllPoints(); self.macroLabel:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 0, macroLabelBottom)
        local scrollBottom = macroLabelBottom + self.macroLabel:GetStringHeight() + 16
        self.scroll:ClearAllPoints()
        self.scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -inputTop - 36)
        self.scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, scrollBottom)
        local db = ns.ModuleDB("keys", defaults)
        local count = #db.notes
        local y = 0
        for i = 1, math.max(count, 1) do
            local row = self.rows[i]
            if not row then
                row = {}
                row.label = ns.UI.Text(self.content, "", 0, 0, 12, width - 60)
                row.remove = ns.UI.Button(self.content, "x", 0, 0, 24, 24, function()
                    table.remove(db.notes, row.index)
                    ns.Refresh("keys")
                end)
                self.rows[i] = row
            end
            row.index = i
            row.label:ClearAllPoints(); row.label:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -y - 3)
            row.label:SetWidth(math.max(165, self.content:GetWidth() - 34))
            row.label:Show()
            row.remove:ClearAllPoints(); row.remove:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -y)
            if db.notes[i] then
                row.label:SetText(db.notes[i]); row.remove:Show()
            else
                row.label:SetText("Your reference notes will appear here. Example: Shift + Q = emergency heal.")
                row.remove:Hide()
            end
            y = y + math.max(33, row.label:GetStringHeight() + 12)
        end
        for i = math.max(count, 1) + 1, #self.rows do self.rows[i].label:Hide(); self.rows[i].remove:Hide() end
        self.content:SetHeight(math.max(40, y))
    end,
})
