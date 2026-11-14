local addonName, ns = ...
local UI = ns.UI
local Model = {}
ns.Models.QuickMenu = Model

local function launcherSettings()
    local db = ns.ModuleDB("launcher", {angle=220})
    db.angle = ns.Number(db.angle, 220) % 360
    return db
end

function Model.AngleForOffset(x, y)
    x, y = ns.Number(x), ns.Number(y)
    if not x or not y or (x == 0 and y == 0) then return nil end
    local radians
    if x > 0 then radians = math.atan(y / x)
    elseif x < 0 then radians = math.atan(y / x) + (y >= 0 and math.pi or -math.pi)
    else radians = y > 0 and math.pi / 2 or -math.pi / 2 end
    return math.deg(radians) % 360
end

local function frameWith(value, names)
    if not ns.Readable(value) or (type(value) ~= "table" and type(value) ~= "userdata") then return false end
    for _, name in ipairs(names) do if type(value[name]) ~= "function" then return false end end
    return true
end

local Module = {
    id="quick", title="Quest Companion", internal=true,
    width=300, height=316, minWidth=280, minHeight=300,
    defaultEnabled={Healing=false,Leveling=false},
}

function ns.OpenQuickMenu()
    if not ns.ready or not ns.modules.quick or not ns.frames.quick then return false end
    if ns.IsCombat() then ns.Notify("Open the navigation menu after combat."); return false end
    local shown = ns.PanelSettings("quick").shown
    ns.SetPanelVisible("quick", not shown)
    ns.Refresh("quick")
    return true
end

local function togglePanel(id)
    if ns.IsCombat() then ns.Notify("Change panels after combat."); return false end
    if not ns.modules[id] then return false end
    local ok = ns.SetPanelVisible(id, not ns.PanelSettings(id).shown)
    if ok then ns.SetPanelVisible("quick", false) end
    return ok
end

function Module:ChooseLocation(mode)
    if ns.IsCombat() then self.feedback="Change quest locations after combat."; ns.Refresh("quick"); return false end
    local handler = ns.Models.Quests and ns.Models.Quests.SetLocationMode
    local ok, reason = ns.Call(handler, mode)
    if ok then
        self.feedback = mode == "off" and "Normal Questie clicks restored."
            or "Now click a tracked quest title to open its map."
    else self.feedback = ns.Text(reason, "Questie navigation is unavailable; see its status below.") end
    ns.Refresh("quick"); ns.Refresh("quests")
    return ok == true
end

function Module:PlaceLauncher()
    if not self.launcher or not self.minimap then return false end
    if ns.IsCombat() or self.dragging then self.placementPending=true; return false end
    local width = ns.Number(ns.Call(self.minimap.GetWidth, self.minimap))
    local height = ns.Number(ns.Call(self.minimap.GetHeight, self.minimap))
    if not width or not height or width <= 0 or height <= 0 then return false end
    local angle = math.rad(launcherSettings().angle)
    local radius = math.min(width, height) / 2 + 8
    self.launcher:ClearAllPoints()
    self.launcher:SetPoint("CENTER", self.minimap, "CENTER", math.cos(angle)*radius, math.sin(angle)*radius)
    self.placementPending = nil
    return true
end

function Module:FinishLauncherDrag()
    if not self.launcher then return end
    self.launcher:StopMovingOrSizing()
    self.dragging = nil
    if ns.IsCombat() then self.placementPending=true; return end
    local x, y = ns.Call(self.launcher.GetCenter, self.launcher)
    local mx, my = ns.Call(self.minimap.GetCenter, self.minimap)
    local scale = ns.Number(ns.Call(self.launcher.GetEffectiveScale, self.launcher))
    local mapScale = ns.Number(ns.Call(self.minimap.GetEffectiveScale, self.minimap))
    x, y, mx, my = ns.Number(x), ns.Number(y), ns.Number(mx), ns.Number(my)
    if x and y and mx and my and scale and mapScale and scale > 0 and mapScale > 0 then
        local angle = Model.AngleForOffset(x*scale-mx*mapScale, y*scale-my*mapScale)
        if angle then launcherSettings().angle = angle end
    end
    self:PlaceLauncher()
end

function Module:CreateLauncher()
    if self.launcher then return true end
    if ns.IsCombat() then return false end
    if not frameWith(Minimap, {"GetWidth", "GetHeight", "GetCenter", "GetEffectiveScale", "GetFrameLevel", "HookScript"}) then
        return false
    end
    local width = ns.Number(ns.Call(Minimap.GetWidth, Minimap))
    local height = ns.Number(ns.Call(Minimap.GetHeight, Minimap))
    if not width or not height or width <= 0 or height <= 0 then return false end
    self.minimap = Minimap
    local button = CreateFrame("Button", "QuestCompanionMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:SetMovable(true)
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(25,25)
    background:SetPoint("TOPLEFT", 2,-4)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    icon:SetSize(20,20)
    icon:SetPoint("TOPLEFT", 6,-6)
    icon:SetTexCoord(0.08,0.92,0.08,0.92)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54,54)
    border:SetPoint("TOPLEFT", 0,0)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then togglePanel("guide") else ns.OpenQuickMenu() end
    end)
    button:SetScript("OnDragStart", function()
        if ns.IsCombat() then return end
        self.dragging = true
        button:StartMoving()
    end)
    button:SetScript("OnDragStop", function() self:FinishLauncherDrag() end)
    UI.Tooltip(button, "Quest Companion\nLeft-click: guide and quest navigation menu.\nRight-click: show or hide the leveling guide.\nDrag: move this button around the minimap.")
    self.launcher = button
    Minimap:HookScript("OnSizeChanged", function() self:PlaceLauncher() end)
    self:PlaceLauncher()
    return true
end

function Module:Create()
    self.guide = UI.Button(self.body, "Guide", 0,0,126,26,function() togglePanel("guide") end)
    self.quests = UI.Button(self.body, "Quest Helper", 134,0,126,26,function() togglePanel("quests") end)
    self.settings = UI.Button(self.body, "Settings", 0,32,126,26,function()
        if not ns.IsCombat() and ns.SetPanelVisible("settings",true) then ns.SetPanelVisible("quick",false) end
    end)
    self.lock = UI.Button(self.body, "Unlock", 134,32,126,26,function()
        ns.SetLocked(not ns.db.locked); ns.Refresh("quick")
    end)
    self.locationLabel = UI.Text(self.body,"Quest locations",0,72,12,260,UI.accent)
    self.locations = {}
    for index, mode in ipairs({"hide", "next", "all"}) do
        local selectedMode = mode
        self.locations[mode] = UI.Button(self.body,mode, (index-1)*89,94,82,26,function()
            self:ChooseLocation(selectedMode)
        end)
    end
    self.normal = UI.Button(self.body,"Normal Questie clicks",0,126,260,26,function() self:ChooseLocation("off") end)
    self.status = UI.Text(self.body,"",0,162,11,260)
    UI.Tooltip(self.locations.hide,"Temporarily hide the clicked quest's locations while its map view is open.")
    UI.Tooltip(self.locations.next,"Show one supported unfinished checkpoint for the quest you click.")
    UI.Tooltip(self.locations.all,"Show the clicked quest's remaining supported Questie locations.")
    UI.Tooltip(self.normal,"Disable our tracker-click adapter and restore Questie's normal behavior.")
    self.body:HookScript("OnSizeChanged", function() ns.Refresh("quick") end)
    self:CreateLauncher()
end

function Module:Refresh()
    if not self.status then return end
    local combat = ns.IsCombat()
    local bridge = ns.QuestieBridge
    local ready, reason = ns.Call(bridge and bridge.GetAvailability)
    local enabled = ns.Call(bridge and bridge.IsEnabled) == true
    local mode = ns.Text(ns.Call(bridge and bridge.GetMode), "next")
    local width = math.max(240, ns.Number(self.body:GetWidth(), 280)-16)
    self.status:SetWidth(width)
    self.locationLabel:SetWidth(width)
    local half, third = (width-8)/2, (width-12)/3
    for index, button in ipairs({self.guide,self.quests,self.settings,self.lock}) do
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT",self.body,"TOPLEFT",((index-1)%2)*(half+8),-math.floor((index-1)/2)*32)
        button:SetWidth(half); button.label:SetWidth(half-10)
        button:SetEnabled(not combat)
    end
    self.guide:SetEnabled(not combat and ns.modules.guide ~= nil)
    self.guide:SetSelected(ns.modules.guide and ns.PanelSettings("guide").shown == true)
    self.quests:SetSelected(ns.PanelSettings("quests").shown == true)
    self.lock:SetText(ns.db.locked and "Unlock panels" or "Lock panels")
    for index, value in ipairs({"hide", "next", "all"}) do
        local button = self.locations[value]
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT",self.body,"TOPLEFT",(index-1)*(third+6),-94)
        button:SetWidth(third); button.label:SetWidth(third-10)
        button:SetText(value:sub(1,1):upper()..value:sub(2))
        button:SetSelected(enabled and mode == value)
        button:SetEnabled(not combat and bridge ~= nil)
    end
    self.normal:SetWidth(width); self.normal.label:SetWidth(width-10)
    self.normal:SetSelected(not enabled)
    self.normal:SetEnabled(not combat and bridge ~= nil)
    local status
    if combat then status="Navigation changes are available after combat."
    elseif ready ~= true then
        status="Questie navigation unavailable.\n"..ns.CleanText(reason or "The provider is not ready. Normal Questie actions remain available.",180)
    elseif not enabled then status="Normal Questie clicks and markers are active."
    else status="Questie navigation ready.\nClick a tracked quest title to use "..mode.." locations." end
    if not combat and ready == true and self.feedback and self.feedback ~= "" then
        status=ns.CleanText(self.feedback,160).."\n"..status
    end
    self.status:SetText(status)
end

ns.RegisterModule(Module)
ns.RegisterCommand("menu", ns.OpenQuickMenu)
for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED"}) do
    ns.On(event, function()
        Module:CreateLauncher(); Module:PlaceLauncher(); ns.Refresh("quick")
    end)
end
ns.On("PLAYER_REGEN_DISABLED", function()
    if Module.dragging and Module.launcher then
        Module.launcher:StopMovingOrSizing(); Module.dragging=nil; Module.placementPending=true
    end
    ns.Refresh("quick")
end)
