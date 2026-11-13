local root=assert(TEST_ROOT,"TEST_ROOT is required")
local Mock=assert(loadfile(root.."/tests/wow_mock.lua"))()
local ns={}
local count=0
local T={}
function T.ok(value,message)
    count=count+1
    if not value then error("Assertion failed: "..(message or "expected truthy"),2) end
end
function T.eq(actual,expected,message)
    count=count+1
    if actual~=expected then
        error("Assertion failed: "..(message or "values differ").."; expected "..tostring(expected)..", got "..tostring(actual),2)
    end
end
function T.near(actual,expected,message)
    count=count+1
    if math.abs(actual-expected)>0.00001 then error(message or "values not close",2) end
end
local manifest=assert(io.open(root.."/PriestCompanion/PriestCompanion.toc"))
for line in manifest:lines() do
    if line:match("%.lua$") then
        local file=line:gsub("\\","/")
        assert(loadfile(root.."/PriestCompanion/"..file))("PriestCompanion",ns)
    end
end
manifest:close()

Mock.Fire("ADDON_LOADED","PriestCompanion")
Mock.Fire("PLAYER_LOGIN")
for key,err in pairs(ns.errors) do error("Module initialization "..key..": "..err) end
T.ok(ns.ready,"addon initializes in bounded mock")
T.eq(ns.db.layout,"Leveling","default layout")
T.eq(ns.db.locked,true,"default layout locked")
for _,id in ipairs({"priest","quests","preparation","references","goals","kills","appearance","settings"}) do
    local alternate=id=="preparation" and "prep" or (id=="references" and "keys" or id)
    T.ok(ns.modules[id] or ns.modules[alternate],"requested module present: "..id)
end

for _,file in ipairs({"goals_cases.lua","quest_kill_cases.lua","gameplay_cases.lua","appearance_cases.lua"}) do
    local cases=assert(loadfile(root.."/tests/"..file))()
    cases(T,ns,Mock)
    print("PASS: "..file)
end

-- Movement survives a save/load cycle at non-unit scale.
local frame=ns.frames.priest
local settings=ns.PanelSettings("priest")
settings.scale=1.25
ns.ApplyPanel("priest")
frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",127,-63)
frame:SetSize(360,340)
ns.SavePlacement("priest")
T.near(settings.x,127,"scaled x anchor round-trip")
T.near(settings.y,-63,"scaled y anchor round-trip")
ns.ApplyPanel("priest")
ns.SavePlacement("priest")
T.near(settings.x,127,"reapplication preserves x")
T.eq(settings.width,360,"width persisted")
T.eq(settings.height,340,"height persisted")

ns.ApplyLayout("Healing")
T.eq(ns.db.layout,"Healing","switch to healing")
ns.PanelSettings("priest").x=-45
ns.PanelSettings("priest").y=82
ns.ApplyPanel("priest")
ns.ApplyLayout("Leveling")
T.near(ns.PanelSettings("priest").x,127,"separate layout position retained")
T.near(ns.PanelSettings("priest").y,-63,"separate layout y retained")

Mock.combat=true
T.eq(ns.ApplyLayout("Healing"),false,"combat layout deferred")
T.eq(ns.db.layout,"Leveling","combat does not change active layout")
T.eq(ns.SetLocked(false),false,"combat unlock blocked")
T.eq(ns.On("NOT_A_REAL_EVENT",function() end),false,"invalid event is rejected")
Mock.combat=false
Mock.Fire("PLAYER_REGEN_ENABLED")
T.eq(ns.db.layout,"Healing","queued layout applied after combat")

local preserved=ns.Copy(ns.db.modules)
ns.ResetLayout()
T.ok(ns.db.previousLayout,"reset retains recoverable layout")
T.ok(ns.RestoreLayout(),"reset can be undone")
T.eq(ns.db.previousLayout,nil,"undo consumed")
T.eq(#ns.db.modules.goals.goals,#preserved.goals.goals,"layout reset retains content")

local secret=Mock.Secret()
T.eq(ns.Readable(secret),false,"secret rejected before indexing")
T.eq(ns.Text(secret,"unavailable"),"unavailable","secret not formatted")
T.eq(ns.Number(secret,0),0,"secret not used in arithmetic")
T.eq(ns.CleanText("|cffffffffHello|r |Hitem:1|h[Item]|h"),"Hello [Item]","markup sanitized")
T.eq(ns.CleanText(ns.CleanText("A|B")),ns.CleanText("A|B"),"sanitization idempotent")
T.eq(ns.Clamp(0/0,0,10,4),4,"NaN settings use fallback")
T.eq(ns.Clamp(math.huge,0,10,4),4,"infinite settings use fallback")

-- Regression: deleting every checklist item must not resurrect default items.
local checklist=ns.db.modules.prep.checklist
ns.db.modules.prep.checklist={}
ns.ModuleDB("prep",{checklist={{text="default",checked=false}}})
T.eq(#ns.db.modules.prep.checklist,0,"empty saved checklist stays empty")
ns.db.modules.prep.checklist=checklist

-- Regression: locking mid-drag saves the final position before stopping.
frame:ClearAllPoints();frame:SetPoint("CENTER",UIParent,"CENTER",71,29)
ns.SetLocked(true)
T.near(ns.PanelSettings("priest").x,71,"locking records drag position")
T.near(ns.PanelSettings("priest").y,29,"locking records drag height")

-- Actual event handler integration: complete provenance remains separate.
local stats=ns.db.modules.kills.lifetime
local beforeAutomatic,beforeManual=stats.automatic,stats.manual
Mock.Fire("CHAT_MSG_COMBAT_XP_GAIN","Test Boar dies, you gain 42 experience.")
T.eq(stats.automatic,beforeAutomatic+1,"readable named XP event increments automatic count")
Mock.Fire("CHAT_MSG_COMBAT_XP_GAIN",Mock.Secret())
T.eq(stats.automatic,beforeAutomatic+1,"restricted message not counted")
T.ok(stats.restricted>0,"restricted coverage recorded")
ns.RunCommand("kill Practice target")
T.eq(stats.manual,beforeManual+1,"manual command increments manual count")
T.eq(stats.automatic,beforeAutomatic+1,"manual command never increments automatic count")

-- Regression: copy dialog cannot focus an invisible queued frame.
ns.SetPanelVisible("copy",false)
ns.modules.copy.box:ClearFocus()
Mock.combat=true
ns.UI.MakeCopyBox("Test text",string.rep("A long readable line with wrapping.\n",60))
T.eq(ns.modules.copy.box:HasFocus(),false,"queued copy dialog does not steal focus")
T.ok(ns.modules.copy.box:GetHeight()>300,"copy text receives scrollable height")
Mock.combat=false
Mock.Fire("PLAYER_REGEN_ENABLED")
T.eq(ns.modules.copy.box:HasFocus(),true,"copy dialog focuses after shown")
ns.modules.copy.box:ClearFocus()

local secretTable={}
Mock.secretTables={[secretTable]=true}
T.eq(ns.Readable(secretTable),false,"secret table rejected before field access")
Mock.secretTables=nil

-- Secret player resources may go to display setters but never into saved data.
Mock.health=Mock.Secret()
ns.SetPanelVisible("priest",true)
Mock.Fire("UNIT_HEALTH","player")
T.eq(ns.modules.priest.health:GetValue(),Mock.health,"secret resource passed only to display")
local function containsSecret(value,seen)
    if not ns.Readable(value) then return true end
    if type(value)~="table" then return false end
    seen=seen or {};if seen[value] then return false end;seen[value]=true
    for key,item in pairs(value) do
        if containsSecret(key,seen) or containsSecret(item,seen) then return true end
    end
    return false
end
T.eq(containsSecret(ns.db),false,"saved settings contain no secret values")
Mock.health=nil

-- Repeated layout and visibility changes must settle and keep one frame per module.
local existingFrames={}
for id,widget in pairs(ns.frames) do existingFrames[id]=widget end
for _=1,4 do
    ns.ApplyLayout("Leveling");ns.ApplyLayout("Healing")
    ns.RunCommand("show all");Mock.Flush()
    ns.RunCommand("lock");ns.RunCommand("unlock")
end
for id,widget in pairs(existingFrames) do T.eq(ns.frames[id],widget,"frame reused: "..id) end
Mock.Fire("PLAYER_LOGOUT")
Mock.Flush()
for key,err in pairs(ns.errors) do error("Runtime mock error "..key..": "..err) end

-- Diagnostics intentionally excludes private player content.
local report=ns.Diagnostics()
T.ok(not report:find("Test Priest",1,true),"diagnostics omit character identity")
T.ok(report:find("16001",1,true),"diagnostics contain interface")
print("PASS: integration, layouts, combat queue, secret guards and diagnostics")
print("PASS: "..count.." assertions in offline Lua 5.4 + bounded WoW UI/API mocks")
print("NOT TESTED: actual WoW client, secure execution, rendering, combat restrictions, locale behavior or live saved-file loading")
