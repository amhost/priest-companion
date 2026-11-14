return function(T, ns)
    local resources = ns.Models.Resources
    local spells = ns.Models.Spells
    local prep = ns.Models.Preparation
    local refs = ns.Models.References

    local label, status = resources.ResourceText(40, 100)
    T.eq(label, "40 / 100", "Resource labels show readable values")
    T.eq(status, "readable", "Readable resource status")
    T.eq(resources.ResourceText(0, 0), "Unavailable", "No divide by zero on unavailable resource")
    T.eq(spells.NormalizeSpellInput("  Renew  "), "Renew", "Spell names trim surrounding whitespace")
    T.eq(spells.NormalizeSpellInput("17"), 17, "Numeric spell lookup")
    T.eq(spells.NormalizeSpellInput("0"), nil, "Zero spell ID rejected")
    T.eq(spells.NormalizeSpellInput("12.5"), nil, "Fractional spell ID rejected")
    T.eq(spells.NormalizeSpellInput("Renew\n/cast Evil"), nil, "Multiline command rejected")
    T.eq(spells.NormalizeSpellInput("Renew; Other"), nil, "Macro separator rejected")

    local originalReadable = ns.Readable
    local secret = setmetatable({}, {
        __tostring = function() error("Secret stringify") end,
        __lt = function() error("Secret compare") end,
        __div = function() error("Secret arithmetic") end,
    })
    ns.Readable = function(value) return value ~= secret and originalReadable(value) end
    local secretLabel, secretStatus = resources.ResourceText(secret, 100)
    T.eq(secretLabel, "Protected display", "Secret resources never format as text")
    T.eq(secretStatus, "protected", "Secret resource status")
    T.eq(spells.NormalizeSpellInput(secret), nil, "Secret spell input rejected before string operations")
    T.eq(resources.PowerPresentation(secret), "Power", "Secret resource token is not used as a key or text")
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
    T.eq(spells.IsSpellLearned(17), true, "Modern learned-spell lookup")
    T.eq(spells.IsSpellLearned(999), false, "Modern false remains false")
    C_Spell = { GetSpellInfo = function()
        return { spellID = 17, name = "Power Word: Shield" }
    end }
    local resolved = spells.ResolveSpell("17")
    T.eq(resolved.name, "Power Word: Shield", "Actual API spell name retained")
    T.eq(resolved.learning, "Learned", "Actual learned status retained")
    C_SpellBook.IsSpellInSpellBook = function(id) return id == 5185 end
    C_Spell.GetSpellInfo = function(query)
        T.eq(query, "Healing Touch", "Generic spell resolver accepts a non-priest spell name")
        return { spellID=5185, name="Healing Touch" }
    end
    local otherClassSpell = spells.ResolveSpell("Healing Touch")
    T.eq(otherClassSpell.name, "Healing Touch", "Non-priest spell names are retained")
    T.eq(otherClassSpell.learning, "Learned", "Non-priest learned status is supported")
    local copyBox, copiedTitle, copiedText = ns.UI.MakeCopyBox, nil, nil
    local referenceModule = ns.modules.keys
    local previousInput = referenceModule.macroInput:GetText()
    ns.UI.MakeCopyBox = function(title, text) copiedTitle,copiedText=title,text end
    C_Spell.IsSpellHelpful = function(id) return id == 5185 end
    referenceModule.macroInput:SetText("Healing Touch")
    referenceModule.macroButton:GetScript("OnClick")()
    T.eq(copiedTitle, "Mouseover macro reference", "Reference button still reaches the generic spell resolver")
    T.eq(copiedText, refs.BuildMouseover("Healing Touch"), "Reference button produces a learned non-priest mouseover macro")
    referenceModule.macroInput:SetText(previousInput)
    ns.UI.MakeCopyBox = copyBox
    C_SpellBook = nil
    IsPlayerSpell = nil
    T.eq(spells.IsSpellLearned(17), nil, "Absent lookup is unavailable, not unlearned")
    C_SpellBook, Enum, IsPlayerSpell, C_Spell = originalSpellBook, originalEnum, originalLegacy, originalSpell

    local originalType, originalPower, originalMaximum = UnitPowerType, UnitPower, UnitPowerMax
    local originalColors, originalEnergy, originalRage, originalMana = PowerBarColor, ENERGY, RAGE, MANA
    local resourceModule = ns.modules.resources
    ENERGY, RAGE, MANA = "Energy", "Rage", "Mana"
    PowerBarColor = { ENERGY={r=0.8,g=0.7,b=0.2} }
    local title, red, green, blue = resources.PowerPresentation("ENERGY")
    T.eq(title, "Energy", "Current resource uses a readable localized label")
    T.near(red, 0.8, "Current resource uses native red component")
    T.near(green, 0.7, "Current resource uses native green component")
    T.near(blue, 0.2, "Current resource uses native blue component")
    T.eq(resources.PowerPresentation(nil), "Power", "Missing power type has a neutral label")
    T.eq(resources.PowerPresentation("UNRECOGNIZED_POWER"), "Power", "Unknown resource is not mislabeled as mana")
    T.eq(resources.PowerPresentation({}), "Power", "Non-string power token is rejected")
    T.eq(resources.PowerPresentation("ENERGY\n/cast"), "Power", "Malformed power token is not used as a global key")
    local currentToken, currentValue = "ENERGY", 55
    local powerIDs = {ENERGY=3,RAGE=1,MANA=0}
    UnitPowerType = function(unit) T.eq(unit, "player", "Power-type lookup uses the player"); return powerIDs[currentToken],currentToken end
    UnitPower = function(unit, powerType)
        T.eq(unit, "player", "Current resource lookup uses the player")
        T.eq(powerType, nil, "Resource lookup does not force mana")
        return currentValue
    end
    UnitPowerMax = function(unit, powerType)
        T.eq(unit, "player", "Maximum resource lookup uses the player")
        T.eq(powerType, nil, "Maximum resource lookup does not force mana")
        return 100
    end
    resourceModule:Refresh()
    T.eq(resourceModule.powerLabel:GetText(), "Energy: 55 / 100", "Energy display follows the current resource")
    T.eq(resourceModule.power:GetValue(), 55, "Current resource value reaches the status bar")
    T.eq(resourceModule.spellInput, nil, "Resources has no chosen-spell editor")
    T.eq(resourceModule.defaultEnabled.Healing, false, "New Healing layout keeps resources optional")
    T.eq(resourceModule.defaultEnabled.Leveling, false, "New Leveling layout keeps resources optional")
    for _, entry in ipairs({{"RAGE","Rage",0},{"MANA","Mana",40}}) do
        currentToken, currentValue = entry[1],entry[3]
        resourceModule:Refresh()
        T.eq(resourceModule.powerLabel:GetText(), entry[2] .. ": " .. entry[3] .. " / 100", "Resource changes use the current label and value")
    end
    currentToken, currentValue = "ENERGY",secret
    ns.Readable = function(value) return value ~= secret and originalReadable(value) end
    resourceModule:Refresh()
    T.eq(resourceModule.powerLabel:GetText(), "Energy: Protected display", "Restricted power values do not enter formatted text")
    T.eq(resourceModule.power:GetValue(), secret, "Restricted power passes directly to a permitted display setter")
    currentValue, ns.Readable = 55,originalReadable
    UnitPowerType = nil
    resourceModule:Refresh()
    T.eq(resourceModule.powerLabel:GetText(), "Power: 55 / 100", "Absent type API preserves values with a neutral label")
    local oldRefresh, refreshed = ns.Refresh, nil
    ns.Refresh = function(id) refreshed=id end
    T.ok(ns.events.UNIT_DISPLAYPOWER and #ns.events.UNIT_DISPLAYPOWER > 0, "Resource-type changes have an event handler")
    for _, callback in ipairs(ns.events.UNIT_DISPLAYPOWER) do callback("UNIT_DISPLAYPOWER", "target") end
    T.eq(refreshed, nil, "Another unit's type change does not refresh the player")
    for _, callback in ipairs(ns.events.UNIT_DISPLAYPOWER) do callback("UNIT_DISPLAYPOWER", "player") end
    T.eq(refreshed, "resources", "Player resource-type change refreshes the bars")
    ns.Refresh = oldRefresh
    UnitPowerType, UnitPower, UnitPowerMax = originalType, originalPower, originalMaximum
    PowerBarColor, ENERGY, RAGE, MANA = originalColors, originalEnergy, originalRage, originalMana
    resourceModule:Refresh()
end
