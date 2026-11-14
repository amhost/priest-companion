return function(T, common, Mock)
    local names = {"QuestieLoader", "LibStub", "C_AddOns", "GetAddOnMetadata", "C_Map", "CreateFrame"}
    local saved = {}
    for _, name in ipairs(names) do saved[name] = _G[name] end
    local function fixture(version)
        local f = {events={}, world={}, mini={}, maps={}, queries={}, combat=false, mutations=0, frames=0,
            live={}, data={Quest={}, NPC={}, Object={}, Item={}}, position={0, 0, 1}, badMaps={}}
        local localNS = {Readable=common.Readable, Number=common.Number, Call=common.Call, CleanText=common.CleanText,
            IsCombat=function() return f.combat end, Refresh=function() f.refreshed=true end}
        function localNS.On(event, fn)
            f.events[event] = f.events[event] or {}; table.insert(f.events[event], fn)
        end
        function f:Fire(event)
            for _, fn in ipairs(self.events[event] or {}) do fn(event) end
        end
        local function mutation() assert(not f.combat, "pin API cannot mutate in combat"); f.mutations=f.mutations+1 end
        local hbd = {
            GetPlayerWorldPosition=function() return table.unpack(f.position) end,
            GetWorldCoordinatesFromZone=function(_, x, y, map)
                if f.badMaps[map] then return nil end
                return x*1000, y*1000, map == 2000 and 2 or 1
            end,
        }
        local pins = {}
        function pins:AddWorldMapIconMap(ref, icon, map, x, y, flag)
            mutation(); assert(flag == -1, "only exact zone map pins are requested")
            f.owner=ref; f.world[ref]=f.world[ref] or {}
            f.world[ref][icon]={map=map,x=x,y=y}; icon:Show()
            if f.failWorld then error("synthetic world pin failure") end
        end
        function pins:AddMinimapIconMap(ref, icon, map, x, y, parent, edge)
            mutation(); assert(not parent and not edge, "guide pins stay on their own zone without edge clutter")
            f.owner=ref; f.mini[ref]=f.mini[ref] or {}
            f.mini[ref][icon]={map=map,x=x,y=y}; icon:Show()
            if f.failMini then error("synthetic minimap pin failure") end
        end
        function pins:RemoveAllWorldMapIcons(ref)
            mutation(); assert(ref ~= f.foreign, "foreign map reference must never be removed")
            if f.failClear then error("synthetic cleanup failure") end
            for icon in pairs(f.world[ref] or {}) do icon:Hide() end
            f.world[ref]={}
        end
        function pins:RemoveAllMinimapIcons(ref)
            mutation(); assert(ref ~= f.foreign, "foreign minimap reference must never be removed")
            if f.failClear then error("synthetic cleanup failure") end
            for icon in pairs(f.mini[ref] or {}) do icon:Hide() end
            f.mini[ref]={}
        end
        f.foreign={}; f.world[f.foreign]={native=true}; f.mini[f.foreign]={personal=true}
        local db = {}
        for _, kind in ipairs({"Quest", "NPC", "Object", "Item"}) do
            db["Query"..kind.."Single"] = function(entityID, field)
                assert(type(entityID)=="number" and type(field)=="string", "DB wrappers are dot-called")
                f.queries[#f.queries+1]={kind,entityID,field}
                local data=f.data[kind][entityID]
                return data and data[field]
            end
        end
        local registry = {HBD=hbd, HBDPins=pins, QuestieDB=db,
            ZoneDB={GetUiMapIdByAreaId=function(_, area)
                if area==85 then return 1420 elseif area==86 then return 1421 elseif area==999 then return 2000 end
            end},
            Phasing={IsSpawnVisible=function(phase)
                assert(type(phase)=="number", "phase visibility is dot-called")
                if f.phaseError then error("phase cache not ready") end
                return phase==1 and true or false
            end},
            QuestieCompat={OpenWorldMap=function(map)
                assert(not f.combat, "map must not open in combat")
                f.maps[#f.maps+1]=map
                return not f.failOpen
            end},
        }
        C_AddOns={GetAddOnMetadata=function(name) return name=="Questie" and (version or "12.9.0") or "1.0.14" end}
        GetAddOnMetadata=nil
        LibStub={GetLibrary=function(_, name)
            if name=="HereBeDragonsQuestie-2.0" then return hbd end
            if name=="HereBeDragonsQuestie-Pins-2.0" then return pins end
        end}
        if version=="12.6.5" then registry.HBD,registry.HBDPins=nil,nil end
        QuestieLoader={_modules=registry}
        C_Map={SetUserWaypoint=function() error("must not set a personal waypoint") end,
            ClearUserWaypoint=function() error("must not clear a personal waypoint") end}
        CreateFrame=function(...)
            assert(not f.combat, "marker frames cannot be created in combat")
            f.frames=f.frames+1
            return saved.CreateFrame(...)
        end
        assert(loadfile(TEST_ROOT.."/PriestCompanion/QuestieBridge.lua"))("PriestCompanion",localNS)
        localNS.QuestieBridge.GetObjectiveLocations=function(questID) return f.live[questID] end
        assert(loadfile(TEST_ROOT.."/PriestCompanion/GuideWaypoints.lua"))("PriestCompanion",localNS)
        f.ns,f.waypoints,f.registry=localNS,localNS.GuideWaypoints,registry
        function f:Count(where)
            local count=0; for _ in pairs(self[where][self.owner] or {}) do count=count+1 end; return count
        end
        function f:Marker(index, where)
            for icon in pairs(self[where or "world"][self.owner] or {}) do
                if icon.guidePoint.ordinal==index then return icon end
            end
        end
        return f
    end
    local function supplied(stepID,x,y)
        return {id=stepID,kind="goto",text="Go to "..stepID,manualOnly=true,
            points={{areaID=85,x=x,y=y,provenance="user",label=stepID}}}
    end
    local function action(stepID,kind,questID) return {id=stepID,kind=kind,text=stepID,questIDs={questID}} end
    local function data(f)
        f.data.NPC[10]={spawns={[85]={{20,20},{60,60},{5,5,2},{10,10,1}}}}
        f.data.NPC[11]={spawns={[85]={{30,30}}}}
        f.data.NPC[12]={spawns={[999]={{1,1}},[85]={{90,90}}}}
        f.data.Object[20]={spawns={[85]={{40,40}}}}
        f.data.Object[21]={spawns={[85]={{50,50}}}}
        f.data.Quest[100]={startedBy={{10}},finishedBy={nil,{20}}}
        f.data.Quest[101]={objectives={{{10,"Kill",5}},{{20,"Use",1}},{{30,"Loot",2}}}}
        f.data.Item[30]={npcDrops={11},objectDrops={21},vendors={}}
    end
    local ok, err = pcall(function()
        for _, version in ipairs({"12.6.5", "12.9.0"}) do
            local f=fixture(version)
            local step=supplied("one",.36,.62)
            local resolved=f.waypoints.ResolveStep(step)
            T.eq(#resolved,1,"explicit coordinate resolves on supported provider "..version)
            T.eq(resolved[1].uiMapID,1420,"area ID comes through live zone converter")
            T.eq(f.frames,0,"resolution is read-only")
            local success,message,info=f.waypoints.Show({step,supplied("two",.27,.59)}, {mode="route",openMap=true})
            T.eq(success,true,"multiple route locations can be shown "..version)
            T.eq(info.rendered,2,"two distinct guide locations")
            T.eq(f:Count("world"),2,"two world markers are owned")
            T.eq(f:Count("mini"),2,"two minimap markers are owned")
            T.eq(f.maps[1],1420,"native compatibility helper opens exact zone")
            T.ok(f:Marker(1)~=f:Marker(1,"mini"),"world and minimap use different frames")
            T.eq(f:Marker(1).icon.texture,"Interface\\GossipFrame\\AvailableQuestIcon","marker uses stock WoW texture")
            T.eq(f:Marker(1).guidePoint.current,true,"current step is highlighted")
            T.eq(f:Marker(2).guidePoint.current,false,"future step has normal emphasis")
            T.eq(f:Marker(1).label:GetText(),"1","first marker is numbered")
            T.ok(message:find("Route hints",1,true),"status does not claim quest availability")
            T.eq(f.world[f.foreign].native,true,"native/Questie world refs are unchanged")
            T.eq(f.mini[f.foreign].personal,true,"personal/other minimap refs are unchanged")
            local frameCount=f.frames
            f.waypoints.Show({step},{mode="current"})
            T.eq(f.frames,frameCount,"marker frames are reused")
            T.eq(f:Count("world"),1,"new route replaces old guide-owned markers")
            T.eq(f.waypoints.Clear(),true,"guide close removes guide markers")
            T.eq(f:Count("world"),0,"world guide pins cleared")
            T.eq(f:Count("mini"),0,"minimap guide pins cleared")
            T.eq(f.world[f.foreign].native,true,"clear retains all other owners")
        end

        local f=fixture();data(f)
        local points=f.waypoints.ResolveStep(action("accept","accept",100))
        T.eq(#points,1,"one closest pickup per action, not every spawn")
        T.near(points[1].x,.1,"visible phased spawn beats farther unphased spawn")
        f.registry.Phasing=nil
        points=f.waypoints.ResolveStep(action("accept","accept",100))
        T.near(points[1].x,.2,"phased spawns are omitted without phase provider")
        f.registry.Phasing={IsSpawnVisible=function() error("not ready") end}
        points=f.waypoints.ResolveStep(action("accept","accept",100))
        T.near(points[1].x,.2,"failing phase helper does not expose hidden phases")
        f.registry.Phasing={IsSpawnVisible=function() return Mock.Secret() end}
        points=f.waypoints.ResolveStep(action("accept","accept",100))
        T.near(points[1].x,.2,"restricted phase result is omitted")
        points=f.waypoints.ResolveStep(action("turnin","turnin",100))
        T.near(points[1].x,.4,"object turn-in resolves from finishedBy")
        points=f.waypoints.ResolveStep(action("objectives","objective",101))
        T.eq(#points,3,"creature, object and item objective each get one location")
        T.near(points[1].x,.2,"creature objective selects one spawn")
        T.near(points[2].x,.4,"object objective maps its spawn")
        T.near(points[3].x,.3,"item source selected nearest previous objective with stable tie")
        T.eq(points[3].provenance,"QuestieDB","raw DB hint provenance is preserved")
        f.data.Quest[102]={startedBy={{12}}}
        points=f.waypoints.ResolveStep(action("sameinstance","accept",102))
        T.eq(points[1].uiMapID,1420,"same-instance location is preferred over closer numerical coordinate elsewhere")

        f=fixture();data(f)
        local success,_,info=f.waypoints.Show({supplied("start",.59,.59),action("accept","accept",100)}, {mode="route"})
        T.eq(success,true)
        T.near(f:Marker(2).guidePoint.x,.6,"route chooses nearest spawn to previous action")
        f.live[101]={{{uiMapID=1420,x=.72,y=.73},{uiMapID=1420,x=.82,y=.83}}}
        points=f.waypoints.ResolveStep(action("live","objective",101))
        T.eq(#points,1,"validated live clusters override broad objective DB groups")
        T.near(points[1].x,.72,"nearest live unfinished cluster is used")
        T.eq(points[1].provenance,"Questie","live icon provenance remains distinct")
        f.live[101]={}
        points=f.waypoints.ResolveStep(action("complete","objective",101))
        T.eq(#points,0,"completed live quest does not fall back to old objective spawns")

        f=fixture();data(f)
        f.data.Quest[103]={startedBy={nil,nil,{31}}}
        f.data.Item[31]={itemDrops={32}}
        f.data.Item[32]={itemDrops={31},objectDrops={20}}
        points=f.waypoints.ResolveStep(action("item-start","accept",103))
        T.eq(#points,1,"item-start quest resolves known container source without looping")
        T.near(points[1].x,.4,"container spawn source is used")
        f.data.Quest[104]={objectives={[5]={{{10,11},999,"credit",2}},[6]={{77,"cast",88}}}}
        local reason,detail
        points,reason,detail=f.waypoints.ResolveStep(action("credit","objective",104))
        T.eq(#points,1,"kill credit maps real NPC list instead of synthetic credit ID")
        T.eq(detail.unmapped,1,"unlocated spell objective is explicitly reported")
        T.ok(reason:find("Some objectives",1,true),"partial objective coverage is visible")

        f=fixture();data(f)
        local explicit=supplied("manual",.36,.62);explicit.questIDs={100};explicit.kind="objective"
        explicit.points[1].areaID=123456
        points=f.waypoints.ResolveStep(explicit)
        T.eq(#points,0,"unknown explicit map is not substituted with an unrelated quest location")
        T.eq(#f.queries,0,"explicit supplied coordinates never trigger broad fallback")
        for _, invalid in ipairs({-1,1.01,math.huge,0/0,Mock.Secret()}) do
            local invalidStep=supplied("bad",invalid,.5)
            points=f.waypoints.ResolveStep(invalidStep)
            T.eq(#points,0,"invalid or restricted coordinate cannot become a marker")
        end
        f.badMaps[1420]=true
        points=f.waypoints.ResolveStep(supplied("badtransform",.3,.5))
        T.eq(#points,0,"silent HBD conversion failure is rejected before marker API")

        f=fixture()
        success,_,info=f.waypoints.Show({supplied("one",.3,.4),supplied("repeat",.3,.4),{id="written",kind="train",text="Train"}},
            {mode="route",focusStepID="repeat"})
        T.eq(success,true)
        T.eq(info.rendered,1,"coincident actions share one marker")
        T.eq(#f:Marker(1).guidePoint.visits,2,"coincident actions remain in marker tooltip")
        T.eq(f:Marker(1).guidePoint.current,true,"a later coincident focused action still highlights its marker")
        T.eq(info.unmapped,1,"written-only action is reported unmapped")
        T.eq(info.unmappedIDs[1],"written","unmapped step ID is available to the UI")
        local steps={}
        for i=1,27 do steps[i]=supplied("step"..i,i/100,.4) end
        success,_,info=f.waypoints.Show(steps,{mode="route"})
        T.eq(success,true)
        T.eq(info.rendered,24,"guide rendering is capped to 24 markers")
        T.eq(info.capped,3,"steps beyond cap are reported")
        T.eq(#info.cappedIDs,3,"capped step IDs are supplied")
        T.eq(f:Count("world"),24,"world owner holds at most 24 markers")
        T.eq(f:Count("mini"),24,"minimap owner holds at most 24 markers")

        f=fixture()
        f.waypoints.Show({supplied("old",.1,.1)},{mode="current"})
        local before,created=f.mutations,f.frames
        f.combat=true
        success,_,info=f.waypoints.Show({supplied("queued",.2,.2)},{mode="current",openMap=true})
        T.eq(success,false,"combat redraw reports deferred rather than pretending drawn")
        T.eq(info.deferred,true,"deferred status is explicit")
        T.eq(f.mutations,before,"combat redraw makes no pin API mutation")
        T.eq(f.frames,created,"combat redraw allocates no marker frames")
        T.eq(f.waypoints.Clear(),false,"combat close queues owned cleanup")
        f.combat=false;f:Fire("PLAYER_REGEN_ENABLED")
        T.eq(f:Count("world"),0,"latest queued close wins over earlier redraw")
        T.eq(#f.maps,0,"superseded combat open does not open map")
        f.combat=true
        f.waypoints.Show({supplied("queued",.2,.2)},{mode="current",openMap=true})
        f.combat=false;f:Fire("PLAYER_REGEN_ENABLED")
        T.eq(f:Count("world"),1,"deferred route is restored after combat")
        T.near(f:Marker(1).guidePoint.x,.2,"latest queued coordinate is used")
        T.eq(#f.maps,1,"deferred user-requested map opens once after combat")
        f:Fire("QUEST_LOG_UPDATE")
        T.eq(#f.maps,1,"automatic refresh never reopens map")
        f.waypoints.Clear();f:Fire("QUEST_LOG_UPDATE")
        T.eq(f:Count("world"),0,"hidden guide cannot resurrect on quest event")

        for _, failure in ipairs({"failWorld","failMini","failOpen"}) do
            f=fixture();f[failure]=true
            success,reason,info=f.waypoints.Show({supplied("error",.3,.3)},{mode="current",openMap=true})
            T.eq(success,false,"provider failure is reported: "..failure)
            T.eq(info.rendered,0,"provider failure does not report rendered success")
            T.eq(f:Count("world"),0,"partial world draw is cleaned on failure")
            T.eq(f:Count("mini"),0,"partial minimap draw is cleaned on failure")
            T.eq(f.world[f.foreign].native,true,"error cleanup preserves foreign map pins")
        end
        f=fixture("12.6.4")
        success,reason=f.waypoints.Show({supplied("unsupported",.2,.2)},{mode="current"})
        T.eq(success,false,"unsupported provider cannot draw")
        T.ok(reason:find("12.6.5",1,true),"unsupported provider gives supported version guidance")
        T.eq(f.frames,0,"unsupported provider creates no markers")
    end)
    for _, name in ipairs(names) do _G[name]=saved[name] end
    if not ok then error(err,0) end
end
