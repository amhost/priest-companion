# Validation record

Version: **0.2.0-alpha.1**. Executed November 14, 2026 (UTC). Environment: managed Linux workspace, Python 3, `liblua5.4.so.0` through the standard-library ctypes runner. No WoW client was available.

## Executed checks

Run from the source project root in Bash:

```bash
python3 tools/check.py
git diff --check
```

Observed test output:

```text
PASS: syntax for 12 addon Lua files (Lua 5.4 parser)
PASS: goals_cases.lua
PASS: quest_kill_cases.lua
PASS: gameplay_cases.lua
PASS: appearance_cases.lua
PASS: migration_cases.lua
PASS: quest_navigation_cases.lua
PASS: questie_bridge_cases.lua
PASS: integration, layouts, combat queue, secret guards and diagnostics
PASS: 1687 assertions in offline Lua 5.4 + bounded WoW UI/API mocks
NOT TESTED: actual WoW client, secure execution, rendering, combat restrictions, locale behavior or live saved-file loading
```

`git diff --check` passed with no whitespace errors. The count includes the production TOC loading the bridge, isolated bridge fixtures and the actual Quest Helper row/control callbacks. It is an assertion count, not 1,687 independent game scenarios.

## New behavior covered

- Plain helper-row click requests navigation once for that row's quest ID. Shift/right-click opens details. Unselected objectives collapse. Missing/disabled bridge falls back without creating a personal waypoint or directly selecting the native map frame.
- Hide / Next / All and off/on retain their distinct meanings. Invalid modes and combat edits do not silently change settings.
- Questie pooled title reuse, current quest identity, modifier/right-click/controller fallbacks, required methods/version guards and partial installation failure.
- One supported world pin plus its minimap twin in Next; selected-quest-only filtering; unfinished objectives and finishers; existing native hidden-icon preferences; no new marker layer or Questie saved preference changes.
- Map-close restoration, switching quests, disabling, frame unload/reuse, new pins after redraw, third-party method replacements and combat resumption.
- A reviewer reproduced a combat issue where native redraw revealed filtered pins and the post-combat handler failed to reapply the selection. The fixed regression independently returned Next/Hide/All to 1/0/3 world pins in the bounded fixture.
- Resources uses current power type and has no chosen-spell editor. The generic spell helper still serves non-priest mouseover references.
- Both old layouts and the saved undo layout migrate additively. Existing Resources preferences take precedence. Legacy spell data, notes, goals, empty checklists, zero-opacity values, SavedVariables identity, binding IDs and aliases remain intact.

## Existing regression coverage

The suite retains goals and delete/undo, carried-count bank exclusions, manual versus automatic kill provenance, localized named XP parsing, quest normalization, guarded spell lookup, macro-input validation, preparation summaries, optional NPC quest acceptance and its Shift/combat/special-offer guards. Appearance coverage includes independent 0% opacity, input-focus release, configuration recovery, scaled placement, temporary edit handles, separate layouts, Compact/Undo and combat deferral.

The tests deliberately do not emulate secure execution, taint, native rendering, mouse hit testing, native locale behavior or actual saved-file loading. Source aims for Lua 5.1-compatible syntax, but only Lua 5.4 was parsed/executed here. Inspection of a provider's source is not proof of the user's installed version or native compatibility.

## Native status and checklist

The user reported that the portions of the earlier build they tried seemed to work. No exact client build or enumerated checks accompanied that feedback. It is an informal smoke report for the prior build, not a completed pass for this new adapter.

Every native check in [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md) remains pending. Start with checks 1-6: identity/data, appearance recovery, direct click, multiple checkpoints, Hide, map close and Off. Later checks cover real quest completion, full restart, combat and coexistence with OpenMap/Dialogue UI. The separate dungeon prototype checks do not apply to this package.

For an integration-only recovery, enter `/qc locations off`. For a complete disable, use **character selection > AddOns > Quest Companion**, uncheck it and log in. Retain the saved settings and code backup described in the checklist.

## Packaging

Run from the source project root in Bash:

```bash
python3 tools/build.py
```

The build checks case-correct manifest paths and load order, absence of the obsolete Priest module, UTF-8 source, XML syntax, required documents, ZIP path boundaries and archive integrity. It generates the install/source archives and SHA-256 sums. Release publication separately verifies the exact remote source blobs, commit parent, tag target, uploaded asset sizes and digests. Those packaging checks do not complete native gameplay checks.
