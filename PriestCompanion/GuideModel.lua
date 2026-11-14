local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Guide = Model
local HISTORY_LIMIT = 100

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function validID(value)
    return ns.Readable(value) and type(value) == "string" and #value > 0
        and #value <= 80 and value:match("^[%w_-]+$") ~= nil
end

local function validQuestID(value)
    local number = ns.Number(value)
    return number and number > 0 and number == math.floor(number) and number or nil
end

local function result(done, automatic, status, text)
    return {done=done,automatic=automatic,status=status,text=text}
end

function Model.BuildRoute(classToken)
    local data = ns.GuideData and ns.GuideData.deathknell
    if not readableTable(data) or not readableTable(data.steps) then return {} end
    local token = ns.Text(classToken, ""):upper()
    local scroll = data.classScrolls[token]
    local route = {}
    for _, template in ipairs(data.steps) do
        local step = ns.Copy(template)
        if step.classQuest then
            if readableTable(scroll) and validQuestID(scroll.id) then
                step.id = step.id .. "-" .. scroll.id
                step.questIDs = {scroll.id}
                step.text = step.text:gsub("{scroll}", scroll.name):gsub("{trainer}", scroll.trainer)
                step.note = "Class-specific starter quest: " .. scroll.name .. "."
            else
                step.id = step.id .. "-manual"
                step.kind, step.manualOnly = "reminder", true
                step.questIDs = nil
                step.text = template.kind == "accept" and "Ask your class trainer about the starter quest offered to your character."
                    or "Read and turn in the starter quest actually offered to your class."
                step.note = "This draft has verified scroll substitutions for Priest and Warlock. Other classes use this manual reminder."
            end
        end
        route[#route + 1] = step
    end
    return route
end

local function flag(evidence, key, id)
    if not readableTable(evidence) or not readableTable(evidence[key]) then return nil end
    local value = evidence[key][id]
    if ns.Readable(value) and type(value) == "boolean" then return value end
    return nil
end

function Model.Evaluate(step, evidence)
    if not readableTable(step) then return result(false,false,"unknown","Step is unavailable.") end
    if step.manualOnly == true or (step.kind ~= "accept" and step.kind ~= "objective" and step.kind ~= "turnin") then
        return result(false,false,"manual","Mark Done after performing this step.")
    end
    if not readableTable(step.questIDs) or #step.questIDs == 0 then
        return result(false,false,"unknown","Quest identity is unavailable.")
    end
    local knownPending, unknown, completedCount = false, false, 0
    for _, rawID in ipairs(step.questIDs) do
        local id = validQuestID(rawID)
        if not id then return result(false,false,"unknown","Quest identity is unavailable.") end
        local turnedIn = flag(evidence,"completed",id)
        local done, pending = turnedIn == true, false
        if step.kind == "turnin" then
            pending = turnedIn == false
        elseif not done then
            local live = flag(evidence,step.kind == "accept" and "inLog" or "ready",id)
            done = live == true
            -- Historical completion can establish a past step even if it is no
            -- longer in the log. A missing historical read is not false.
            pending = live == false and turnedIn == false
        end
        if done then completedCount = completedCount + 1
        elseif pending then knownPending = true
        else unknown = true end
    end
    if completedCount == #step.questIDs then
        return result(true,true,"complete",step.kind == "turnin" and "Turn-in confirmed by the character's quest history."
            or step.kind == "accept" and "Quest acceptance or prior completion confirmed."
            or "Quest objectives are ready, or the quest was already turned in.")
    end
    if knownPending then
        return result(false,false,"pending",completedCount > 0 and (completedCount .. "/" .. #step.questIDs .. " quest tasks complete.")
            or (step.kind == "turnin" and "Turn in the quest; ready to turn in is not turned in." or "Quest task still pending."))
    end
    return result(false,false,"unknown",unknown and "Quest progress is unavailable; use Done only after checking the step."
        or "Quest progress is unavailable.")
end

local function ensureState(state)
    if not readableTable(state) then return false end
    if state.manual == nil then state.manual = {} end
    if state.history == nil then state.history = {} end
    return readableTable(state.manual) and readableTable(state.history)
end

function Model.Status(step, state, evidence)
    if readableTable(step) and validID(step.id) and readableTable(state) and readableTable(state.manual) then
        local mark = state.manual[step.id]
        if ns.Readable(mark) then
            if mark == "done" then return result(true,false,"done","Marked done by you.") end
            if mark == "skipped" then return result(true,false,"skipped","Skipped by you; this does not complete a game quest.") end
        end
    end
    return Model.Evaluate(step,evidence)
end

local function writeMark(state, stepID, mark)
    if not validID(stepID) or not ensureState(state) then return false end
    local previous = state.manual[stepID]
    if not ns.Readable(previous) then return false end
    if previous ~= "done" and previous ~= "skipped" then previous = nil end
    if previous == mark then return true end
    state.history[#state.history+1] = {id=stepID, previous=previous}
    if #state.history > HISTORY_LIMIT then table.remove(state.history,1) end
    state.manual[stepID] = mark
    return true
end

function Model.SetManual(state, stepID, done)
    if not ns.Readable(done) or type(done) ~= "boolean" then return false end
    return writeMark(state,stepID,done and "done" or nil)
end

function Model.Skip(state, stepID)
    return writeMark(state,stepID,"skipped")
end

function Model.Undo(state)
    if not ensureState(state) then return false end
    local entry = state.history[#state.history]
    if not readableTable(entry) or not validID(entry.id) then return false end
    local previous = entry.previous
    if not ns.Readable(previous) or (previous ~= nil and previous ~= "done" and previous ~= "skipped") then return false end
    table.remove(state.history)
    state.manual[entry.id] = previous
    return true, entry.id
end

function Model.Current(route, state, evidence)
    if not readableTable(route) then return nil end
    for index, step in ipairs(route) do
        local status = Model.Status(step,state,evidence)
        if not status.done then return index,step,status end
    end
    return nil
end

function Model.Progress(route, state, evidence)
    local counts = {total=0,done=0,skipped=0,automatic=0,manual=0,pending=0}
    if not readableTable(route) then return counts end
    for index, step in ipairs(route) do
        local status = Model.Status(step,state,evidence)
        counts.total = counts.total + 1
        if status.done then
            counts.done = counts.done + 1
            if status.status == "skipped" then counts.skipped = counts.skipped + 1
            elseif status.automatic then counts.automatic = counts.automatic + 1
            else counts.manual = counts.manual + 1 end
        else
            counts.pending = counts.pending + 1
            if not counts.currentIndex then counts.currentIndex = index end
        end
    end
    return counts
end
