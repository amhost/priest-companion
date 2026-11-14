return function(T,ns,Mock)
    -- Exercise appearance through public actions and the rendered widget state.
    -- This bounded mock cannot establish real clipping, hit testing or taint.
    local originalDB,originalSaved=ns.db,PriestCompanionDB
    local original={layouts=ns.Copy(ns.db.layouts),layout=ns.db.layout,locked=ns.db.locked,
        previousLayout=ns.Copy(ns.db.previousLayout),uiScale=UIParent:GetScale()}
    local frame=ns.frames.resources
    local function apply(id,key,value)
        T.ok(ns.SetPanelAppearance(id,key,value),"appearance action accepted: "..key)
        Mock.Flush()
    end
    local function screenCenter(widget)
        local x,y=widget:GetCenter()
        return x*widget:GetEffectiveScale(),y*widget:GetEffectiveScale()
    end
    local function effectiveAlpha(widget)
        local result=1
        while widget do
            result=result*widget:GetAlpha()
            widget=widget:GetParent()
        end
        return result
    end
    local function textureAlpha(texture)
        local color=texture.vertexColor or texture.color
        return (color and color[4] or 1)*effectiveAlpha(texture)
    end
    local function checkSettings(actual,expected,message)
        for _,key in ipairs({"point","relativePoint","x","y","width","height","scale",
            "opacity","contentOpacity","hideHeader","shown"}) do
            if type(expected[key])=="number" then T.near(actual[key],expected[key],message..": "..key)
            else T.eq(actual[key],expected[key],message..": "..key) end
        end
    end

    T.eq(ns.IsCustomizablePanel("resources"),true,"resources have appearance controls")
    T.eq(ns.IsCustomizablePanel("quests"),true,"quests have appearance controls")
    for _,id in ipairs({"settings","appearance","copy","missing"}) do
        T.eq(ns.IsCustomizablePanel(id),false,"configuration panel excluded: "..id)
    end
    ns.ApplyLayout("Leveling")
    ns.SetLocked(true)
    ns.SetPanelVisible("resources",true)
    Mock.Flush()

    -- A real slider change reaches exactly zero; refresh never invokes its writer.
    local values={}
    local control=ns.UI.Slider(UIParent,"Test opacity",0,0,220,0,100,1,function(value)
        values[#values+1]=value
    end)
    control:SetDisplayValue(61,false)
    T.eq(#values,0,"programmatic slider synchronization is silent")
    T.eq(control.slider:GetValue(),61,"programmatic slider synchronization moves thumb")
    T.ok(control.slider:GetThumbTexture(),"slider has a visible thumb texture")
    T.ok(Mock.DragSlider(control.slider,0),"enabled slider accepts user drag")
    T.eq(#values,1,"user slider change invokes one callback")
    T.eq(values[1],0,"slider callback preserves exact zero")
    T.eq(control.valueText:GetText(),"0%","zero is displayed as zero percent")
    control:SetDisplayValue(84,true)
    T.eq(#values,1,"mixed slider refresh does not write settings")
    T.ok(control.valueText:GetText():lower():find("mixed",1,true),"mixed slider state is visible")
    control:SetEnabled(false)
    T.eq(Mock.DragSlider(control.slider,50),false,"disabled slider rejects user drag")
    T.eq(#values,1,"disabled slider does not invoke writer")
    control:SetEnabled(true)
    Mock.DragSlider(control.slider,25)
    T.eq(values[2],25,"re-enabled slider resumes user changes")
    control:SetDisplayValue(0,false)
    T.eq(#values,2,"later zero synchronization remains silent")
    control:Hide()

    -- Background alpha covers all chrome surfaces without fading content.
    apply("resources","hideHeader",false)
    apply("resources","contentOpacity",0.67)
    apply("resources","opacity",0)
    T.eq(ns.PanelSettings("resources").opacity,0,"saved zero background is not raised to old minimum")
    T.eq(frame.background[4],0,"panel background reaches zero")
    T.eq(frame.border[4],0,"panel border reaches zero")
    T.near(textureAlpha(frame.headerBG),0,"header background reaches zero")
    T.eq(frame:GetAlpha(),1,"root frame keeps content independent from background")
    T.near(frame.body:GetAlpha(),0.67,"content alpha uses independent value")
    T.near(effectiveAlpha(ns.modules.resources.health),0.67,"resource bar follows content opacity")
    T.eq(frame.body:IsVisible(),true,"zero background preserves visible content")
    apply("resources","contentOpacity",1)
    T.near(effectiveAlpha(ns.modules.resources.power),1,"full-opacity power remains visible on zero background")

    -- Zero content releases focus in panels that still contain editors.
    ns.SetPanelVisible("keys",true)
    local referenceInput=ns.modules.keys.input
    referenceInput:SetFocus()
    apply("keys","contentOpacity",0)
    T.eq(ns.frames.keys.body:IsShown(),false,"zero content hides interactive reference descendants")
    T.eq(referenceInput:IsVisible(),false,"hidden reference body conceals its edit box")
    T.eq(referenceInput:HasFocus(),false,"zero content releases reference editor keyboard focus")

    -- The resource-only panel remains recoverable when its content is invisible.
    apply("resources","hideHeader",true)
    apply("resources","contentOpacity",0)
    T.eq(frame.body:IsShown(),false,"zero resource content is hidden")
    T.eq(frame:IsMouseEnabled(),false,"locked invisible shell does not capture mouse input")
    local baseHeight=ns.PanelSettings("resources").height
    ns.RunCommand("unlock")
    Mock.Flush()
    T.eq(frame.header:IsVisible(),true,"unlock reveals drag header")
    T.eq(frame.body:IsVisible(),true,"unlock reveals content for recovery")
    T.ok(frame.body:GetAlpha()>=0.35,"edit preview content remains readable")
    T.eq(ns.PanelSettings("resources").contentOpacity,0,"edit preview leaves saved zero content unchanged")
    T.eq(ns.PanelSettings("resources").opacity,0,"edit preview leaves saved zero background unchanged")
    T.eq(ns.PanelSettings("resources").hideHeader,true,"edit preview leaves hidden-header preference unchanged")
    T.eq(frame:GetHeight(),baseHeight+22,"unlock makes room for recovery header")
    ns.SavePlacement("resources")
    T.eq(ns.PanelSettings("resources").height,baseHeight,"temporary header height is not persisted")
    ns.ApplyPanel("resources")
    T.eq(frame:GetHeight(),baseHeight+22,"reapplication does not add header height twice")
    Mock.combat=true
    Mock.Fire("PLAYER_REGEN_DISABLED")
    T.eq(frame.body:IsShown(),false,"combat removes temporary edit preview")
    T.eq(frame:GetHeight(),baseHeight,"combat removes temporary header height")
    Mock.combat=false
    Mock.Fire("PLAYER_REGEN_ENABLED")
    T.eq(frame.body:IsShown(),true,"leaving combat restores unlocked edit preview")
    ns.RunCommand("lock")
    Mock.Flush()
    T.eq(frame.body:IsShown(),false,"locking restores zero content")
    T.eq(frame:GetHeight(),baseHeight,"locking restores saved base height")
    ns.SetPanelVisible("settings",false)
    ns.RunCommand("")
    Mock.Flush()
    T.eq(ns.frames.settings:IsVisible(),true,"slash command recovers panel manager")
    T.eq(ns.frames.settings.body:GetAlpha(),1,"recovery controls remain fully readable")
    ns.SetPanelVisible("appearance",false)
    ns.RunCommand("appearance")
    Mock.Flush()
    T.eq(ns.frames.appearance:IsVisible(),true,"documented appearance command opens recovery controls")
    Mock.combat=true
    Mock.Fire("PLAYER_REGEN_DISABLED")
    T.eq(ns.modules.appearance.sliders.opacity.enabled,false,"combat entry immediately disables visible appearance slider")
    Mock.combat=false
    Mock.Fire("PLAYER_REGEN_ENABLED")
    T.eq(ns.modules.appearance.sliders.opacity.enabled,true,"combat exit restores appearance slider")

    -- Bulk actions exclude the controls used to undo them.
    local protected={}
    for _,id in ipairs({"settings","appearance","copy"}) do
        protected[id]=ns.Copy(ns.PanelSettings(id))
    end
    apply("all","opacity",0)
    apply("all","contentOpacity",0)
    apply("all","hideHeader",true)
    apply("all","scale",0.5)
    for _,id in ipairs({"settings","appearance","copy"}) do
        local widget=ns.frames[id]
        checkSettings(ns.PanelSettings(id),protected[id],"bulk action preserves recovery panel "..id)
        T.near(widget.background[4],0.94,"recovery panel background stays readable: "..id)
        T.eq(widget.body:GetAlpha(),1,"recovery panel content stays readable: "..id)
        T.eq(widget.body:IsShown(),true,"recovery panel body stays enabled: "..id)
    end
    T.eq(ns.SetPanelAppearance("appearance","opacity",0),false,"direct action also protects appearance controls")

    -- Verify the actual appearance callback, including target selection.
    apply("resources","opacity",0.44)
    apply("quests","opacity",0.73)
    ns.OpenAppearance("resources")
    Mock.Flush()
    local appearance=ns.modules.appearance
    T.eq(appearance.selected,"resources","appearance opens the selected panel")
    Mock.DragSlider(appearance.sliders.opacity.slider,0)
    Mock.Flush()
    T.eq(ns.PanelSettings("resources").opacity,0,"appearance slider writes exact zero to selected panel")
    T.near(ns.PanelSettings("quests").opacity,0.73,"selected-panel slider leaves other panels unchanged")

    -- Scaling preserves physical center, including a scaled UIParent.
    UIParent:SetScale(0.8)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER",UIParent,"CENTER",127,-63)
    ns.SavePlacement("resources")
    local physicalX,physicalY=screenCenter(frame)
    apply("resources","scale",1.25)
    local x,y=screenCenter(frame)
    T.near(x,physicalX,"increasing scale preserves physical horizontal center")
    T.near(y,physicalY,"increasing scale preserves physical vertical center")
    apply("resources","scale",0.5)
    x,y=screenCenter(frame)
    T.near(x,physicalX,"minimum scale preserves physical horizontal center")
    T.near(y,physicalY,"minimum scale preserves physical vertical center")
    ns.ApplyPanel("resources")
    ns.SavePlacement("resources")
    x,y=screenCenter(frame)
    T.near(x,physicalX,"reapplication does not accumulate horizontal scale drift")
    T.near(y,physicalY,"reapplication does not accumulate vertical scale drift")
    UIParent:SetScale(original.uiScale)

    -- Fresh edge-anchored panels must not drift when temporary edit chrome closes.
    local edge=ns.PanelSettings("resources")
    edge.point,edge.relativePoint,edge.x,edge.y="TOPLEFT","TOPLEFT",24,-80
    ns.ApplyPanel("resources")
    physicalX,physicalY=screenCenter(frame)
    ns.SetLocked(false)
    ns.SavePlacement("resources")
    ns.SetLocked(true)
    ns.ApplyPanel("resources")
    x,y=screenCenter(frame)
    T.near(x,physicalX,"temporary title preserves edge-anchored horizontal position")
    T.near(y,physicalY,"temporary title preserves edge-anchored vertical position")

    -- Combat does not partially persist appearance or compact-preset changes.
    local beforeCombat=ns.Copy(ns.PanelSettings("resources"))
    local previousBeforeCombat=ns.db.previousLayout
    Mock.combat=true
    T.eq(ns.SetPanelAppearance("resources","opacity",0.9),false,"combat blocks opacity action")
    T.eq(ns.SetPanelAppearance("resources","contentOpacity",0.9),false,"combat blocks content action")
    T.eq(ns.SetPanelAppearance("resources","scale",1),false,"combat blocks scale action")
    T.eq(ns.ApplyCompactLayout(),false,"combat blocks compact preset")
    checkSettings(ns.PanelSettings("resources"),beforeCombat,"combat preserves current appearance")
    T.eq(ns.db.previousLayout,previousBeforeCombat,"combat does not replace undo snapshot")
    Mock.combat=false
    Mock.Flush()

    -- Resources is always a compact bar view, with no retired spell editor.
    apply("resources","contentOpacity",1)
    apply("resources","hideHeader",false)
    local resourceSettings=ns.PanelSettings("resources")
    resourceSettings.width,resourceSettings.height=200,1
    ns.ApplyPanel("resources")
    Mock.Flush()
    T.eq(frame:GetWidth(),200,"resource panel supports compact width")
    T.eq(frame:GetHeight(),92,"visible resource title reserves its minimum height")
    T.eq(ns.modules.resources.health:IsVisible(),true,"compact resources keeps health visible")
    T.eq(ns.modules.resources.power:IsVisible(),true,"compact resources keeps current power visible")
    T.eq(ns.modules.resources.spellInput,nil,"resources has no chosen-spell editor")
    T.eq(ns.modules.appearance.barsOnly,nil,"appearance has no retired bars-only toggle")
    apply("resources","hideHeader",true)
    resourceSettings.height=1
    ns.ApplyPanel("resources")
    Mock.Flush()
    T.eq(frame:GetHeight(),68,"hidden resource title permits the compact minimum height")
    local function editBoxCount(widget)
        local count=widget.kind=="EditBox" and 1 or 0
        for _,child in ipairs({widget:GetChildren()}) do count=count+editBoxCount(child) end
        return count
    end
    T.eq(editBoxCount(frame.body),0,"resource view contains no editor descendants")

    -- Presets affect only the active layout and have an exact appearance undo.
    for _,layout in ipairs({"Leveling","Healing"}) do
        ns.ApplyLayout(layout)
        ns.SetPanelVisible("resources",layout=="Leveling")
        for _,id in ipairs(ns.order) do ns.SavePlacement(id) end
        local before=ns.Copy(ns.db.layouts[layout])
        local other=layout=="Leveling" and "Healing" or "Leveling"
        local otherResources=ns.Copy(ns.PanelSettings("resources",other))
        local modules=ns.db.modules
        T.ok(ns.ApplyCompactLayout(),"compact preset applies to "..layout)
        Mock.Flush()
        T.ok(ns.db.previousLayout,"compact preset preserves undo snapshot")
        T.eq(ns.db.modules,modules,"compact preset retains module content")
        checkSettings(ns.PanelSettings("resources",other),otherResources,"compact preset preserves other layout")
        for _,id in ipairs(ns.order) do
            if ns.IsCustomizablePanel(id) then
                local settings=ns.PanelSettings(id)
                T.near(settings.scale,0.8,"compact scale: "..id)
                T.eq(settings.opacity,0,"compact background: "..id)
                T.near(settings.contentOpacity,0.85,"compact content: "..id)
                T.eq(settings.hideHeader,true,"compact header: "..id)
                local expectedShown=id=="resources" and before.resources.shown
                    or (layout=="Leveling" and id=="quests") or (layout=="Healing" and id=="prep")
                T.eq(settings.shown,expectedShown,"compact visibility: "..layout.."/"..id)
            else checkSettings(ns.PanelSettings(id),before[id],"compact preset preserves controls: "..id) end
        end
        T.eq(ns.PanelSettings("resources").shown,before.resources.shown,"compact preserves optional resource visibility")
        T.eq(frame:GetHeight(),68,"compact resources has the intended short height")
        T.ok(ns.RestoreLayout(),"compact preset undo succeeds")
        Mock.Flush()
        for _,id in ipairs(ns.order) do
            checkSettings(ns.PanelSettings(id),before[id],"undo restores "..layout.."/"..id)
        end
    end

    -- Persisted zeros survive layout switching and database default merging.
    ns.ApplyLayout("Leveling")
    apply("resources","opacity",0)
    apply("resources","contentOpacity",0)
    apply("resources","hideHeader",true)
    apply("resources","scale",0.5)
    ns.ApplyLayout("Healing")
    apply("resources","opacity",0.61)
    apply("resources","contentOpacity",0.92)
    ns.ApplyLayout("Leveling")
    T.eq(ns.PanelSettings("resources").opacity,0,"layout switch retains zero background")
    T.eq(ns.PanelSettings("resources").contentOpacity,0,"layout switch retains zero content")
    PriestCompanionDB=ns.Copy(ns.db)
    T.ok(ns.Models.Core.InitializeDatabase(),"copied saved variables reinitialize")
    ns.ApplyPanel("resources")
    Mock.Flush()
    T.eq(ns.PanelSettings("resources").opacity,0,"default merging retains persisted zero background")
    T.eq(ns.PanelSettings("resources").contentOpacity,0,"default merging retains persisted zero content")
    T.eq(ns.PanelSettings("resources").hideHeader,true,"default merging retains hidden header")
    T.near(ns.PanelSettings("resources").scale,0.5,"default merging retains minimum scale")
    T.eq(frame.body:IsShown(),false,"reinitialized zero content remains noninteractive")
    T.near(ns.PanelSettings("resources","Healing").opacity,0.61,"reinitialization retains independent Healing opacity")

    -- Restore shared fixture state for the existing integration cases below us.
    ns.db, PriestCompanionDB=originalDB,originalSaved
    ns.db.layouts,ns.db.layout,ns.db.locked=original.layouts,original.layout,original.locked
    ns.db.previousLayout=original.previousLayout
    UIParent:SetScale(original.uiScale)
    for _,id in ipairs(ns.order) do ns.ApplyPanel(id) end
    Mock.Flush()
end
