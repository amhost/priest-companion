local addonName, ns = ...
local UI, Model = ns.UI, ns.Models.Guide

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function settings()
    return ns.ModuleDB("guide", {route="deathknell", markers="current", follow=true,
        expanded=false, progress={manual={},history={}}})
end

local function readEvidence(route)
    local evidence = {inLog={},completed={},ready={}}
    local api = readableTable(C_QuestLog) and C_QuestLog or nil
    if not api then return evidence end
    local wanted, found = {}, {}
    for _, step in ipairs(route) do
        for _, id in ipairs(step.questIDs or {}) do wanted[id] = true end
    end
    local total = ns.Number(ns.Call(api.GetNumQuestLogEntries))
    local fullLog = total ~= nil and total >= 0 and total <= 1000 and total == math.floor(total)
    if fullLog then
        for index = 1, total do
            local row = ns.Call(api.GetInfo, index)
            if not readableTable(row) or not ns.Readable(row.isHeader) then fullLog = false
            elseif row.isHeader ~= true then
                local id = ns.Number(row.questID)
                if id and id > 0 and id == math.floor(id) then found[id] = true else fullLog = false end
            end
        end
    end
    for id in pairs(wanted) do
        if found[id] then evidence.inLog[id] = true
        elseif fullLog then evidence.inLog[id] = false end
        local done = ns.Call(api.IsQuestFlaggedCompleted, id)
        if ns.Readable(done) and type(done) == "boolean" then evidence.completed[id] = done end
        if found[id] then
            local ready = ns.Call(api.IsComplete, id)
            if ns.Readable(ready) and type(ready) == "boolean" then evidence.ready[id] = ready end
        elseif fullLog and evidence.completed[id] == false then evidence.ready[id] = false end
    end
    return evidence
end

ns.Models.GuideUI = {ReadEvidence=readEvidence}

local kinds = {["goto"]="Travel",accept="Accept quest",objective="Quest objective",turnin="Turn in",
    interact="Interact",train="Visit trainer",reminder="Reminder"}

local Module = {id="guide",title="Deathknell 1-6",width=360,height=360,minWidth=300,minHeight=280,
    description="A class-aware leveling checklist with current and route markers, manual controls and quest progress.",
    defaultOpacity=0,defaultEnabled={Healing=false,Leveling=false}}

local function routeIndex(route, id)
    for index, step in ipairs(route or {}) do if step.id == id then return index end end
end

local function remainingSteps(self)
    local db, steps = settings(), {}
    if not self.index then return steps end
    if db.markers == "current" then return {self.route[self.index]} end
    for index = self.index, #self.route do
        local step = self.route[index]
        if index == self.index or not Model.Status(step,db.progress,self.evidence).done then steps[#steps+1] = step end
    end
    return steps
end

function Module:UpdateMarkers(openMap)
    local provider, db = ns.GuideWaypoints, settings()
    if not provider then self.mapMessage = "Guide map support is unavailable."; return false end
    local steps = remainingSteps(self)
    local ids = {db.markers}
    for _, step in ipairs(steps) do ids[#ids+1] = step.id end
    local signature = table.concat(ids, ":")
    if not openMap and signature == self.markerSignature then return true end
    local ok, message = provider.Show(steps, {mode=db.markers,openMap=openMap==true,
        focusStepID=self.index and self.route[self.index].id})
    self.markerSignature = signature
    self.mapMessage = ns.Text(message, ok and "" or "No guide location is available for this action.")
    if self.mapStatus then self.mapStatus:SetText(self.mapMessage) end
    return ok
end

function Module:Select(index, openMap)
    if ns.IsCombat() then ns.Notify("Change the guide step after combat."); return false end
    if not self.route[index] then return false end
    local db = settings()
    db.selected, db.follow = self.route[index].id, false
    self.markerSignature = nil
    self:Refresh()
    if openMap then self:UpdateMarkers(true); self:Reflow() end
    return true
end

function Module:Mark(skip)
    if ns.IsCombat() then ns.Notify("Change guide progress after combat."); return false end
    local step = self.index and self.route[self.index]
    if not step then return false end
    local db = settings()
    local ok
    if skip then ok=Model.Skip(db.progress,step.id) else ok=Model.SetManual(db.progress,step.id,true) end
    if not ok then return false end
    db.follow = true
    self.markerSignature = nil
    self:Refresh()
    return true
end

function Module:Create()
    self.rows = {}
    self.progressLabel = UI.Text(self.body,"",0,0,11,320,{0.75,0.75,0.75})
    self.heading = UI.Text(self.body,"",0,22,13,320,UI.accent)
    self.instruction = UI.Text(self.body,"",0,45,12,320)
    UI.Tooltip(self.instruction,function()
        local step=self.index and self.route and self.route[self.index]
        return step and (step.note or Model.Status(step,settings().progress,self.evidence).text)
    end)
    self.stateLabel = UI.Text(self.body,"",0,90,10,320,{0.75,0.75,0.75})
    self.controls = {}
    local function action(text, callback)
        local button = UI.TrackerAction(self.body,text,0,0,58,22,callback)
        self.controls[#self.controls+1] = button
        return button
    end
    self.back = action("Back",function() if self.index then self:Select(math.max(1,self.index-1),false) end end)
    self.done = action("Done",function() self:Mark(false) end)
    self.skip = action("Skip",function() self:Mark(true) end)
    self.undo = action("Undo",function()
        if ns.IsCombat() then return end
        local db = settings()
        local ok, id = Model.Undo(db.progress)
        if ok then db.selected,db.follow=id,false; self.markerSignature=nil; self:Refresh() end
    end)
    self.resume = action("Resume",function()
        if ns.IsCombat() then return end
        local db = settings()
        local index = Model.Current(self.route,db.progress,self.evidence)
        if index then db.selected=self.route[index].id end
        db.follow=true; self.markerSignature=nil; self:Refresh()
    end)
    UI.Tooltip(self.done,"Mark this action done after performing it. This does not accept, complete or turn in a game quest.")
    UI.Tooltip(self.skip,"Skip this checklist action. Skipping does not complete the underlying game quest. Undo restores the last manual change.")
    UI.Tooltip(self.back,"Review the previous action without changing game or checklist progress.")
    UI.Tooltip(self.resume,"Return to the earliest unfinished checklist action and resume following readable quest progress.")
    self.map = UI.TrackerAction(self.body,"Map",0,0,52,22,function()
        if ns.IsCombat() then return end
        if settings().markers == "hide" then
            settings().markers="current";self.markerSignature=nil;self:Refresh()
        end
        self:UpdateMarkers(true); self:Reflow()
    end)
    self.modeButtons = {}
    for _, mode in ipairs({"current","route","hide"}) do
        local value = mode
        self.modeButtons[mode] = UI.TrackerAction(self.body,mode,0,0,68,22,function()
            if ns.IsCombat() then return end
            settings().markers=value; self.markerSignature=nil; self:Refresh()
            if value~="hide" then self:UpdateMarkers(true); self:Reflow() end
        end)
    end
    UI.Tooltip(self.modeButtons.current,"Guide markers for the displayed action. Quest pickup and turn-in locations come from the installed database; supplied route coordinates remain guide points.")
    UI.Tooltip(self.modeButtons.route,"Numbered markers for mapped remaining guide actions, up to 24. This is a checklist route, not a computed walking path. Your personal waypoint is unchanged.")
    UI.Tooltip(self.modeButtons.hide,"Remove this guide's own map and minimap markers. Questie icons are controlled separately.")
    self.mapStatus = UI.Text(self.body,"",0,0,10,320,{0.75,0.75,0.75})
    self.stepsToggle = UI.TrackerAction(self.body,"All steps",0,0,180,22,function()
        settings().expanded=not settings().expanded; self:Refresh()
    end)
    self.scroll,self.content=UI.ScrollArea(self.body,220,0)
    UI.Tooltip(self.progressLabel,function()
        return ns.GuideData.deathknell.provenance .. "\n" .. ns.GuideData.deathknell.verification
            .. "\n" .. (self.progress and (self.progress.automatic .. " automatic, " .. self.progress.manual .. " manually done, " .. self.progress.skipped .. " skipped.") or "")
    end)
    self.body:HookScript("OnSizeChanged",function() self:Reflow() end)
    self.frame:HookScript("OnHide",function()
        self.markerSignature=nil
        if ns.GuideWaypoints then ns.GuideWaypoints.Clear() end
    end)
end

function Module:Reflow()
    if self.reflowing or not self.heading then return end
    self.reflowing=true
    local width=math.max(250,self.body:GetWidth())
    local y=0
    local function label(widget, gap)
        widget:SetWidth(width)
        widget:ClearAllPoints(); widget:SetPoint("TOPLEFT",self.body,"TOPLEFT",0,-y)
        y=y+math.max(12,ns.Number(widget:GetStringHeight(),12))+(gap or 5)
    end
    label(self.progressLabel,7); label(self.heading,6); label(self.instruction,6); label(self.stateLabel,5)
    local buttonWidth=(width-16)/5
    for i,button in ipairs(self.controls) do
        button:ClearAllPoints();button:SetPoint("TOPLEFT",self.body,"TOPLEFT",(i-1)*(buttonWidth+4),-y)
        button:SetWidth(buttonWidth);button.label:SetWidth(buttonWidth-4)
    end
    y=y+26
    local modes={self.map,self.modeButtons.current,self.modeButtons.route,self.modeButtons.hide}
    local modeWidth=(width-12)/4
    for i,button in ipairs(modes) do
        button:ClearAllPoints();button:SetPoint("TOPLEFT",self.body,"TOPLEFT",(i-1)*(modeWidth+4),-y)
        button:SetWidth(modeWidth);button.label:SetWidth(modeWidth-4)
    end
    y=y+25
    label(self.mapStatus,5)
    self.stepsToggle:ClearAllPoints();self.stepsToggle:SetPoint("TOPLEFT",self.body,"TOPLEFT",0,-y)
    y=y+25
    self.scroll:ClearAllPoints();self.scroll:SetPoint("TOPLEFT",self.body,"TOPLEFT",0,-y)
    self.scroll:SetPoint("BOTTOMRIGHT",self.body,"BOTTOMRIGHT",-24,0)
    self.content:SetWidth(math.max(210,width-26))
    local rowY=0
    for _,row in ipairs(self.rows) do
        if row.button:IsShown() then
            row.button:SetWidth(math.max(210,width-30));row.button.label:SetWidth(math.max(200,width-42))
            row.button.label:SetWordWrap(true)
            ns.Call(row.button.label.SetMaxLines,row.button.label,0)
            local height=math.max(26,row.button.label:GetStringHeight()+8)
            row.button:SetHeight(height)
            row.button:ClearAllPoints();row.button:SetPoint("TOPLEFT",self.content,"TOPLEFT",0,-rowY)
            rowY=rowY+height+3
        end
    end
    self.content:SetHeight(math.max(1,rowY))
    self.reflowing=false
end

function Module:Refresh()
    if not self.heading then return end
    local _,classToken=ns.Call(UnitClass,"player")
    self.route=Model.BuildRoute(classToken)
    self.evidence=readEvidence(self.route)
    local db=settings()
    if db.markers~="current" and db.markers~="route" and db.markers~="hide" then db.markers="current" end
    local index=routeIndex(self.route,db.selected) or Model.Current(self.route,db.progress,self.evidence) or #self.route
    if db.follow then
        while index<#self.route and Model.Status(self.route[index],db.progress,self.evidence).done do index=index+1 end
    end
    self.index=index
    local step=self.route[index]
    if not step then return end
    db.selected=step.id
    self.progress=Model.Progress(self.route,db.progress,self.evidence)
    self.progressLabel:SetText(self.progress.done .. "/" .. #self.route .. " checklist actions | Deathknell 1-6")
    self.heading:SetText(string.format("%02d / 15  %s",step.sourceStep,kinds[step.kind] or "Guide action"))
    self.instruction:SetText(step.text)
    local status=Model.Status(step,db.progress,self.evidence)
    self.stateLabel:SetText(status.done and status.text or (status.status=="unknown" and "Progress unavailable. Check the quest, then use Done." or
        (step.manualOnly and "Use Done after this action." or "Follows your quest progress.")))
    local combat=ns.IsCombat()
    self.back:SetEnabled(not combat and index>1)
    self.done:SetEnabled(not combat and not status.done)
    self.skip:SetEnabled(not combat and not status.done)
    self.undo:SetEnabled(not combat and #db.progress.history>0)
    self.resume:SetEnabled(not combat and self.progress.currentIndex~=nil)
    self.map:SetEnabled(not combat)
    for mode,button in pairs(self.modeButtons) do
        button:SetText(mode:sub(1,1):upper()..mode:sub(2))
        button:SetSelected(db.markers==mode);button:SetEnabled(not combat)
    end
    self.stepsToggle:SetText(db.expanded and "Upcoming steps" or "All steps")
    local first,last=db.expanded and 1 or index,db.expanded and #self.route or math.min(#self.route,index+3)
    local used=0
    for routePosition=first,last do
        used=used+1
        local row=self.rows[used]
        if not row then
            row={}
            row.button=UI.TrackerAction(self.content,"",0,0,300,28,function()
                if row.index then self:Select(row.index,true) end
            end)
            UI.Tooltip(row.button,function() return row.tooltip end)
            self.rows[used]=row
        end
        local item=self.route[routePosition]
        local evaluation=Model.Status(item,db.progress,self.evidence)
        local mark=evaluation.status=="skipped" and "[Skip] " or evaluation.done and "[Done] " or ""
        row.index=routePosition
        row.tooltip=item.text .. "\n" .. (item.note or evaluation.text) .. "\nClick to review and map this action."
        row.button:SetText(string.format("%02d  %s%s",item.sourceStep,mark,item.text))
        row.button:SetSelected(routePosition==index);row.button:SetEnabled(not combat);row.button:Show()
    end
    for i=used+1,#self.rows do self.rows[i].button:Hide() end
    self:UpdateMarkers(false)
    self.mapStatus:SetText(self.mapMessage or "")
    self:Reflow()
end

ns.RegisterModule(Module)
ns.RegisterCommand("guide",function() ns.SetPanelVisible("guide",true) end)
for _,event in ipairs({"QUEST_LOG_UPDATE","QUEST_ACCEPTED","QUEST_REMOVED","QUEST_TURNED_IN",
    "QUEST_DATA_LOAD_RESULT","PLAYER_ENTERING_WORLD","ZONE_CHANGED_NEW_AREA","PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED"}) do
    ns.On(event,function() Module.markerSignature=nil;ns.Refresh("guide") end)
end
