return function(T, ns, Mock)
    local Guide = ns.Models.Guide
    T.ok(Guide, "Guide model is exported")
    local route = Guide.BuildRoute("PRIEST")
    T.eq(#route, 33, "Compound route actions remain separately trackable")
    local sourceSteps, ids, userPoints = {}, {}, 0
    local priestScroll, tainted = 0, 0
    for _, step in ipairs(route) do
        T.eq(ids[step.id],nil,"Stable action IDs are unique")
        ids[step.id] = true
        sourceSteps[step.sourceStep] = true
        for _, id in ipairs(step.questIDs or {}) do
            if id == 3097 then priestScroll = priestScroll + 1 end
            if id == 3099 then tainted = tainted + 1 end
        end
        for _, point in ipairs(step.points or {}) do
            userPoints = userPoints + 1
            T.eq(point.areaID,85,"Supplied points use the verified Tirisfal area")
            T.eq(point.provenance,"user","Coordinates retain user provenance")
            T.ok(point.x > 0 and point.x < 1 and point.y > 0 and point.y < 1,
                "Guide coordinates are normalized without inventing 0,0")
            T.eq(point.mapID,nil,"Guide data does not pretend a runtime map resolution occurred")
        end
    end
    for index=1,15 do T.eq(sourceSteps[index],true,"Original source step retained: " .. index) end
    T.eq(userPoints,6,"User's coordinates retained, including cave travel and objective")
    T.eq(priestScroll,2,"Priest acceptance and turn-in use Hallowed Scroll")
    T.eq(tainted,0,"Priest route never requires Warlock Tainted Scroll")
    local warlock = Guide.BuildRoute("WARLOCK")
    T.eq(warlock[9].questIDs[1],3099,"Warlock keeps its own scroll")
    T.ok(warlock[11].text:find("Maximillion",1,true),"Warlock trainer is class-specific")
    T.ok(route[11].text:find("Dark Cleric Duesten",1,true),"Priest trainer is class-specific")
    local other = Guide.BuildRoute("ROGUE")
    T.eq(other[9].manualOnly,true,"Unverified class substitution stays manual")
    T.eq(other[9].questIDs,nil,"Unverified class has no invented quest ID")
    route[9].questIDs[1]=999
    route[19].points[1].x=0.1
    route = Guide.BuildRoute("PRIEST")
    T.eq(route[9].questIDs[1],3097,"Route edits do not mutate shared data")
    T.near(route[19].points[1].x,0.36,"Point edits do not mutate shared data")

    local accept={id="test-accept",kind="accept",questIDs={1}}
    local turnin={id="test-turnin",kind="turnin",questIDs={1}}
    local objective={id="test-objective",kind="objective",questIDs={1}}
    local travel={id="test-travel",kind="goto",text="Walk there",manualOnly=true}
    local evidence={inLog={[1]=true},completed={[1]=false},ready={[1]=true}}
    T.eq(Guide.Evaluate(accept,evidence).done,true,"Current log confirms acceptance")
    T.eq(Guide.Evaluate(objective,evidence).done,true,"Ready objectives can complete an objective row")
    T.eq(Guide.Evaluate(turnin,evidence).done,false,"Ready-to-turn-in is not historical turn-in")
    T.eq(Guide.Evaluate(turnin,evidence).status,"pending","Known unturned quest stays pending")
    evidence.completed[1]=nil
    T.eq(Guide.Evaluate(turnin,evidence).status,"unknown","Missing completion history is not false")
    evidence.completed[1]=true
    evidence.inLog[1]=false
    evidence.ready[1]=false
    T.eq(Guide.Evaluate(accept,evidence).done,true,"Historical completion establishes prior acceptance")
    T.eq(Guide.Evaluate(objective,evidence).done,true,"Historical completion establishes finished objectives")
    T.eq(Guide.Evaluate(turnin,evidence).done,true,"Historical completion confirms turn-in")
    T.eq(Guide.Evaluate(travel,evidence).done,false,"Quest history never completes travel")
    T.eq(Guide.Evaluate({kind="interact",questIDs={1}},evidence).status,"manual","Interactions stay manual")
    T.eq(Guide.Evaluate({kind="train"},evidence).status,"manual","Training stays manual")
    T.eq(Guide.Evaluate({kind="objective",manualOnly=true,questIDs={1}},evidence).done,false,
        "Looting Fipps is not inferred from whole-quest readiness")

    local compound={id="test-compound",kind="turnin",questIDs={1,2}}
    evidence.completed[2]=false
    T.eq(Guide.Evaluate(compound,evidence).done,false,"Every compound turn-in is required")
    T.eq(Guide.Evaluate(compound,evidence).text,"1/2 quest tasks complete.","Partial compound progress is visible")
    evidence.completed[2]=nil
    T.eq(Guide.Evaluate(compound,evidence).status,"unknown","Missing second quest does not produce completion")
    evidence.completed[2]=true
    T.eq(Guide.Evaluate(compound,evidence).done,true,"Both historical flags complete compound turn-in")
    T.eq(Guide.Evaluate(accept,{}).status,"unknown","Absent APIs remain unknown")
    T.eq(Guide.Evaluate({kind="accept",questIDs={}},evidence).status,"unknown","Empty identity list cannot auto-complete")
    T.eq(Guide.Evaluate({kind="turnin",questIDs={0}},evidence).status,"unknown","Zero quest ID is not a real quest")
    T.eq(Guide.Evaluate({kind="turnin",questIDs={1.5}},evidence).status,"unknown","Fractional quest ID is rejected")

    local secret=Mock.Secret()
    T.eq(Guide.Evaluate(turnin,{completed={[1]=secret}}).status,"unknown","Secret completion flag is not compared or persisted")
    T.eq(Guide.Evaluate(accept,{inLog=secret,completed={}}).status,"unknown","Secret evidence table is not indexed")
    T.eq(Guide.Evaluate(secret,evidence).status,"unknown","Secret step is not indexed")
    T.eq(Guide.BuildRoute(secret)[9].questIDs,nil,"Secret class token cannot select a class route")

    local state={manual={},history={}}
    T.eq(Guide.Current({travel,turnin},state,evidence),1,"First manual action remains current")
    T.ok(Guide.SetManual(state,travel.id,true),"Done records explicit player progress")
    T.eq(Guide.Status(travel,state,evidence).status,"done","Manual completion has distinct provenance")
    T.eq(Guide.Current({travel,turnin},state,evidence),nil,"Known completed route has no fabricated next step")
    T.ok(Guide.Skip(state,travel.id),"Skip can replace a manual mark")
    T.eq(Guide.Status(travel,state,evidence).status,"skipped","Skipped rows are distinct from done")
    T.ok(Guide.Undo(state),"Undo restores prior done state")
    T.eq(Guide.Status(travel,state,evidence).status,"done","Undo restores previous mark rather than clearing all progress")
    T.ok(Guide.Undo(state),"Second undo restores unmarked state")
    T.eq(Guide.Status(travel,state,evidence).status,"manual","Unmarked travel again needs explicit completion")
    T.eq(Guide.Undo(state),false,"Empty undo does nothing")
    T.ok(Guide.SetManual(state,travel.id,true),"Manual completion can be set again")
    T.ok(Guide.SetManual(state,travel.id,false),"Done can be cleared without resetting the route")
    T.eq(Guide.Status(travel,state,evidence).done,false,"Cleared manual state is pending")
    T.eq(Guide.SetManual(state,secret,true),false,"Secret IDs are not stored")
    T.eq(Guide.SetManual(state,"unsafe\nkey",true),false,"Invalid progress keys are rejected")
    T.eq(Guide.SetManual(state,"safe",secret),false,"Secret control values are rejected")
    T.eq(Guide.SetManual(secret,"safe",true),false,"Secret progress state is not indexed")

    local skipped={id="test-skip",kind="reminder",manualOnly=true}
    Guide.SetManual(state,travel.id,true)
    Guide.Skip(state,skipped.id)
    local beforeHistory=#state.history
    local progress=Guide.Progress({travel,turnin,skipped},state,evidence)
    T.eq(progress.total,3,"Progress counts all action rows")
    T.eq(progress.done,3,"Progress includes resolved rows")
    T.eq(progress.manual,1,"Manual done counted separately")
    T.eq(progress.skipped,1,"Skip counted separately")
    T.eq(progress.automatic,1,"Confirmed game progress counted separately")
    T.eq(progress.pending,0,"Resolved route has no pending row")
    T.eq(state.manual[turnin.id],nil,"Observed game completion is not written as manual data")
    T.eq(#state.history,beforeHistory,"Read-only status does not create undo history")
    for index=1,110 do Guide.SetManual(state,"bounded-"..index,true) end
    T.eq(#state.history,100,"Undo history remains bounded")
end
