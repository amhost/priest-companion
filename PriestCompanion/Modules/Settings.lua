local addonName, ns = ...
local UI = ns.UI

local function place(widget, parent, x, y)
    widget:ClearAllPoints()
    widget:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
end

local function textHeight(label, minimum)
    return math.max(minimum or 16, ns.Number(label:GetStringHeight(), 0))
end

ns.RegisterModule({
    id="settings", title="Priest Companion", internal=true,
    width=420, height=450, minWidth=340, minHeight=350,
    defaultEnabled={Healing=false,Leveling=false},
    Create=function(self)
        self.summary = UI.Text(self.body, "", 0, 0, 12, 380)
        self.healing = UI.Button(self.body, "Healing", 0, 26, 100, 28, function() ns.ApplyLayout("Healing") end)
        self.leveling = UI.Button(self.body, "Leveling", 108, 26, 100, 28, function() ns.ApplyLayout("Leveling") end)
        self.lock = UI.Button(self.body, "Unlock", 216, 26, 100, 28, function() ns.SetLocked(not ns.db.locked) end)
        UI.Tooltip(self.lock, "Unlock panels to drag their titles or resize from their bottom corners. Lock panels to finish arranging them.")
        self.appearance = UI.Button(self.body, "Appearance", 0, 62, 160, 28, function() ns.OpenAppearance("all") end)
        self.compact = UI.Button(self.body, "Compact layout", 170, 62, 160, 28, function()
            ns.ApplyCompactLayout()
            ns.Refresh("settings")
        end)
        UI.Tooltip(self.appearance, "Adjust background opacity, content opacity, scale and titles for a selected panel or all gameplay panels.")
        UI.Tooltip(self.compact, "Apply compact sizing, opacity and visibility to this layout. Undo layout restores your previous arrangement.")

        local scroll, content = UI.ScrollArea(self.body, 102, 70)
        self.scroll, self.content, self.rows, self.rowOrder = scroll, content, {}, {}
        for _, id in ipairs(ns.order) do
            local moduleID = id
            if ns.IsCustomizablePanel(moduleID) then
                local module = ns.modules[moduleID]
                local row = {frame=CreateFrame("Frame", nil, content)}
                row.check = UI.Check(row.frame, module.title, 0, 0, function(value) ns.SetPanelVisible(moduleID, value) end)
                if module.description then UI.Tooltip(row.check, module.description) end
                row.scale = UI.Text(row.frame, "", 25, 24, 11, 120, {0.72,0.75,0.8})
                row.appearance = UI.Button(row.frame, "Appearance", 0, 0, 96, 28, function() ns.OpenAppearance(moduleID) end)
                UI.Tooltip(row.appearance, "Adjust this panel's opacity, scale and title in the current layout.")
                self.rows[moduleID] = row
                self.rowOrder[#self.rowOrder + 1] = moduleID
            end
        end

        local footer = CreateFrame("Frame", nil, self.body)
        footer:SetPoint("BOTTOMLEFT", 0, 0)
        footer:SetPoint("BOTTOMRIGHT", 0, 0)
        footer:SetHeight(62)
        self.footer = footer
        self.reset = UI.Button(footer, "Reset layout", 0, 0, 110, 28, function() ns.ResetLayout() end)
        self.undo = UI.Button(footer, "Undo layout", 118, 0, 110, 28, function() ns.RestoreLayout() end)
        self.diagnostics = UI.Button(footer, "Diagnostics", 236, 0, 110, 28, function() UI.MakeCopyBox("Diagnostics", ns.Diagnostics()) end)
        UI.Tooltip(self.reset, "Reset the active layout's panel settings to defaults. Saved goals, notes and tracking data remain. Undo layout restores the previous arrangement.")
        UI.Tooltip(self.undo, "Restore the layout saved before the most recent Compact layout or Reset layout action.")
        UI.Tooltip(self.diagnostics, "Open a copyable status report for troubleshooting.")
        self.version = UI.Text(footer, ns.VERSION .. " | Forever alpha", 0, 40, 10, 380, {0.65,0.67,0.73})

        self.Reflow = function()
            if self.reflowing then return end
            self.reflowing = true
            local width = self.body:GetWidth()
            self.summary:SetWidth(width)
            local y = textHeight(self.summary) + 10
            local third = (width - 16) / 3
            for index, button in ipairs({self.healing, self.leveling, self.lock}) do
                place(button, self.body, (index - 1) * (third + 8), y)
                button:SetWidth(third)
                button.label:SetWidth(third - 10)
            end
            y = y + 36
            local half = (width - 8) / 2
            for index, button in ipairs({self.appearance, self.compact}) do
                place(button, self.body, (index - 1) * (half + 8), y)
                button:SetWidth(half)
                button.label:SetWidth(half - 10)
            end
            y = y + 40
            scroll:ClearAllPoints()
            scroll:SetPoint("TOPLEFT", self.body, "TOPLEFT", 0, -y)
            scroll:SetPoint("BOTTOMRIGHT", self.body, "BOTTOMRIGHT", -24, 70)

            local rowWidth = math.max(240, content:GetWidth())
            local rowY = 0
            for _, id in ipairs(self.rowOrder) do
                local row = self.rows[id]
                local labelWidth = rowWidth - 133
                row.check.label:SetWidth(labelWidth)
                local scaleY = textHeight(row.check.label) + 7
                row.scale:SetWidth(labelWidth)
                place(row.scale, row.frame, 25, scaleY)
                local rowHeight = scaleY + textHeight(row.scale, 14) + 10
                row.frame:SetSize(rowWidth, rowHeight)
                place(row.frame, content, 0, rowY)
                row.appearance:ClearAllPoints()
                row.appearance:SetPoint("TOPRIGHT", row.frame, "TOPRIGHT", 0, -math.max(0, (rowHeight - 28) / 2))
                rowY = rowY + rowHeight
            end
            content:SetHeight(math.max(rowY, 1))
            for index, button in ipairs({self.reset, self.undo, self.diagnostics}) do
                place(button, footer, (index - 1) * (third + 8), 0)
                button:SetWidth(third)
                button.label:SetWidth(third - 10)
            end
            self.version:SetWidth(width)
            self.reflowing = false
        end
        self.body:HookScript("OnSizeChanged", self.Reflow)
        content:HookScript("OnSizeChanged", self.Reflow)
    end,
    Refresh=function(self)
        local combat = ns.IsCombat()
        self.summary:SetText("Layout: " .. ns.db.layout .. (combat and " | In combat" or ""))
        self.lock:SetText(ns.db.locked and "Unlock" or "Lock")
        self.lock:SetEnabled(not combat)
        self.compact:SetEnabled(not combat)
        self.reset:SetEnabled(not combat)
        self.undo:SetEnabled(not combat and ns.db.previousLayout ~= nil)
        for id, row in pairs(self.rows) do
            local settings = ns.PanelSettings(id)
            row.check:SetChecked(settings.shown)
            row.scale:SetText(math.floor(settings.scale * 100 + 0.5) .. "% scale")
        end
        self.Reflow()
    end,
})
