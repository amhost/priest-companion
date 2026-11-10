local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Kills = Model

local templateNames = {
    "COMBATLOG_XPGAIN_FIRSTPERSON", "COMBATLOG_XPGAIN_FIRSTPERSON_GROUP", "COMBATLOG_XPGAIN_FIRSTPERSON_RAID",
    "COMBATLOG_XPGAIN_EXHAUSTION1", "COMBATLOG_XPGAIN_EXHAUSTION1_GROUP", "COMBATLOG_XPGAIN_EXHAUSTION1_RAID",
    "COMBATLOG_XPGAIN_EXHAUSTION2", "COMBATLOG_XPGAIN_EXHAUSTION2_GROUP", "COMBATLOG_XPGAIN_EXHAUSTION2_RAID",
    "COMBATLOG_XPGAIN_EXHAUSTION4", "COMBATLOG_XPGAIN_EXHAUSTION4_GROUP", "COMBATLOG_XPGAIN_EXHAUSTION4_RAID",
    "COMBATLOG_XPGAIN_EXHAUSTION5", "COMBATLOG_XPGAIN_EXHAUSTION5_GROUP", "COMBATLOG_XPGAIN_EXHAUSTION5_RAID",
}
local allowedTemplates = {}
for _, name in ipairs(templateNames) do allowedTemplates[name] = true end

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function clean(value, limit)
    return ns.CleanText(value, limit):gsub("^%s+", ""):gsub("%s+$", "")
end

local function integer(value)
    return math.min(999999999999, math.max(0, math.floor(ns.Number(value, 0))))
end

local function literalPattern(character)
    if string.find("^$()%.[]*+-?", character, 1, true) then return "%" .. character end
    return character
end

-- Only known, named kill-XP formats are accepted. Unnamed experience is not evidence of a kill.
-- Positional printf parameters are mapped by argument number, not by their order in the locale.
function Model.CompileTemplate(name, template)
    if not ns.Readable(name) or type(name) ~= "string" or not allowedTemplates[name] then return nil end
    if not ns.Readable(template) or type(template) ~= "string" or #template > 1500 then return nil end
    local pattern, captures, argumentTypes = { "^" }, {}, {}
    local index, nextArgument, positional = 1, 1, nil
    while index <= #template do
        local character = template:sub(index, index)
        if character ~= "%" then
            pattern[#pattern + 1] = literalPattern(character)
            index = index + 1
        elseif template:sub(index + 1, index + 1) == "%" then
            pattern[#pattern + 1] = "%%"
            index = index + 2
        else
            local tail = template:sub(index)
            local position, conversion = tail:match("^%%(%d+)%$([sd])")
            local consumed, argument, isPositional
            if position then
                argument = tonumber(position)
                consumed = #position + 3
                isPositional = true
            else
                conversion = tail:match("^%%([sd])")
                if not conversion then return nil end
                argument = nextArgument
                nextArgument = nextArgument + 1
                consumed = 2
                isPositional = false
            end
            if not argument or argument < 1 or argument > 20 then return nil end
            if positional ~= nil and positional ~= isPositional then return nil end
            positional = isPositional
            if argumentTypes[argument] and argumentTypes[argument] ~= conversion then return nil end
            argumentTypes[argument] = conversion
            captures[#captures + 1] = { argument = argument, kind = conversion }
            if #captures > 20 then return nil end
            pattern[#pattern + 1] = conversion == "d" and "(%d+)" or "(.-)"
            index = index + consumed
        end
    end
    if argumentTypes[1] ~= "s" or argumentTypes[2] ~= "d" then return nil end
    pattern[#pattern + 1] = "$"
    return { name = name, pattern = table.concat(pattern), captures = captures }
end

function Model.BuildPatterns(globals)
    local patterns = {}
    if not readableTable(globals) then return patterns end
    for _, name in ipairs(templateNames) do
        local compiled = Model.CompileTemplate(name, globals[name])
        if compiled then patterns[#patterns + 1] = compiled end
    end
    return patterns
end

function Model.MatchMessage(text, patterns)
    if not ns.Readable(text) then return nil, "restricted" end
    if type(text) ~= "string" or #text > 3000 then return nil, "invalid" end
    for _, compiled in ipairs(patterns or {}) do
        local captures = { text:match(compiled.pattern) }
        if #captures == #compiled.captures then
            local arguments, consistent = {}, true
            for index, descriptor in ipairs(compiled.captures) do
                local capture = captures[index]
                if arguments[descriptor.argument] and arguments[descriptor.argument] ~= capture then
                    consistent = false
                end
                arguments[descriptor.argument] = capture
            end
            local xp = ns.Number(tonumber(arguments[2]), nil)
            local label = clean(arguments[1], 100)
            if consistent and label ~= "" and xp and xp > 0 and xp == math.floor(xp) then
                return { label = label, xp = xp, template = compiled.name }, "matched"
            end
        end
    end
    return nil, "unmatched"
end

function Model.NewStats()
    return { automatic = 0, manual = 0, xp = 0, restricted = 0, unmatched = 0, targets = {} }
end

function Model.NormalizeStats(raw)
    local result = Model.NewStats()
    if not readableTable(raw) then return result end
    for _, key in ipairs({ "automatic", "manual", "xp", "restricted", "unmatched" }) do
        result[key] = integer(raw[key])
    end
    if readableTable(raw.targets) then
        local count = 0
        for key, row in pairs(raw.targets) do
            if ns.Readable(key) and type(key) == "string" and readableTable(row) then
                local label = clean(key, 100)
                if label ~= "" then
                    result.targets[label] = { automatic = integer(row.automatic), manual = integer(row.manual),
                        xp = integer(row.xp), note = clean(row.note, 240) }
                    count = count + 1
                    if count >= 201 then break end
                end
            end
        end
    end
    return result
end

local function targetRow(stats, label)
    if not stats.targets[label] then
        local count = 0
        for _ in pairs(stats.targets) do count = count + 1 end
        if count >= 200 then label = "Other targets (history limit)" end
        stats.targets[label] = stats.targets[label] or { automatic = 0, manual = 0, xp = 0, note = "" }
    end
    return stats.targets[label]
end

function Model.AddAutomatic(stats, record)
    if not readableTable(record) then return false end
    local label = clean(record.label, 100)
    local xp = ns.Number(record.xp, nil)
    if label == "" or not xp or xp <= 0 or xp ~= math.floor(xp) then return false end
    local row = targetRow(stats, label)
    stats.automatic = integer(stats.automatic + 1)
    stats.xp = integer(stats.xp + xp)
    row.automatic = integer(row.automatic + 1)
    row.xp = integer(row.xp + xp)
    return true
end

function Model.AddManual(stats, label, note)
    local safeLabel, safeNote = clean(label, 100), clean(note, 240)
    if safeLabel == "" then return false end
    local row = targetRow(stats, safeLabel)
    stats.manual = integer(stats.manual + 1)
    row.manual = integer(row.manual + 1)
    if safeNote ~= "" then row.note = safeNote end
    return true
end

function Model.Rows(lifetime, session)
    local result = {}
    for label, row in pairs(lifetime.targets) do
        local current = session.targets[label] or { automatic = 0, manual = 0 }
        result[#result + 1] = { label = label, automatic = row.automatic, manual = row.manual,
            sessionAutomatic = current.automatic, sessionManual = current.manual, note = row.note }
    end
    table.sort(result, function(a, b)
        local totalA, totalB = a.automatic + a.manual, b.automatic + b.manual
        if totalA == totalB then return a.label < b.label end
        return totalA > totalB
    end)
    return result
end

local session = Model.NewStats()
local patterns
local database
local xpEventSupported = false

local function getDB()
    local db = ns.ModuleDB("kills", { autoEnabled = true, lifetime = Model.NewStats(), manualLabel = "", manualNote = "" })
    if db ~= database then
        db.lifetime = Model.NormalizeStats(db.lifetime)
        db.manualLabel = clean(db.manualLabel, 100)
        db.manualNote = clean(db.manualNote, 240)
        if not ns.Readable(db.autoEnabled) or type(db.autoEnabled) ~= "boolean" then db.autoEnabled = true end
        database = db
    end
    return db
end

local function getPatterns()
    if not patterns then patterns = Model.BuildPatterns(_G) end
    return patterns
end

local function recordManual(label, note)
    local db = getDB()
    if not Model.AddManual(db.lifetime, label, note) then
        ns.Notify("Enter a target label before adding a manual kill.")
        return false
    end
    Model.AddManual(session, label, note)
    db.manualLabel, db.manualNote = clean(label, 100), clean(note, 240)
    ns.Refresh("kills")
    return true
end

local function resetSession()
    session = Model.NewStats()
    ns.Refresh("kills")
    ns.Notify("Kill session reset. All-time counts are retained.")
end

local Module = {
    id = "kills", title = "Kill Tracker",
    description = "XP-credit kills and separately recorded manual kills, with session and all-time totals.",
    width = 410, height = 500, minWidth = 350, minHeight = 420,
    defaultEnabled = { Healing = false, Leveling = true },
}

function Module:Create()
    local db = getDB()
    self.rows = {}
    self.sessionText = ns.UI.Text(self.body, "", 8, 6, 12, 380)
    self.totalText = ns.UI.Text(self.body, "", 8, 32, 11, 380)
    self.coverage = ns.UI.Text(self.body, "", 8, 57, 10, 380, { 0.73, 0.78, 0.85 })
    self.auto = ns.UI.Check(self.body, "Track readable XP-credit kills", 8, 95, function(checked)
        getDB().autoEnabled = checked == true
        ns.Refresh("kills")
    end)
    self.manualLabel = ns.UI.Text(self.body, "Manual target", 8, 128, 11, 95)
    self.manualNote = ns.UI.Text(self.body, "Note", 8, 158, 11, 95)
    self.labelInput = ns.UI.Input(self.body, 110, 124, 265, 24, "Manual target label", function(text)
        getDB().manualLabel = clean(text, 100)
    end)
    self.noteInput = ns.UI.Input(self.body, 110, 154, 265, 24, "Optional target note", function(text)
        getDB().manualNote = clean(text, 240)
    end)
    self.labelInput:SetText(db.manualLabel)
    self.noteInput:SetText(db.manualNote)
    self.addButton = ns.UI.Button(self.body, "+1 manual", 8, 186, 122, 25, function()
        recordManual(self.labelInput:GetText(), self.noteInput:GetText())
    end)
    self.resetButton = ns.UI.Button(self.body, "New session", 140, 186, 122, 25, resetSession)
    ns.UI.Tooltip(self.addButton, "Records one manual kill under this label. It never increases the automatic XP-credit counter.")
    ns.UI.Tooltip(self.resetButton, "Start the session counters at zero. All-time counts and target notes remain saved.")
    self.scroll, self.content = ns.UI.ScrollArea(self.body, 225, 31)
    self.footer = ns.UI.Text(self.body, "Group XP credit counts. Grey/no-XP kills are not automatic.", 8, 0, 10, 380, { 0.68, 0.73, 0.8 })
    self.footer:ClearAllPoints()
    self.footer:SetPoint("BOTTOMLEFT", self.body, "BOTTOMLEFT", 8, 5)
    self.footer:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -8, 5)
    self.body:HookScript("OnSizeChanged", function() ns.Refresh("kills") end)
end

function Module:Refresh()
    if not self.sessionText then return end
    local db = getDB()
    local lifetime = db.lifetime
    self.sessionText:SetText("Session: " .. session.automatic .. " XP-credit kills | " .. session.manual .. " manual")
    self.totalText:SetText("All time: " .. lifetime.automatic .. " XP-credit | " .. lifetime.manual .. " manual | " .. lifetime.xp .. " kill XP")
    local status
    if not xpEventSupported or #getPatterns() == 0 then
        status = "Automatic tracking unavailable: no supported event or locale format. Manual entries work."
    elseif not db.autoEnabled then
        status = "Automatic tracking paused. Manual entries remain available."
    elseif session.restricted > 0 then
        status = "Partial coverage: " .. session.restricted .. " restricted XP messages skipped this session."
    elseif session.automatic == 0 then
        status = "Waiting for readable, named kill XP messages. This is a partial kill history."
    else
        status = "Named XP-credit kills only. This does not identify who landed the killing blow."
    end
    self.coverage:SetText(status)
    self.auto:SetChecked(db.autoEnabled)
    local width = math.max(280, ns.Number(self.body:GetWidth(), 390) - 20)
    self.sessionText:SetWidth(width)
    self.totalText:SetWidth(width)
    self.coverage:SetWidth(width)
    self.labelInput:SetWidth(math.max(170, width - 110))
    self.noteInput:SetWidth(math.max(170, width - 110))
    local function place(widget, x, y)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", self.body, "TOPLEFT", x, -y)
    end
    local headerY = 6
    place(self.sessionText, 8, headerY)
    headerY = headerY + math.max(16, ns.Number(self.sessionText:GetStringHeight(), 16)) + 8
    place(self.totalText, 8, headerY)
    headerY = headerY + math.max(16, ns.Number(self.totalText:GetStringHeight(), 16)) + 8
    place(self.coverage, 8, headerY)
    headerY = headerY + math.max(28, ns.Number(self.coverage:GetStringHeight(), 28)) + 8
    place(self.auto, 8, headerY)
    if self.auto.label then self.auto.label:SetWidth(width - 25) end
    headerY = headerY + math.max(25, self.auto.label and ns.Number(self.auto.label:GetStringHeight(), 20) + 5 or 25) + 6
    place(self.manualLabel, 8, headerY + 4)
    place(self.labelInput, 114, headerY)
    headerY = headerY + 31
    place(self.manualNote, 8, headerY + 4)
    place(self.noteInput, 114, headerY)
    headerY = headerY + 32
    place(self.addButton, 8, headerY)
    place(self.resetButton, 140, headerY)
    self.scroll:ClearAllPoints()
    self.scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -(headerY + 39))
    self.scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, 31)
    local contentWidth = math.max(260, ns.Number(self.scroll:GetWidth(), width) - 20)
    self.content:SetWidth(contentWidth)
    local rows = Model.Rows(lifetime, session)
    local y = 0
    for index = 1, math.max(1, #rows) do
        local font = self.rows[index]
        if not font then font = ns.UI.Text(self.content, "", 4, 0, 11, contentWidth - 8); self.rows[index] = font end
        local row = rows[index]
        local text
        if row then
            text = row.label .. "\nSession: " .. row.sessionAutomatic .. " XP-credit, " .. row.sessionManual .. " manual"
                .. " | All time: " .. row.automatic .. " XP-credit, " .. row.manual .. " manual"
            if row.note ~= "" then text = text .. "\n" .. row.note end
        else
            text = "No targets recorded yet. Kill an XP-granting creature or add a manual entry."
        end
        font:ClearAllPoints()
        font:SetPoint("TOPLEFT", self.content, "TOPLEFT", 4, -y)
        font:SetWidth(contentWidth - 8)
        font:SetText(text)
        font:Show()
        y = y + math.max(34, ns.Number(font:GetStringHeight(), 34)) + 12
    end
    for index = math.max(1, #rows) + 1, #self.rows do self.rows[index]:Hide() end
    self.content:SetHeight(math.max(1, y))
end

ns.RegisterModule(Module)
xpEventSupported = ns.On("CHAT_MSG_COMBAT_XP_GAIN", function(_, text)
    local db = getDB()
    if not db.autoEnabled then return end
    local record, reason = Model.MatchMessage(text, getPatterns())
    if record then
        Model.AddAutomatic(db.lifetime, record)
        Model.AddAutomatic(session, record)
    elseif reason == "restricted" then
        session.restricted = integer(session.restricted + 1)
        db.lifetime.restricted = integer(db.lifetime.restricted + 1)
    elseif reason == "unmatched" then
        session.unmatched = integer(session.unmatched + 1)
    end
    ns.Refresh("kills")
end)
ns.On("PLAYER_ENTERING_WORLD", function()
    patterns = nil
    ns.Refresh("kills")
end)
ns.RegisterCommand("kill", function(rest) recordManual(rest, "") end)
ns.RegisterCommand("killsession", resetSession)
