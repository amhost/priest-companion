return function(T, ns, Mock)
    local module = ns.modules.quests
    local oldBridge, oldQuests, oldShift = ns.QuestieBridge, Mock.quests, IsShiftKeyDown
    local oldSelected, oldShown = ns.db.modules.quests.selectedQuestID, ns.PanelSettings("quests").shown
    local oldDetails, oldWaypoint, oldMapID = Mock.detailsID, Mock.waypoint, Mock.mapID
    local oldMap, oldSetMapID = C_Map, WorldMapFrame.SetMapID
    local oldCopy = ns.UI.MakeCopyBox
    local enabled, mode, canNavigate, calls, lastID = true, "next", true, 0, nil
    ns.QuestieBridge = {
        IsEnabled = function() return enabled end,
        GetMode = function() return mode end,
        SetEnabled = function(value) enabled = value; return true end,
        SetMode = function(value) mode = value; return true end,
        Status = function() return "Bounded bridge test" end,
        Navigate = function(id) calls = calls + 1; lastID = id; return canNavigate end,
    }
    -- The adapter owns its Questie pins. A failed/disabled adapter must never
    -- overwrite a personal waypoint or directly change native map state.
    local nativeCalls = 0
    C_Map = {
        SetUserWaypoint = function() nativeCalls = nativeCalls + 1 end,
        OpenWorldMap = function() nativeCalls = nativeCalls + 1 end,
    }
    WorldMapFrame.SetMapID = function() nativeCalls = nativeCalls + 1 end
    Mock.quests = {
        {questID=101,title="First errand",level=18,isHeader=false,isHidden=false},
        {questID=202,title="Second errand",level=19,isHeader=false,isHidden=false},
    }
    ns.SetPanelVisible("quests", true)
    module:Refresh()
    T.eq(module.footer, nil, "Removed permanent location disclaimer leaves no footer")
    T.eq(module.map, nil, "Separate Map button is removed")
    module.rows[2].button:Click()
    Mock.Flush()
    T.eq(calls, 1, "One row click makes one navigation request")
    T.eq(lastID, 202, "Clicked row supplies its quest ID")
    T.eq(ns.db.modules.quests.selectedQuestID, 202, "Clicked quest stays selected")
    T.eq(module.rows[1].text:IsShown(), false, "Unselected objectives are collapsed")
    T.eq(module.rows[2].text:IsShown(), true, "Selected objectives remain readable")

    IsShiftKeyDown = function() return true end
    Mock.detailsID = nil
    module.rows[1].button:Click()
    Mock.Flush()
    T.eq(calls, 1, "Shift-click bypasses checkpoint navigation")
    T.eq(Mock.detailsID, 101, "Shift-click opens the clicked quest details")
    IsShiftKeyDown = function() return false end
    module.rows[2].button:Click("RightButton")
    Mock.Flush()
    T.eq(calls, 1, "Right-click retains details access")
    T.eq(Mock.detailsID, 202, "Right-click opens the clicked quest details")

    for _, value in ipairs({"hide", "next", "all"}) do
        enabled = false
        module.locationButtons[value]:Click()
        Mock.Flush()
        T.eq(mode, value, "Location button selects " .. value)
        T.eq(enabled, true, "Location button enables saved bridge mode")
    end
    ns.RunCommand("locations off")
    T.eq(enabled, false, "Off disables adapter")
    T.eq(mode, "all", "Off preserves selected mode")
    ns.RunCommand("locations on")
    T.eq(enabled, true, "On re-enables adapter")
    T.eq(mode, "all", "On retains selected mode")
    ns.RunCommand("locations next")
    T.eq(mode, "next", "Slash route selects next")
    ns.RunCommand("locations invalid")
    T.eq(mode, "next", "Invalid mode does not alter settings")

    Mock.combat = true
    local before = calls
    Mock.detailsID = nil
    module.rows[1].button:Click()
    ns.RunCommand("locations off")
    T.eq(calls, before, "Combat row click cannot navigate")
    T.eq(Mock.detailsID, nil, "Combat row click cannot open details")
    T.eq(enabled, true, "Combat mode changes are rejected")
    Mock.combat = false

    canNavigate = false
    for _, value in ipairs({"hide", "next", "all"}) do
        mode = value
        Mock.detailsID = nil
        module.rows[2].button:Click()
        Mock.Flush()
        T.eq(Mock.detailsID, 202, "Unavailable " .. value .. " opens quest details")
    end
    enabled = false
    before = calls
    Mock.detailsID = nil
    module.rows[1].button:Click()
    Mock.Flush()
    T.eq(calls, before, "Disabled adapter is not called")
    T.eq(Mock.detailsID, 101, "Disabled adapter leaves details available")
    T.eq(nativeCalls, 0, "Fallback neither creates personal pins nor calls SetMapID")

    local oldDetailsHelper = QuestMapFrame_OpenToQuestDetails
    QuestMapFrame_OpenToQuestDetails = nil
    local copiedTitle, copiedText
    ns.UI.MakeCopyBox = function(title, text) copiedTitle, copiedText = title, text end
    module.rows[2].button:Click()
    Mock.Flush()
    T.eq(copiedTitle, "Second errand", "Missing details API uses selected title")
    T.ok(copiedText and copiedText:find("Collect supplies",1,true), "Missing details API keeps objective text readable")

    QuestMapFrame_OpenToQuestDetails, ns.UI.MakeCopyBox = oldDetailsHelper, oldCopy
    C_Map, WorldMapFrame.SetMapID = oldMap, oldSetMapID
    ns.QuestieBridge, Mock.quests, IsShiftKeyDown = oldBridge, oldQuests, oldShift
    ns.db.modules.quests.selectedQuestID = oldSelected
    ns.SetPanelVisible("quests", oldShown)
    module:Refresh()
    Mock.Flush()
    Mock.detailsID, Mock.waypoint, Mock.mapID = oldDetails, oldWaypoint, oldMapID
end
