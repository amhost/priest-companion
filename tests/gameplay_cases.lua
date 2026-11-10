return function(T, ns)
    local priest = ns.Models.Priest
    local prep = ns.Models.Preparation
    local refs = ns.Models.References

    local label, status = priest.ResourceText(40, 100)
    T.eq(label, "40 / 100", "Resource labels show readable values")
    T.eq(status, "readable", "Readable resource status")
    T.eq(priest.ResourceText(0, 0), "Unavailable", "No divide by zero on unavailable resource")
    T.eq(priest.NormalizeSpellInput("  Renew  "), "Renew", "Spell names trim surrounding whitespace")
    T.eq(priest.NormalizeSpellInput("17"), 17, "Numeric spell lookup")
    T.eq(priest.NormalizeSpellInput("0"), nil, "Zero spell ID rejected")
    T.eq(priest.NormalizeSpellInput("12.5"), nil, "Fractional spell ID rejected")
    T.eq(priest.NormalizeSpellInput("Renew\n/cast Evil"), nil, "Multiline command rejected")
    T.eq(priest.NormalizeSpellInput("Renew; Other"), nil, "Macro separator rejected")

    local originalReadable = ns.Readable
    local secret = setmetatable({}, {
        __tostring = function() error("Secret stringify") end,
        __lt = function() error("Secret compare") end,
        __div = function() error("Secret arithmetic") end,
    })
    ns.Readable = function(value) return value ~= secret and originalReadable(value) end
    local secretLabel, secretStatus = priest.ResourceText(secret, 100)
    T.eq(secretLabel, "Protected display", "Secret resources never format as text")
    T.eq(secretStatus, "protected", "Secret resource status")
    T.eq(priest.NormalizeSpellInput(secret), nil, "Secret spell input rejected before string operations")
    local durability = prep.Durability({ { 10, 20 }, { 0, 30 }, { secret, 100 } })
    T.eq(durability.count, 2, "Restricted equipment does not enter durability math")
    T.eq(durability.minimum, 0, "Broken gear minimum")
    T.eq(durability.broken, 1, "Broken equipment count")
    T.ok(durability.restricted, "Partial durability coverage is marked")
    T.eq(refs.BuildMouseover(secret), nil, "Secret macro input rejected")
    T.eq(refs.BindingText(secret, "Q"), "Q", "Secret binding ignored")
    ns.Readable = originalReadable

    durability = prep.Durability({ {}, { 25, 50 }, { 80, 100 } })
    T.eq(durability.minimum, 50, "Minimum equipment percentage is correct")
    T.eq(durability.count, 2, "Empty equipment slots ignored")
    T.eq(prep.Durability({ {}, {} }).minimum, nil, "Empty equipment is not reported healthy")
    local bags = prep.BagSpace({
        { free = 4, total = 16, family = 0 },
        { free = 12, total = 20, family = 32 },
        { free = 3, total = 8, family = 0 },
    })
    T.eq(bags.free, 7, "Only general bag free slots count")
    T.eq(bags.total, 24, "General bag denominator excludes specialty bags")
    T.eq(bags.specialty, 1, "Specialty bags reported separately")
    T.ok(prep.BagSpace({ { free = 30, total = 16, family = 0 } }).restricted, "Impossible bag data is not trusted")
    T.ok(prep.BagSpace({ { free = 3, total = nil, family = 0 } }).restricted, "Missing slot-count read marks partial coverage")
    T.ok(prep.BagSpace({ { free = 0, total = -1, family = 0 } }).restricted, "Negative slot-count read marks partial coverage")
    T.eq(prep.BagSpace({ { free = 0, total = 0, family = 0 } }).restricted, false, "Zero slots is a legitimately absent bag")

    local checks = {}
    T.ok(prep.AddItem(checks, "Water"), "Checklist item added")
    T.eq(checks[1].checked, false, "Checklist starts unchecked")
    T.eq(prep.AddItem(checks, "  "), false, "Blank checklist entry rejected")
    local notes = {}
    T.ok(refs.AddNote(notes, "Shift + Q = emergency heal"), "Reference note saved")
    T.eq(refs.AddNote(notes, ""), false, "Blank reference rejected")
    T.eq(refs.BindingText("SHIFT-Q", "MOUSE4"), "SHIFT-Q / MOUSE4", "Both actual bindings shown")
    T.eq(refs.BindingText("Q", "Q"), "Q", "Duplicate binding text collapsed")
    T.eq(refs.BindingText(nil, nil), "Unbound / unavailable", "No invented default bindings")
    local macro = refs.BuildMouseover("Renew")
    T.eq(macro, "#showtooltip Renew\n/cast [@mouseover,help,nodead] [help,nodead] [@player] Renew", "Mouseover fallback ordering")
    T.eq(refs.BuildMouseover("Renew\n/run print(1)"), nil, "Macro injection blocked")
    T.eq(refs.BuildMouseover("Renew [harm]"), nil, "Custom macro conditions rejected")
    T.eq(refs.BuildMouseover(string.rep("x", 91)), nil, "Macro name length bounded")

    local originalSpellBook, originalEnum, originalLegacy, originalSpell = C_SpellBook, Enum, IsPlayerSpell, C_Spell
    C_SpellBook = { IsSpellInSpellBook = function(id, bank, overrides)
        T.eq(bank, 0, "Modern player spell-bank enum passed explicitly")
        T.eq(overrides, true, "Known override spells included")
        return id == 17
    end }
    Enum = { SpellBookSpellBank = { Player = 0 } }
    IsPlayerSpell = function() error("Modern lookup must not use a deprecated global") end
    T.eq(priest.IsSpellLearned(17), true, "Modern learned-spell lookup")
    T.eq(priest.IsSpellLearned(999), false, "Modern false remains false")
    C_Spell = { GetSpellInfo = function()
        return { spellID = 17, name = "Power Word: Shield" }
    end }
    local resolved = priest.ResolveSpell("17")
    T.eq(resolved.name, "Power Word: Shield", "Actual API spell name retained")
    T.eq(resolved.learning, "Learned", "Actual learned status retained")
    C_SpellBook = nil
    IsPlayerSpell = nil
    T.eq(priest.IsSpellLearned(17), nil, "Absent lookup is unavailable, not unlearned")
    C_SpellBook, Enum, IsPlayerSpell, C_Spell = originalSpellBook, originalEnum, originalLegacy, originalSpell
end
