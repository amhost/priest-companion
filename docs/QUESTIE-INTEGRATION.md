# Questie integration

`PriestCompanion/QuestieBridge.lua` adapts Questie's tracker clicks and existing map icons. `Modules/Quests.lua` provides the controls and details fallback. The bridge is optional and uses private Questie interfaces, not a supported public extension API.

## Inspected source and compatibility gate

| Questie release | Inspected immutable source |
| --- | --- |
| 12.8.0 | [`968dd36747e58df157934b73d7781e8cfe560668`](https://github.com/Questie/Questie/tree/968dd36747e58df157934b73d7781e8cfe560668) |
| 12.9.0 | [`624cb783bfc1d272aeccd3dfa353dde8452e276f`](https://github.com/Questie/Questie/tree/624cb783bfc1d272aeccd3dfa353dde8452e276f) |

The inspected tracker and map/frame lifecycle interfaces were identical between these pins. The following source paths establish the behavior used by the adapter; links are pinned to 12.9.0:

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

Installation accepts loaded Questie metadata in **12.8.x or 12.9.x** only, then checks required module methods and frame methods. This permits compatible patch releases; it does not establish that every patch was inspected or that an installation works in-game. Unknown versions or missing shapes retain ordinary navigation. QuestieDB's loaded metadata version is reported, not used as a compatibility guarantee.

The adapter reads `QuestieLoader._modules` without invoking `ImportModule`, because that loader method creates absent module entries. Private interfaces can change despite a matching version. Reinspect the source and rerun regression and native checks before widening the version gate.

## Location semantics

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

There is no additional pin layer. A temporary per-frame `ShouldBeHidden`/`FakeShow` wrapper and Questie's `FakeHide` suppress disallowed icons. Questie's fake visibility methods preserve HBD show/hide intent and notify its patrol-path owner logic. The adapter tracks the exact data object and which hides it owns.

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
| `Status()` | Concise loaded metadata, shape-guarded/unavailable state, enabled state, mode, selected checkpoint count and last controlled failure. No quest IDs or titles. |

In-game commands are `/qc locations hide`, `/qc locations next`, `/qc locations all`, `/qc locations off` and `/qc locations on`. Choosing Hide/Next/All through the panel or command also enables the adapter.

An unsupported Questie tracker click calls its original callback. Quest Companion's own row uses ordinary quest details when bridge navigation is unavailable; if the client's details helper is absent, it opens the readable quest/objective copy panel. Details remains explicitly accessible. No fallback writes or clears the player's personal waypoint, and no fallback pin is layered over Questie.

## Validation and data boundary

No quest database or upstream implementation body is copied into this addon. This adapter consumes already-loaded Questie objects and existing pins. A website crawl is not part of its runtime behavior.

`tests/questie_bridge_cases.lua` uses isolated provider and UI doubles to cover pin counts, completion/turn-in changes, redraws, pooled rows/frames, restoration, hidden preferences, third-party replacements, modifiers, restricted inputs, combat resume and failure fallbacks. `tests/quest_navigation_cases.lua` covers the panel integration.

From the repository root, run the offline suite:

```bash
python3 tools/check.py
```

Passing those checks does **not** verify native WoW rendering, taint, secure execution, actual client combat restrictions or another installed addon combination. Native validation remains pending. Use [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md), including selected-quest Next/All/Hide counts, turn-ins, map close, combat exit, redraw and Off restoration, before calling this integration verified in-game.
