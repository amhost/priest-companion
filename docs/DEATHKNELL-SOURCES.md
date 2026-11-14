# Deathknell guide: sources and verification limits

The included Deathknell 1-6 guide adapts the 15 steps and coordinates supplied by the user in this conversation. It splits compound instructions into 33 checklist actions. This guide does not bundle third-party guide text or a quest database. See [using the leveling guide](LEVELING-GUIDE.md) for the in-game controls.

## Class correction

The supplied route used **Tainted Scroll (3099)**. The inspected Wowhead Forever records identify that as the Warlock starter quest and **Hallowed Scroll (3097)** as the Priest starter quest:

- [Hallowed Scroll, quest 3097](https://www.wowhead.com/forever/quest=3097/hallowed-scroll), delivered to Dark Cleric Duesten.
- [Tainted Scroll, quest 3099](https://www.wowhead.com/forever/quest=3099/tainted-scroll), delivered to Maximillion.

`GuideModel.BuildRoute` selects these two verified substitutions by the character's class token. Other classes receive a manual reminder to follow the starter quest actually offered to their character. This draft does not invent class quest IDs.

## Coordinate frame and runtime map resolution

The five unique coordinate pairs are the user's Tirisfal Glades percentages: Samuel Fipps 36,62; Night Web's Hollow 27,59; the cemetery grave 31,64; Scarlet enemies 35,68; Meven Korgal 36,68. The cave point occurs on both its travel and objective actions. These locations are marked `provenance="user"`, not independently surveyed Forever spawns.

The mapping context was checked against **QuestieDB v1.0.14**, commit [`e19dfdf8528334ea63da0ecc4e291c134c0fc266`](https://github.com/Questie/QuestieDB/tree/e19dfdf8528334ea63da0ecc4e291c134c0fc266). Both `v1.0.14` and `curse/v1.0.14/Forever` resolve to that commit.

- [`src/corrections/enum/zones.lua`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/src/corrections/enum/zones.lua) defines Tirisfal Glades as area ID 85.
- [`support/Forever/Zones/areaIdToUiMapId.lua`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/support/Forever/Zones/areaIdToUiMapId.lua) maps Tirisfal Glades 85, Deathknell 154 and Night Web's Hollow 155 to map 1420. The guide stores area ID 85 and leaves the final UI map ID to the loaded provider's `ZoneDB:GetUiMapIdByAreaId` mapping.
- [`data/Forever/conversion.json`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/data/Forever/conversion.json) records identity scale and offset for Tirisfal area 85.
- [`docs/api.md`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/docs/api.md) documents coordinate conversion as a geometry projection. It cannot establish whether a particular NPC, object, or quest remains at a supplied coordinate. Its documented Forever geometry target is 1.60.1.69893, not the user's build 70938.

The data module stores coordinates normalized to 0-1. A missing runtime map conversion or absent quest location must remain unavailable rather than produce a guessed pin.

## Runtime quest database fields

The same pinned [API reference](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/docs/api.md) documents `Quest.Get`, `Npc.Get` and `Object.Get` fields. [`src/meta/questMeta.lua`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/src/meta/questMeta.lua) describes `startedBy` as NPC/object/item ID groups, `finishedBy` as NPC/object ID groups, and `objectives` as creature/object/item/reputation/kill-credit/spell groups. An empty field is not evidence of a usable location.

[`src/meta/npcMeta.lua`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/src/meta/npcMeta.lua) and [`src/meta/objectMeta.lua`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/src/meta/objectMeta.lua) define spawn tuples as percentage X, percentage Y, and optional **phase**. That third value must not be interpreted as a map ID or elevation; phase visibility belongs to the live provider.

Questie 12.6.5's wrapper and objective tuple definitions are pinned at commit [`0214175640abba697f535b2be73787a4c2f2b32b`](https://github.com/Questie/Questie/tree/0214175640abba697f535b2be73787a4c2f2b32b), including [`.types/QuestieDB/General.t.lua`](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/.types/QuestieDB/General.t.lua). The guide uses the bridge's guarded runtime provider rather than copying those databases into its own data file.

## What the checklist can confirm

The model consumes only explicit boolean evidence from the character's quest log, quest readiness and completed quest history:

- Acceptance is established by the quest being in the log or already completed.
- A whole-quest objective action is established by quest readiness or historical completion.
- A turn-in is established by historical completion. Being ready to turn in is insufficient.
- Actions containing several quests require evidence for every named quest.
- Travel, training, reminders, grave interaction and the partial Samuel Fipps action require a manual Done or Skip. The model does not infer those actions from proximity or whole-quest state.
- Missing or restricted evidence remains unknown. Manual Done and Skip are reversible checklist marks; they do not perform game actions or alter quest state.

## Remaining in-game validation

This is a user-route draft, not a fully verified Forever leveling route. QuestieDB's own [`docs/forever.md`](https://github.com/Questie/QuestieDB/blob/e19dfdf8528334ea63da0ecc4e291c134c0fc266/docs/forever.md) describes a layered Classic baseline plus Forever changes and the limits of converted data. The user's exact client, **1.60.1 / 70938 / interface 16001**, still requires native testing.

All quest IDs other than the corrected class scrolls come from the supplied route. In particular, the supplied **A Rogue's Deal (8)** is retained as a draft instruction with an in-game verification note. The [Forever page for quest 8](https://www.wowhead.com/forever/quest=8/a-rogues-deal) exists, but its presence alone does not prove the current starter-area offer uses that ID. No unverified replacement has been substituted.

Offline tests establish route coverage, class selection, evidence interpretation, manual history behavior, and coordinate provenance. They cannot establish current quest availability, spawn accuracy, map rendering, provider readiness or compatibility with the running game client.
