# Quest Companion 0.2.0-alpha.1

The addon now has a class-neutral name and a direct Questie navigation path. This alpha builds on the compact appearance controls from 0.1.0-alpha.2.

## Changes

- **Plain left-click a Questie tracker title to open its checkpoint map.** Our Quest Helper rows do the same without an extra Map-button click. Only the selected helper row expands its objectives. The permanent location disclaimer is removed.
- **Hide / Next / All** operate on the clicked quest's existing supported Questie pins. Next chooses one nearest unfinished checkpoint, or a finisher when ready. All retains Questie's rendered locations and clustering. Other quests keep their normal settings. The temporary filter restores when the world map closes.
- **Quest Companion** is the visible product name. Use `/qc` or `/questcompanion`; the old commands still work. Resources replace the Priest panel and follow the character's current resource. The chosen-spell editor is removed; its saved data is retained. No rotation management is added.
- **Existing appearance controls stay:** independent 0-100% background/content opacity, 50-150% scale, hidden titles, separate Healing/Leveling layouts and Compact/Undo. Resources are optional on new profiles; Compact preserves their existing visibility.
- **Upgrade handling:** existing Priest-panel placement, opacity and visibility migrate to a compact Resources panel without deleting old layout keys or spell data. Existing Resources settings take priority.

## Use the navigation controls

Enter `/qc locations next`, then plain left-click a Questie title. Choose `/qc locations all` or `/qc locations hide` to change the selected quest's mode. `/qc locations off` restores normal Questie behavior; `/qc locations on` re-enables the saved mode. These controls also appear in `/qc show quests`. After configuring, `/qc hide quests` leaves the tracker bridge active.

The adapter checks the inspected Questie 12.8/12.9 interface family and required methods at runtime. Source inspection covered 12.8.0 and 12.9.0; it is not evidence of live compatibility with every patch or another addon's modifications. Unsupported shapes, missing pins, combat/controller input and modified clicks retain Questie's normal handling. Our own rows fall back to quest details without replacing a personal waypoint. Next is coordinate proximity, not a route optimizer.

## Update

1. Download **QuestCompanion-0.2.0-alpha.1.zip**, the installable asset.
2. Exit WoW. Move the existing `PriestCompanion` folder outside the Forever client's `Interface\AddOns` directory as a backup.
3. Extract the new archive and put its **PriestCompanion** folder in `Interface\AddOns`. Keep the existing `WTF` folder and saved settings.
4. At character selection, open **AddOns** and enable **Quest Companion**. Enter the world and type `/qc`.

The legacy folder, TOC filename and `PriestCompanionDB` save key are deliberate upgrade compatibility details. Do not rename the folder or install both old and new copies. All recommended companion addons are separate; no third-party addon code or database is bundled.

## Validation and next session

**1,687 offline assertions passed** with 12 addon Lua files parsed. The checks cover the actual helper row actions, mode controls, title-wrapper reuse, strict selected-quest filtering, map-close restoration, disabling, redraws, combat resumption, resource switching and additive layout migration. See [VALIDATION.md](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.1/docs/VALIDATION.md) for exact executed results.

**The new bridge has not been tested inside WoW.** Native rendering, taint/secure execution, combat coexistence and cold-start saved-file loading remain pending. Use [FRESH-LOGIN-CHECKLIST.md](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.1/docs/FRESH-LOGIN-CHECKLIST.md), starting with checks 1-6. If needed, `/qc locations off` disables only the bridge; disabling Quest Companion from character selection is the full recovery step.

This release does not include the separate incomplete dungeon checklist prototype in [PR #1](https://github.com/amhost/priest-companion/pull/1). For now, use the installed DungeonJournal for dungeon quests and Questie for locations. The prototype's 18 entries do not yet justify an Available/ready-before-run claim.

Bug reports: client build, Questie and QuestieDB versions, exact click sequence, expected/actual result, whether combat was active, and `/qc diagnostics`. The report omits character names and personal lists. Source is MIT licensed; no telemetry or external updater.
