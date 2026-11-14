return function(T,ns,Mock)
    -- Exercise the real database initializer with old saved data. This does not
    -- emulate the client's SavedVariables file writer or native slash dispatch.
    local originalDB,originalSaved=ns.db,PriestCompanionDB
    local original={layouts=ns.Copy(ns.db.layouts),layout=ns.db.layout,locked=ns.db.locked,
        previousLayout=ns.Copy(ns.db.previousLayout),selected=ns.modules.appearance.selected}
    local function same(actual,expected,label)
        T.eq(type(actual),type(expected),label.." type")
        if type(expected)~="table" then T.eq(actual,expected,label);return end
        for key,value in pairs(expected) do same(actual[key],value,label.."."..tostring(key)) end
        for key in pairs(actual) do T.ok(expected[key]~=nil,label.." retains only expected key "..tostring(key)) end
    end
    local legacy={
        schema=1,layout="Healing",locked=true,welcomed=true,
        layouts={
            Leveling={
                priest={point="TOPRIGHT",relativePoint="TOPRIGHT",x=-91,y=-42,
                    width=590,height=500,scale=0.7,opacity=0,contentOpacity=0,
                    hideHeader=true,shown=false,barsOnly=false},
                quests={point="CENTER",relativePoint="CENTER",x=48,y=19,
                    width=420,height=390,scale=0.8,opacity=0,contentOpacity=0.42,shown=true},
            },
            Healing={
                priest={point="CENTER",relativePoint="CENTER",x=123,y=-44,
                    width=250,height=420,scale=0.93,opacity=0.31,contentOpacity=0.8,
                    hideHeader=false,shown=true,barsOnly=true},
            },
        },
        previousLayout={name="Leveling",panels={
            priest={point="LEFT",relativePoint="LEFT",x=22,y=11,width=120,height=480,
                scale=0.6,opacity=0,contentOpacity=0,hideHeader=false,shown=true},
            goals={point="CENTER",relativePoint="CENTER",x=-5,y=9,width=340,height=400,
                scale=0.9,opacity=0.2,contentOpacity=1,shown=false},
        }},
        modules={
            priest={spells={{id=2061,name="Flash Heal"},{id=17,name="Power Word: Shield"}}},
            keys={notes={"Mouseover heal on 4","Use the side mouse button for interrupt"}},
            prep={checklist={}},
            goals={goals={{id=7,kind="Shopping",label="Linen cloth",itemID=2589,target=40,done=false},
                {id=12,kind="Profession",label="Visit the trainer",target=1,done=true}},
                nextID=13,filter="Shopping",hideCompleted=false},
            quests={selectedQuestID=101,autoAccept=true},
            kills={lifetime={automatic=0,manual=2,xp=0,restricted=0},
                manualLabels={Practice=2}},
        },
    }
    local before=ns.Copy(legacy)
    local legacyModules=legacy.modules
    PriestCompanionDB=legacy
    T.ok(ns.Models.Core.InitializeDatabase(),"schema-1 data upgrades through the real initializer")
    T.eq(ns.db,legacy,"existing per-character saved table is reused")
    T.eq(PriestCompanionDB,legacy,"legacy SavedVariables global remains authoritative")
    T.eq(ns.db.schema,1,"compatible upgrade keeps schema 1")
    T.eq(ns.db.layout,"Healing","upgrade preserves active layout")
    T.eq(ns.db.locked,true,"upgrade preserves lock state")
    T.eq(ns.db.modules,legacyModules,"upgrade does not replace module content")
    same(ns.db.modules,before.modules,"all saved spells, notes, checklist and goals survive")
    T.eq(#ns.db.modules.prep.checklist,0,"intentionally empty checklist remains empty")
    T.eq(ns.modules.priest,nil,"retired priest module is not registered")
    T.ok(ns.modules.resources,"replacement resources module is registered")

    for _,layout in ipairs({"Leveling","Healing"}) do
        local panels=ns.db.layouts[layout]
        T.ok(panels.resources~=panels.priest,"resource layout is an independent copy: "..layout)
        same(panels.priest,before.layouts[layout].priest,"legacy layout remains available for rollback: "..layout)
        for _,key in ipairs({"point","relativePoint","x","y","scale","opacity","contentOpacity",
            "hideHeader","shown"}) do
            T.eq(panels.resources[key],before.layouts[layout].priest[key],"resource migration preserves "..layout.."/"..key)
        end
    end
    T.eq(ns.db.layouts.Leveling.resources.width,320,"large legacy panel migrates to compact width")
    T.eq(ns.db.layouts.Leveling.resources.height,68,"hidden legacy title migrates to 68px resource height")
    T.eq(ns.db.layouts.Healing.resources.width,250,"already compact legacy width is preserved")
    T.eq(ns.db.layouts.Healing.resources.height,92,"visible legacy title migrates to 92px resource height")
    same(ns.db.layouts.Leveling.quests,before.layouts.Leveling.quests,"migration preserves other panels")
    local previous=ns.db.previousLayout
    T.eq(previous.name,"Leveling","undo snapshot retains its layout name")
    T.ok(previous.panels.resources~=previous.panels.priest,"undo resource layout is an independent copy")
    T.ok(previous.panels.resources~=ns.db.layouts.Leveling.resources,"undo and current resources are independent")
    T.eq(previous.panels.resources.width,200,"undersized old undo panel uses resource minimum width")
    T.eq(previous.panels.resources.height,92,"undo snapshot migrates resource height")
    T.eq(previous.panels.resources.opacity,0,"undo snapshot preserves exact zero opacity")
    same(previous.panels.priest,before.previousLayout.panels.priest,"undo retains legacy priest layout")
    same(previous.panels.goals,before.previousLayout.panels.goals,"undo retains unrelated layout entries")

    -- A second login must keep edits made after migration, including visibility
    -- and zero opacity; old priest settings must never win again.
    local resources=ns.db.layouts.Leveling.resources
    resources.width,resources.height,resources.x,resources.shown=450,220,307,true
    resources.scale,resources.opacity,resources.contentOpacity=0.5,0,0
    previous.panels.resources.width,previous.panels.resources.height=390,180
    local updatedResources=ns.Copy(resources)
    local updatedUndo=ns.Copy(previous.panels.resources)
    T.ok(ns.Models.Core.InitializeDatabase(),"a later login reinitializes migrated data")
    same(ns.db.layouts.Leveling.resources,updatedResources,"new resource settings win on later logins")
    same(ns.db.previousLayout.panels.resources,updatedUndo,"new resource undo snapshot wins on later logins")
    local zeroSettings=ns.PanelSettings("resources","Leveling")
    T.eq(zeroSettings.opacity,0,"panel normalization preserves saved zero background opacity")
    T.eq(zeroSettings.contentOpacity,0,"panel normalization preserves saved zero content opacity")
    T.eq(zeroSettings.width,450,"normalization does not reapply the one-time migration width cap")
    T.eq(zeroSettings.height,220,"normalization permits later resource resizing")
    same(ns.db.modules,before.modules,"reinitialization preserves complete saved module content")
    same(ns.db.layouts.Leveling.priest,before.layouts.Leveling.priest,"new resource edits do not mutate legacy layout")

    PriestCompanionDB=nil
    T.ok(ns.Models.Core.InitializeDatabase(),"fresh install initializes without legacy data")
    for _,layout in ipairs({"Leveling","Healing"}) do
        T.eq(ns.PanelSettings("resources",layout).shown,false,"fresh resources are optional in "..layout)
        T.eq(ns.PanelSettings("resources",layout).height,92,"fresh resources use compact bar height in "..layout)
        T.eq(ns.db.layouts[layout].priest,nil,"fresh install does not create a legacy priest layout")
    end
    T.eq(ns.db.modules.priest,nil,"fresh install does not recreate chosen-spell storage")

    -- Keep the existing refusal to overwrite a future incompatible save format.
    local freshDB=ns.db
    local future={schema=2,modules={keys={notes={"Future data"}}}}
    PriestCompanionDB=future
    T.eq(ns.Models.Core.InitializeDatabase(),false,"newer saved schema is rejected")
    T.eq(PriestCompanionDB,future,"rejected future schema is not replaced")
    T.eq(ns.db,freshDB,"rejected future schema is not made active")
    same(future,{schema=2,modules={keys={notes={"Future data"}}}},"future saved data is untouched")

    ns.db,PriestCompanionDB=originalDB,originalSaved
    local manifestFile=assert(io.open(TEST_ROOT.."/PriestCompanion/PriestCompanion.toc"))
    local manifest=manifestFile:read("*a");manifestFile:close()
    T.ok(manifest:find("## SavedVariablesPerCharacter: PriestCompanionDB\n",1,true),
        "manifest retains the existing per-character SavedVariables name")
    local bindingsFile=assert(io.open(TEST_ROOT.."/PriestCompanion/Bindings.xml"))
    local bindings=bindingsFile:read("*a");bindingsFile:close()
    for _,id in ipairs({"TOGGLE","LOCK","LAYOUT"}) do
        T.ok(bindings:find('name="PRIESTCOMPANION_'..id..'"',1,true),
            "binding declaration retains existing identifier: "..id)
    end
    T.eq(SLASH_PRIESTCOMPANION1,"/qc","primary slash alias uses new name")
    T.eq(SLASH_PRIESTCOMPANION2,"/questcompanion","long new slash alias is registered")
    T.eq(SLASH_PRIESTCOMPANION3,"/pc","legacy short slash alias remains registered")
    T.eq(SLASH_PRIESTCOMPANION4,"/priestcompanion","legacy long slash alias remains registered")
    T.eq(SlashCmdList.PRIESTCOMPANION,ns.RunCommand,"all aliases retain the existing handler registration")
    T.eq(BINDING_HEADER_PRIESTCOMPANION,"Quest Companion","binding group displays new product name")
    T.eq(type(PriestCompanion_Toggle),"function","legacy toggle binding function remains available")
    T.eq(type(PriestCompanion_Lock),"function","legacy lock binding function remains available")
    T.eq(type(PriestCompanion_Layout),"function","legacy layout binding function remains available")
    local function slash(message)
        local prefix,body=message:match("^(%S+)%s*(.*)$")
        for index=1,4 do
            if _G["SLASH_PRIESTCOMPANION"..index]==prefix then
                return SlashCmdList.PRIESTCOMPANION(body)
            end
        end
        error("Unregistered slash alias: "..prefix)
    end
    slash("/pc appearance priest")
    Mock.Flush()
    T.eq(ns.modules.appearance.selected,"resources","legacy appearance priest command selects resources")
    T.eq(ns.frames.appearance:IsVisible(),true,"legacy appearance command opens the live control panel")
    slash("/qc appearance resources")
    Mock.Flush()
    T.eq(ns.modules.appearance.selected,"resources","new appearance resources command selects resources")
    slash("/qc hide resources")
    Mock.Flush()
    T.eq(ns.PanelSettings("resources").shown,false,"new slash command hides resources")
    slash("/pc show priest")
    Mock.Flush()
    T.eq(ns.PanelSettings("resources").shown,true,"legacy panel alias controls resources")
    T.eq(ns.frames.resources:IsVisible(),true,"legacy panel alias changes the existing resource frame")

    -- Restore the shared integration fixture, including UI changes above.
    ns.db.layouts,ns.db.layout,ns.db.locked=original.layouts,original.layout,original.locked
    ns.db.previousLayout=original.previousLayout
    ns.modules.appearance.selected=original.selected
    for _,id in ipairs(ns.order) do ns.ApplyPanel(id) end
    Mock.Flush()
end
