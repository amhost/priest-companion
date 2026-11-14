return function(T, ns, Mock)
    local UI = ns.UI
    local original = {layouts=ns.Copy(ns.db.layouts), layout=ns.db.layout,
        locked=ns.db.locked, fontDelta=UI.fontDelta}
    local originalHighlight, originalNormal = GameFontHighlight, GameFontNormal

    -- Locale/UI font replacements must remain the source of our fonts, including
    -- after the appearance font-size action. No global FontObject is modified.
    local fontWrites = 0
    GameFontHighlight = {
        GetFont=function() return "ClientLocaleFont.ttf", 13, "OUTLINE" end,
        SetFont=function() fontWrites=fontWrites+1 end,
    }
    GameFontNormal = {GetFont=function() return "ClientHeadingFont.ttf", 13, "" end}
    local holder = CreateFrame("Frame", nil, UIParent)
    local label = UI.Text(holder, "Read a quest", 0, 0, 12, 180)
    local heading = UI.Text(holder, "Deathknell", 0, 20, 14, 180, UI.accent)
    local path, size, flags = label:GetFont()
    T.eq(path, "ClientLocaleFont.ttf", "Text respects the client's configured locale font")
    T.eq(flags, "OUTLINE", "Client font flags are preserved")
    T.eq(heading:GetFont(), "ClientHeadingFont.ttf", "Headings derive from the native normal FontObject")
    UI.SetFontDelta(2)
    path, size, flags = label:GetFont()
    T.eq(path, "ClientLocaleFont.ttf", "Changing text size does not replace the locale font")
    T.eq(size, 14, "Text size changes still apply to the native font")
    T.eq(fontWrites, 0, "Changing our text never mutates a global font object")
    T.eq(label.shadowColor[4], 1, "Tracker text has a readable shadow over the world")

    -- Native controls keep their callbacks and selection behavior. Transparent
    -- actions retain normal disabled-button input blocking, not alpha-only hiding.
    T.eq(ns.modules.settings.healing.template, "UIPanelButtonTemplate", "Settings use the client's button template")
    T.eq(ns.frames.settings.close.template, "UIPanelCloseButton", "Settings use the client's close control")
    local clicks, lastButton = 0, nil
    local action = UI.TrackerAction(holder, "Show all", 0, 40, 120, 24, function(_, button)
        clicks=clicks+1; lastButton=button
    end)
    action:Click()
    T.eq(clicks, 1, "Tracker text action invokes its callback once")
    T.eq(lastButton, "LeftButton", "Tracker text preserves the click argument")
    action:SetSelected(true)
    T.eq(action.label.textColor[3], 1, "Selected tracker action is visibly highlighted")
    action:SetEnabled(false)
    action:Click()
    T.eq(clicks, 1, "Disabled tracker action cannot invoke its callback")
    T.near(action.label.textColor[1], 0.5, "Disabled tracker action is visibly muted")
    action:SetEnabled(true)
    action:SetSelected(false)
    action:Click("RightButton")
    T.eq(clicks, 2, "Re-enabled tracker action resumes input")
    T.eq(lastButton, "RightButton", "Tracker action preserves an explicitly requested right click")
    action:SetWidth(80)
    T.eq(action.label:GetWidth(), 76, "Resizing a tracker action keeps text within the hit target")

    ns.ApplyLayout("Leveling")
    ns.SetPanelVisible("resources", true)
    ns.SetLocked(true)
    ns.SetPanelAppearance("resources", "opacity", 0.53)
    ns.SetPanelAppearance("resources", "contentOpacity", 0.42)
    ns.SetPanelAppearance("resources", "hideHeader", false)
    local frame = ns.frames.resources
    T.near(frame.background[4], 0.53, "Native restyle preserves literal saved background opacity")
    T.near(frame.body:GetAlpha(), 0.42, "Native restyle preserves independent content opacity")
    T.eq(frame.border[4], 0, "Locked gameplay panel has no window frame edge")
    T.eq(frame.headerBG.color[4], 0, "Locked gameplay title has no colored title bar")
    T.eq(frame.backdrop.bgFile, "Interface\\Tooltips\\UI-Tooltip-Background", "Panels use a client-owned background texture")
    ns.SetLocked(false)
    T.ok(frame.border[4] > 0, "Unlock exposes a visible native editing boundary")
    T.near(ns.PanelSettings("resources").opacity, 0.53, "Editing boundary does not rewrite saved opacity")
    ns.SetLocked(true)
    T.eq(frame.border[4], 0, "Lock removes editing boundary again")
    T.ok(ns.frames.settings.border[4] > 0, "Configuration retains a visible native frame")

    GameFontHighlight, GameFontNormal = originalHighlight, originalNormal
    UI.SetFontDelta(original.fontDelta or 0)
    holder:Hide()
    ns.db.layouts, ns.db.layout, ns.db.locked = original.layouts, original.layout, original.locked
    for _, id in ipairs(ns.order) do ns.ApplyPanel(id) end
    Mock.Flush()
end
