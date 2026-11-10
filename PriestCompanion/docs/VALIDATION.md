# Validation and first in-game run

## Executed offline checks

Date: November 10, 2026. Environment: managed Linux workspace, Python 3, installed `liblua5.4.so.0` through ctypes. No third-party Python packages are used by the check runner.

Command, run from the source project's root:

```bash
python3 tools/check.py
```

Observed result:

```text
PASS: syntax for 10 addon Lua files (Lua 5.4 parser)
PASS: goals_cases.lua
PASS: quest_kill_cases.lua
PASS: gameplay_cases.lua
PASS: integration, layouts, combat queue, secret guards and diagnostics
PASS: 333 assertions in offline Lua 5.4 + bounded WoW UI/API mocks
NOT TESTED: actual WoW client, secure execution, rendering, combat restrictions, locale behavior or live saved-file loading
```

Coverage includes localized kill-message formats, unnamed-XP rejection, invalid input, manual/automatic provenance, quest normalization, missing map context, optional APIs, goals and delete/undo, bank-exclusion flags, learned-spell states, macro-input validation, equipment and bag summaries, scaled layout persistence, separate profile state, combat deferral, deleted-checklist persistence, copy-dialog focus and scrolling, secret-resource pass-through and exclusion from saved state, and private-data exclusion from diagnostics. Quest acceptance checks cover default-off behavior, checkbox persistence, hidden-panel event handling, Shift bypass, combat, repeated events, special offers, giver filtering, missing APIs, API errors and restricted values.

The mocks deliberately do not emulate Blizzard's secure execution or native rendering. A pass is not evidence that the addon is already compatible with a live client. Source uses Lua 5.1-compatible syntax, but only the Lua 5.4 parser/runtime has been exercised here.

## First in-game verification

Install with the README instructions. Keep this an alpha until the checks below have observed results.

### 1. Identify the client

Inside WoW, press Enter, paste the following line, and press Enter:

```lua
/run local v,b,d,t=GetBuildInfo(); print("Version:",v,"Build:",b,"Date:",d,"Interface:",t)
```

Record the printed version, build and interface. The declared target is 16001. A different interface requires a compatibility review; do not change the TOC just to silence a mismatch.

### 2. Load and arrange

Enter `/pc`. Open each of the seven feature panels from the manager. Enter `/pc unlock`, drag each title, and resize each panel from its bottom-right grip. Enter `/pc lock`. Expected: the panels stay where placed, inputs and buttons remain visible, and locked panels do not move.

### 3. Verify both layouts and persistence

Use `/pc layout healing`, arrange it, then use `/pc layout leveling` and arrange it differently. Switch between them. Expected: each arrangement returns independently.

Add one checklist entry, one personal reference note and one manual shopping goal. Use `/reload`. Expected: those items and both layouts persist. Next, use **Escape > Exit Game**, restart the same Forever client, and log in to the same character. Expected: the saved items and layouts still persist. A reload alone does not establish cold-start persistence.

### 4. Verify the feature panels

| Area | Exact action | Result that matters |
| --- | --- | --- |
| Priest | Open `/pc show priest`, add a spell currently in the spellbook, observe health and mana outside and during ordinary play | Display works without Lua errors; references identify the correct client spell |
| Quest Helper | Open `/pc show quests`, select an existing quest, click Details and Map | Correct objective text; a provided location opens, or missing location is stated |
| Quest acceptance | In `/pc show quests`, confirm **Auto-accept NPC quests** starts unchecked. Enable it and open an ordinary NPC quest offer. For the next offer, hold Shift before opening it. Disable the checkbox when finished. | Enabled ordinary acceptance works outside combat; Shift keeps an offer open for reading; disabled acceptance stays manual. No automatic gossip selection, turn-in or reward choice. Missing APIs show an unavailable message. |
| Preparation | Open `/pc show prep`, add/check/remove an entry, compare equipment and bags with the native UI | Manual marks stay manual; general-bag and equipment summaries are accurate or explicitly partial |
| References | Open `/pc show keys`, compare a known main-bar binding, enter a learned helpful spell and click View / copy | Correct binding and spell text; copying does not create a macro automatically |
| Goals | Open `/pc show goals`, add a target using a known carried item's ID or link, then change the carried quantity during normal play | Carried and remaining counts update; manual completion stays independent; Delete/Undo restores the selected row |
| Kills | Open `/pc show kills`, note counts, defeat one ordinary XP-granting creature, then add one manual target | At most the supported XP-credit event adds an automatic count; the manual action adds only a manual count |
| Interface | Open `/pc show appearance`, increase text size and adjust opacity; enable cursor tooltips and hover an ordinary item outside combat | Text remains readable, controls remain usable, and the tooltip option is reversible |

### 5. Verify combat deferral and coexistence

During ordinary combat, request the other layout with `/pc layout healing` or `/pc layout leveling`. Expected: the arrangement remains stable during combat and changes afterward. Check that no forbidden-action or secret-value errors appear.

Complete a normal questing or dungeon session with the other addons you normally use. Inspect `/pc diagnostics`. Expected: zero module errors and usable panels. Record any conflict with the exact other addon and version rather than assuming compatibility from the offline tests.

### Recovery

If a layout is inconvenient, use `/pc resetlayout`; `/pc restorelayout` undoes the last reset. If this alpha causes game UI problems, log out to character selection, choose **AddOns**, uncheck **Priest Companion**, and log back in. This disables the addon without deleting its saved settings or your game data.

## Packaging checks

The build script verifies that every manifest entry exists with exact path casing, that Lua source is UTF-8, that the binding XML parses, that required documents are present and that generated ZIP paths stay under their intended top-level directory. It writes SHA-256 hashes for the distributable and source archives. These archive checks are separate from gameplay validation.
