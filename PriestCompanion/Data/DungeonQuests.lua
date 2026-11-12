local addonName, ns = ...

-- Small, manually maintained subset of ATT's Forever catalog, under MIT.
-- Copyright (c) 2026 AllTheThings WoW Addon. See ../LICENSE-ATT.txt.
-- No GPL dataset, scraped guide, quest prose, reward table or addon code used.
-- NONE of these dungeon assignments or requirements is live-verified here.
local revision = "3ed4599270cee01575393b1a62e543dc9e32fa2f"
local sourceRoot = "https://github.com/ATTWoWAddon/AllTheThings/blob/" .. revision
    .. "/.contrib/.db/forever/dungeons%20%26%20raids/"

local function quest(id, title, faction, minLevel, giver, reportedPrior, pickup)
    return {
        id = id, title = title, faction = faction, minLevel = minLevel,
        giver = giver, reportedPrior = reportedPrior, pickup = pickup,
        -- Missing source fields are NOT evidence of no restrictions.
        requirementsComplete = false,
        -- sourceQuest annotations may include breadcrumbs. Keep them advisory
        -- until mandatory/alternative semantics are verified.
        prerequisites = nil,
    }
end

ns.DungeonQuestCatalog = {
    version = "prototype-1",
    dungeons = {
        {
            key = "deadmines", name = "The Deadmines", coverage = "partial",
            source = { name = "AllTheThings Forever", license = "MIT", revision = revision,
                url = sourceRoot .. "the%20deadmines.lua",
                blob = "bfed917a9d14324d9df883442edb4ac6d29cc533", verification = "provisional" },
            quests = {
                quest(168, "Collecting Memories", "Alliance", 14,
                    "Wilder Thistlenettle (NPC 656), Stormwind 70.2, 40.8"),
                quest(92753, "Destruction in Deadmines (1/2)", "Alliance", 9,
                    "Alba Fairmoon (NPC 253092), Westfall 52.5, 53.0", {92752}),
                quest(92819, "Destruction in Deadmines (2/2)", "Alliance", 9,
                    "Alba Fairmoon (NPC 253279), Westfall 52.5, 53.0", {92753}),
                quest(167, "Oh Brother. . .", "Alliance", 15,
                    "Wilder Thistlenettle (NPC 656), Stormwind 70.2, 40.8"),
                quest(214, "Red Silk Bandanas", "Alliance", 14,
                    "Scout Riell (NPC 820), Westfall 56.7, 47.4", {153, 155}),
                quest(166, "The Defias Brotherhood (7/7)", "Alliance", 14,
                    "Gryan Stoutmantle (NPC 234), Westfall 56.3, 47.5", {155}),
                quest(373, "The Unsent Letter", "Alliance", 16,
                    "An Unsent Letter (item 2874), dropped by VanCleef", nil,
                    "Item starts this quest during the run; not a pre-entry pickup."),
                quest(2040, "Underground Assault", "Alliance", 15,
                    "Shoni the Shilent (NPC 6579), Stormwind 62.8, 34.8", {2041}),
            },
        },
        {
            key = "thanes", name = "Hall of Thanes", coverage = "partial",
            source = { name = "AllTheThings Forever", license = "MIT", revision = revision,
                url = sourceRoot .. "hall%20of%20thanes.lua",
                blob = "b3cd94acd223ccc1dd5d5fc09965fd13fa04a194", verification = "provisional" },
            quests = {
                quest(96395, "An Ancient Grudge", "Alliance", 10,
                    "Ghostly Attendant (NPC 265002); pickup location unverified"),
                quest(96403, "Important Heirlooms", "Alliance", 10,
                    "Thom Filch (NPC 265003), Ironforge 32.4, 44.8"),
                quest(96393, "Old Ironforge Incursion", "Alliance", 9,
                    "Earthseer Farsen (NPC 264936), Dun Morogh 64.8, 58.4", {96391}),
                quest(96394, "The Restless Dead", "Alliance", 10,
                    "Afadra Dunwall (NPC 264943), Ironforge 33.2, 47.8"),
                quest(98423, "The Treaty of Understanding", "Alliance", 9,
                    "Treaty of Understanding (item 281030); acquisition location unverified", nil,
                    "Item-started quest; pre-entry availability unknown."),
            },
        },
        {
            key = "ragefire", name = "Ragefire Chasm", coverage = "partial",
            source = { name = "AllTheThings Forever", license = "MIT", revision = revision,
                url = sourceRoot .. "ragefire%20chasm.lua",
                blob = "cee1dc938f3107acd326a890532f75b29d85022a", verification = "provisional" },
            quests = {
                quest(5728, "Hidden Enemies (3/5)", "Horde", 9,
                    "Thrall (NPC 4949), Orgrimmar 32.0, 37.8", {5727}),
                quest(5722, "Searching for the Lost Satchel", "Horde", 9,
                    "Rahauro (NPC 11833), Thunder Bluff 70.6, 31.4"),
                quest(5761, "Slaying the Beast", "Horde", 9,
                    "Neeru Fireblade (NPC 3216), Orgrimmar 49.6, 50.6", {5727}),
                quest(5723, "Testing an Enemy's Strength", "Horde", 9,
                    "Rahauro (NPC 11833), Thunder Bluff 70.6, 31.4"),
                quest(5725, "The Power to Destroy...", "Horde", 9,
                    "Varimathras (NPC 2425), Undercity 56.2, 91.8"),
            },
        },
    },
}
