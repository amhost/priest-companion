# Questie integration

Updated for **0.2.0-alpha.2**, November 14, 2026 (UTC).

`PriestCompanion/QuestieBridge.lua` adapts Questie's tracker clicks and existing map icons. `Modules/Quests.lua` and `Modules/QuickMenu.lua` provide visible controls and failure messages. `GuideWaypoints.lua` uses a separately guarded provider to place this addon's own numbered guide markers. The integration is optional and uses private Questie interfaces, not a supported public extension API.

## Inspected source and compatibility gate

| Questie release | Inspected immutable source | Coordinate and pin library lookup |
| --- | --- | --- |
| 12.6.5 | [`0214175640abba697f535b2be73787a4c2f2b32b`](https://github.com/Questie/Questie/tree/0214175640abba697f535b2be73787a4c2f2b32b) | `LibStub:GetLibrary("HereBeDragonsQuestie-2.0", true)` and `LibStub:GetLibrary("HereBeDragonsQuestie-Pins-2.0", true)` |
| 12.8.0 | [`968dd36747e58df157934b73d7781e8cfe560668`](https://github.com/Questie/Questie/tree/968dd36747e58df157934b73d7781e8cfe560668) | `QuestieLoader._modules.HBD` and `.HBDPins` |
| 12.9.0 | [`624cb783bfc1d272aeccd3dfa353dde8452e276f`](https://github.com/Questie/Questie/tree/624cb783bfc1d272aeccd3dfa353dde8452e276f) | `QuestieLoader._modules.HBD` and `.HBDPins` |

The user's alpha.1 diagnostic reported Questie **12.6.5**, QuestieDB **1.0.14**, and client **1.60.1 / 70938 / interface 16001**. Alpha.1's version gate excluded 12.6.5. Widening that gate alone would still fail because its coordinate library is registered through LibStub, not `registry.HBD`. Alpha.2 implements the inspected legacy lookup and retains the modern lookup. LibStub is a callable table; the adapter invokes its `GetLibrary` method with explicit self and silent lookup, rather than passing the table to the function-only `ns.Call` helper.

The relevant library registration can be compared directly in the pinned [12.6.5 HBD source](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Libs/HereBeDragons/HereBeDragons-2.0.lua), [12.6.5 pin source](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua), [12.9.0 HBD source](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Libs/HereBeDragons/HereBeDragons-2.0.lua), and [12.9.0 pin source](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Libs/HereBeDragons/HereBeDragons-Pins-2.0.lua). The world-map pin template also changes between these versions. Quest Companion uses the inspected add/remove methods and does not hardcode or enumerate either template.

Between the inspected 12.6.5 and 12.9.0 sources, `TrackerMapEligibility`, `TrackerQuestieBehavior`, `LineBuilder`, and `QuestieCompat` are identical. The relevant map/frame changes switch library discovery; the tracker line changes add tooltip handling without changing the title/map contract used here. The following source paths establish those contracts; links in this table are pinned to 12.9.0:

| Source path | Relevant contract |
| --- | --- |
| [`Modules/Tracker/LinePool/LineBuilder.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Tracker/LinePool/LineBuilder.lua) | `AddTitle(options)` assigns the target and click handler before returning the current pooled line. |
| [`Modules/Tracker/LinePool/TrackerLinePool.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Tracker/LinePool/TrackerLinePool.lua) | `GetCurrentLine()` and `ForEachQuestTitleLine(callback)` expose current and existing titles. |
| [`Modules/Tracker/LinePool/TrackerLine.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Tracker/LinePool/TrackerLine.lua) | Rows retain a current `Quest` and receive their ordinary `OnClick` handler when rebuilt. |
| [`Modules/Tracker/TrackerMapEligibility.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Tracker/TrackerMapEligibility.lua) | `RefreshAndGetCapabilities(id, expectedQuest)` refreshes live state and validates original quest/objective identity. |
| [`Modules/Tracker/TrackerQuestieBehavior.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Tracker/TrackerQuestieBehavior.lua) | Display objectives receive verified original enrichment by native objective index. |
| [`Modules/Map/QuestieMap.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/Map/QuestieMap.lua) | `GetFramesForQuest(id)`, `QueueDraw`, `ProcessQueue`; world/minimap registration, normalized `UiMapID`, coordinates and `minimapTwin`. |
| [`Modules/FramePool/QuestieFrame.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/FramePool/QuestieFrame.lua) | `ShouldBeHidden`, `FakeHide`, `FakeShow`, unloading and associated patrol-path visibility. |
| [`Modules/FramePool/QuestieFramePool.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/FramePool/QuestieFramePool.lua) | `UnloadFrame` and deferred unloading before pooled frames can be reused. |
| [`Modules/QuestieCompat.lua`](https://github.com/Questie/Questie/blob/624cb783bfc1d272aeccd3dfa353dde8452e276f/Modules/QuestieCompat.lua) | `OpenWorldMap(uiMapID)` uses the supported map-opening path for the client; direct `WorldMapFrame:SetMapID` is unsuitable on Forever. |

Installation accepts loaded Questie metadata for **exactly 12.6.5**, or the existing **12.8.x / 12.9.x** families, then checks required module methods and frame methods. Other 12.6 releases are not admitted. The modern family gate permits compatible patch releases; it does not establish that every patch was inspected or that an installation works in-game. Unknown versions or missing shapes retain ordinary navigation with an actionable failure reason. QuestieDB's loaded metadata version is reported, not used as a compatibility guarantee.

The pinned [12.6.5 Forever TOC](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Questie_Forever.toc) declares interface 16001 and QuestieDB contract 4. This agrees with the reported interface, but source declarations and offline mocks do not establish behavior on build 70938.

The adapter reads `QuestieLoader._modules` without invoking `ImportModule`, because that loader method creates absent module entries. Private interfaces can change despite a matching version. Reinspect the source and rerun regression and native checks before widening the version gate.

## Visible controls and selected-quest locations

No slash command is required for normal navigation:

1. Left-click the **Quest Companion map icon beside the minimap** to open the quick menu.
2. Under **Quest locations**, choose **Next**, **All**, or **Hide**, then click a tracked quest title in Questie's right-side tracker.
3. Use **Normal Questie clicks** to disable tracker interception, or **Quest Helper** to open this addon's quest list and its matching location controls.

The quick menu displays availability separately from the enabled preference. The Quest Helper displays an unavailable-provider reason when interception is enabled but not ready. A selected mode alone does not claim that the provider loaded or that a quest has a usable location.

Controls affect **the quest clicked most recently through the adapter**, while its map view is open. Other quests retain their own icon behavior.

| Control | Selected quest |
| --- | --- |
| **Next** | One supported unfinished world-map checkpoint and its matching minimap twin, subject to native minimap visibility. A complete quest uses a turn-in. |
| **All** | All supported unfinished **rendered** world-map checkpoints and matching twins, or rendered turn-ins for a complete quest. |
| **Hide** | Suppresses the selected quest's registered world-map and minimap locations. |
| **Adapter Off** | Restores Questie's ordinary clicks and icons. This is separate from Hide. |

Next ranks valid rendered coordinates using HBD world positions, preferring the player's world instance and then geometric distance. It opens the checkpoint's map. It does not calculate a walking route, travel cost or dungeon path.

Questie's clustering, phase filtering and native hidden preferences bound available locations. All does not promise every raw database spawn. Completed, unmapped, party-only, native-hidden and unusable-coordinate candidates are excluded. The bridge does not manufacture missing coordinates or override an existing hidden preference to claim a visible target. If it cannot establish a usable selection, navigation falls back.

The saved defaults are `mode = "next"` and `enabled = true` under `ns.ModuleDB("navigation", ...)`. Installation alone does not change icon visibility. Filtering starts with a successful navigation action. Only these preferences are saved; selected quests, provider objects and temporary wrappers are not persisted.

## Hooks, filtering and restoration

The adapter post-hooks `LineBuilder.AddTitle` and attaches existing quest titles through `ForEachQuestTitleLine`. Its wrapper handles plain left click only, reads the current pooled row at click time and preserves the original callback for right click, modifiers, controller mode, combat and unsuccessful navigation.

Selected-quest filtering creates no additional pin layer. A temporary per-frame `ShouldBeHidden`/`FakeShow` wrapper and Questie's `FakeHide` suppress disallowed icons. Questie's fake visibility methods preserve HBD show/hide intent and notify its patrol-path owner logic. The adapter tracks the exact data object and which hides it owns. Numbered guide markers are a separate feature with separate ownership, described below.

`QueueDraw` suppresses new selected-quest icons until selection is recalculated. A dirty `ProcessQueue` hook coalesces refresh after those icons draw. `QUEST_LOG_UPDATE` revalidates live objective completion and quest identity. There is no adapter polling loop.

Map close, adapter disable and selection change release temporary filtering. `UnloadFrame` removes wrappers after actual unloading; deferred unloads wait for Questie's lifecycle. Restoration replaces a method or title callback only if it is still the adapter's own wrapper, preserves later third-party replacements and respects current native hidden preferences.

Combat and controller mode block adapter UI mutations. Native behavior can temporarily reveal icons during combat; `PLAYER_REGEN_ENABLED` revalidates and reapplies an active selection. A map-close restoration requested during combat is deferred until it can run. Controller activation requests restoration, completed when the adapter can act again. A partial secure-hook installation failure requires a reload rather than stacking more hooks on retry.

## API, controls and failure behavior

All methods below use dot calls on `ns.QuestieBridge`:

| Method | Contract |
| --- | --- |
| `Navigate(questID, expectedOriginalQuest)` | Optional original-object identity guard; returns `success, reason`. Unexpected synchronous navigation errors release owned state and return a controlled failure. |
| `SetMode("hide" / "next" / "all")` | Persists mode; recomputes an active selection. Does not independently enable the adapter. |
| `GetMode()` | Returns saved mode, default Next. |
| `SetEnabled(boolean)` / `IsEnabled()` | Separate adapter switch; Off restores titles/icons while retaining mode. |
| `Install()` | Guarded, repeatable installation/readiness check. |
| `GetAvailability()` | Returns `ready, reason`; ready describes successful adapter installation/shape validation, not native client certification or availability of a particular quest location. |
| `Status()` | Concise loaded metadata, shape-guarded/unavailable state, enabled state, mode, selected checkpoint count and last controlled failure. No quest IDs or titles. |
| `GetMapProvider()` | Returns a runtime provider for guarded reads and owned-pin operations, or `nil, reason`. Required fields are `hbd`, `hbdPins`, and `compat`; optional shape-checked fields are `db`, `zones`, and `phasing`. Metadata fields are `version`, `databaseVersion`, and `profile`. Lookup does not install hooks, change settings, or depend on tracker interception being enabled. |
| `GetObjectiveLocations(questID)` | Returns groups of copied normalized coordinates for validated live unfinished objectives. `nil` means no validated snapshot; an empty table means the live quest is complete. No Questie object or frame references escape. Does not draw or change icon visibility. |

Optional in-game commands remain `/qc locations hide`, `/qc locations next`, `/qc locations all`, `/qc locations off` and `/qc locations on`. Choosing Hide/Next/All through the panel, quick menu, or command also enables the adapter. Selecting a mode without an active selected quest waits for the next quest-title click; it does not create a target by itself.

An unsupported Questie tracker click calls its original callback. Quest Companion's own row uses ordinary quest details when bridge navigation is unavailable; if the client's details helper is absent, it opens the readable quest/objective copy panel. Details remains explicitly accessible. No fallback writes or clears the player's personal waypoint, and no fallback pin is layered over Questie.

## Separate numbered guide markers

Open **minimap map icon > Guide**, or right-click that icon to toggle the guide directly. In the guide, **Current** displays locations for the displayed checklist action; **Route** displays mapped remaining actions; **Hide** removes guide markers. **Map** opens the focused location's zone and switches a hidden guide back to Current. Clicking a guide row reviews and maps that action. These controls are independent of Questie's Next/All/Hide controls.

`GuideWaypoints.lua` resolves and renders runtime hints through `GetMapProvider()`:

| Input | Resolution and limits |
| --- | --- |
| Explicit guide point | The supplied area ID is resolved through `ZoneDB:GetUiMapIdByAreaId`. Supplied normalized coordinates take precedence. A failed conversion remains unmapped; a broad quest location is not substituted. |
| Pickup / turn-in | Dot-called `QueryQuestSingle(id, "startedBy" / "finishedBy")`, then the referenced NPC/object spawns. Item-started quests may resolve known item sources. |
| Active objective | Prefer validated live unfinished Questie clusters, when the bridge can provide them. A confirmed complete live snapshot does not fall back to historical objective spawns. |
| Future objective | Read the loaded corrected creature/object/item/kill-credit groups. Item sources include known NPC drops, object drops, vendors, and containers with cycle detection and a recursion bound. Reputation and spell objectives without a reliable destination remain unmapped. |
| Raw spawn phase | Spawn tuples are `{xPercent, yPercent, phase?}`. A non-nil phase requires readable `true` from `Phasing.IsSpawnVisible(phase)`; missing, failed, or restricted phase checks omit that spawn. |

The getter aliases are established by pinned [QuestieDB.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Database/QuestieDB.lua). Exact field/tuple shapes are recorded in [General.t.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/.types/QuestieDB/General.t.lua) and [Item.t.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/.types/QuestieDB/Item.t.lua). Runtime map conversion comes from [zoneDB.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Database/Zones/zoneDB.lua). The inspected [Phasing.lua](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Modules/Phasing.lua) uses a dot-call visibility function and is identical between the inspected 12.6.5 and 12.9.0 sources. See [DEATHKNELL-SOURCES.md](DEATHKNELL-SOURCES.md) for QuestieDB 1.0.14 source pins and the supplied route's provenance.

Resolution selects one nearest usable location per action/objective, preferring the current world instance. Route distance selection proceeds from the prior action, while checklist order remains unchanged. It does not calculate terrain-aware travel or prove quest availability. Missing coordinates are reported. Same-position actions share a numbered marker and retain their instructions in its tooltip. The renderer caps output at **24 numbered locations**, reports wholly unmapped, partly mapped, and capped steps, and highlights the focused action.

Both world and minimap icons use the stock available-quest texture by path plus an ordinal label. Each map surface receives its own frame. A unique addon-owned reference is passed to `AddWorldMapIconMap` / `AddMinimapIconMap` and the corresponding `RemoveAll...` methods. The renderer never removes another reference's pins, copies Questie's frame pool, or invokes personal-waypoint setters/clearers. World markers are limited to their exact zone map; minimap markers do not float on the edge.

Guide Hide and panel close remove owned markers. Combat defers removal/redraw and applies the latest queued request on `PLAYER_REGEN_ENABLED`. A queued close supersedes an earlier queued draw. Partial drawing or map-opening errors attempt owned cleanup and return a failure reason. Quest/world refreshes re-read objective and phase data without reopening the map. If an upstream cleanup method fails, the controlled failure asks the player to reload before retrying.

All guide waypoint methods use dot calls on `ns.GuideWaypoints`:

| Method | Contract |
| --- | --- |
| `Show(steps, options)` | Returns `success, message, info`. Options are `mode="current" / "route" / "hide"`, `openMap=boolean`, and optional `focusStepID`. Current expects the selected step; Route expects remaining steps including it. |
| `ResolveStep(step)` | Returns `points, reason, detail` without creating frames, opening a map, or changing progress. Points contain normalized coordinates and source provenance. |
| `Clear()` | Returns boolean; false during combat means cleanup was queued. It clears only this renderer's ownership. |
| `Status()` | Returns the last concise message and info. |

`Show` info exposes `rendered`, `unmapped`, `partial`, `capped`, `mappedSteps`, `unmappedIDs`, and `cappedIDs` for a resolved route. Combat adds `deferred=true`; early failures may return only the applicable count fields. `ResolveStep` detail counts unresolved actions/objective groups rather than whole route steps. Only guide preferences and manual progress belong in saved data. Provider objects, pins, coordinate caches, selected-quest wrappers, and pending combat requests remain in memory.

## Validation and data boundary

No quest database or upstream implementation body is copied into this addon. Selected-quest navigation consumes already-loaded Questie objects and existing pins. Guide routing reads the same loaded provider plus the user's supplied route points. A website crawl is not part of runtime behavior, and a database marker is not evidence that a quest can currently be accepted.

`tests/questie_bridge_cases.lua` uses isolated provider and UI doubles to cover both library-discovery paths, rejection of uninspected legacy versions, availability reasons, read-only provider/snapshot access, pin counts, completion/turn-in changes, redraws, pooled rows/frames, restoration, hidden preferences, third-party replacements, modifiers, restricted inputs, combat resume and failure fallbacks. The 12.6.5 fixture deliberately has no `registry.HBD` or `registry.HBDPins` entries.

`tests/guide_waypoints_cases.lua` covers live ZoneDB conversion, phase filtering, nearest-source selection and route chaining, live objective precedence, explicit-point precedence, item-source cycles, coordinate validation, coincident actions, the 24-marker cap, separate world/minimap frames, foreign ownership preservation, combat queuing, and partial-draw/open failure cleanup. `tests/quest_navigation_cases.lua`, `tests/quick_menu_cases.lua`, and `tests/guide_ui_cases.lua` cover the visible controls and integration. These are bounded mocks, not native provider execution.

From the repository root, run the offline suite:

```bash
python3 tools/check.py
```

Passing those checks does **not** verify native WoW rendering, taint, secure execution, actual client combat restrictions or another installed addon combination. Native validation remains pending. Use [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md), including selected-quest Next/All/Hide counts, turn-ins, map close, combat exit, redraw and Off restoration. Also check guide Current/Route/Hide, numbered world/minimap locations, same-position action tooltips, unknown-location messages, closing the guide, combat resume, and preservation of an existing personal waypoint before calling these features verified in-game.
