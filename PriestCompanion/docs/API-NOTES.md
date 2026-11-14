# API evidence and implementation boundaries

Original API research: November 10, 2026. Questie and guide integration update for **0.2.0-alpha.3**: November 14, 2026 (UTC). This document distinguishes inspected source from native runtime evidence. No actual Forever client was available in the build environment.

## Target declaration

The pinned [Questie 12.6.5 Forever manifest](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Questie_Forever.toc) declares interface **16001**, version **12.6.5**, and QuestieDB contract **4**. The user's supplied diagnostic reports **1.60.1 / build 70938 / interface 16001 / enUS**, with Questie **12.6.5** and QuestieDB **1.0.14**. Those are distinct evidence sources: the source declaration agrees with the reported interface, while neither proves that this release has been exercised inside that client. Quest Companion's legacy-named TOC targets 16001 and reports a mismatch in chat if loaded elsewhere.

The source-backed compatibility gate accepts exactly **12.6.5** plus the existing **12.8.x / 12.9.x** families, with method-shape checks. Legacy 12.6.5 resolves HBD libraries through `LibStub:GetLibrary`; the inspected modern versions use Questie loader modules. This is an implemented compatibility path, not only a relaxed version check. Unsupported versions remain unavailable with a visible reason. The exact inspected commits, source contracts and remaining checks are in [QUESTIE-INTEGRATION.md](QUESTIE-INTEGRATION.md).

## Questie startup timer contract

The alpha.2 report contains `C_Timer.NewTicker` bad argument #2 at `QuestieMap.lua:235`, followed by the user's successful Questie reload with Quest Companion disabled. At the pinned [12.6.5 source](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Modules/Map/QuestieMap.lua), `InitializeQueue` passes `QuestieMap.ProcessQueue` directly to the timer. Our previous secure hook changed that field during early login. The [staged initializer](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Modules/QuestieInit.lua) yields before reaching the queue stage.

Alpha.3 removes the hook and its method dependency entirely. QueueDraw schedules our own Lua closure with `C_Timer.After(0, ...)`; callback identity and native timer ownership remain with Questie. Deferral is required because Questie registers the frame pair after queuing it. The bridge rejects missing scheduling support and restores its filtering if scheduling fails.

The regression fixture now models timer registration, a captured callback, both startup orders, partial frame registration and scheduler failures. It reproduces alpha.2's failure under a bounded rejection contract and passes with the fix. This models the observed native constraint; it does not emulate Blizzard's secure runtime. The in-game alpha.3 reload check is still pending.

## Combat data

Blizzard's [UI customization explanation](https://news.blizzard.com/en-gb/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons) and [combat addon explanation](https://news.blizzard.com/en-gb/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) describe the distinction between presenting protected combat values and interpreting them in custom logic. These articles concern the modern API model; exact Forever behavior still needs in-game validation.

Core guards use the available `issecretvalue`, `issecrettable` and `canaccessvalue` functions before ordinary inspection. The Resources panel permits values to pass directly into supported StatusBar setters, wrapped with `pcall`; it does not compare protected health or resource values. Unsupported display calls fall back to an explicit unavailable state. No combat log bypass or protected-value reconstruction is attempted.

## Quests

Inspected [Blizzard-generated QuestLog documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua). Current quest-log reads use `GetNumQuestLogEntries`, `GetInfo`, `GetQuestObjectives` and `IsComplete` under `C_QuestLog` when available. Navigation now uses the guarded Questie adapter described in [QUESTIE-INTEGRATION.md](QUESTIE-INTEGRATION.md). The previous `GetNextWaypoint`/personal-waypoint fallback is no longer called: an unavailable bridge falls back to ordinary quest details without overwriting the player's personal point.

The helper contains no borrowed world database or guessed quest locations. Alpha.2 adds a leveling checklist derived from the user's supplied Deathknell route; its provenance and limits are recorded in [DEATHKNELL-SOURCES.md](DEATHKNELL-SOURCES.md). Missing data is not interpreted as quest completion.

Visible navigation controls are under **Quest Companion minimap map icon > Quest locations > Next / All / Hide** and **Quest Helper**. Select a mode, then click a tracked Questie title to choose its current location. `GetAvailability()` exposes successful adapter installation separately from the enabled preference and returns an actionable failure reason. **Normal Questie clicks** restores ordinary tracker behavior. Slash commands are optional.

For optional quest acceptance, inspected the [extracted Blizzard quest-frame source at commit 70ef1b2](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua). It processes `QUEST_DETAIL`, identifies the giver through `questnpc`, and calls `AcceptQuest()` for an ordinary offer. It handles PvP confirmation, already autoaccepted quests, item-started offers, adventure-map offers and area triggers separately. This source evidence does not establish that an addon may successfully call every function in the user's native client; live acceptance remains part of alpha verification.

The optional acceptance path requires a readable, existing, non-player `questnpc`. This is a conservative giver filter, not proof that every shared-quest edge case has been validated. The per-character preference starts off and applies in both layouts, even with the panel hidden. Shift, combat, a special offer or unavailable data leaves that displayed offer manual. A successful API call is shown only as an acceptance request; the addon does not claim server confirmation from the call's return alone.

## Guide progress and map markers

Open **Quest Companion minimap map icon > Guide**; right-clicking the icon also toggles it. The guide uses **Current / Route / Hide** for its own locations and **Map** to open the focused zone. Its progress model and marker resolver are separate: a marker indicates a route location, not whether a quest is available or completed.

Guide evidence uses capability-checked `C_QuestLog.GetNumQuestLogEntries`, `GetInfo`, `IsComplete`, and `IsQuestFlaggedCompleted`, accepting explicit readable booleans. Historical completion or presence in the log can confirm an acceptance action. Readiness or historical completion can confirm a whole-quest objective action. A turn-in requires historical completion; readiness alone is insufficient. Every quest in a multi-quest action needs confirming evidence. An incomplete or restricted log read does not prove absence.

Travel, training, reminders, the partial Samuel Fipps action, and grave interaction use manual **Done / Skip**. Those reversible checklist marks do not perform game actions or alter quest state. The renderer does not infer progress from proximity. Only guide preferences and manual progress are persisted; live evidence and provider/frame objects are not.

The guide obtains runtime map services from `QuestieBridge.GetMapProvider()`, which does not install tracker hooks or enable interception. Required shapes include coordinate conversion, owned world/minimap pin add/remove methods, and map opening. Optional `QuestieDB`, `ZoneDB`, and `Phasing` services are exposed only when their inspected methods exist. A valid provider shape still needs native validation.

The pinned [Questie 12.6.5 DB wrapper](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Database/QuestieDB.lua) aliases `QueryQuestSingle`, `QueryNPCSingle`, `QueryObjectSingle`, and `QueryItemSingle` directly to `LibQuestieDB` getters. Calls are `getter(id, field)` with no implicit self. The `Query*` multi-field aliases instead require a requested-field array and return packed positional values; this renderer uses the Single getters.

| Data | Inspected shape and use |
| --- | --- |
| `startedBy` | NPC, object, and item ID groups. Resolve one usable pickup source for the action. |
| `finishedBy` | NPC and object ID groups. Resolve a finisher location without claiming the player can turn in. |
| `objectives` | Creature, object, item, reputation, kill-credit, and spell groups. Supported entity/item groups produce hints; a spell or reputation objective alone does not identify a reliable destination. |
| NPC/object `spawns` | `{[areaID]={{xPercent,yPercent,phase?},...}}`. Convert percentages to 0-1 and area ID through live `ZoneDB:GetUiMapIdByAreaId`. |
| Item sources | `npcDrops` and `vendors` contain NPC IDs; `objectDrops` contains object IDs; `itemDrops` contains container item IDs. Container resolution is bounded and cycle-safe. |

These contracts are pinned in [General.t.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/.types/QuestieDB/General.t.lua) and [Item.t.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/.types/QuestieDB/Item.t.lua). The provider's [Phasing.IsSpawnVisible](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Modules/Phasing.lua) is dot-called. For a non-nil phase, only readable `true` permits a raw DB spawn; a missing, throwing, or restricted phase check omits it. An explicit user route coordinate remains a manual route hint with its own provenance, not a phase-verified spawn claim.

Active objectives prefer copied, validated unfinished Questie clusters through `GetObjectiveLocations`. Future steps use loaded corrected DB fields. Explicit supplied coordinates take precedence, and failed map conversion remains unavailable rather than becoming a guessed location. HBD world conversion is checked before marker creation because its add methods can return without registering an unusable coordinate.

The inspected [12.6.5 HBD pin API](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua) supplies `AddWorldMapIconMap(ref, icon, uiMapID, x, y, showFlag, frameLevel)`, `AddMinimapIconMap(ref, icon, uiMapID, x, y, showInParentZone, floatOnEdge)`, and `RemoveAllWorldMapIcons(ref)` / `RemoveAllMinimapIcons(ref)`. Guide markers use a unique reference and separate world/minimap frames. They do not write or clear personal waypoints, remove other owners' pins, or depend on a version-specific world-map template name.

The renderer selects a nearest valid spawn per action/objective, preserves checklist order, groups coincident positions, and caps display at **24 numbered locations**. Wholly unmapped, partly mapped, and capped steps are reported. Route distance selection is geometric; it does not calculate a walkable path or inspect prerequisite, level, class, or current offer eligibility. Hide/close clears owned markers; combat defers cleanup/redraw until combat ends; partial failures attempt owned cleanup and return a reason. Automatic quest/world updates do not reopen the map.

`tests/questie_bridge_cases.lua` and `tests/guide_waypoints_cases.lua` exercise both library-discovery paths, shape failures, phase/source selection, ownership, caps, combat queues, and error cleanup through bounded mocks. They do not establish native taint safety, actual rendering, or spawn accuracy on build 70938. Follow [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md) before recording in-game validation.

## Inventory and professions

Inspected [Blizzard-generated Item documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua). Shopping targets call `C_Item.GetItemCount(itemID, false, false, false, false)`, excluding bank, charge, reagent-bank and account-bank counts. Values must be readable, nonnegative whole numbers before calculation.

Primary profession summaries capability-check `GetProfessions` and `GetProfessionInfo`. The manual goal editor remains usable without those APIs. Preparation uses capability-checked equipment durability and modern container APIs. General-space totals exclude specialized bag families and treat failed readings as partial coverage.

## Spell references and macro text

Spells are resolved through `C_Spell.GetSpellInfo` rather than hardcoded Forever ability IDs. Modern learned-spell checks use `C_SpellBook.IsSpellInSpellBook` when available, with a checked legacy fallback. A helpful-spell check is used when available. Newlines, macro commands, custom condition fragments and oversized inputs are rejected by the copyable macro builder.

The builder produces text only. Spell-specific targeting behavior still requires a player review in the actual game.

## XP-credit tracking

The generated event surface includes `CHAT_MSG_COMBAT_XP_GAIN`; the implementation checks event registration and actual available localized `COMBATLOG_XPGAIN_*` globals. Only known named kill-XP templates are compiled. Positional format arguments are supported. A secret or unrecognized message is skipped; an unnamed XP event is not counted as a kill.

This is partial XP-credit history, not a full combat log or proof of a player's killing blow. Consecutive identical messages are separate events and are not deduplicated by text. Manual entries remain separate. Native locale formats and live event receipt remain untested.

## Distribution

Blizzard's [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534) informs the free, visible-source distribution. This original package includes no ads, paid feature gate or in-game donation prompt.

The shared UI uses game-provided fonts and textures by path. No Blizzard texture or sound files are included in either ZIP.
