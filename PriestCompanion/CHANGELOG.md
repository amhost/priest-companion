# Changelog

## 0.2.0-alpha.1

- Renamed the visible product Quest Companion and added /qc and /questcompanion while retaining legacy commands and saved identity.
- Replaced the Priest panel with optional health/current-resource bars. Removed the chosen-spell editor, retained saved spell data, and kept generic mouseover references.
- Added an additive old-panel-to-Resources layout migration with rollback data and existing destination preference preserved.
- Added a guarded Questie tracker-title bridge: plain click opens a selected quest's checkpoint map. Hide / Next / All temporarily filter existing supported pins; map close and disabling restore normal behavior.
- Preserved Questie's modifier/right-click/controller/combat fallback and avoided copying its database, adding another pin layer or changing its saved preferences.
- Made Quest Helper rows navigate with one click, collapsed unselected objectives, and removed the separate Map button and permanent location footer.
- Removed the fallback personal-waypoint setter, which could overwrite the player's point or leave a stale duplicate beside Questie pins. Unavailable bridge navigation opens ordinary quest details.
- Added pooled-frame, redraw, map restoration, combat-resume, click-flow and migration regressions plus a fresh-login checklist. New native game behavior remains pending.

## 0.1.0-alpha.2

- Replaced opacity buttons with independent background/content sliders from 0-100%, in 1% steps, for one panel or all gameplay panels.
- Added a 50-150% scale slider with stable screen positioning, hidden titles while locked, and a health/mana-only Priest view.
- Added an explicit Compact layout preset: 80% scale, transparent backgrounds, 85% content, and two visible gameplay panels. Undo layout restores the prior arrangement.
- Made background opacity cover the header and border. Zero-opacity content releases input focus. Unlock temporarily restores editing handles without changing saved opacity, size or position.
- Kept Appearance, the manager and copy dialog readable independently. Reworked configuration into smaller, scrollable panels with per-panel Appearance access.
- Preserved existing layouts until the user changes them or applies Compact layout. Added a manual companion-addon installation guide.
- Added offline coverage for slider callbacks, exact zero opacity, recovery, stable scale, compact undo and persistence. Native Forever rendering and behavior remain untested.

## 0.1.0-alpha.1

- Added independent movable and resizable panels with saved per-character settings.
- Added Healing and Leveling layouts, lock controls, per-panel scale and visibility, and recoverable layout resets.
- Added Priest information, Quest Helper, Dungeon preparation, Keybind and mouseover references, Professions & Shopping, Kill Tracker and Interface preferences.
- Added optional NPC quest auto-accept, initially off, with Shift bypass and guards for combat, shared/unknown givers, special offers and unavailable data.
- Added guarded API access, explicit unavailable/partial-data messages, and out-of-combat layout changes.
- Added direct-install packaging, a privacy-limited diagnostic report, original source, MIT license and offline regression checks.
- Native WoW Forever testing is pending for this first alpha.
