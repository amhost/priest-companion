local addonName, ns = ...
local UI = ns.UI
UI.fonts = {}
UI.accent = {0.72, 0.64, 0.94}

local function styleFrame(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1})
    frame:SetBackdropColor(0.055, 0.06, 0.085, 0.94)
    frame:SetBackdropBorderColor(0.28, 0.27, 0.37, 1)
end

function UI.Text(parent, text, x, y, size, width, color)
    local label = parent:CreateFontString(nil, "OVERLAY")
    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    label.pcBaseSize = size or 12
    label:SetFont(font, label.pcBaseSize + (UI.fontDelta or 0), "")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    if width then label:SetWidth(width) end
    label:SetJustifyH("LEFT")
    label:SetJustifyV("TOP")
    label:SetWordWrap(true)
    local c = color or {0.9, 0.91, 0.95}
    label:SetTextColor(c[1], c[2], c[3])
    label:SetText(ns.Text(text, ""))
    UI.fonts[#UI.fonts + 1] = label
    return label
end

function UI.SetFontDelta(delta)
    UI.fontDelta = ns.Clamp(delta, -1, 4, 0)
    local font = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
    for _, label in ipairs(UI.fonts) do label:SetFont(font, label.pcBaseSize + UI.fontDelta, "") end
    ns.RefreshAll()
end

function UI.Button(parent, text, x, y, width, height, onClick)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", x or 0, -(y or 0))
    button:SetSize(width or 90, height or 24)
    styleFrame(button)
    button:SetBackdropColor(0.12, 0.12, 0.18, 1)
    local label = UI.Text(button, text, 5, 5, 11, (width or 90) - 10)
    label:ClearAllPoints()
    label:SetPoint("CENTER")
    label:SetJustifyH("CENTER")
    button.label = label
    button.SetText = function(_, value) label:SetText(value) end
    button.GetText = function() return label:GetText() end
    button:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(UI.accent)) end)
    button:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.28, 0.27, 0.37, 1) end)
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

function UI.CreatePanel(module)
    local frame = CreateFrame("Frame", "PriestCompanionPanel_" .. module.id, UIParent, "BackdropTemplate")
    frame:SetSize(module.width or 320, module.height or 280)
    frame:SetFrameStrata(module.internal and "DIALOG" or "MEDIUM")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    if frame.SetResizeBounds then
        frame:SetResizeBounds(module.minWidth or 260, module.minHeight or 160, 1000, 900)
    elseif frame.SetMinResize then frame:SetMinResize(module.minWidth or 260, module.minHeight or 160) end
    styleFrame(frame)

    local header = CreateFrame("Button", nil, frame)
    header:SetPoint("TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", -26, -1)
    header:SetHeight(29)
    header:RegisterForDrag("LeftButton")
    local headerBG = header:CreateTexture(nil, "BACKGROUND")
    headerBG:SetAllPoints()
    headerBG:SetColorTexture(0.12, 0.105, 0.18, 1)
    frame.title = UI.Text(header, module.title, 10, 7, 13, (module.width or 320) - 100, UI.accent)
    frame.moveLabel = UI.Text(header, "", 0, 8, 10, 55, {0.72,0.74,0.8})
    frame.moveLabel:ClearAllPoints()
    frame.moveLabel:SetPoint("TOPRIGHT", -6, -8)
    frame.moveLabel:SetJustifyH("RIGHT")
    header:SetScript("OnDragStart", function()
        if ns.db and not ns.db.locked and not ns.IsCombat() then frame:StartMoving(); frame:Raise() end
    end)
    header:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); ns.SavePlacement(module.id) end)
    header:SetScript("OnMouseDown", function() frame:Raise() end)
    UI.Tooltip(header, "Drag this title when panels are unlocked. Use /pc unlock or the panel manager.")

    local close = UI.Button(frame, "x", 0, 0, 22, 22, function() ns.SetPanelVisible(module.id, false) end)
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", -4, -4)
    UI.Tooltip(close, "Hide this panel in the current layout. Restore it from /pc.")

    frame.body = CreateFrame("Frame", nil, frame)
    frame.body:SetPoint("TOPLEFT", 10, -38)
    frame.body:SetPoint("BOTTOMRIGHT", -10, 16)
    if frame.body.SetClipsChildren then frame.body:SetClipsChildren(true) end

    local grip = CreateFrame("Button", nil, frame)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:SetSize(18, 18)
    local gripText = UI.Text(grip, "/", 3, 0, 16, 14, {0.65,0.62,0.78})
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function()
        if ns.db and not ns.db.locked and not ns.IsCombat() then frame:StartSizing("BOTTOMRIGHT") end
    end)
    grip:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); ns.SavePlacement(module.id) end)
    UI.Tooltip(grip, "Drag to resize. Size is saved separately for Healing and Leveling.")
    frame.grip = grip

    frame.UpdateLock = function(self)
        local unlocked = ns.db and not ns.db.locked and not ns.IsCombat()
        self.grip:SetShown(unlocked)
        self.moveLabel:SetText(unlocked and "drag" or "")
        headerBG:SetColorTexture(unlocked and 0.18 or 0.12, 0.105, unlocked and 0.25 or 0.18, 1)
    end
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
