# Missing dungeon quests: prototype review

Built November 12, 2026 against upstream source
[523ef3d885df95af9dd463fcc621b7ee267d4bbd](https://github.com/amhost/priest-companion/commit/523ef3d885df95af9dd463fcc621b7ee267d4bbd).
This isolated prototype is unpublished. No release or installable archive was built.

**Result:** a new opt-in movable panel compares a small dungeon catalog with
character progress. **523 offline assertions pass.** No dungeon membership, pickup
requirement, coordinate or native Forever behavior has been live-verified by this
work. It is not yet an exhaustive pre-run quest checklist.

## Proposed behavior

Open **/pc**, then enable **Dungeon quests (prototype)**. Direct commands:
**/pc dungeons deadmines**, **/pc dungeons thanes**, **/pc dungeons ragefire**.
Previous/Next selects a dungeon; Refresh retries missing client data; Sources
opens the exact source revision and license information. Use **/pc unlock** to
move/resize and **/pc lock** to finish. Shared layout, opacity and scale controls
continue to apply.

| Progress | Required evidence | Meaning |
| --- | --- | --- |
| In Log | Readable IsOnQuest=true, or a positive log index when IsOnQuest is unavailable | Accepted, including ready to turn in. Takes precedence for active repeatables. |
| Completed | Character IsQuestFlaggedCompleted=true, without positive in-log evidence | Historical character completion. Repeatable availability is not assessed. |
| Missing | IsOnQuest=false AND IsQuestFlaggedCompleted=false AND a nonempty client-resolved title | Absent from log/history. Does not mean available for pickup. |
| Unknown | Missing, failed, restricted, malformed or unresolved required client data | Absence unproven. A community title cannot satisfy the client-title check. |

Pickup eligibility is separate. Known faction/level conflicts say **Blocked
(catalog)** and stay visible. Missing metadata says **Unknown**. The engine
supports explicitly reviewed mandatory ALL and alternative ANY prerequisite
groups. Only completion satisfies them; acceptance is insufficient. It uses
three-valued logic and never recursively walks chains or invents predecessor data.

All shipped predecessor relationships are advisory. ATT sourceQuest/sourceQuests
annotations are displayed with character progress but are not converted into
mandatory gates: breadcrumbs and alternative semantics need verification.
Omitted prerequisites do not mean none. Class, race, reputation, profession, item,
exclusivity, maximum-level and repeatable constraints are not fully modeled.
Every seed has requirementsComplete=false, so none claims confirmed availability.

Partial coverage is always visible. Zero Missing, all Completed, empty catalogs
and unsupported dungeons never produce an all-ready verdict. Item-started quests
have explicit notes; The Unsent Letter is not a pre-entry pickup. The panel does
not accept/turn in quests, place waypoints or mark the manual checklist.

## Sources and licensing

| Source | Finding | Decision |
| --- | --- | --- |
| [AllTheThings Forever](https://github.com/ATTWoWAddon/AllTheThings/tree/3ed4599270cee01575393b1a62e543dc9e32fa2f/.contrib/.db/forever/dungeons%20%26%20raids) | Pinned repository [license is MIT](https://github.com/ATTWoWAddon/AllTheThings/blob/3ed4599270cee01575393b1a62e543dc9e32fa2f/LICENSE). Dungeon files contain IDs, factions, levels, givers and predecessor annotations. | Selected 18 community records. Full upstream notice in PriestCompanion/LICENSE-ATT.txt. |
| [tyler3497/forever-quests](https://github.com/tyler3497/forever-quests/blob/9f4c5aac2d077854d7f4a2bdc2f8eceb8d7b23af/README.md) | v1.3.0 documents 4,630 quests/96 zones, live-verification gaps and GPLv3 derivation from QuestieDB, TrinityCore and NorgannonDB. | No records or converter code incorporated. |
| [Dungeon Quest Atlas](https://github.com/Pirson-s-Addons/DungeonQuestAtlas/blob/main/LICENSE) | Current notice prohibits reuse without written permission, with separate exceptions for libraries and older releases. | Current data/code excluded. Historical MIT terms do not establish permission for current additions. |
| Client APIs | Provide state/titles for known IDs. Inspected contracts do not promise an exhaustive dungeon catalog or pickup eligibility. | Runtime observations only; no packaged Blizzard database. |

MIT compatibility does not allow relabeling GPL-derived material as MIT. The
[GNU FAQ](https://www.gnu.org/licenses/gpl-faq.html#WhatDoesCompatMean) describes
distribution of compatible combined programs under GPL. This prototype avoids
that combination. Future GPL use requires a separately reviewed approach or
permission from relevant rights holders; a separate Lua file alone does not
resolve the question.

All selected facts come from ATT revision
**3ed4599270cee01575393b1a62e543dc9e32fa2f**, inspected November 12:

| Dungeon and exact source | Included IDs | Git blob |
| --- | --- | --- |
| [The Deadmines](https://github.com/ATTWoWAddon/AllTheThings/blob/3ed4599270cee01575393b1a62e543dc9e32fa2f/.contrib/.db/forever/dungeons%20%26%20raids/the%20deadmines.lua) | 168, 92753, 92819, 167, 214, 166, 373, 2040 | bfed917a9d14324d9df883442edb4ac6d29cc533 |
| [Hall of Thanes](https://github.com/ATTWoWAddon/AllTheThings/blob/3ed4599270cee01575393b1a62e543dc9e32fa2f/.contrib/.db/forever/dungeons%20%26%20raids/hall%20of%20thanes.lua) | 96395, 96403, 96393, 96394, 98423 | b3cd94acd223ccc1dd5d5fc09965fd13fa04a194 |
| [Ragefire Chasm](https://github.com/ATTWoWAddon/AllTheThings/blob/3ed4599270cee01575393b1a62e543dc9e32fa2f/.contrib/.db/forever/dungeons%20%26%20raids/ragefire%20chasm.lua) | 5728, 5722, 5761, 5723, 5725 | cee1dc938f3107acd326a890532f75b29d85022a |

Ragefire follow-ups 5729, 5730 and 5724 were omitted from this small prototype.
Neither the subsets nor their source files establish exhaustive live coverage.
Community titles are fallbacks until localized client titles resolve. Pickup
hints are plain text, not map pins. No lore, objective prose, rewards, maps,
artwork or source addon implementation was copied.

## Client API basis

Inspected Blizzard-generated documentation mirrored by Gethe/wow-ui-source:

- [Forever QuestLogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/4cd0ab752a77164f654ccbca9d0c1fe8dafceebe/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua), pinned at 4cd0ab752a77164f654ccbca9d0c1fe8dafceebe: IsOnQuest, IsQuestFlaggedCompleted, GetLogIndexForQuestID, IsComplete, GetTitleForQuestID, RequestLoadQuestByID and QUEST_DATA_LOAD_RESULT.
- [Forever QuestLineInfoDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLineInfoDocumentation.lua): available lines by map and quests in a known line. Not a completeness contract.

GetQuestsOnMap returns POIs and may return nothing; omitted POIs do not establish
absence. Account completion is never substituted for character completion. Nil
log indices do not prove absence. Client title resolution proves neither dungeon
assignment nor availability.

Each unresolved catalog/predecessor ID gets one load request per session, capped
at 64 IDs per dungeon; Refresh permits a retry. The synchronous data-load event
cannot create a retry loop. State refreshes on events while the panel is shown,
pauses in combat with a stale-data label, and is never persisted as completion
history. No scanning arbitrary quest IDs or external data downloading occurs.

## Implementation and executed checks

| File | Purpose |
| --- | --- |
| PriestCompanion/Data/DungeonQuests.lua | Small catalog, provenance, pickup hints and advisory predecessors |
| PriestCompanion/DungeonQuestStatus.lua | Pure model and guarded transient API snapshot |
| PriestCompanion/Modules/DungeonQuests.lua | Optional panel, selection, events and bounded data loading |
| PriestCompanion/LICENSE-ATT.txt | Upstream attribution |
| PriestCompanion/PriestCompanion.toc | Three loads in dependency order |
| tests/dungeon_quest_cases.lua; tests/run.lua | Focused model and UI/event regressions |

**LOW uncertainty within this scope:** Linux, Python 3, installed Lua 5.4 shared
library and bounded WoW UI/API doubles, November 12, 2026.

- **523 assertions pass**, versus the baseline's 333; all 13 addon Lua files parse.
- Cases include tri-state progress, account/character separation, active
  repeatables, turn-in readiness, faction/level boundaries, missing metadata,
  ALL/ANY prerequisites, unresolved IDs, secret/error returns, delayed/synchronous
  data loads, retry bounds, hidden/combat behavior, selection persistence and
  movement/layouts.
- Checklist contents/checks and the auto-accept preference are preserved.
- Independent source audit matches all 18 IDs, titles, factions, levels,
  giver/item IDs, predecessor annotations and supplied coordinates to the pinned
  ATT blobs; the MIT notice is preserved verbatim.
- Manifest paths/order, XML and git diff whitespace checks pass.
- Core.lua, UI.lua, Modules/Quests.lua and Modules/Preparation.lua are
  byte-identical to the hash-verified upstream snapshot.

Exact read-only verification in this managed Linux workspace:

~~~bash
cd /workspace/scratch/ea56526ecc1e/priest-companion
python3 tools/check.py
python3 /workspace/scratch/ea56526ecc1e/research/audit_catalog.py
git diff --check
~~~

The standalone audit checks the fetched reference files' Git blob IDs first.
No packaging tool was run. The local baseline uses 36 hash-verified GitHub blobs;
its tree matches upstream **57816dcd196369e86ed226e19961f87887f3e96e**.
The local snapshot commit is not upstream history. On approval, apply this diff
to a branch based on the real upstream commit, rather than pushing the local
snapshot ancestry.

## Remaining risks and live test

**HIGH uncertainty: native Forever behavior is untested.** Offline tests do not
prove native Lua compatibility, protected-value enforcement, rendering, quest
cache timing or saved-file persistence. False completion during initialization
needs a live check. No record becomes verified merely because its title resolves.
Community minimum levels, locations and gates can be stale or incomplete.

After approval and installation of the reviewed source, run these in game chat:

~~~text
/dump GetBuildInfo()
/pc dungeons deadmines
/dump C_QuestLog and C_QuestLog.IsOnQuest and C_QuestLog.IsOnQuest(168)
/dump C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted and C_QuestLog.IsQuestFlaggedCompleted(168)
/dump C_QuestLog and C_QuestLog.GetTitleForQuestID and C_QuestLog.GetTitleForQuestID(168)
~~~

1. Compare quest 168 with actual log and turn-in history. Nil/failed reads must
   show Unknown; accepted/ready to turn in must show In Log; historical completion
   must show Completed. Resolved false/false may show Missing with unknown pickup
   eligibility. Check before/after normal acceptance and turn-in when applicable.
2. Select Hall of Thanes and Ragefire Chasm. Wrong-faction rows must show Blocked
   (catalog), and every dungeon retains partial/provisional warnings. Cross-check
   actual NPC offers before relying on hints. Record build, faction, level, quest
   ID, giver and observed gates.
3. Use /pc unlock, drag title and bottom corner, /pc lock, then /reload. Check
   selection/placement and original checklist/auto-accept settings. Enter/leave
   combat normally: stale rows must be labeled and then refresh. Open /pc
   diagnostics for any module error.

Do not mark these checks passed from mocks. Stop catalog expansion until the
panel runs without errors, states match the character and one dungeon's offers
and gates have been checked. Full chain traversal, worldwide coverage, routing,
scraping and external updates remain outside scope. CurseForge is not required.

## Approval boundary

Proposed next action: apply the reviewed changes to a new branch from current
upstream main and open a draft PR titled **Prototype missing dungeon quest panel
with provisional MIT catalog**. Recheck main first. Explicit user approval is
required. Releases and modified-addon package distribution require separate
approval and have not been performed.
