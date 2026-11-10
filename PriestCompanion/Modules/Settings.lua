local addonName, ns = ...
local UI = ns.UI

ns.RegisterModule({
    id="settings", title="Priest Companion", internal=true,
    width=440, height=550, minWidth=410, minHeight=430,
    defaultEnabled={Healing=false,Leveling=false},
    Create=function(self)
        self.summary = UI.Text(self.body, "", 0, 0, 12, 390)
        UI.Button(self.body, "Healing", 0, 27, 100, 27, function() ns.ApplyLayout("Healing") end)
        UI.Button(self.body, "Leveling", 108, 27, 100, 27, function() ns.ApplyLayout("Leveling") end)
        self.lock = UI.Button(self.body, "Unlock", 220, 27, 130, 27, function() ns.SetLocked(not ns.db.locked) end)
        UI.Text(self.body, "Choose panels. Drag titles and bottom corners when unlocked.", 0, 65, 11, 390)
        local scroll, content = UI.ScrollArea(self.body, 100, 100)
        self.content, self.rows = content, {}
        local y = 0
        for _, id in ipairs(ns.order) do
            local moduleID = id
            local module = ns.modules[moduleID]
            if not module.internal then
                local row = {}
                row.check = UI.Check(content, module.title, 0, y, function(value) ns.SetPanelVisible(moduleID, value) end)
                row.check.label:SetWidth(210)
                if module.description then UI.Tooltip(row.check, module.description) end
                UI.Button(content, "-", 228, y, 26, 24, function()
                    if ns.IsCombat() then ns.Notify("Change panel sizes after combat."); return end
                    local settings = ns.PanelSettings(moduleID)
                    ns.SavePlacement(moduleID)
                    settings.scale = ns.Clamp(settings.scale - 0.05, 0.65, 1.5, 1)
                    ns.ApplyPanel(moduleID); ns.Refresh("settings")
                end)
                row.scale = UI.Text(content, "", 259, y + 5, 11, 45)
                UI.Button(content, "+", 308, y, 26, 24, function()
                    if ns.IsCombat() then ns.Notify("Change panel sizes after combat."); return end
                    local settings = ns.PanelSettings(moduleID)
                    ns.SavePlacement(moduleID)
                    settings.scale = ns.Clamp(settings.scale + 0.05, 0.65, 1.5, 1)
                    ns.ApplyPanel(moduleID); ns.Refresh("settings")
                end)
                self.rows[moduleID] = row
                y = y + 42
            end
        end
        content:SetHeight(math.max(y, 1))
        local footer = CreateFrame("Frame", nil, self.body)
        footer:SetPoint("BOTTOMLEFT", 0, 0)
        footer:SetPoint("BOTTOMRIGHT", 0, 0)
        footer:SetHeight(92)
        UI.Button(footer, "Reset layout", 0, 0, 110, 25, function() ns.ResetLayout() end)
        UI.Button(footer, "Undo reset", 118, 0, 105, 25, function() ns.RestoreLayout() end)
        UI.Button(footer, "Diagnostics", 232, 0, 110, 25, function() UI.MakeCopyBox("Diagnostics", ns.Diagnostics()) end)
        UI.Text(footer, "Each layout remembers positions, sizes, scale, opacity and visibility.\n/pc opens this manager at any time.", 0, 35, 11, 390)
        UI.Text(footer, ns.VERSION .. " | Forever alpha", 0, 76, 10, 390, {0.65,0.67,0.73})
    end,
    Refresh=function(self)
        self.summary:SetText("Active layout: " .. ns.db.layout .. (ns.IsCombat() and "  |  changes wait for combat" or ""))
        self.lock:SetText(ns.db.locked and "Unlock panels" or "Lock panels")
        for id, row in pairs(self.rows) do
            local settings = ns.PanelSettings(id)
            row.check:SetChecked(settings.shown)
            row.scale:SetText(math.floor(settings.scale * 100 + 0.5) .. "%")
        end
    end,
})
