return function(T, ns)
    local M = ns.Models.Goals
    local function draft(label, item, target, kind)
        return { label = label, item = item, target = target, kind = kind or "Shopping" }
    end
    local function fresh()
        return M.NormalizeDB({})
    end

    T.eq(M.ParseItemID(" 6948 "), 6948, "numeric item ID")
    T.eq(M.ParseItemID(6948), 6948, "number item ID")
    T.eq(M.ParseItemID("item:6948:0:0:0"), 6948, "item string")
    T.eq(M.ParseItemID("|cffffffff|Hitem:6948::::::::1:::::::::|h[Hearthstone]|h|r"), 6948, "item link")
    T.eq(M.ParseItemID("|Hitem:6948:0|h[Hearthstone]|h"), 6948, "uncolored item link")
    T.eq(M.ParseItemID("spell:6948"), nil, "spell link is not an item")
    T.eq(M.ParseItemID("abc6948"), nil, "substring is not an item ID")
    T.eq(M.ParseItemID(-1), nil, "negative item ID")
    T.eq(M.ParseItemID(1.5), nil, "fractional item ID")
    T.eq(M.ParseItemID(0), nil, "zero item ID")
    T.eq(M.ParseItemID("2147483648"), nil, "item ID bounded")

    local manual = M.ValidateDraft(draft("Train Tailoring to 150", nil, nil, "Profession"))
    T.eq(manual.label, "Train Tailoring to 150", "manual profession label")
    T.eq(manual.itemID, nil, "manual goal has no automatic item count")
    T.eq(manual.target, 1, "manual goal target is one completion")
    T.eq(M.ValidateDraft(draft("", "", "1")), nil, "empty manual goal rejected")
    T.eq(M.ValidateDraft(draft("Cloth", "bad", "20")), nil, "bad item rejected")
    T.eq(M.ValidateDraft(draft("Cloth", "2589", "0")), nil, "zero target rejected")
    T.eq(M.ValidateDraft(draft("Cloth", "2589", "2.5")), nil, "fractional target rejected")
    T.eq(M.ValidateDraft(draft("Cloth", "2589", "1000000")), nil, "target bounded")
    T.eq(M.ValidateDraft(draft("Cloth", "2589", "20", "Other")), nil, "unsupported category rejected")
    local item = M.ValidateDraft(draft("", "|cffffffff|Hitem:2589:0|h[Linen Cloth]|h|r", "40"))
    T.eq(item.label, "Linen Cloth", "item link supplies optional label")
    T.eq(item.itemID, 2589, "item reference parsed")
    T.eq(item.target, 40, "item target parsed")
    local cleaned = M.ValidateDraft(draft("  |cffff0000Need\ncloth|r  ", "2589", "3"))
    T.eq(cleaned.label, "Need cloth", "labels are plain text and trimmed")
    local again = M.ValidateDraft(draft(cleaned.label, "2589", "3"))
    T.eq(again.label, cleaned.label, "editing does not double markup escapes")

    local db = fresh()
    local first = M.Save(db, nil, draft("Linen", "2589", "40"))
    local second = M.Save(db, nil, draft("Train Tailoring", "", "1", "Profession"))
    T.eq(first.id, 1, "first stable ID")
    T.eq(second.id, 2, "next stable ID")
    T.eq(#db.goals, 2, "two goals saved")
    T.eq(M.Toggle(db, first.id), true, "manual completion toggled on")
    local edited = M.Save(db, first.id, draft("More Linen", "2589", "80"))
    T.eq(edited.id, 1, "editing preserves ID")
    T.eq(edited.done, true, "editing preserves manual completion")
    T.eq(#db.goals, 2, "editing does not duplicate")
    T.eq(M.Save(db, 999, draft("Ghost", "", "1")), nil, "missing edit does not add")
    T.eq(#M.Visible(db, "All", false), 2, "all goals visible")
    T.eq(#M.Visible(db, "Profession", false), 1, "category filter")
    T.eq(#M.Visible(db, "All", true), 1, "manual completed filter")

    local undo = M.Remove(db, first.id)
    T.eq(#db.goals, 1, "delete removes selected goal only")
    local third = M.Save(db, nil, draft("Buy bags", "", "1"))
    T.eq(third.id, 3, "deleted ID is not reused")
    local restored = M.Undo(db, undo)
    T.eq(restored.id, first.id, "undo restores identity")
    T.eq(restored.done, true, "undo restores completion")
    T.eq(db.goals[1].id, first.id, "undo restores list position")
    T.eq(#db.goals, 3, "undo preserves additions made after deletion")
    T.eq(M.Undo(db, undo), nil, "duplicate undo cannot duplicate a goal")
    T.eq(M.Remove(db, 999), nil, "unknown deletion is harmless")

    local progress = M.Progress(20, 12)
    T.eq(progress.known, true, "count known")
    T.eq(progress.needed, 8, "remaining inventory requirement")
    T.eq(progress.ready, false, "not ready below target")
    T.eq(M.Progress(20, 25).needed, 0, "extra inventory is not negative requirement")
    T.eq(M.Progress(20, 25).ready, true, "ready at or above target")
    T.eq(M.Progress(20, 0).needed, 20, "known zero is meaningful")
    T.eq(M.Progress(20, nil).known, false, "missing count is not zero")
    T.eq(M.Progress(20, -1).known, false, "invalid negative count rejected")
    T.eq(M.Progress(20, 1.5).known, false, "invalid fractional count rejected")
    T.eq(edited.done, true, "inventory calculations do not rewrite manual completion")

    local malformed = M.NormalizeDB({
        nextID = "bad", filter = "bad", hideCompleted = "yes",
        goals = {
            { id = 4, kind = "Shopping", label = "One", target = 1 },
            { id = 4, kind = "Profession", label = "Two", target = 1 },
            { id = 5, kind = "Shopping", label = "Broken", itemID = -1, target = 1 },
            false,
        },
    })
    T.eq(#malformed.goals, 2, "malformed rows do not crash or masquerade as valid")
    T.ok(malformed.goals[1].id ~= malformed.goals[2].id, "duplicate IDs normalized uniquely")
    T.eq(malformed.filter, "All", "invalid filter reset")
    T.eq(malformed.hideCompleted, false, "invalid completion filter reset")
    local full = fresh()
    for i = 1, 100 do M.Save(full, nil, draft("Goal " .. i, "", "1")) end
    T.eq(M.Save(full, nil, draft("Overflow", "", "1")), nil, "bounded persisted list")

    local oldItem, oldReadable = C_Item, ns.Readable
    local secret = {}
    ns.Readable = function(value)
        if value == secret then return false end
        return oldReadable(value)
    end
    T.eq(M.ParseItemID(secret), nil, "secret item input not inspected")
    T.eq(M.ValidateDraft(draft("Secret", secret, "1")), nil, "secret draft item rejected")
    T.eq(M.Save(db, secret, draft("Secret selection", "", "1")), nil, "secret selection not compared")
    T.eq(M.Progress(20, secret).known, false, "secret inventory does not become zero")
    T.eq(M.NormalizeDB({ goals = { secret } }).goals[1], nil, "secret row not indexed")
    local calls = 0
    C_Item = { GetItemCount = function(id, bank, uses, reagentBank, accountBank)
        calls = calls + 1
        T.eq(id, 2589, "inventory query uses exact item ID")
        T.eq(bank, false, "personal bank excluded")
        T.eq(uses, false, "charges excluded")
        T.eq(reagentBank, false, "reagent bank excluded")
        T.eq(accountBank, false, "account bank excluded")
        return 12
    end }
    T.eq(M.CarriedCount(2589), 12, "readable inventory returned")
    T.eq(calls, 1, "one inventory query")
    C_Item.GetItemCount = function() return secret end
    T.eq(M.CarriedCount(2589), nil, "secret inventory skipped")
    C_Item.GetItemCount = function() error("unavailable") end
    T.eq(M.CarriedCount(2589), nil, "failed inventory call unavailable")
    C_Item = nil
    T.eq(M.CarriedCount(2589), nil, "absent inventory API unavailable")
    C_Item, ns.Readable = oldItem, oldReadable
end
