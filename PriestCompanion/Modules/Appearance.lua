local addonName, ns = ...
local UI = ns.UI
local tooltipHooked = false

local function updateFonts(db)
    UI.SetFontDelta(db.fontDelta)
end

local function tooltipIsUsable(tooltip)
    if not tooltip or ns.IsCombat() then return false end
    if tooltip.IsForbidden and ns.Call(tooltip.IsForbidden, tooltip) then return false end
    return true
end

ns.RegisterModule({
    id="appearance", title="Interface preferences", width=370, height=365, minWidth=340, minHeight=335,
    description="Text size, panel backgrounds, optional tooltip placement and native Edit Mode access.",
    defaultEnabled={Healing=false,Leveling=false},
    Create=function(self)
        local db = ns.ModuleDB("appearance", {fontDelta=0,cursorTooltip=false})
        db.fontDelta = ns.Clamp(db.fontDelta, -1, 4, 0)
        updateFonts(db)
        UI.Text(self.body, "Addon text size", 0, 0, 13, 320)
        UI.Button(self.body, "Smaller", 0, 26, 90, 25, function()
            db.fontDelta = ns.Clamp(db.fontDelta - 1, -1, 4, 0)
            updateFonts(db); ns.Refresh("appearance")
        end)
        UI.Button(self.body, "Larger", 98, 26, 90, 25, function()
            db.fontDelta = ns.Clamp(db.fontDelta + 1, -1, 4, 0)
            updateFonts(db); ns.Refresh("appearance")
        end)
        self.fontStatus = UI.Text(self.body, "", 203, 32, 12, 110)

        UI.Text(self.body, "Panel background opacity", 0, 72, 13, 320)
        UI.Text(self.body, "Applies to panels in the current layout.", 0, 94, 11, 320)
        local function opacity(amount)
            if ns.IsCombat() then ns.Notify("Change appearance after combat."); return end
            for _, id in ipairs(ns.order) do
                local settings = ns.PanelSettings(id)
                settings.opacity = ns.Clamp(settings.opacity + amount, 0.35, 1, 0.94)
                ns.ApplyPanel(id)
            end
        end
        UI.Button(self.body, "Lighter", 0, 116, 90, 25, function() opacity(-0.1) end)
        UI.Button(self.body, "More solid", 98, 116, 100, 25, function() opacity(0.1) end)

        self.tooltipCheck = UI.Check(self.body, "Place ordinary tooltips near the cursor", 0, 162, function(value)
            db.cursorTooltip = value
            if GameTooltip and tooltipIsUsable(GameTooltip) then GameTooltip:Hide() end
        end)
        self.tooltipCheck.label:SetWidth(295)
        UI.Text(self.body, "Optional. Applies outside combat; default is off.", 26, 190, 11, 295, {0.72,0.75,0.8})

        self.editButton = UI.Button(self.body, "Open native Edit Mode", 0, 226, 190, 26, function()
            if ns.IsCombat() then ns.Notify("Open Edit Mode after combat."); return end
            if EditModeManagerFrame and type(ShowUIPanel) == "function" then
                ns.Call(ShowUIPanel, EditModeManagerFrame)
            else ns.Notify("Use Escape > Edit Mode in the game menu if your client offers it.") end
        end)
        UI.Text(self.body, "Use native Edit Mode for Blizzard frames. These preferences style this addon's panels.", 0, 266, 11, 320)

        if not tooltipHooked and type(hooksecurefunc) == "function" and type(GameTooltip_SetDefaultAnchor) == "function" then
            hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
                if db.cursorTooltip and tooltipIsUsable(tooltip) then
                    tooltip:SetOwner(parent or UIParent, "ANCHOR_CURSOR")
                end
            end)
            tooltipHooked = true
        end
    end,
    Refresh=function(self)
        local db = ns.ModuleDB("appearance", {})
        self.fontStatus:SetText((db.fontDelta >= 0 and "+" or "") .. db.fontDelta .. " pt")
        self.tooltipCheck:SetChecked(db.cursorTooltip)
    end,
})
