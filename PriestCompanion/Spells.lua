local addonName, ns = ...

ns.Models = ns.Models or {}
local Model = {}
ns.Models.Spells = Model

function Model.NormalizeSpellInput(value)
    if not ns.Readable(value) or type(value) ~= "string" then
        return nil, "Enter a spell name or spell ID."
    end
    value = value:match("^%s*(.-)%s*$")
    if #value == 0 or #value > 120 or value:find("[%c|/;%[%]]") then
        return nil, "Use a spell name or numeric spell ID only."
    end
    local id = tonumber(value)
    if id then
        if id ~= math.floor(id) or id < 1 or id > 1000000000 then
            return nil, "Spell IDs must be positive whole numbers."
        end
        return id
    end
    return value
end

function Model.IsSpellLearned(id)
    if C_SpellBook and type(C_SpellBook.IsSpellInSpellBook) == "function" and Enum and Enum.SpellBookSpellBank then
        local bank = ns.Number(Enum.SpellBookSpellBank.Player)
        if bank then
            local known = ns.Call(C_SpellBook.IsSpellInSpellBook, id, bank, true)
            if ns.Readable(known) and type(known) == "boolean" then return known end
        end
    end
    local known = ns.Call(IsPlayerSpell, id)
    if ns.Readable(known) and type(known) == "boolean" then return known end
    return nil
end

function Model.ResolveSpell(value)
    local query, problem = Model.NormalizeSpellInput(value)
    if not query then return nil, problem end
    if not C_Spell or type(C_Spell.GetSpellInfo) ~= "function" then
        return nil, "Spell lookup is unavailable in this client."
    end
    local info = ns.Call(C_Spell.GetSpellInfo, query)
    if not ns.Readable(info) or type(info) ~= "table" then
        return nil, "Spell lookup is unavailable or that spell was not found."
    end
    local name = ns.Text(info.name)
    local id = ns.Number(info.spellID)
    if not name or not id or name == "" then
        return nil, "The client did not provide readable spell details."
    end
    local known = Model.IsSpellLearned(id)
    local state = "Learning check unavailable"
    if ns.Readable(known) and type(known) == "boolean" then
        state = known and "Learned" or "Not learned"
    end
    return { id = id, name = name, learning = state }
end
