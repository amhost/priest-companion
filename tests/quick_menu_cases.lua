return function(T, ns, Mock)
    local module = ns.modules.quick
    T.ok(module and module.frame, "Production TOC loads the native quick menu")
    local original = {layouts=ns.Copy(ns.db.layouts),layout=ns.db.layout,locked=ns.db.locked,
        launcher=ns.Copy(ns.db.modules.launcher),feedback=module.feedback}
    local oldBridge, oldModeHandler = ns.QuestieBridge, ns.Models.Quests.SetLocationMode
    local oldMinimap, oldCombat = Minimap, Mock.combat
    local ready, enabled, mode, failure = true, true, "next", nil
    local selectedModes = {}
    ns.QuestieBridge = {
        GetAvailability=function() return ready,failure end,
        IsEnabled=function() return enabled end,
        GetMode=function() return mode end,
    }
    ns.Models.Quests.SetLocationMode = function(value)
        selectedModes[#selectedModes+1]=value
        if not ready and value~="off" then return false,failure end
        if value=="off" then enabled=false else mode=value;enabled=true end
        return true
    end
    Mock.combat=false
    ns.ApplyLayout("Leveling")
    ns.SetPanelVisible("quick",false)
    if not Minimap then
        Minimap=CreateFrame("Frame",nil,UIParent)
        Minimap:SetSize(140,140)
        Minimap:SetPoint("TOPRIGHT",UIParent,"TOPRIGHT",-20,-20)
    end
    T.ok(module:CreateLauncher(), "Minimap launcher can initialize from native frame methods")
    local launcher=module.launcher
    module:CreateLauncher()
    T.eq(module.launcher,launcher,"Repeated readiness does not create duplicate minimap buttons")
    launcher:Click()
    Mock.Flush()
    T.eq(ns.PanelSettings("quick").shown,true,"Minimap left click opens the menu without a command")
    T.ok(ns.modules.guide,"Guide module is present for menu integration")
    ns.SetPanelVisible("guide",false)
    module.guide:Click()
    Mock.Flush()
    T.eq(ns.PanelSettings("guide").shown,true,"Guide menu button shows the guide")
    T.eq(ns.PanelSettings("quick").shown,false,"Opening guide closes the quick menu")
    launcher:Click("RightButton")
    Mock.Flush()
    T.eq(ns.PanelSettings("guide").shown,false,"Minimap right click toggles the guide directly")

    launcher:Click()
    Mock.Flush()
    for _,value in ipairs({"hide","next","all"}) do
        module.locations[value]:Click()
        Mock.Flush()
        T.eq(selectedModes[#selectedModes],value,"Location button reaches the shared action: "..value)
        T.eq(mode,value,"Location button changes the saved mode: "..value)
    end
    module.normal:Click()
    Mock.Flush()
    T.eq(enabled,false,"Normal Questie button disables the adapter")
    T.eq(mode,"all","Normal Questie preserves the prior location mode")
    T.ok(module.status:GetText():find("Normal Questie",1,true),"Restoration feedback is visible in the menu")

    ready,enabled,failure=false,true,"Questie test interface is unavailable."
    module:Refresh()
    T.ok(module.status:GetText():find("navigation unavailable",1,true),"Enabled preference is not presented as ready")
    T.ok(module.status:GetText():find(failure,1,true),"Provider failure reason is visible without diagnostics")
    T.eq(module:ChooseLocation("next"),false,"A failed location change reports failure")
    Mock.Flush()
    T.ok(not module.status:GetText():find("navigation ready",1,true),"Failed location change does not claim readiness")
    ready,failure=true,nil

    local beforeLocked=ns.db.locked
    module.lock:Click()
    Mock.Flush()
    T.eq(ns.db.locked,not beforeLocked,"Lock button reaches the actual layout lock action")
    ns.SetLocked(beforeLocked)
    ns.SetPanelVisible("quests",false)
    module.quests:Click()
    Mock.Flush()
    T.eq(ns.PanelSettings("quests").shown,true,"Quest Helper can be reached without chat commands")
    ns.OpenQuickMenu()
    Mock.Flush()
    ns.SetPanelVisible("settings",false)
    module.settings:Click()
    Mock.Flush()
    T.eq(ns.PanelSettings("settings").shown,true,"Settings can be reached from minimap menu")
    T.eq(ns.PanelSettings("quick").shown,false,"Opening settings closes the quick menu")

    T.near(ns.Models.QuickMenu.AngleForOffset(1,1),45,"Drag angle first quadrant")
    T.near(ns.Models.QuickMenu.AngleForOffset(-1,1),135,"Drag angle second quadrant")
    T.near(ns.Models.QuickMenu.AngleForOffset(-1,-1),225,"Drag angle third quadrant")
    T.near(ns.Models.QuickMenu.AngleForOffset(1,-1),315,"Drag angle fourth quadrant")
    T.eq(ns.Models.QuickMenu.AngleForOffset(Mock.Secret(),1),nil,"Restricted drag position is not interpreted")
    Mock.Trigger(launcher,"OnDragStart")
    launcher:ClearAllPoints()
    launcher:SetPoint("CENTER",module.minimap,"CENTER",30,30)
    Mock.Trigger(launcher,"OnDragStop")
    T.near(ns.db.modules.launcher.angle,45,"Drag stop saves a minimap angle")
    module:PlaceLauncher()
    local _,relative,_,x,y=launcher:GetPoint()
    T.eq(relative,module.minimap,"Launcher remains anchored to the minimap")
    T.near(x,y,"Saved 45-degree angle is reapplied")
    T.eq(launcher:GetScript("OnUpdate"),nil,"Launcher movement uses no per-frame polling")

    ns.SetPanelVisible("quick",true)
    Mock.combat=true
    Mock.Fire("PLAYER_REGEN_DISABLED")
    local before=#selectedModes
    module.locations.next:Click()
    T.eq(#selectedModes,before,"Disabled combat controls cannot change location mode")
    T.eq(ns.OpenQuickMenu(),false,"Combat menu requests do not mutate visibility")
    Mock.Trigger(launcher,"OnDragStart")
    T.ok(not module.dragging,"Combat blocks starting a minimap drag")
    local savedAngle=ns.db.modules.launcher.angle
    module:FinishLauncherDrag()
    T.eq(ns.db.modules.launcher.angle,savedAngle,"Combat drag stop preserves saved angle")
    Mock.combat=false
    Mock.Fire("PLAYER_REGEN_ENABLED")
    T.ok(module.locations.next:IsEnabled(),"Menu controls recover after combat")

    -- A missing minimap is a capability absence, not a repeating create error.
    Minimap=nil
    local objectCount=#Mock.objects
    T.eq(module.CreateLauncher({}),false,"Missing Minimap leaves the manager fallback usable")
    T.eq(#Mock.objects,objectCount,"Missing Minimap creates no orphan button")
    Minimap=oldMinimap
    ns.QuestieBridge,ns.Models.Quests.SetLocationMode=oldBridge,oldModeHandler
    Mock.combat=oldCombat
    module.feedback=original.feedback
    ns.db.modules.launcher=original.launcher
    ns.db.layouts,ns.db.layout,ns.db.locked=original.layouts,original.layout,original.locked
    module:PlaceLauncher()
    for _,id in ipairs(ns.order) do ns.ApplyPanel(id) end
    Mock.Flush()
end
