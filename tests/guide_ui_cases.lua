return function(T,ns,Mock)
    local module=ns.modules.guide
    local oldAPI,oldProvider=C_QuestLog,ns.GuideWaypoints
    local oldDB,oldShown=ns.db.modules.guide,ns.PanelSettings("guide").shown
    local log,completed,ready={}, {}, {}
    local calls,clears,lastRequest=0,0,nil
    C_QuestLog={
        GetNumQuestLogEntries=function() return #log end,
        GetInfo=function(index) return {questID=log[index],isHeader=false,isHidden=false,title="Guide test quest"} end,
        IsQuestFlaggedCompleted=function(id) return completed[id]==true end,
        IsComplete=function(id) return ready[id]==true end,
    }
    ns.GuideWaypoints={
        Show=function(steps,options)
            calls=calls+1;lastRequest={steps=steps,options=options}
            return true,"Test guide markers",{rendered=#steps}
        end,
        Clear=function() clears=clears+1;return true end,
        Status=function() return "Test provider" end,
    }
    ns.db.modules.guide={route="deathknell",markers="current",follow=true,expanded=false,
        progress={manual={},history={}}}
    ns.SetPanelVisible("guide",true);Mock.Flush()
    T.eq(module.route[module.index].id,"dk01-exit","Fresh guide begins with supplied crypt action")
    T.eq(module.route[9].questIDs[1],3097,"Real guide UI uses Priest scroll substitution")
    T.eq(module.frame.background[4],0,"Fresh guide is transparent")
    module.done:Click();Mock.Flush()
    T.eq(module.route[module.index].id,"dk02-accept363","Done advances manual travel to next action")
    T.eq(ns.db.modules.guide.progress.manual["dk01-exit"],"done","Manual travel retains explicit provenance")

    log={363};Mock.Fire("QUEST_ACCEPTED",363)
    T.eq(module.route[module.index].id,"dk02-turnin363","Quest log acceptance advances to turn-in")
    T.eq(ns.db.modules.guide.progress.manual["dk02-accept363"],nil,"Automatic acceptance does not become a manual saved mark")
    ready[363]=true;Mock.Fire("QUEST_LOG_UPDATE")
    T.eq(module.route[module.index].id,"dk02-turnin363","Ready quest does not falsely complete turn-in")
    completed[363]=true;log={};Mock.Fire("QUEST_TURNED_IN",363)
    T.eq(module.route[module.index].id,"dk03-accept364","Historical completion advances turn-in")

    local evidence=ns.Models.GuideUI.ReadEvidence(module.route)
    T.eq(evidence.completed[363],true,"Reader preserves actual completed flag")
    T.eq(evidence.inLog[363],false,"Readable full log establishes absence")
    T.eq(evidence.ready[364],false,"Known unaccepted/uncompleted task is not ready")
    local originalHistory=C_QuestLog.IsQuestFlaggedCompleted
    C_QuestLog.IsQuestFlaggedCompleted=function() return Mock.Secret() end
    evidence=ns.Models.GuideUI.ReadEvidence(module.route)
    T.eq(evidence.completed[363],nil,"Restricted history remains unknown")
    T.eq(evidence.ready[364],nil,"Restricted history is not compared as a boolean")
    C_QuestLog.IsQuestFlaggedCompleted=originalHistory
    local originalInfo=C_QuestLog.GetInfo
    log={363};C_QuestLog.GetInfo=function() error("Unavailable log row") end
    evidence=ns.Models.GuideUI.ReadEvidence(module.route)
    T.eq(evidence.inLog[364],nil,"Partial log does not prove absence")
    C_QuestLog.GetInfo=originalInfo;log={}

    ready[6395],completed[6395]=true,true
    module:Select(19,false);Mock.Flush()
    T.eq(module.route[module.index].id,"dk09-fipps","Explicit selected partial action remains selected")
    T.eq(module.done:IsEnabled(),true,"Whole-quest evidence cannot auto-complete manual kill/loot action")
    module.done:Click();Mock.Flush()
    T.eq(module.route[module.index].id,"dk10-cave","Manual partial action advances to cave travel")
    module.modeButtons.route:Click();Mock.Flush()
    T.eq(lastRequest.options.mode,"route","Route button requests multiple guide actions")
    T.ok(#lastRequest.steps>1,"Route request contains remaining steps")
    T.eq(lastRequest.options.openMap,true,"Route button opens map without a slash command")
    module.skip:Click();Mock.Flush()
    T.eq(ns.db.modules.guide.progress.manual["dk10-cave"],"skipped","Skip is not a completion flag")
    module.undo:Click();Mock.Flush()
    T.eq(ns.db.modules.guide.progress.manual["dk10-cave"],nil,"Undo restores the skipped travel action")
    T.eq(module.route[module.index].id,"dk10-cave","Undo selects restored action")
    module.back:Click();Mock.Flush()
    T.eq(module.route[module.index].id,"dk09-fipps","Back reviews previous action")
    T.eq(ns.db.modules.guide.progress.manual["dk09-fipps"],"done","Back leaves prior manual completion intact")

    local hookCount=#module.instruction.hooks.OnEnter
    for _=1,6 do module:Refresh() end
    T.eq(#module.instruction.hooks.OnEnter,hookCount,"Refresh does not accumulate instruction tooltips")
    module.stepsToggle:Click();Mock.Flush()
    T.eq(ns.db.modules.guide.expanded,true,"All steps opens full checklist")
    T.eq(module.rows[12].button.label.maxLines,0,"Guide route rows explicitly permit multiple lines")
    T.ok(module.rows[12].button:GetHeight()>26,"Long guide instructions receive wrapped row height")
    module.rows[25].button:Click();Mock.Flush()
    T.eq(module.route[module.index].id,"dk12-scarlet","Clicking a route row selects its actual action")
    T.eq(lastRequest.options.openMap,true,"Route row click maps its action")
    module.modeButtons.hide:Click();Mock.Flush()
    T.eq(lastRequest.options.mode,"hide","Hide requests guide-owned marker removal")
    module.map:Click();Mock.Flush()
    T.eq(ns.db.modules.guide.markers,"current","Map makes a hidden guide destination visible")
    T.eq(module.modeButtons.current.pcSelected,true,"Map highlights Current after leaving Hide")
    T.eq(module.modeButtons.hide.pcSelected,false,"Map clears the prior Hide highlight")
    T.eq(lastRequest.options.openMap,true,"Map opens selected action directly")

    Mock.combat=true;Mock.Fire("PLAYER_REGEN_DISABLED")
    local before=ns.Copy(ns.db.modules.guide.progress)
    module.done:Click();module.skip:Click()
    T.eq(#ns.db.modules.guide.progress.history,#before.history,"Combat controls cannot change guide progress")
    T.eq(module.map:IsEnabled(),false,"Map control is disabled during combat")
    Mock.combat=false;Mock.Fire("PLAYER_REGEN_ENABLED")
    T.eq(module.map:IsEnabled(),true,"Guide controls recover after combat")
    local beforeClear=clears
    ns.SetPanelVisible("guide",false);Mock.Flush()
    T.eq(clears,beforeClear+1,"Hiding guide releases its markers")
    T.ok(calls>0,"Real UI flow used marker provider")

    C_QuestLog,ns.GuideWaypoints=oldAPI,oldProvider
    ns.db.modules.guide=oldDB
    module.markerSignature=nil
    ns.SetPanelVisible("guide",oldShown)
    if oldShown then module:Refresh() end
    Mock.Flush()
end
