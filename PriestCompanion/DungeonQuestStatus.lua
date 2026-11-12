local addonName, ns = ...
local Model = {}
ns.Models.DungeonQuests = Model

local function readableTable(value)
    return ns.Readable(value) and type(value) == "table"
end

local function positiveID(value)
    local number = ns.Number(value)
    if number and number > 0 and number == math.floor(number) then return number end
end
Model.PositiveID = positiveID

local function boolean(value)
    if ns.Readable(value) and type(value) == "boolean" then return value end
end

local function call(api, name, ...)
    if not readableTable(api) or not ns.Readable(api[name]) then return nil end
    return ns.Call(api[name], ...)
end

-- Transient character-only progress. A ready-to-turn-in quest is still In Log.
function Model.Snapshot(api, faction, level)
    local snapshot = { faction = ns.Text(faction), level = ns.Number(level), cache = {} }
    function snapshot.read(id)
        id = positiveID(id)
        if not id then return {} end
        if snapshot.cache[id] then return snapshot.cache[id] end
        local rawTitle = call(api, "GetTitleForQuestID", id)
        local title = ""
        if ns.Readable(rawTitle) and type(rawTitle) == "string" then
            title = ns.CleanText(rawTitle, 180):match("^%s*(.-)%s*$")
        end
        local state = {
            inLog = boolean(call(api, "IsOnQuest", id)),
            completed = boolean(call(api, "IsQuestFlaggedCompleted", id)),
            title = title ~= "" and title or nil,
        }
        -- A positive index proves presence; nil/zero cannot prove absence
        -- when IsOnQuest is unavailable (collapsed/hidden log rows).
        if state.inLog == nil then
            local index = positiveID(call(api, "GetLogIndexForQuestID", id))
            if index then state.inLog = true end
        end
        if state.inLog == true then state.ready = boolean(call(api, "IsComplete", id)) end
        snapshot.cache[id] = state
        return state
    end
    return snapshot
end

function Model.Progress(state)
    if state.inLog == true then return "In Log" end
    if state.completed == true then return "Completed" end
    -- False also occurs for invalid IDs. Require a resolved client title,
    -- without interpreting a title as proof of availability or membership.
    if state.inLog == false and state.completed == false and state.title then return "Missing" end
    return "Unknown"
end

local function completionEvidence(state)
    if state.completed == true then return true end
    if state.completed == false and (state.title or state.inLog == true) then return false end
end

-- Three-valued logic for explicitly reviewed prerequisite groups.
-- No recursive chain walk: unresolved IDs stay unknown; cycles cannot recurse.
local function groupState(ids, mode, read)
    if not readableTable(ids) then return nil end
    local unknown, failed, passed = false, false, false
    for index = 1, 65 do
        local id = ids[index]
        if not ns.Readable(id) then return nil end
        if id == nil then
            if mode == "all" then
                if failed then return false end
                if unknown then return nil end
                return true
            end
            if passed then return true end
            if unknown then return nil end
            return false
        end
        if index == 65 then return nil end
        id = positiveID(id)
        local value
        if id then value = completionEvidence(read(id)) end
        if value == true then passed = true
        elseif value == false then failed = true
        else unknown = true end
    end
end

function Model.Eligibility(quest, snapshot)
    local blocked, unknown = {}, {}
    local faction = quest.faction
    if faction ~= "Both" then
        if faction ~= "Alliance" and faction ~= "Horde" then
            unknown[#unknown + 1] = "Faction requirement unknown"
        elseif snapshot.faction ~= "Alliance" and snapshot.faction ~= "Horde" then
            unknown[#unknown + 1] = "Player faction unavailable"
        elseif faction ~= snapshot.faction then blocked[#blocked + 1] = faction .. " only" end
    end
    local minimum = positiveID(quest.minLevel)
    if not minimum or not snapshot.level or snapshot.level <= 0 then
        unknown[#unknown + 1] = "Level requirement/player level unknown"
    elseif snapshot.level < minimum then blocked[#blocked + 1] = "Requires level " .. minimum end
    local prerequisites = quest.prerequisites
    if not readableTable(prerequisites) or prerequisites.complete ~= true then
        unknown[#unknown + 1] = "Prerequisite rules unverified"
    end
    if readableTable(prerequisites) then
        if prerequisites.all == nil and prerequisites.any == nil then
            unknown[#unknown + 1] = "Prerequisite groups unspecified"
        end
        for _, mode in ipairs({"all", "any"}) do
            local ids = prerequisites[mode]
            if ids ~= nil then
                local state = groupState(ids, mode, snapshot.read)
                if state == false then
                    blocked[#blocked + 1] = mode == "all" and "Required prior quest not completed"
                        or "No alternative prerequisite completed"
                elseif state == nil then unknown[#unknown + 1] = "Prerequisite progress unavailable" end
            end
        end
    end
    if quest.requirementsComplete ~= true then unknown[#unknown + 1] = "Other requirements unverified" end
    if #blocked > 0 then return "Blocked (catalog)", table.concat(blocked, "; ") end
    if #unknown > 0 then return "Unknown", table.concat(unknown, "; ") end
    return "Meets catalog rules", "Pickup offer still needs confirmation in game"
end

function Model.Evaluate(quest, snapshot)
    local id = positiveID(quest.id)
    local state = snapshot.read(id)
    local eligibility, reason = Model.Eligibility(quest, snapshot)
    local notes = {}
    for _, prior in ipairs(quest.reportedPrior or {}) do
        local previous = snapshot.read(prior)
        local progress = previous.completed == true and "completed"
            or (previous.inLog == true and "in log; not turned in")
            or (completionEvidence(previous) == false and "not completed" or "unknown")
        notes[#notes + 1] = "#" .. prior .. " " .. progress
    end
    return {
        id = id, title = state.title or ns.CleanText(quest.title, 180),
        clientTitle = state.title ~= nil, status = Model.Progress(state),
        ready = state.ready == true, eligibility = eligibility, reason = reason,
        prior = #notes > 0 and ("Reported prior quests: " .. table.concat(notes, ", ")
            .. ". Relationship unverified.") or nil,
        giver = quest.giver, pickup = quest.pickup,
    }
end

function Model.Build(dungeon, snapshot)
    local result = { rows = {}, counts = { Missing = 0, ["In Log"] = 0, Completed = 0, Unknown = 0 } }
    for _, quest in ipairs(dungeon.quests) do
        local row = Model.Evaluate(quest, snapshot)
        result.rows[#result.rows + 1] = row
        result.counts[row.status] = result.counts[row.status] + 1
    end
    result.coverage = "Partial catalog; other quests may exist. No all-ready verdict."
    if #result.rows == 0 then result.coverage = "No catalog records; coverage unknown. This does not mean no quests." end
    return result
end

function Model.Find(catalog, key)
    for index, dungeon in ipairs(catalog.dungeons) do
        if dungeon.key == key then return dungeon, index end
    end
end

function Model.QueryIDs(dungeon)
    local ids, seen = {}, {}
    local function add(id)
        id = positiveID(id)
        if id and not seen[id] and #ids < 64 then
            ids[#ids + 1], seen[id] = id, true
        end
    end
    for _, quest in ipairs(dungeon.quests) do
        add(quest.id)
        for _, id in ipairs(quest.reportedPrior or {}) do add(id) end
        for _, mode in ipairs({"all", "any"}) do
            for _, id in ipairs(quest.prerequisites and quest.prerequisites[mode] or {}) do add(id) end
        end
    end
    return ids
end
