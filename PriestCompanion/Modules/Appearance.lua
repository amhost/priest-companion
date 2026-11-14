local addonName, ns = ...
local UI = ns.UI
local tooltipHooked = false

local function updateFonts(db)
    UI.SetFontDelta(db.fontDelta)
end

local function tooltipIsUsable(tooltip)
    if not tooltip or ns.IsCombat() then return false end
    if tooltip.IsForbidden then
        local forbidden = ns.Call(tooltip.IsForbidden, tooltip)
        if not ns.Readable(forbidden) or forbidden then return false end
    end
    return true
end

local function choices()
    local result = {"all"}
    for _, id in ipairs(ns.order) do
        if ns.IsCustomizablePanel(id) then result[#result + 1] = id end
    end
    return result
end

local function normalizeSelection(id)
    if not ns.Readable(id) or type(id) ~= "string" then return "all" end
    local aliases = {references="keys", preparation="prep", priest="resources"}
    id = aliases[id] or id
    return ns.IsCustomizablePanel(id) and id or "all"
end

local function selectedValue(self, key, fallback)
    local first, found, mixed
    for _, id in ipairs(ns.order) do
        if ns.IsCustomizablePanel(id) and (self.selected == "all" or self.selected == id) then
            local value = ns.PanelSettings(id)[key]
            if type(fallback) == "boolean" then
                value = ns.Readable(value) and value == true
            else
                value = ns.Number(value, fallback)
            end
            if not found then
                first, found = value, true
            elseif value ~= first then
                mixed = true
            end
        end
    end
    if not found then first = fallback end
    return first, mixed == true
end

local function place(widget, parent, x, y)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
end

local function textHeight(label, minimum)
    return math.max(minimum or 16, ns.Number(label:GetStringHeight(), 0))
end

function ns.OpenAppearance(id)
    if not ns.ready then return false end
    local module = ns.modules.appearance
    module.selected = normalizeSelection(id)
    if module.scroll then module.scroll:SetVerticalScroll(0) end
    local opened = ns.SetPanelVisible("appearance", true)
    ns.Refresh("appearance")
    return opened
end

ns.RegisterModule({
    id="appearance", title="Appearance", internal=true,
    width=400, height=450, minWidth=340, minHeight=320,
    description="Choose a panel, adjust opacity and scale, or apply the compact layout.",
    defaultEnabled={Healing=false,Leveling=false},
    Create=function(self)
        local db = ns.ModuleDB("appearance", {fontDelta=0,cursorTooltip=false})
        db.fontDelta = ns.Clamp(db.fontDelta, -1, 4, 0)
        updateFonts(db)
        self.selected = normalizeSelection(self.selected)

        local function cycle(direction)
            local list, current = choices(), 1
            for index, id in ipairs(list) do
                if id == self.selected then current = index; break end
            end
            self.selected = list[((current - 1 + direction) % #list) + 1]
            self.scroll:SetVerticalScroll(0)
            ns.Refresh("appearance")
        end
        self.prevPanel = UI.Button(self.body, "Prev", 0, 0, 54, 28, function() cycle(-1) end)
        self.nextPanel = UI.Button(self.body, "Next", 0, 0, 54, 28, function() cycle(1) end)
        self.selection = UI.Text(self.body, "All panels", 62, 4, 12, 240, UI.accent)
        self.selection:SetJustifyH("CENTER")
        UI.Tooltip(self.prevPanel, "Select the previous panel. All panels changes every gameplay panel in the current layout.")
        UI.Tooltip(self.nextPanel, "Select the next panel. Appearance and the panel manager stay visible while you adjust opacity.")

        local scroll, content = UI.ScrollArea(self.body, 44, 0)
        self.scroll, self.content = scroll, content
        self.scope = UI.Text(content, "", 0, 0, 11, 320, {0.72,0.75,0.8})
        local function change(key, value)
            ns.SetPanelAppearance(self.selected, key, value)
            ns.Refresh("appearance")
            ns.Refresh("settings")
        end
        self.sliders = {
            opacity = UI.Slider(content, "Background opacity", 0, 24, 320, 0, 100, 1,
                function(value) change("opacity", value / 100) end),
            contentOpacity = UI.Slider(content, "Content opacity", 0, 84, 320, 0, 100, 1,
                function(value) change("contentOpacity", value / 100) end),
            scale = UI.Slider(content, "Scale", 0, 144, 320, 50, 150, 1,
                function(value) change("scale", value / 100) end),
        }
        UI.Tooltip(self.sliders.opacity.slider, "0% removes panel backgrounds. Bars and text keep their separate content opacity. Changes apply to the current layout.")
        UI.Tooltip(self.sliders.contentOpacity.slider, "Controls bars, text and other panel content. At 0%, content is invisible; reopen Appearance with /qc appearance to restore it.")
        UI.Tooltip(self.sliders.scale.slider, "50% to 150% in 1% steps. Scale changes the whole panel, including its text. Mixed means the selected panels have different values.")

        self.hideTitle = UI.Check(content, "Hide title when locked", 0, 210, function(value)
            change("hideHeader", value)
        end)
        UI.Tooltip(self.hideTitle, "Hide the selected panels' titles while locked. Unlock panels to reveal their titles and drag handles. A mixed selection becomes checked for every selected panel on the first click.")

        self.compact = UI.Button(content, "Compact layout", 0, 280, 150, 30, function()
            ns.ApplyCompactLayout()
            ns.Refresh("appearance")
            ns.Refresh("settings")
        end)
        self.undo = UI.Button(content, "Undo layout", 160, 280, 150, 30, function()
            ns.RestoreLayout()
            ns.Refresh("appearance")
            ns.Refresh("settings")
        end)
        UI.Tooltip(self.compact, "Apply compact sizing, opacity and visibility to the active layout. Undo layout restores the saved previous layout.")
        UI.Tooltip(self.undo, "Restore the layout saved before the most recent Compact layout or Reset layout action.")

        self.fontHeading = UI.Text(content, "Text size", 0, 330, 13, 320)
        self.smaller = UI.Button(content, "Smaller", 0, 354, 90, 28, function()
            db.fontDelta = ns.Clamp(db.fontDelta - 1, -1, 4, 0)
            updateFonts(db)
        end)
        self.larger = UI.Button(content, "Larger", 98, 354, 90, 28, function()
            db.fontDelta = ns.Clamp(db.fontDelta + 1, -1, 4, 0)
            updateFonts(db)
        end)
        self.fontStatus = UI.Text(content, "", 202, 360, 12, 100)
        UI.Tooltip(self.smaller, "Decrease addon label text size. This preference applies to both layouts.")
        UI.Tooltip(self.larger, "Increase addon label text size. This preference applies to both layouts.")

        self.tooltipCheck = UI.Check(content, "Tooltips near cursor", 0, 400, function(value)
            db.cursorTooltip = value
            if GameTooltip and tooltipIsUsable(GameTooltip) then GameTooltip:Hide() end
        end)
        UI.Tooltip(self.tooltipCheck, "Optional; off by default. Place ordinary tooltips near the cursor outside combat. This preference applies to both layouts.")
        self.editButton = UI.Button(content, "Open native Edit Mode", 0, 438, 320, 30, function()
            if ns.IsCombat() then ns.Notify("Open Edit Mode after combat."); return end
            if EditModeManagerFrame and type(ShowUIPanel) == "function" then
                ns.Call(ShowUIPanel, EditModeManagerFrame)
            else ns.Notify("Use Escape > Edit Mode in the game menu if your client offers it.") end
        end)
        UI.Tooltip(self.editButton, "Use the game's Edit Mode for Blizzard frames. Appearance controls style this addon's panels.")

        self.Reflow = function()
            if self.reflowing then return end
            self.reflowing = true
            local bodyWidth = self.body:GetWidth()
            self.selection:SetWidth(math.max(120, bodyWidth - 124))
            self.nextPanel:ClearAllPoints()
            self.nextPanel:SetPoint("TOPRIGHT", self.body, "TOPRIGHT", 0, 0)
            local headerHeight = math.max(28, textHeight(self.selection) + 8)
            scroll:ClearAllPoints()
            scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -(headerHeight + 12))
            scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, 0)
            local width = math.max(240, content:GetWidth())
            self.scope:SetWidth(width)
            local y = textHeight(self.scope) + 12
            for _, key in ipairs({"opacity", "contentOpacity", "scale"}) do
                local slider = self.sliders[key]
                place(slider, content, 0, y)
                slider:SetWidth(width)
                y = y + math.max(48, slider:GetHeight()) + 12
            end
            for _, check in ipairs({self.hideTitle}) do
                check.label:SetWidth(width - 30)
                place(check, content, 0, y)
                y = y + math.max(24, textHeight(check.label) + 6) + 12
            end
            local half = (width - 10) / 2
            for _, button in ipairs({self.compact, self.undo}) do
                button:SetWidth(half)
                button.label:SetWidth(half - 10)
            end
            place(self.compact, content, 0, y)
            place(self.undo, content, half + 10, y)
            y = y + 48
            self.fontHeading:SetWidth(width)
            place(self.fontHeading, content, 0, y)
            y = y + textHeight(self.fontHeading) + 8
            place(self.smaller, content, 0, y)
            place(self.larger, content, 98, y)
            place(self.fontStatus, content, 202, y + 5)
            self.fontStatus:SetWidth(math.max(50, width - 202))
            y = y + 42
            self.tooltipCheck.label:SetWidth(width - 30)
            place(self.tooltipCheck, content, 0, y)
            y = y + math.max(24, textHeight(self.tooltipCheck.label) + 6) + 12
            place(self.editButton, content, 0, y)
            self.editButton:SetWidth(width)
            self.editButton.label:SetWidth(width - 10)
            content:SetHeight(y + self.editButton:GetHeight() + 8)
            self.reflowing = false
        end
        self.body:HookScript("OnSizeChanged", self.Reflow)
        content:HookScript("OnSizeChanged", self.Reflow)

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
        local combat = ns.IsCombat()
        self.selected = normalizeSelection(self.selected)
        local selected = self.selected ~= "all" and ns.modules[self.selected] or nil
        self.selection:SetText(selected and selected.title or "All panels")
        self.scope:SetText(ns.db.layout .. (combat and " layout | change after combat" or " layout"))
        for _, key in ipairs({"opacity", "contentOpacity", "scale"}) do
            local value, mixed = selectedValue(self, key, key == "opacity" and 0.94 or 1)
            self.sliders[key]:SetDisplayValue(value * 100, mixed)
            self.sliders[key]:SetEnabled(not combat)
        end
        local hidden, mixed = selectedValue(self, "hideHeader", false)
        self.hideTitle:SetChecked(hidden and not mixed)
        self.hideTitle.label:SetText("Hide title when locked" .. (mixed and " (mixed)" or ""))
        self.hideTitle:SetEnabled(not combat)
        self.compact:SetEnabled(not combat)
        self.undo:SetEnabled(not combat and ns.db.previousLayout ~= nil)
        self.smaller:SetEnabled(db.fontDelta > -1)
        self.larger:SetEnabled(db.fontDelta < 4)
        self.fontStatus:SetText((db.fontDelta >= 0 and "+" or "") .. db.fontDelta .. " pt")
        self.tooltipCheck:SetChecked(db.cursorTooltip)
        self.editButton:SetEnabled(not combat)
        self.Reflow()
    end,
})
