local addonName, ns = ...

-- All persisted rows contain the player's own input, never live inventory data.
-- Inventory counts are refreshed from C_Item and are never assumed to be zero
-- when the API is absent, restricted, or returns an invalid value.
local Model = {}
ns.Models = ns.Models or {}
ns.Models.Goals = Model

local MAX_GOALS = 100
local MAX_LABEL = 120
local MAX_ITEM_ID = 2147483647
local MAX_QUANTITY = 999999

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function plainText(value, maximum)
    if not ns.Readable(value) or type(value) ~= "string" then
        return ""
    end
    -- Labels are deliberately plain text. Strip UI markup and control bytes
    -- before saving so editing a label repeatedly never doubles pipe escapes.
    local text = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H[^|]*|h(.-)|h", "%1")
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    text = text:gsub("|", ""):gsub("[%z\1-\31\127]", " ")
    text = text:gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
    if #text > maximum then
        text = text:sub(1, maximum)
        -- Avoid leaving an incomplete UTF-8 sequence at the truncation edge.
        while #text > 0 and text:byte(-1) >= 128 and text:byte(-1) < 192 do
            text = text:sub(1, -2)
        end
        if #text > 0 and text:byte(-1) >= 192 then
            text = text:sub(1, -2)
        end
    end
    return text
end

local function positiveInteger(value, maximum)
    if not ns.Readable(value) then
        return nil
    end
    if type(value) == "string" then
        value = value:match("^%s*(%d+)%s*$")
        if not value then return nil end
        value = tonumber(value)
    end
    local number = ns.Number(value, nil)
    if not number or number < 1 or number > maximum or number ~= math.floor(number) then
        return nil
    end
    return number
end

function Model.ParseItemID(value)
    if not ns.Readable(value) then return nil end
    if type(value) == "number" then
        return positiveInteger(value, MAX_ITEM_ID)
    end
    if type(value) ~= "string" then return nil end
    local text = value:match("^%s*(.-)%s*$") or ""
    local id = text:match("^(%d+)$")
        or text:match("^item:(%d+):")
        or text:match("^item:(%d+)$")
        or text:match("^|c%x%x%x%x%x%x%x%x|Hitem:(%d+):")
        or text:match("^|Hitem:(%d+):")
    return id and positiveInteger(id, MAX_ITEM_ID) or nil
end

function Model.ValidateDraft(draft)
    if not readableTable(draft) then return nil, "Enter a goal first." end
    local kind = ns.Readable(draft.kind) and draft.kind or nil
    if kind ~= "Profession" and kind ~= "Shopping" then
        return nil, "Choose Profession or Shopping."
    end
    local itemText = draft.item
    local hasItem = false
    if ns.Readable(itemText) then
        if type(itemText) == "number" then
            hasItem = true
        elseif type(itemText) == "string" then
            hasItem = itemText:match("%S") ~= nil
        elseif itemText ~= nil then
            return nil, "Use an item ID or item link."
        end
    else
        return nil, "The item input is unavailable."
    end
    local itemID = hasItem and Model.ParseItemID(itemText) or nil
    if hasItem and not itemID then
        return nil, "Use a whole item ID or an item link."
    end
    local target = 1
    if itemID then
        target = positiveInteger(draft.target, MAX_QUANTITY)
        if not target then
            return nil, "Target must be a whole number from 1 to 999999."
        end
    end
    local label = plainText(draft.label, MAX_LABEL)
    if label == "" and itemID then
        if type(itemText) == "string" then
            local linkLabel = itemText:match("|h%[([^%]]+)%]|h")
            label = plainText(linkLabel, MAX_LABEL)
        end
        if label == "" then label = "Item #" .. itemID end
    end
    if label == "" then
        return nil, "Give this goal a name."
    end
    return { kind = kind, label = label, itemID = itemID, target = target, done = false }
end

local function copyGoal(goal)
    return {
        id = goal.id, kind = goal.kind, label = goal.label,
        itemID = goal.itemID, target = goal.target, done = goal.done == true,
    }
end

function Model.NormalizeDB(db)
    if not readableTable(db) then db = {} end
    local source = readableTable(db.goals) and db.goals or {}
    local rows, used = {}, {}
    local nextID = positiveInteger(db.nextID, MAX_ITEM_ID) or 1
    local highestID = 0
    for _, raw in ipairs(source) do
        if #rows >= MAX_GOALS then break end
        if readableTable(raw) then
            local goal = Model.ValidateDraft({
                kind = raw.kind, label = raw.label, item = raw.itemID,
                target = raw.target,
            })
            if goal then
                local id = positiveInteger(raw.id, MAX_ITEM_ID)
                if not id or used[id] then
                    id = math.max(nextID, highestID + 1)
                end
                -- A malformed extreme ID is replaced by a small unique ID.
                if id >= MAX_ITEM_ID then
                    id = 1
                    while used[id] do id = id + 1 end
                end
                goal.id = id
                goal.done = ns.Readable(raw.done) and raw.done == true or false
                used[id] = true
                highestID = math.max(highestID, id)
                rows[#rows + 1] = goal
            end
        end
    end
    db.goals = rows
    db.nextID = math.max(nextID, highestID + 1)
    if db.nextID >= MAX_ITEM_ID then db.nextID = highestID + 1 end
    local filter = ns.Readable(db.filter) and db.filter or nil
    db.filter = (filter == "Profession" or filter == "Shopping") and filter or "All"
    db.hideCompleted = ns.Readable(db.hideCompleted) and db.hideCompleted == true or false
    return db
end

function Model.Find(db, id)
    id = positiveInteger(id, MAX_ITEM_ID)
    if not id or not readableTable(db) or not readableTable(db.goals) then return nil end
    for index, goal in ipairs(db.goals) do
        if readableTable(goal) and ns.Readable(goal.id) and goal.id == id then
            return goal, index
        end
    end
    return nil
end

function Model.Save(db, id, draft)
    local goal, err = Model.ValidateDraft(draft)
    if not goal then return nil, err end
    if not ns.Readable(id) then return nil, "The selected goal is unavailable." end
    if id ~= nil then
        local current, index = Model.Find(db, id)
        if not current then return nil, "That goal no longer exists. Choose New." end
        goal.id, goal.done = current.id, current.done == true
        db.goals[index] = goal
        return goal
    end
    if #db.goals >= MAX_GOALS then
        return nil, "You can keep up to 100 goals. Remove one before adding another."
    end
    goal.id = positiveInteger(db.nextID, MAX_ITEM_ID - 1) or 1
    while Model.Find(db, goal.id) do goal.id = goal.id + 1 end
    db.nextID = goal.id + 1
    db.goals[#db.goals + 1] = goal
    return goal
end

function Model.Toggle(db, id)
    local goal = Model.Find(db, id)
    if not goal then return nil end
    goal.done = not goal.done
    return goal.done
end

function Model.Remove(db, id)
    local goal, index = Model.Find(db, id)
    if not goal then return nil, "Select a goal to remove." end
    local undo = { index = index, goal = copyGoal(goal) }
    table.remove(db.goals, index)
    return undo
end

function Model.Undo(db, undo)
    if not readableTable(undo) or not readableTable(undo.goal) then
        return nil, "There is no deletion to undo."
    end
    if #db.goals >= MAX_GOALS then return nil, "Remove another goal to make room before undoing." end
    if Model.Find(db, undo.goal.id) then return nil, "That goal is already present." end
    local row = Model.ValidateDraft({
        kind = undo.goal.kind, label = undo.goal.label,
        item = undo.goal.itemID, target = undo.goal.target,
    })
    local id = positiveInteger(undo.goal.id, MAX_ITEM_ID - 1)
    if not row or not id then return nil, "The deleted goal cannot be restored." end
    row.id = id
    row.done = ns.Readable(undo.goal.done) and undo.goal.done == true or false
    local index = positiveInteger(undo.index, MAX_GOALS) or (#db.goals + 1)
    table.insert(db.goals, math.min(index, #db.goals + 1), row)
    db.nextID = math.max(db.nextID, id + 1)
    return row
end

function Model.Visible(db, filter, hideCompleted)
    local visible = {}
    for _, goal in ipairs(db.goals) do
        if (filter == "All" or filter == goal.kind) and (not hideCompleted or not goal.done) then
            visible[#visible + 1] = goal
        end
    end
    return visible
end

function Model.Progress(target, owned)
    target = positiveInteger(target, MAX_QUANTITY)
    owned = ns.Number(owned, nil)
    if not target or not owned or owned < 0 or owned ~= math.floor(owned) then
        return { known = false }
    end
    local needed = math.max(0, target - owned)
    return { known = true, owned = owned, needed = needed, ready = needed == 0 }
end

function Model.CarriedCount(itemID)
    itemID = positiveInteger(itemID, MAX_ITEM_ID)
    if not itemID or type(C_Item) ~= "table" or type(C_Item.GetItemCount) ~= "function" then
        return nil
    end
    -- Explicitly exclude personal, reagent, and account bank storage and
    -- charge counts. The label is "carried" because equipped items can count.
    local count = ns.Call(C_Item.GetItemCount, itemID, false, false, false, false)
    count = ns.Number(count, nil)
    if count == nil or count < 0 or count ~= math.floor(count) then return nil end
    return count
end

local function professionSummary()
    if type(GetProfessions) ~= "function" or type(GetProfessionInfo) ~= "function" then
        return "Profession levels unavailable. Your manual goals still work."
    end
    local first, second = ns.Call(GetProfessions)
    local names, seen = {}, {}
    for _, index in pairs({ first, second }) do
        index = positiveInteger(index, MAX_ITEM_ID)
        if index and not seen[index] then
            seen[index] = true
            local name, _, rank, maximum = ns.Call(GetProfessionInfo, index)
            name = plainText(name, 45)
            rank, maximum = ns.Number(rank, nil), ns.Number(maximum, nil)
            if name ~= "" then
                local detail = name
                if rank and maximum and rank >= 0 and maximum > 0 then
                    detail = detail .. " " .. math.floor(rank) .. "/" .. math.floor(maximum)
                else
                    detail = detail .. " (level unavailable)"
                end
                names[#names + 1] = detail
            end
        end
    end
    if #names == 0 then return "No primary profession data. Add your own goals below." end
    return table.concat(names, "\n")
end

local function setEnabled(widget, enabled)
    if widget.SetEnabled then
        widget:SetEnabled(enabled)
    elseif enabled then
        widget:Enable()
    else
        widget:Disable()
    end
end

local function setFilterHighlight(widget, active)
    if widget.SetSelected then widget:SetSelected(active); return end
    if active and widget.LockHighlight then widget:LockHighlight() end
    if not active and widget.UnlockHighlight then widget:UnlockHighlight() end
    if widget.SetBackdropColor then
        if active then
            widget:SetBackdropColor(0.25, 0.20, 0.08, 1)
        else
            widget:SetBackdropColor(0.08, 0.08, 0.08, 1)
        end
    end
end

local function setFeedback(self, message)
    self.feedback:SetText(message or "Item totals are carried inventory, with all bank storage excluded.")
end

local function loadEditor(self, goal)
    self.selectedID = goal and goal.id or nil
    self.editorKind = goal and goal.kind or self.editorKind or "Shopping"
    self.kindButton:SetText(self.editorKind)
    self.editorTitle:SetText(goal and ("Editing goal #" .. goal.id) or "New goal")
    self.nameInput:SetText(goal and goal.label or "")
    self.itemInput:SetText(goal and goal.itemID and tostring(goal.itemID) or "")
    self.quantityInput:SetText(goal and tostring(goal.target) or "1")
    self.saveButton:SetText(goal and "Save" or "Add")
    setEnabled(self.deleteButton, goal ~= nil)
    setFeedback(self)
end

local function saveEditor(self)
    local goal, err = Model.Save(self.db, self.selectedID, {
        kind = self.editorKind, label = self.nameInput:GetText(),
        item = self.itemInput:GetText(), target = self.quantityInput:GetText(),
    })
    if not goal then setFeedback(self, err); return end
    loadEditor(self, goal)
    self.nameInput:ClearFocus()
    self.itemInput:ClearFocus()
    self.quantityInput:ClearFocus()
    setFeedback(self, "Saved. Check a row to mark it complete manually.")
    ns.Refresh("goals")
end

local function createRow(self, index)
    local row = {}
    row.check = ns.UI.Check(self.content, "", 0, 0, function()
        if row.goalID then
            Model.Toggle(self.db, row.goalID)
            ns.Refresh("goals")
        end
    end)
    row.button = ns.UI.Button(self.content, "", 32, 0, 260, 58, function()
        local goal = Model.Find(self.db, row.goalID)
        if goal then loadEditor(self, goal); ns.Refresh("goals") end
    end)
    ns.UI.Tooltip(row.button, function()
        local goal = Model.Find(self.db, row.goalID)
        if not goal then return "Select this row to edit it." end
        local text = goal.label
        if goal.itemID then text = text .. "\nItem #" .. goal.itemID .. "; target " .. goal.target end
        return text .. "\nClick to edit. The check box marks manual completion."
    end)
    row.title = ns.UI.Text(row.button, "", 8, 5, 12, 240)
    row.title:SetHeight(29)
    row.detail = ns.UI.Text(row.button, "", 8, 35, 10, 240)
    row.detail:SetHeight(20)
    self.rows[index] = row
    return row
end

local function renderRows(self)
    local rows = Model.Visible(self.db, self.db.filter, self.db.hideCompleted)
    local width = math.max(220, self.content:GetWidth())
    for index, goal in ipairs(rows) do
        local row = self.rows[index] or createRow(self, index)
        row.goalID = goal.id
        row.check:ClearAllPoints()
        row.check:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, -(index - 1) * 66 - 14)
        row.button:ClearAllPoints()
        row.button:SetPoint("TOPLEFT", self.content, "TOPLEFT", 32, -(index - 1) * 66)
        row.button:SetWidth(width - 34)
        row.title:SetWidth(width - 52)
        row.detail:SetWidth(width - 52)
        row.title:SetText(goal.label)
        local detail = goal.kind .. " | "
        if goal.itemID then
            local progress = Model.Progress(goal.target, Model.CarriedCount(goal.itemID))
            if progress.known then
                detail = detail .. progress.owned .. "/" .. goal.target .. " carried"
                detail = detail .. (progress.ready and "; ready" or ("; need " .. progress.needed))
            else
                detail = detail .. "carried count unavailable"
            end
        else
            detail = detail .. "manual goal"
        end
        if goal.done then detail = detail .. "; completed manually" end
        -- A literal pipe is escaped for WoW text rendering, including the
        -- separator generated above. User labels contain no markup pipes.
        row.detail:SetText(detail:gsub("|", "||"))
        row.title:SetTextColor(goal.done and 0.58 or 0.93, goal.done and 0.62 or 0.95, goal.done and 0.66 or 1)
        row.detail:SetTextColor(0.70, 0.79, 0.86)
        row.check:SetChecked(goal.done)
        setFilterHighlight(row.button, self.selectedID == goal.id)
        row.check:Show()
        row.button:Show()
    end
    for index = #rows + 1, #self.rows do
        self.rows[index].check:Hide()
        self.rows[index].button:Hide()
    end
    if #rows == 0 then
        self.emptyLabel:SetText(#self.db.goals == 0 and "Add a profession or shopping goal below." or "No goals match this filter.")
        self.emptyLabel:SetWidth(width - 8)
        self.emptyLabel:Show()
    else
        self.emptyLabel:Hide()
    end
    self.content:SetHeight(math.max(48, #rows * 66))
end

local function resizeEditor(self)
    local width = math.max(320, self.body:GetWidth())
    self.professionText:SetWidth(width - 4)
    self.nameInput:SetWidth(width - 10)
    self.itemInput:SetWidth(width - 100)
    self.quantityLabel:ClearAllPoints()
    self.quantityLabel:SetPoint("TOPLEFT", self.editor, "TOPLEFT", width - 84, -79)
    self.quantityInput:ClearAllPoints()
    self.quantityInput:SetPoint("TOPLEFT", self.editor, "TOPLEFT", width - 84, -96)
    self.quantityInput:SetWidth(74)
    self.feedback:SetWidth(width - 4)
    ns.Refresh("goals")
end

ns.RegisterModule({
    id = "goals", title = "Professions & Shopping",
    description = "Your own goals, with carried item counts when available.",
    width = 390, height = 510, minWidth = 360, minHeight = 450,
    defaultEnabled = { Healing = false, Leveling = true },
    Create = function(self)
        self.db = Model.NormalizeDB(ns.ModuleDB("goals", {
            nextID = 1, goals = {}, filter = "All", hideCompleted = false,
        }))
        self.rows, self.filterButtons = {}, {}
        self.professionText = ns.UI.Text(self.body, "", 0, 0, 11, 350)
        self.professionText:SetHeight(38)
        local filterSpecs = {
            { "All", 0, 70 }, { "Shopping", 76, 104 }, { "Profession", 186, 118 },
        }
        for _, info in ipairs(filterSpecs) do
            local filter = info[1]
            self.filterButtons[filter] = ns.UI.Button(self.body, filter, info[2], 42, info[3], 24, function()
                self.db.filter = filter
                ns.Refresh("goals")
            end)
        end
        self.hideCompleted = ns.UI.Check(self.body, "Hide completed", 0, 71, function(checked)
            self.db.hideCompleted = checked == true
            ns.Refresh("goals")
        end)
        self.scroll, self.content = ns.UI.ScrollArea(self.body, 102, 220)
        self.emptyLabel = ns.UI.Text(self.content, "", 0, 8, 12, 310, { 0.70, 0.79, 0.86 })

        self.editor = CreateFrame("Frame", nil, self.body)
        self.editor:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 0, 0)
        self.editor:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", 0, 0)
        self.editor:SetHeight(210)
        self.kindButton = ns.UI.Button(self.editor, "Shopping", 0, 0, 122, 24, function()
            self.editorKind = self.editorKind == "Shopping" and "Profession" or "Shopping"
            self.kindButton:SetText(self.editorKind)
        end)
        ns.UI.Tooltip(self.kindButton, "Choose the category for this goal. Click to switch.")
        self.editorTitle = ns.UI.Text(self.editor, "New goal", 134, 5, 11, 180)
        ns.UI.Text(self.editor, "Goal name", 0, 30, 11, 180)
        self.nameInput = ns.UI.Input(self.editor, 0, 47, 330, 23, "Your goal", function() saveEditor(self) end)
        self.nameInput:SetMaxLetters(MAX_LABEL)
        ns.UI.Text(self.editor, "Item ID or link (optional)", 0, 79, 11, 234)
        self.itemInput = ns.UI.Input(self.editor, 0, 96, 236, 23, "Leave empty for a manual goal", function() saveEditor(self) end)
        self.itemInput:SetMaxLetters(512)
        ns.UI.Tooltip(self.itemInput, "Paste an item link or type its numeric item ID. Empty means a manual goal. This does not buy or move items.")
        self.quantityLabel = ns.UI.Text(self.editor, "Target", 246, 79, 11, 76)
        self.quantityInput = ns.UI.Input(self.editor, 246, 96, 76, 23, "1", function() saveEditor(self) end)
        self.quantityInput:SetMaxLetters(6)
        self.saveButton = ns.UI.Button(self.editor, "Add", 0, 129, 88, 25, function() saveEditor(self) end)
        self.newButton = ns.UI.Button(self.editor, "New", 94, 129, 62, 25, function()
            loadEditor(self)
            ns.Refresh("goals")
        end)
        self.deleteButton = ns.UI.Button(self.editor, "Delete", 162, 129, 74, 25, function()
            local undo, err = Model.Remove(self.db, self.selectedID)
            if not undo then setFeedback(self, err); return end
            self.undo = undo
            loadEditor(self)
            setFeedback(self, "Deleted. Undo restores the most recent deletion this session.")
            ns.Refresh("goals")
        end)
        self.undoButton = ns.UI.Button(self.editor, "Undo", 242, 129, 84, 25, function()
            local goal, err = Model.Undo(self.db, self.undo)
            if not goal then setFeedback(self, err); return end
            self.undo = nil
            loadEditor(self, goal)
            setFeedback(self, "Restored the deleted goal.")
            ns.Refresh("goals")
        end)
        ns.UI.Tooltip(self.undoButton, "Restore the last goal removed from this panel during this session. Game items are never affected.")
        self.feedback = ns.UI.Text(self.editor, "", 0, 163, 11, 330, { 0.70, 0.79, 0.86 })
        self.feedback:SetHeight(44)
        loadEditor(self)
        if self.body.HookScript then
            self.body:HookScript("OnSizeChanged", function() resizeEditor(self) end)
        end
        resizeEditor(self)
        for _, event in ipairs({ "BAG_UPDATE_DELAYED", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "PLAYER_REGEN_ENABLED" }) do
            ns.On(event, function() ns.Refresh("goals") end)
        end
    end,
    Refresh = function(self)
        self.professionText:SetText(professionSummary())
        self.hideCompleted:SetChecked(self.db.hideCompleted)
        for filter, button in pairs(self.filterButtons) do
            setFilterHighlight(button, self.db.filter == filter)
        end
        setEnabled(self.undoButton, self.undo ~= nil)
        setEnabled(self.deleteButton, Model.Find(self.db, self.selectedID) ~= nil)
        renderRows(self)
    end,
})
