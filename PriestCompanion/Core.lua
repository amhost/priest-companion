local addonName, ns = ...

ns.VERSION = "0.1.0-alpha.1"
ns.TARGET_INTERFACE = 16001
ns.Models = ns.Models or {}
ns.modules, ns.order, ns.frames = {}, {}, {}
ns.errors, ns.warnings, ns.commands = {}, {}, {}
ns.events, ns.queued = {}, {}
ns.UI = ns.UI or {}

local unpackValues = unpack or table.unpack
local eventFrame = CreateFrame("Frame")
local function hasFunction(value) return type(value) == "function" end

function ns.Readable(value)
    if hasFunction(issecretvalue) then
        local ok, secret = pcall(issecretvalue, value)
        if not ok or secret then return false end
    end
    if type(value) == "table" and hasFunction(issecrettable) then
        local ok, secretTable = pcall(issecrettable, value)
        if not ok or secretTable then return false end
    end
    if hasFunction(canaccessvalue) then
        local ok, accessible = pcall(canaccessvalue, value)
        if not ok or not accessible then return false end
    end
    return true
end

function ns.Number(value, fallback)
    if ns.Readable(value) and type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge then return value end
    return fallback
end

function ns.Text(value, fallback)
    if ns.Readable(value) then
        if type(value) == "string" then return value end
        if ns.Number(value) then return tostring(value) end
    end
    return fallback or ""
end

function ns.CleanText(value, limit)
    local text = ns.Text(value, ""):gsub("[%z\1-\8\11\12\14-\31]", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("|H[^|]*|h(.-)|h", "%1")
    text = text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|", "")
    return text:sub(1, limit or 240)
end

function ns.Call(fn, ...)
    if not hasFunction(fn) then return nil end
    local ok, a, b, c, d, e, f = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d, e, f
end

function ns.IsCombat() return ns.Call(InCombatLockdown) == true end

function ns.Notify(text)
    local message = "|cffc4b5fdPriest Companion:|r " .. ns.Text(text, "")
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage(message)
    elseif print then print(message) end
end

function ns.WarnOnce(key, message)
    if ns.warnings[key] then return end
    ns.warnings[key] = true
    ns.Notify(message)
end

local function recordError(key, message)
    ns.errors[key] = ns.Text(message, "Unavailable error detail"):sub(1, 500)
    ns.WarnOnce(key, "A module reported an error (" .. key .. "). Use /pc diagnostics.")
end

function ns.Copy(value, depth)
    if not ns.Readable(value) then return nil end
    local kind = type(value)
    if kind == "number" then return ns.Number(value) end
    if kind == "string" or kind == "boolean" then return value end
    if kind ~= "table" or (depth or 0) > 12 then return nil end
    local copy = {}
    for key, item in pairs(value) do
        if ns.Readable(key) and (type(key) == "string" or type(key) == "number") then
            copy[key] = ns.Copy(item, (depth or 0) + 1)
        end
    end
    return copy
end

function ns.Defaults(target, defaults)
    local exists = ns.Readable(target) and type(target) == "table"
    if not exists then target = {} end
    -- Existing lists are user data, including an intentionally empty list.
    -- Filling list defaults again would resurrect deleted checklist entries.
    if exists and type(defaults) == "table" and defaults[1] ~= nil then return target end
    for key, value in pairs(defaults or {}) do
        if type(value) == "table" then
            target[key] = ns.Defaults(target[key], value)
        elseif target[key] == nil or type(target[key]) ~= type(value) then
            target[key] = value
        end
    end
    return target
end

local function clamp(value, low, high, fallback)
    return math.min(high, math.max(low, ns.Number(value, fallback or low)))
end
ns.Clamp = clamp

function ns.ModuleDB(id, defaults)
    if not ns.db then error("Priest Companion settings are not initialized") end
    ns.db.modules[id] = ns.Defaults(ns.db.modules[id], defaults or {})
    return ns.db.modules[id]
end

function ns.RegisterModule(module)
    assert(type(module.id) == "string" and module.id:match("^[a-z]+$"), "Invalid module ID")
    assert(not ns.modules[module.id], "Duplicate module ID")
    ns.modules[module.id] = module
    ns.order[#ns.order + 1] = module.id
end

function ns.On(event, callback)
    if type(event) ~= "string" or not hasFunction(callback) then return false end
    if not ns.events[event] then
        if C_EventUtils and hasFunction(C_EventUtils.IsEventValid) then
            local valid = ns.Call(C_EventUtils.IsEventValid, event)
            if valid == false then return false end
        end
        local ok = pcall(eventFrame.RegisterEvent, eventFrame, event)
        if not ok then return false end
        ns.events[event] = {}
    end
    ns.events[event][#ns.events[event] + 1] = callback
    return true
end

local function refreshNow(id)
    ns.queued[id] = nil
    local module = ns.modules[id]
    if not ns.ready or not module or not module.frame or not module.frame:IsShown() then return end
    if module.Refresh then
        local ok, err = pcall(module.Refresh, module)
        if not ok then recordError("refresh-" .. id, err) end
    end
end

function ns.Refresh(id)
    if not ns.ready or not ns.modules[id] or ns.queued[id] then return end
    ns.queued[id] = true
    if C_Timer and hasFunction(C_Timer.After) then
        C_Timer.After(0.08, function() refreshNow(id) end)
    else refreshNow(id) end
end

function ns.RefreshAll()
    for _, id in ipairs(ns.order) do ns.Refresh(id) end
end

local placements = {
    priest = { "TOPLEFT", 24, -80 },
    quests = { "TOPRIGHT", -32, -80 },
    preparation = { "LEFT", 24, 0 },
    prep = { "LEFT", 24, 0 },
    references = { "BOTTOM", 0, 60 },
    keys = { "BOTTOM", 0, 60 },
    goals = { "BOTTOMRIGHT", -32, 70 },
    kills = { "BOTTOMLEFT", 24, 70 },
    appearance = { "CENTER", 50, 30 },
    settings = { "CENTER", 0, 0 },
}
local validPoints = { TOPLEFT=true, TOP=true, TOPRIGHT=true, LEFT=true, CENTER=true,
    RIGHT=true, BOTTOMLEFT=true, BOTTOM=true, BOTTOMRIGHT=true }

function ns.PanelSettings(id, layout)
    layout = layout or ns.db.layout
    if layout ~= "Healing" and layout ~= "Leveling" then layout = "Leveling" end
    local module = ns.modules[id]
    if not module then return nil end
    ns.db.layouts[layout] = ns.db.layouts[layout] or {}
    local default = placements[id] or { "CENTER", 0, 0 }
    local enabled = module.defaultEnabled and module.defaultEnabled[layout] == true
    local value = ns.Defaults(ns.db.layouts[layout][id], {
        point=default[1], relativePoint=default[1], x=default[2], y=default[3],
        width=module.width or 320, height=module.height or 280,
        scale=1, opacity=0.94, shown=enabled,
    })
    value.width = clamp(value.width, module.minWidth or 260, 1000, module.width or 320)
    value.height = clamp(value.height, module.minHeight or 160, 900, module.height or 280)
    value.scale = clamp(value.scale, 0.65, 1.5, 1)
    value.opacity = clamp(value.opacity, 0.35, 1, 0.94)
    value.x = clamp(value.x, -10000, 10000, 0)
    value.y = clamp(value.y, -10000, 10000, 0)
    if not validPoints[value.point] then value.point = "CENTER" end
    if not validPoints[value.relativePoint] then value.relativePoint = "CENTER" end
    ns.db.layouts[layout][id] = value
    return value
end

function ns.SavePlacement(id)
    local frame = ns.frames[id]
    if not frame or not ns.db or ns.applying then return end
    local x, y = frame:GetCenter()
    local px, py = UIParent:GetCenter()
    if not ns.Number(x) or not ns.Number(y) or not ns.Number(px) or not ns.Number(py) then return end
    local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local settings = ns.PanelSettings(id)
    settings.point, settings.relativePoint = "CENTER", "CENTER"
    -- Anchor offsets are in the moved frame's coordinate space. UIParent's
    -- center is converted before subtracting, so changing panel scale is stable.
    settings.x, settings.y = x - px / scale, y - py / scale
    settings.width, settings.height = frame:GetWidth(), frame:GetHeight()
end

function ns.ApplyPanel(id)
    local frame = ns.frames[id]
    if not frame then return end
    local settings = ns.PanelSettings(id)
    ns.applying = true
    frame:StopMovingOrSizing()
    frame:SetScale(settings.scale)
    frame:SetSize(settings.width, settings.height)
    frame:ClearAllPoints()
    frame:SetPoint(settings.point, UIParent, settings.relativePoint, settings.x, settings.y)
    if frame.SetClampedToScreen then frame:SetClampedToScreen(true) end
    if frame.SetBackdropColor then frame:SetBackdropColor(0.055, 0.06, 0.085, settings.opacity) end
    frame:SetShown(settings.shown)
    ns.applying = false
    if frame.UpdateLock then frame:UpdateLock() end
    ns.Refresh(id)
end

function ns.SetPanelVisible(id, visible)
    local aliases = {references="keys", preparation="prep"}
    if not ns.modules[id] and aliases[id] then id = aliases[id] end
    if not ns.modules[id] then ns.Notify("Unknown panel. Use /pc for the panel list."); return false end
    if ns.IsCombat() then
        ns.pendingVisibility = ns.pendingVisibility or {}
        ns.pendingVisibility[id] = not not visible
        ns.Notify("Panel visibility will change after combat.")
        return false
    end
    ns.PanelSettings(id).shown = not not visible
    ns.ApplyPanel(id)
    ns.Refresh("settings")
    return true
end

function ns.ApplyLayout(layout)
    if layout ~= "Healing" and layout ~= "Leveling" then return false end
    if ns.IsCombat() then
        ns.pendingLayout = layout
        ns.Notify(layout .. " layout queued until combat ends.")
        return false
    end
    -- Save the old layout before applying the new one.
    for _, id in ipairs(ns.order) do ns.SavePlacement(id) end
    ns.db.layout = layout
    for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    ns.RefreshAll()
    return true
end

function ns.SetLocked(locked)
    if not locked and ns.IsCombat() then ns.Notify("Unlock panels after combat."); return false end
    ns.db.locked = not not locked
    for id, frame in pairs(ns.frames) do
        frame:StopMovingOrSizing()
        ns.SavePlacement(id)
        if frame.UpdateLock then frame:UpdateLock() end
    end
    ns.Refresh("settings")
    return true
end

function ns.ResetLayout()
    if ns.IsCombat() then ns.Notify("Reset layouts after combat."); return false end
    local layout = ns.db.layout
    ns.db.previousLayout = { name=layout, panels=ns.Copy(ns.db.layouts[layout]) }
    ns.db.layouts[layout] = {}
    for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    ns.SetPanelVisible("settings", true)
    ns.Notify(layout .. " layout reset. /pc restorelayout restores the previous arrangement.")
    return true
end

function ns.RestoreLayout()
    if ns.IsCombat() then ns.Notify("Restore layouts after combat."); return false end
    local previous = ns.db.previousLayout
    if type(previous) ~= "table" or type(previous.panels) ~= "table" then
        ns.Notify("There is no saved layout reset to undo."); return false
    end
    local name = previous.name
    if name ~= "Healing" and name ~= "Leveling" then return false end
    ns.db.layouts[name] = ns.Copy(previous.panels)
    ns.db.previousLayout = nil
    ns.db.layout = name
    for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    ns.Notify(name .. " arrangement restored.")
    return true
end

function ns.Diagnostics()
    local version, build, date, interface = ns.Call(GetBuildInfo)
    local lines = {
        "Priest Companion " .. ns.VERSION,
        "Client: " .. ns.Text(version, "unavailable") .. " / " .. ns.Text(build, "unavailable"),
        "Interface: " .. ns.Text(interface, "unavailable") .. "; target: " .. ns.TARGET_INTERFACE,
        "Locale: " .. ns.Text(ns.Call(GetLocale), "unavailable"),
        "Layout: " .. (ns.db and ns.db.layout or "not initialized"),
        "Game runtime validation: required; offline tests cannot establish compatibility.",
        "Capabilities:",
        "  Quest log: " .. tostring(C_QuestLog ~= nil),
        "  Item API: " .. tostring(C_Item ~= nil),
        "  Secret-value guard: " .. tostring(hasFunction(issecretvalue)),
        "  XP message event registered: " .. tostring(ns.events.CHAT_MSG_COMBAT_XP_GAIN ~= nil),
    }
    local errorKeys = {}
    for key in pairs(ns.errors) do errorKeys[#errorKeys + 1] = key end
    table.sort(errorKeys)
    lines[#lines + 1] = "Module errors: " .. #errorKeys
    for _, key in ipairs(errorKeys) do lines[#lines + 1] = "  " .. key end
    lines[#lines + 1] = "This report excludes character names, quest data, shopping lists, and raw errors."
    return table.concat(lines, "\n")
end

function ns.RegisterCommand(name, callback) ns.commands[name] = callback end

function ns.RunCommand(message)
    if not ns.ready then ns.Notify("Settings are not ready. See the login error, if any."); return end
    local command, rest = ns.Text(message, ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = (command or ""):lower()
    if command == "" or command == "settings" then
        ns.SetPanelVisible("settings", not ns.PanelSettings("settings").shown)
    elseif command == "lock" then ns.SetLocked(true)
    elseif command == "unlock" then ns.SetLocked(false)
    elseif command == "layout" then
        local value = rest:lower()
        if value == "healing" then ns.ApplyLayout("Healing")
        elseif value == "leveling" then ns.ApplyLayout("Leveling")
        else ns.Notify("Use /pc layout healing or /pc layout leveling.") end
    elseif command == "show" or command == "hide" then
        local id = rest:lower()
        if id == "all" then
            for _, moduleID in ipairs(ns.order) do ns.SetPanelVisible(moduleID, command == "show") end
        else ns.SetPanelVisible(id, command == "show") end
    elseif command == "resetlayout" then ns.ResetLayout()
    elseif command == "restorelayout" then ns.RestoreLayout()
    elseif command == "diagnostics" then ns.UI.MakeCopyBox("Diagnostics", ns.Diagnostics())
    elseif ns.commands[command] then
        local ok, err = pcall(ns.commands[command], rest)
        if not ok then recordError("command-" .. command, err) end
    else
        ns.Notify("/pc | /pc unlock | /pc lock | /pc layout healing | /pc layout leveling")
        ns.Notify("/pc show <panel> | /pc hide <panel> | /pc resetlayout | /pc restorelayout | /pc diagnostics")
        ns.Notify("Panels: " .. table.concat(ns.order, ", "))
    end
end

SLASH_PRIESTCOMPANION1 = "/pc"
SLASH_PRIESTCOMPANION2 = "/priestcompanion"
SlashCmdList.PRIESTCOMPANION = ns.RunCommand
BINDING_HEADER_PRIESTCOMPANION = "Priest Companion"
BINDING_NAME_PRIESTCOMPANION_TOGGLE = "Open panel manager"
BINDING_NAME_PRIESTCOMPANION_LOCK = "Lock / unlock panels"
BINDING_NAME_PRIESTCOMPANION_LAYOUT = "Switch Healing / Leveling layout"
function PriestCompanion_Toggle() ns.RunCommand("") end
function PriestCompanion_Lock() if ns.ready then ns.SetLocked(not ns.db.locked) end end
function PriestCompanion_Layout()
    if ns.ready then ns.ApplyLayout(ns.db.layout == "Healing" and "Leveling" or "Healing") end
end

local function initializeDatabase()
    if type(PriestCompanionDB) == "table" and ns.Number(PriestCompanionDB.schema, 1) > 1 then
        ns.Notify("These saved settings belong to a newer addon version. This alpha left them unchanged.")
        return false
    end
    PriestCompanionDB = ns.Defaults(PriestCompanionDB, {
        schema=1, layout="Leveling", locked=true, layouts={Healing={},Leveling={}}, modules={},
    })
    ns.db = PriestCompanionDB
    if ns.db.layout ~= "Healing" and ns.db.layout ~= "Leveling" then ns.db.layout = "Leveling" end
    return true
end

local function initializePanels()
    if ns.ready or not ns.db then return end
    for _, id in ipairs(ns.order) do
        local module = ns.modules[id]
        local ok, err = pcall(function()
            module.frame = ns.UI.CreatePanel(module)
            module.body = module.frame.body
            ns.frames[id] = module.frame
            if module.Create then module:Create() end
        end)
        if not ok then recordError("create-" .. id, err) end
    end
    ns.ready = true
    for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    ns.RefreshAll()
    if not ns.db.welcomed then
        ns.db.welcomed = true
        ns.Notify("Alpha loaded. /pc opens panels and layouts; /pc unlock enables dragging and resizing.")
        ns.SetPanelVisible("settings", true)
    end
    local _, _, _, interface = ns.Call(GetBuildInfo)
    if ns.Number(interface) and interface ~= ns.TARGET_INTERFACE then
        ns.Notify("This alpha targets Forever interface 16001; this client reports " .. interface .. ".")
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if ns.Readable(name) and name == addonName then initializeDatabase() end
    elseif event == "PLAYER_LOGIN" then initializePanels()
    elseif event == "PLAYER_LOGOUT" and ns.ready then
        for _, id in ipairs(ns.order) do ns.SavePlacement(id) end
    elseif event == "PLAYER_REGEN_DISABLED" and ns.ready then
        for id, frame in pairs(ns.frames) do
            frame:StopMovingOrSizing()
            ns.SavePlacement(id)
            if frame.UpdateLock then frame:UpdateLock() end
        end
    elseif event == "PLAYER_REGEN_ENABLED" and ns.ready then
        if ns.pendingLayout then
            local pending = ns.pendingLayout; ns.pendingLayout = nil; ns.ApplyLayout(pending)
        end
        if ns.pendingVisibility then
            local pending = ns.pendingVisibility; ns.pendingVisibility = nil
            for id, visible in pairs(pending) do ns.SetPanelVisible(id, visible) end
        end
        for _, frame in pairs(ns.frames) do if frame.UpdateLock then frame:UpdateLock() end end
        ns.RefreshAll()
    elseif (event == "UI_SCALE_CHANGED" or event == "DISPLAY_SIZE_CHANGED") and ns.ready then
        for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    end
    local callbacks = ns.events[event]
    if callbacks and ns.ready then
        for _, callback in ipairs(callbacks) do
            local ok, err = pcall(callback, event, ...)
            if not ok then recordError("event-" .. event, err) end
        end
    end
end)

for _, event in ipairs({"ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    pcall(eventFrame.RegisterEvent, eventFrame, event)
end

ns.Models.Core = { Clamp=clamp, InitializeDatabase=initializeDatabase, InitializePanels=initializePanels }
ns.eventFrame = eventFrame
