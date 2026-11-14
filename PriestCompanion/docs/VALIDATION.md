# Validation record

Version: **0.2.0-alpha.2**. Executed November 14, 2026 (UTC). Environment: managed Linux workspace, Python 3, `liblua5.4.so.0` through the standard-library ctypes runner. No WoW client was available.

## Executed checks

Run from the source project root in Bash:

```bash
python3 tools/check.py
git diff --check
```

Observed test output:

```text
PASS: syntax for 17 addon Lua files (Lua 5.4 parser)
PASS: goals_cases.lua
PASS: quest_kill_cases.lua
PASS: gameplay_cases.lua
PASS: appearance_cases.lua
PASS: native_style_cases.lua
PASS: migration_cases.lua
PASS: quest_navigation_cases.lua
PASS: questie_bridge_cases.lua
PASS: guide_cases.lua
PASS: quick_menu_cases.lua
PASS: guide_waypoints_cases.lua
PASS: guide_ui_cases.lua
PASS: integration, layouts, combat queue, secret guards and diagnostics
PASS: 2236 assertions in offline Lua 5.4 + bounded WoW UI/API mocks
NOT TESTED: actual WoW client, secure execution, rendering, combat restrictions, locale behavior or live saved-file loading
```

`git diff --check` passed with no whitespace errors. This count includes the production TOC, isolated providers, and actual menu/helper/guide callbacks. It is an assertion count, not 2,236 independent gameplay scenarios.

## New behavior covered

- Questie 12.6.5's callable-table LibStub registry, deliberately without modern HBD/HBDPins module entries; the existing 12.9 module fixture; exact legacy version and provider-shape guards. Unsupported 12.6.4 and 12.6.6 remain rejected.
- Visible provider failures and real minimap menu callbacks, including Guide, Settings, location modes, normal Questie clicks, launcher dragging and combat guards.
- Native-font selection and shadows, stock control templates, gold selection states, disabled states, transparent new panels, saved opacity preservation and borderless locked gameplay panels. These are structural/style assertions, not observed native rendering.
- All 33 guide actions and stable IDs, the 15 source-step references, Priest/Warlock scroll expansion, other-class manual reminders and the supplied coordinate provenance.
- Readable acceptance, whole-quest readiness and completed-history distinctions. Ready-to-turn-in does not satisfy a turn-in action. Missing/secret/partial evidence stays unknown. Travel, training, partial kill/loot and grave interactions remain manual.
- Manual Done/Skip/Undo, Back/Resume, saved selection, pooled rows, tooltips installed once, row clicks and multiple-marker requests. Review findings for long rows and Map after Hide have regression cases.
- Guide provider discovery, area-to-map conversion, explicit route coordinates, live unfinished objective preference and future DB fallback. NPC, object and item sources include bounded cycle handling; phased locations require readable verified visibility.
- Independent world/minimap frames, nearest-point and successive route anchors, coincident-position grouping, the 24-location cap, unknown/partial/capped reporting, combat deferral and cleanup after partial drawing or map-opening errors. Other owners' pins and the personal waypoint are not changed in the bounded fixtures.

## Existing regression coverage

The suite retains Questie title reuse and click fallbacks, temporary selected-quest filtering, map-close restoration and combat resumption. It also retains Resources/current-power behavior, additive layout migration, goals and delete/undo, carried-count bank exclusions, manual versus automatic kill provenance, localized named XP parsing, quest normalization, guarded spell lookup, macro validation, preparation summaries, optional NPC quest acceptance and Shift/combat/special-offer guards.

Appearance checks cover independent 0% opacity, input-focus release, configuration recovery, scaled placement, temporary edit handles, separate layouts and Compact/Undo. Existing notes, shopping data, spell rollback data, zero-opacity values, SavedVariables identity, binding IDs and aliases remain intact in the fixtures.

The tests do not emulate secure execution, taint, native rendering, mouse hit testing, native locale behavior or actual saved-file loading. Source aims for Lua 5.1-compatible syntax, but only Lua 5.4 was parsed/executed here. Inspection of provider source is not proof of native compatibility.

## Native evidence and remaining checks

The user supplied an **alpha.1** diagnostic reporting:

- Client **1.60.1 / 70938**, interface and addon target **16001**, locale **enUS**.
- Quest log, item API and secret-value guard available; XP message event registered.
- **Questie 12.6.5 / DB 1.0.14 unavailable**, despite enabled Next mode; the old adapter supported only the newer families.
- **Module errors: 0**.

This is evidence for the prior build's reported load state and rejection reason. It does not establish alpha.2 rendering, navigation, secure execution or saved-file behavior. All alpha.2 native checks in [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md) remain pending. The Deathknell sequence, current offers and supplied coordinates also require in-game confirmation; see [DEATHKNELL-SOURCES.md](DEATHKNELL-SOURCES.md).

To disable only tracker interception, choose **minimap map icon > Normal Questie clicks**. To clear guide markers, choose **Guide > Hide** or close the guide. For a complete disable, use **character selection > AddOns > Quest Companion**, uncheck it and log in. Keep the saved settings and code backup described in the checklist.

## Packaging

Run from the source project root in Bash:

```bash
python3 tools/build.py
```

The build checks case-correct manifest paths and dependency load order, absence of the obsolete Priest module, UTF-8 source, XML syntax, required guide/control documents, ZIP path boundaries and archive integrity. It creates deterministic install/source archives and SHA-256 sums. Release publication separately verifies remote source blobs, commit parent, tag target, uploaded asset sizes and digests. Those checks do not complete native gameplay validation.
