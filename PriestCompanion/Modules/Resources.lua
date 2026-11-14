local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Resources = Model

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

local powerNames = { MANA="Mana", RAGE="Rage", ENERGY="Energy", FOCUS="Focus", RUNIC_POWER="Runic power" }
local powerColors = {
    MANA={0.49,0.57,0.92}, RAGE={0.9,0.25,0.25}, ENERGY={0.95,0.85,0.25},
    FOCUS={1,0.5,0.25}, RUNIC_POWER={0.2,0.8,1},
}
local defaultColor = {0.55,0.65,0.82}

function Model.PowerPresentation(token)
    if not ns.Readable(token) or type(token) ~= "string" or #token > 32 or not token:match("^[A-Z_]+$") then
        return "Power", defaultColor[1], defaultColor[2], defaultColor[3]
    end
    local label = ns.Text(_G[token])
    if label == "" then label = powerNames[token] or "Power" end
    local color = powerColors[token] or defaultColor
    if ns.Readable(PowerBarColor) and type(PowerBarColor) == "table" then
        local candidate = PowerBarColor[token]
        if ns.Readable(candidate) and type(candidate) == "table" then
            local r, g, b = ns.Number(candidate.r), ns.Number(candidate.g), ns.Number(candidate.b)
            if r and g and b then
                return ns.CleanText(label, 40), ns.Clamp(r,0,1), ns.Clamp(g,0,1), ns.Clamp(b,0,1)
            end
        end
    end
    return ns.CleanText(label, 40), color[1], color[2], color[3]
end

local function resourceBar(parent, y, color)
    local bar = CreateFrame("StatusBar", nil, parent)
    bar:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
    bar:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -y)
    bar:SetHeight(20)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    bar:SetStatusBarColor(color[1], color[2], color[3])
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints(bar)
    background:SetColorTexture(0.13, 0.14, 0.19, 0.9)
    local label = ns.UI.Text(bar, "", 6, 3, 11, 288)
    label:SetWordWrap(false)
    return bar, label
end

local function updateResource(bar, label, title, current, maximum)
    local text, status = Model.ResourceText(current, maximum)
    -- Restricted values are forwarded only to permitted display setters. They
    -- never enter comparisons, formatted text, table keys or saved variables.
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

ns.RegisterModule({
    id = "resources", title = "Resources",
    description = "Optional health and current-resource bars for any class.",
    width = 320, height = 92, minWidth = 200, minHeight = 68,
    defaultEnabled = { Healing = false, Leveling = false },
    Create = function(self)
        self.health, self.healthLabel = resourceBar(self.body, 0, {0.38,0.75,0.58})
        self.power, self.powerLabel = resourceBar(self.body, 26, defaultColor)
        for _, event in ipairs({"UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER",
            "UNIT_DISPLAYPOWER", "PLAYER_ENTERING_WORLD"}) do
            ns.On(event, function(_, unit)
                if not ns.Readable(unit) then return end
                if unit == nil or unit == "player" or type(unit) ~= "string" then ns.Refresh("resources") end
            end)
        end
        self.body:HookScript("OnSizeChanged", function() ns.Refresh("resources") end)
    end,
    Refresh = function(self)
        updateResource(self.health, self.healthLabel, "Health", ns.Call(UnitHealth, "player"), ns.Call(UnitHealthMax, "player"))
        local _, token = ns.Call(UnitPowerType, "player")
        local title, r, g, b = Model.PowerPresentation(token)
        self.power:SetStatusBarColor(r, g, b)
        -- Omitting the power-type argument follows the current resource. Mana
        -- must not remain selected when a class or form uses rage or energy.
        updateResource(self.power, self.powerLabel, title, ns.Call(UnitPower, "player"), ns.Call(UnitPowerMax, "player"))
        local width = math.max(100, self.body:GetWidth() - 12)
        self.healthLabel:SetWidth(width)
        self.powerLabel:SetWidth(width)
    end,
})
