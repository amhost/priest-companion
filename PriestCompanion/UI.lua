local addonName, ns = ...
local UI = ns.UI
UI.fonts = {}
UI.accent = {1, 0.82, 0}
UI.textColor = {1, 1, 1}

local function styleFrame(frame)
    -- These are the client's own tooltip assets, also used by Questie's tracker.
    -- No textures or fonts are bundled or replaced globally.
    frame:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16,
        insets={left=4, right=4, top=4, bottom=4}})
    frame:SetBackdropColor(0, 0, 0, 0.94)
    frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.94)
end

local function setLabelFont(label, size, fontObject)
    if fontObject then ns.Call(label.SetFontObject, label, fontObject) end
    local path, _, flags
    if fontObject and ns.Readable(fontObject) then
        path, _, flags = ns.Call(fontObject.GetFont, fontObject)
    end
    label.pcBaseSize = ns.Number(size, 12)
    label.pcFontPath = ns.Text(path, STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF")
    label.pcFontFlags = ns.Text(flags, "")
    label:SetFont(label.pcFontPath, label.pcBaseSize + (UI.fontDelta or 0), label.pcFontFlags)
    ns.Call(label.SetShadowColor, label, 0, 0, 0, 1)
    ns.Call(label.SetShadowOffset, label, 1, -1)
    UI.fonts[#UI.fonts + 1] = label
end

function UI.Text(parent, text, x, y, size, width, color)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    setLabelFont(label, size, color == UI.accent and GameFontNormal or GameFontHighlight)
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    local c = color or UI.textColor
    label:SetTextColor(c[1], c[2], c[3])
    label:SetText(ns.Text(text, ""))
    return label
end

function UI.SetFontDelta(delta)
    UI.fontDelta = ns.Clamp(delta, -1, 4, 0)
    for _, label in ipairs(UI.fonts) do
        label:SetFont(label.pcFontPath, label.pcBaseSize + UI.fontDelta, label.pcFontFlags)
    end
    ns.RefreshAll()
end

function UI.Button(parent, text, x, y, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    button:SetSize(width or 90, height or 24)
    button:SetText(ns.Text(text, ""))
    local label = button:GetFontString()
    if label then
        setLabelFont(label, 11, GameFontNormal)
    else
        -- The bounded test double and a stripped client may lack template text.
        label = UI.Text(button, text, 5, 5, 11, (width or 90) - 10, UI.accent)
    end
    label:ClearAllPoints()
    label:SetPoint("CENTER")
    label:SetWidth((width or 90) - 10)
    label:SetJustifyH("CENTER")
    button.label = label
    button.SetText = function(_, value) label:SetText(value) end
    button.GetText = function() return label:GetText() end
    button.SetSelected = function(self, selected)
        self.pcSelected = selected == true
        if self.pcSelected then ns.Call(self.LockHighlight, self)
        else ns.Call(self.UnlockHighlight, self) end
    end
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

-- Text actions fit alongside tracked objectives without a row of boxed buttons.
-- The same argument order as UI.Button lets feature panels choose either style.
function UI.TrackerAction(parent, text, x, y, width, height, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    button:SetSize(width or 90, height or 24)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local label = UI.Text(button, text, 0, 0, 12, width or 90, UI.accent)
    label:ClearAllPoints()
    label:SetPoint("LEFT", button, "LEFT", 2, 0)
    label:SetWordWrap(false)
    ns.Call(label.SetMaxLines, label, 1)
    button.label = label
    button.SetText = function(_, value) label:SetText(ns.Text(value, "")) end
    button.GetText = function() return label:GetText() end
    local function updateColor(self)
        local enabled = ns.Call(self.IsEnabled, self)
        if enabled == false then label:SetTextColor(0.5, 0.5, 0.5)
        elseif self.pcSelected or self.pcHover then label:SetTextColor(1, 1, 1)
        else label:SetTextColor(UI.accent[1], UI.accent[2], UI.accent[3]) end
    end
    button.SetSelected = function(self, selected)
        self.pcSelected = selected == true
        updateColor(self)
    end
    button:SetScript("OnEnter", function(self) self.pcHover=true; updateColor(self) end)
    button:SetScript("OnLeave", function(self) self.pcHover=nil; updateColor(self) end)
    button:SetScript("OnEnable", updateColor)
    button:SetScript("OnDisable", updateColor)
    button:HookScript("OnSizeChanged", function(_, newWidth)
        label:SetWidth(math.max(1, newWidth - 4))
    end)
    if onClick then button:SetScript("OnClick", onClick) end
    return button
end

function UI.Input(parent, x, y, width, height, placeholder, onEnter)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", (x or 0) + 4, -(y or 0))
    box:SetSize(math.max(30, (width or 180) - 8), height or 24)
    box:SetFontObject(GameFontHighlightSmall)
    box:SetAutoFocus(false)
    box:SetMaxLetters(512)
    box:SetTextInsets(3, 3, 0, 0)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    box:SetScript("OnEnterPressed", function(self)
        if onEnter then onEnter(self:GetText(), self) end
        self:ClearFocus()
    end)
    if placeholder and placeholder ~= "" then UI.Tooltip(box, placeholder) end
    return box
end

function UI.Check(parent, text, x, y, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    check:SetSize(22, 22)
    check.label = UI.Text(check, text, 25, 3, 12, math.max(140, (parent:GetWidth() or 280) - (x or 0) - 30))
    check:SetScript("OnClick", function(self)
        if onClick then onClick(self:GetChecked() == true, self) end
    end)
    return check
end

function UI.Slider(parent, label, x, y, width, low, high, step, onChanged)
    local control = CreateFrame("Frame", nil, parent)
    control:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    control:SetSize(width or 280, 48)
    control.label = UI.Text(control, label, 0, 0, 12, (width or 280) - 70)
    control.valueText = UI.Text(control, "", 0, 0, 12, 65, UI.accent)
    control.valueText:ClearAllPoints()
    control.valueText:SetPoint("TOPRIGHT", 0, 0)
    control.valueText:SetJustifyH("RIGHT")
    local slider = CreateFrame("Slider", nil, control)
    control.slider = slider
    slider:SetPoint("TOPLEFT", 0, -23)
    slider:SetPoint("TOPRIGHT", 0, -23)
    slider:SetHeight(18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0); track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.3, 0.3, 0.3, 1)
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    thumb:SetSize(10, 18)
    thumb:SetVertexColor(UI.accent[1], UI.accent[2], UI.accent[3], 1)
    control.enabled = true
    local function rounded(value)
        return ns.Clamp(low + math.floor((value - low) / step + 0.5) * step, low, high, low)
    end
    slider:SetScript("OnValueChanged", function(_, value)
        value = ns.Number(value)
        if not value then return end
        value = rounded(value)
        control.valueText:SetText(string.format("%d%%", value))
        if control.syncing or not control.enabled then return end
        if control.lastValue == value then return end
        control.lastValue = value
        if onChanged then onChanged(value) end
    end)
    control.SetDisplayValue = function(self, value, mixed)
        value = rounded(ns.Number(value, low))
        self.syncing = true
        self.lastValue = value
        slider:SetValue(value)
        self.syncing = false
        self.valueText:SetText(mixed and "Mixed" or string.format("%d%%", value))
    end
    control.SetEnabled = function(self, value)
        self.enabled = value == true
        slider:EnableMouse(self.enabled)
        slider:EnableMouseWheel(self.enabled)
        self:SetAlpha(self.enabled and 1 or 0.5)
    end
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(_, delta)
        if control.enabled and ns.Number(delta) then
            slider:SetValue(rounded(ns.Number(slider:GetValue(), low) + delta * step))
        end
    end)
    control:HookScript("OnSizeChanged", function(self, newWidth)
        self.label:SetWidth(math.max(100, newWidth - 70))
    end)
    control:SetDisplayValue(low)
    return control
end

function UI.Tooltip(widget, textOrFunction)
    widget:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        local text = type(textOrFunction) == "function" and textOrFunction(self) or textOrFunction
        if not ns.Readable(text) or type(text) ~= "string" then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text, 0.95, 0.95, 1, 1, true)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

function UI.ScrollArea(parent, top, bottom)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -(top or 0))
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -24, bottom or 0)
    if scroll.SetClipsChildren then scroll:SetClipsChildren(true) end
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(math.max(100, parent:GetWidth() - 28), 1)
    scroll:SetScrollChild(content)
    scroll:HookScript("OnSizeChanged", function(self, width)
        content:SetWidth(math.max(100, width))
    end)
    return scroll, content
end

function UI.ClearFocusWithin(parent, depth)
    if (depth or 0) > 12 or not parent then return end
    if type(parent.ClearFocus) == "function" then parent:ClearFocus() end
    if type(parent.GetChildren) == "function" then
        for _, child in ipairs({parent:GetChildren()}) do UI.ClearFocusWithin(child, (depth or 0) + 1) end
    end
end

function UI.CreatePanel(module)
    local frame = CreateFrame("Frame", "PriestCompanionPanel_" .. module.id, UIParent, "BackdropTemplate")
    frame:SetSize(module.width or 320, module.height or 280)
    frame:SetFrameStrata(module.internal and "DIALOG" or "MEDIUM")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(module.minWidth or 260, module.minHeight or 160, 1000, 900)
    elseif frame.SetMinResize then frame:SetMinResize(module.minWidth or 260, module.minHeight or 160) end
    styleFrame(frame)

    local header = CreateFrame("Button", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -26, -1)
    header:SetHeight(22)
    header:SetFrameLevel(frame:GetFrameLevel() + 10)
    header:RegisterForDrag("LeftButton")
    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetAllPoints()
    headerBG:SetColorTexture(0, 0, 0, 0)
    frame.title = UI.Text(header, module.title, 8, 4, 12, (module.width or 320) - 100, UI.accent)
    frame.moveLabel = UI.Text(header, "", 0, 4, 10, 55, {0.7,0.7,0.7})
    frame.moveLabel:ClearAllPoints()
    frame.moveLabel:SetPoint("TOPRIGHT", -6, -4)
    frame.moveLabel:SetJustifyH("RIGHT")
    header:SetScript("OnDragStart", function()
        if ns.db and not ns.db.locked and not ns.IsCombat() then frame:StartMoving(); frame:Raise() end
    end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); ns.SavePlacement(module.id) end)
    header:SetScript("OnMouseDown", function() frame:Raise() end)
    UI.Tooltip(header, "Drag this title when panels are unlocked. Use /qc unlock or the panel manager.")

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetScript("OnClick", function() ns.SetPanelVisible(module.id, false) end)
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", -1, -1)
    close:SetFrameLevel(header:GetFrameLevel() + 1)
    UI.Tooltip(close, "Hide this panel in the current layout. Restore it from /qc.")

    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetPoint("TOPLEFT", 8, -30)
    frame.body:SetPoint("BOTTOMRIGHT", -8, 8)
    if frame.body.SetClipsChildren then frame.body:SetClipsChildren(true) end

    local grip = CreateFrame("Button", nil, frame)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:SetSize(18, 18)
    UI.Text(grip, "/", 3, 0, 16, 14, UI.accent)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function()
        if ns.db and not ns.db.locked and not ns.IsCombat() then frame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); ns.SavePlacement(module.id) end)
    UI.Tooltip(grip, "Drag to resize. Size is saved separately for Healing and Leveling.")
    frame.grip = grip
    frame.header, frame.headerBG, frame.close = header, headerBG, close

    frame.UpdateAppearance = function(self)
        if not ns.db then return end
        local settings = ns.PanelSettings(module.id)
        local configurable = ns.IsCustomizablePanel(module.id)
        local unlocked = ns.db and not ns.db.locked and not ns.IsCombat()
        local background = configurable and settings.opacity or 0.94
        local content = configurable and settings.contentOpacity or 1
        if unlocked and configurable then
            background, content = math.max(background, 0.18), math.max(content, 0.35)
        end
        self:SetAlpha(1)
        self:SetBackdropColor(0, 0, 0, background)
        -- Locked gameplay panels have objective-tracker chrome: no frame edge
        -- or colored title bar. Saved background opacity remains literal.
        local border = configurable and not unlocked and 0 or background
        self:SetBackdropBorderColor(0.6, 0.6, 0.6, border)
        headerBG:SetColorTexture(0, 0, 0, configurable and not unlocked and 0 or background)
        local hideHeader = configurable and settings.hideHeader
        header:SetShown(not hideHeader or unlocked)
        close:SetShown(not hideHeader or unlocked)
        self.body:SetAlpha(content)
        if content == 0 and self.body:IsShown() then UI.ClearFocusWithin(self.body) end
        self.body:SetShown(content > 0)
        -- The shell never intercepts gameplay clicks while locked. Actual child
        -- controls keep their own hit testing, and zero-alpha content is hidden.
        self:EnableMouse(unlocked)
        -- Editing temporarily adds room for the title instead of drawing it on
        -- top of the resource bars. SavePlacement excludes this extra height.
        local extra = hideHeader and unlocked and 22 or 0
        if (self.pcHeaderExtra or 0) ~= extra then
            local minWidth, minHeight = ns.PanelMinimum(module.id, settings)
            local baseHeight = math.max(minHeight, self:GetHeight() - (self.pcHeaderExtra or 0))
            local x, y = self:GetCenter()
            local px, py = UIParent:GetCenter()
            local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
            if ns.Number(x) and ns.Number(y) and ns.Number(px) and ns.Number(py) and ns.Number(scale) and scale > 0 then
                self:ClearAllPoints()
                self:SetPoint("CENTER", UIParent, "CENTER", x - px / scale, y - py / scale)
            end
            self.pcHeaderExtra = extra
            self:SetHeight(baseHeight + extra)
            if self.SetResizeBounds then self:SetResizeBounds(minWidth, minHeight + extra, 1000, 900 + extra)
            elseif self.SetMinResize then self:SetMinResize(minWidth, minHeight + extra) end
        end
        local inset = hideHeader and not unlocked and 8 or 30
        if self.pcBodyInset ~= inset then
            self.pcBodyInset = inset
            self.body:ClearAllPoints()
            self.body:SetPoint("TOPLEFT", 8, -inset)
            self.body:SetPoint("BOTTOMRIGHT", -8, 8)
            ns.Refresh(module.id)
        end
        self.grip:SetShown(unlocked)
        self.moveLabel:SetText(unlocked and "drag" or "")
    end
    frame.UpdateLock = frame.UpdateAppearance
    frame:SetScript("OnSizeChanged", function(self, width)
        self.title:SetWidth(math.max(100, width - 110))
        if ns.ready and not ns.applying then ns.Refresh(module.id) end
    end)
    frame:SetScript("OnShow", function() ns.Refresh(module.id) end)
    frame:SetScript("OnHide", function(self)
        self:StopMovingOrSizing()
        if not ns.applying then ns.SavePlacement(module.id) end
    end)
    frame:Hide()
    return frame
end

ns.RegisterModule({
    id="copy", title="Copy text", internal=true, width=560, height=400, minWidth=360, minHeight=240,
    defaultEnabled={Healing=false,Leveling=false},
    Create=function(self)
        UI.Text(self.body, "Ctrl+A, then Ctrl+C to copy. Edits here are not saved.", 0, 0, 12, 500)
        local scroll, content = UI.ScrollArea(self.body, 34, 4)
        local box = CreateFrame("EditBox", nil, content)
        box:SetMultiLine(true)
        box:SetAutoFocus(false)
        box:SetFontObject(GameFontHighlightSmall)
        box:SetPoint("TOPLEFT", 0, 0)
        box:SetSize(480, 300)
        box:SetMaxLetters(12000)
        box:SetScript("OnEscapePressed", function(widget) widget:ClearFocus() end)
        local measure = content:CreateFontString(nil, "OVERLAY")
        measure:SetFontObject(GameFontHighlightSmall)
        measure:SetWordWrap(true)
        measure:Hide()
        local function reflow()
            measure:SetWidth(math.max(250, box:GetWidth()))
            measure:SetText(box:GetText())
            local height = math.max(280, measure:GetStringHeight() + 24)
            box:SetHeight(height)
            content:SetHeight(height + 20)
        end
        box:SetScript("OnTextChanged", reflow)
        content:SetHeight(320)
        scroll:HookScript("OnSizeChanged", function(_, width)
            box:SetWidth(math.max(250, width - 8)); reflow()
        end)
        self.box = box
        self.frame:HookScript("OnShow", function()
            if self.wantFocus then
                self.wantFocus = nil
                box:HighlightText(); box:SetFocus()
            end
        end)
    end,
})

function UI.MakeCopyBox(title, text)
    if not ns.ready then return end
    local module = ns.modules.copy
    module.frame.title:SetText(ns.Text(title, "Copy text"))
    module.box:SetText(ns.Text(text, ""))
    module.wantFocus = true
    if ns.SetPanelVisible("copy", true) then
        module.wantFocus = nil
        module.box:HighlightText(); module.box:SetFocus()
    end
end
