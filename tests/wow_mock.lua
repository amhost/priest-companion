-- A deliberately bounded test double. It is NOT a WoW client emulator.
-- It models ordinary frames, events, settings and readable/restricted values.
unpack = table.unpack
local Mock = { objects={}, timers={}, messages={}, combat=false, secrets={} }
local Methods = {}
local Meta = {__index=Methods}

local function trigger(object, event, ...)
    if object.scripts and object.scripts[event] then object.scripts[event](object, ...) end
    if object.hooks and object.hooks[event] then
        for _, fn in ipairs(object.hooks[event]) do fn(object, ...) end
    end
end

local function object(kind, name, parent)
    local result = setmetatable({kind=kind,name=name,parent=parent,scripts={},hooks={},points={},shown=true,
        scale=1,text="",alpha=1,enabled=true,children={}},Meta)
    Mock.objects[#Mock.objects+1]=result
    if parent then parent.children[#parent.children+1]=result end
    if name then _G[name]=result end
    return result
end

function CreateFrame(kind,name,parent,template)
    local result=object(kind,name,parent)
    result.template=template
    if template=="UICheckButtonTemplate" then result.Text=object("FontString",nil,result) end
    if template=="UIPanelScrollFrameTemplate" then result.ScrollBar=object("Slider",nil,result) end
    return result
end
function Methods:CreateFontString(name) return object("FontString",name,self) end
function Methods:CreateTexture(name) return object("Texture",name,self) end
function Methods:SetScript(event,fn) self.scripts[event]=fn end
function Methods:GetScript(event) return self.scripts[event] end
function Methods:HookScript(event,fn)
    self.hooks[event]=self.hooks[event] or {};table.insert(self.hooks[event],fn)
end
function Methods:RegisterEvent(event)
    if event=="NOT_A_REAL_EVENT" or event=="COMBAT_LOG_EVENT_UNFILTERED" then error("Unavailable event") end
    self.events=self.events or {};self.events[event]=true
end
function Methods:UnregisterEvent(event) if self.events then self.events[event]=nil end end
function Methods:RegisterUnitEvent(event) self:RegisterEvent(event) end
function Methods:SetPoint(point,a,b,c,d)
    local parent,relativePoint,x,y
    if type(a)=="table" then parent=a;relativePoint=b or point;x=c or 0;y=d or 0
    elseif type(a)=="number" then parent=self.parent;relativePoint=point;x=a;y=b or 0
    elseif type(a)=="string" then parent=self.parent;relativePoint=a;x=b or 0;y=c or 0
    else parent=self.parent;relativePoint=point;x=0;y=0 end
    self.points[#self.points+1]={point,parent,relativePoint,x,y}
end
function Methods:ClearAllPoints() self.points={} end
function Methods:GetPoint(index) return unpack(self.points[index or 1] or {}) end
function Methods:GetNumPoints() return #self.points end
function Methods:SetAllPoints(parent)
    self.allPoints=parent or self.parent
end
function Methods:GetParent() return self.parent end
function Methods:SetParent(parent) self.parent=parent end
function Methods:GetName() return self.name end
local function anchoredDimension(self,axis)
    if self.allPoints then return axis==1 and self.allPoints:GetWidth() or self.allPoints:GetHeight() end
    local low,high
    for _,p in ipairs(self.points) do
        local point=p[1]
        if axis==1 then
            if point:find("LEFT") then low=p end
            if point:find("RIGHT") then high=p end
        else
            if point:find("BOTTOM") then low=p end
            if point:find("TOP") then high=p end
        end
    end
    if low and high and low[2] and low[2]==high[2] then
        local size=axis==1 and low[2]:GetWidth() or low[2]:GetHeight()
        return math.max(1,size+(high[axis+3] or 0)-(low[axis+3] or 0))
    end
    return nil
end
function Methods:GetWidth() return anchoredDimension(self,1) or self.width or 300 end
function Methods:GetHeight() return anchoredDimension(self,2) or self.height or (self.kind=="FontString" and self:GetStringHeight()) or 100 end
function Methods:GetSize() return self:GetWidth(),self:GetHeight() end
function Methods:SetSize(w,h)
    local oldW,oldH=self:GetWidth(),self:GetHeight()
    self.width,self.height=w,h
    if oldW~=w or oldH~=h then trigger(self,"OnSizeChanged",w,h) end
end
function Methods:SetWidth(w) local old=self:GetWidth();self.width=w;if old~=w then trigger(self,"OnSizeChanged",w,self:GetHeight()) end end
function Methods:SetHeight(h) local old=self:GetHeight();self.height=h;if old~=h then trigger(self,"OnSizeChanged",self:GetWidth(),h) end end
local offsets={CENTER={0,0},TOPLEFT={-0.5,0.5},TOP={0,0.5},TOPRIGHT={0.5,0.5},
    LEFT={-0.5,0},RIGHT={0.5,0},BOTTOMLEFT={-0.5,-0.5},BOTTOM={0,-0.5},BOTTOMRIGHT={0.5,-0.5}}
function Methods:GetCenter()
    if self==UIParent then return self.width/2,self.height/2 end
    local p=self.points[1]
    if not p then return 300,200 end
    local target=p[2] or self.parent or UIParent
    local tx,ty=target:GetCenter()
    local factor=target:GetEffectiveScale()/self:GetEffectiveScale()
    local off=offsets[p[3]] or offsets.CENTER
    local own=offsets[p[1]] or offsets.CENTER
    return (tx+target:GetWidth()*off[1])*factor+p[4]-self:GetWidth()*own[1],
        (ty+target:GetHeight()*off[2])*factor+p[5]-self:GetHeight()*own[2]
end
function Methods:SetScale(value) self.scale=value end
function Methods:GetScale() return self.scale end
function Methods:GetEffectiveScale() return self.scale*(self.parent and self.parent:GetEffectiveScale() or 1) end
function Methods:SetShown(value) if value then self:Show() else self:Hide() end end
function Methods:Show() local was=self.shown;self.shown=true;if not was then trigger(self,"OnShow") end end
function Methods:Hide() local was=self.shown;self.shown=false;if was then trigger(self,"OnHide") end end
function Methods:IsShown() return self.shown end
function Methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function Methods:SetText(text)
    self.text=text or ""
    trigger(self,"OnTextChanged",false)
end
function Methods:GetText() return self.text end
function Methods:SetFormattedText(fmt,...) self:SetText(string.format(fmt,...)) end
function Methods:SetFont(path,size,flags) self.font={path,size,flags};return true end
function Methods:GetFont() return unpack(self.font or {"font",12,""}) end
function Methods:SetFontObject(value) self.fontObject=value end
function Methods:GetFontString() return self.label or self.Text end
function Methods:GetStringHeight()
    local text=type(self.text)=="string" and self.text or ""
    local _,lines=text:gsub("\n","")
    local size=self.font and self.font[2] or 12
    return math.max(1,lines+1,math.ceil(#text*size*0.5/math.max(1,self.width or 300)))*(size+3)
end
function Methods:GetStringWidth() return #(type(self.text)=="string" and self.text or "")*6 end
function Methods:SetChecked(v) self.checked=v==true end
function Methods:GetChecked() return self.checked end
function Methods:SetEnabled(v) self.enabled=not not v end
function Methods:IsEnabled() return self.enabled end
function Methods:Enable() self.enabled=true end
function Methods:Disable() self.enabled=false end
function Methods:SetFocus() self.focus=true;trigger(self,"OnEditFocusGained") end
function Methods:ClearFocus() self.focus=false;trigger(self,"OnEditFocusLost") end
function Methods:HasFocus() return self.focus end
function Methods:SetMaxLetters(n) self.maxLetters=n end
function Methods:SetAutoFocus(v) self.autoFocus=v end
function Methods:SetMultiLine(v) self.multiline=v end
function Methods:SetNumeric(v) self.numeric=v end
function Methods:GetNumber() return tonumber(self.text) or 0 end
function Methods:SetNumber(v) self:SetText(tostring(v)) end
function Methods:Insert(v) self:SetText(self.text..v) end
function Methods:SetScrollChild(child) self.scrollChild=child end
function Methods:GetScrollChild() return self.scrollChild end
function Methods:SetVerticalScroll(v) self.verticalScroll=v end
function Methods:GetVerticalScroll() return self.verticalScroll or 0 end
function Methods:GetVerticalScrollRange() return math.max(0,(self.scrollChild and self.scrollChild:GetHeight() or 0)-self:GetHeight()) end
function Methods:SetMinMaxValues(low,high) self.minValue,self.maxValue=low,high end
function Methods:GetMinMaxValues() return self.minValue,self.maxValue end
function Methods:SetValue(v) self.value=v end
function Methods:GetValue() return self.value end
function Methods:SetStatusBarTexture(v) self.statusTexture=v end
function Methods:GetStatusBarTexture() self.barTexture=self.barTexture or object("Texture",nil,self);return self.barTexture end
function Methods:SetStatusBarColor(...) self.statusColor={...} end
function Methods:SetBackdropColor(...) self.background={...} end
function Methods:SetBackdropBorderColor(...) self.border={...} end
function Methods:SetAlpha(v) self.alpha=v end
function Methods:GetAlpha() return self.alpha end
function Methods:SetOwner(parent,anchor) self.owner,self.ownerAnchor=parent,anchor end
function Methods:GetOwner() return self.owner end
function Methods:IsForbidden() return false end
function Methods:SetMovable(v) self.movable=v end
function Methods:IsMovable() return self.movable end
function Methods:SetResizable(v) self.resizable=v end
function Methods:StartMoving() self.moving=true end
function Methods:StartSizing() self.sizing=true end
function Methods:StopMovingOrSizing() self.moving=false;self.sizing=false end
function Methods:SetFrameStrata(v) self.strata=v end
function Methods:GetFrameStrata() return self.strata end
function Methods:SetFrameLevel(v) self.level=v end
function Methods:GetFrameLevel() return self.level or 1 end
function Methods:GetChildren() return unpack(self.children) end
function Methods:Click(button)
    if not self.enabled then return end
    if self.kind=="CheckButton" then self.checked=not self.checked end
    trigger(self,"OnClick",button or "LeftButton")
end
for _,name in ipairs({"SetBackdrop","SetToplevel","SetClampedToScreen","SetClipsChildren","EnableMouse",
    "EnableMouseWheel","SetResizeBounds","SetMinResize","SetJustifyH","SetJustifyV","SetWordWrap",
    "SetTextColor","SetTextInsets","SetColorTexture","SetTexture","SetVertexColor","SetTexCoord",
    "RegisterForDrag","RegisterForClicks","Raise","HighlightText","SetCursorPosition","SetNormalTexture",
    "SetPushedTexture","SetHighlightTexture","SetDisabledTexture","LockHighlight","UnlockHighlight",
    "SetHitRectInsets","SetObeyStepOnDrag","SetValueStep","SetOrientation","SetDrawLayer",
    "SetNonSpaceWrap","SetJustifyH","SetIndentedWordWrap","SetAutoFocus","SetAutoFocus",
    "SetFontObject","SetTextInsets","SetHyperlinksEnabled","UpdateScrollChildRect","SetPropagateKeyboardInput"}) do
    if not Methods[name] then Methods[name]=function() end end
end

UIParent=CreateFrame("Frame","UIParent")
UIParent.width,UIParent.height=1920,1080
DEFAULT_CHAT_FRAME={AddMessage=function(_,message) Mock.messages[#Mock.messages+1]=message end}
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
GameFontHighlightSmall={};GameFontNormalSmall={};GameFontHighlight={}
GameTooltip=CreateFrame("GameTooltip","GameTooltip",UIParent)
SlashCmdList={}
C_Timer={After=function(_,fn) Mock.timers[#Mock.timers+1]=fn end}
C_EventUtils={IsEventValid=function(event) return event~="NOT_A_REAL_EVENT" end}
function InCombatLockdown() return Mock.combat end
function GetBuildInfo() return "1.60.1","offline-test","Nov 10 2026",16001 end
function GetLocale() return "enUS" end
function GetTime() return Mock.time or 100 end
function GetServerTime() return 1794300000 end
function UnitName() return "Test Priest" end
function UnitClass() return "Priest","PRIEST",5 end
function UnitLevel() return 18 end
function UnitExists(unit) return unit=="player" or unit=="target" end
function UnitHealth() return Mock.health or 720 end
function UnitHealthMax() return Mock.maxHealth or 1000 end
function UnitPower() return Mock.mana or 350 end
function UnitPowerMax() return Mock.maxMana or 500 end
function UnitPowerType() return 0,"MANA" end
function GetInventoryItemDurability() return 80,100 end
function GetInventoryItemID() return nil end
function GetBindingKey(action) return action=="ACTIONBUTTON1" and "1" or nil end
function GetBindingText(key) return key end
function GetActionInfo(slot) if slot==1 then return "spell",2061,nil end end
function GetActionText() return nil end
function GetNumGroupMembers() return 0 end
function GetNumSubgroupMembers() return 0 end
function IsInGroup() return false end
function IsInRaid() return false end
function IsPlayerSpell() return true end
function IsSpellKnown() return true end
function IsShiftKeyDown() return false end
function GetProfessions() return 1,2 end
function GetProfessionInfo(index) return index==1 and "Tailoring" or "Enchanting",nil,25,75 end
function issecretvalue(value) return Mock.secrets[value]==true end
function issecrettable(value) return Mock.secretTables and Mock.secretTables[value]==true end
function canaccessvalue(value) return not issecretvalue(value) end
function Mock.Secret()
    local value=setmetatable({},{__tostring=function() error("Secret formatted") end,
        __add=function() error("Secret arithmetic") end,__lt=function() error("Secret compared") end,
        __le=function() error("Secret compared") end,__concat=function() error("Secret concatenated") end,
        __index=function() error("Secret indexed") end})
    Mock.secrets[value]=true;return value
end
function hooksecurefunc(name,fn)
    local original=_G[name]
    _G[name]=function(...) local values={original(...)};fn(...);return unpack(values) end
end
function GameTooltip_SetDefaultAnchor(tooltip,parent) tooltip:SetOwner(parent,"ANCHOR_RIGHT") end
function ShowUIPanel(frame) frame:Show() end
EditModeManagerFrame=CreateFrame("Frame","EditModeManagerFrame",UIParent)
function QuestMapFrame_OpenToQuestDetails(id) Mock.detailsID=id end
WorldMapFrame=CreateFrame("Frame","WorldMapFrame",UIParent)
WorldMapFrame.SetMapID=function(_,id) Mock.mapID=id end
C_AddOns={LoadAddOn=function() return true end}
C_Item={GetItemCount=function() return 3 end,GetItemNameByID=function() return "Test item" end,
    GetItemInfo=function() return "Test item" end}
C_Container={GetContainerNumFreeSlots=function() return 4,0 end,GetContainerNumSlots=function() return 16 end}
Enum={PowerType={Mana=0},BagIndex={Backpack=0,ReagentBag=5},SpellBookSpellBank={Player=0},}
NUM_BAG_SLOTS=4
C_Spell={GetSpellName=function(value) return tonumber(value) and "Flash Heal" or value end,
    GetSpellInfo=function(value) return {name=tonumber(value) and "Flash Heal" or value,spellID=tonumber(value) or 2061,iconID=135907} end,
    GetSpellCooldown=function() return {startTime=0,duration=0,isEnabled=true} end,
    GetSpellDescription=function() return "Test spell description" end}
C_SpellBook={IsSpellKnown=function() return true end,IsSpellInSpellBook=function() return true end}
Mock.quests={{isHeader=true,title="Test zone"},{questID=101,title="A test errand",level=18,isHeader=false,isHidden=false}}
C_QuestLog={
    GetNumQuestLogEntries=function() return #Mock.quests,1 end,
    GetInfo=function(index) return Mock.quests[index] end,
    GetQuestObjectives=function() return {{text="Collect supplies: 1/4",numFulfilled=1,numRequired=4,finished=false,type="item"}} end,
    IsComplete=function() return false end,
    GetNextWaypoint=function() return 12,0.4,0.6 end,
    GetQuestsOnMap=function() return {{questID=101,x=0.4,y=0.6}} end,
    GetLogIndexForQuestID=function() return 2 end,
    AddQuestWatch=function() end,
}
C_Map={GetBestMapForUnit=function() return 12 end,SetUserWaypoint=function(point) Mock.waypoint=point end}
C_SuperTrack={SetSuperTrackedUserWaypoint=function(value) Mock.superTracked=value end}
UiMapPoint={CreateFromCoordinates=function(id,x,y) return {uiMapID=id,position={x=x,y=y}} end}
COMBATLOG_XPGAIN_FIRSTPERSON="%s dies, you gain %d experience."
COMBATLOG_XPGAIN_FIRSTPERSON_GROUP="%s dies, you gain %d experience. (+%d group bonus)"
COMBATLOG_XPGAIN_EXHAUSTION1="%s dies, you gain %d experience. (+%d exp Rested bonus)"

function Mock.Flush()
    local loops=0
    while #Mock.timers>0 do
        loops=loops+1;if loops>1000 then error("Refresh did not settle") end
        local timers=Mock.timers;Mock.timers={}
        for _,fn in ipairs(timers) do fn() end
    end
end
function Mock.Fire(event,...)
    for _,frame in ipairs(Mock.objects) do
        if frame.events and frame.events[event] then trigger(frame,"OnEvent",event,...) end
    end
    Mock.Flush()
end
Mock.Trigger=trigger
return Mock
