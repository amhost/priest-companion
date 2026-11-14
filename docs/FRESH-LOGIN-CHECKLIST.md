# Quest Companion: fresh-login checklist

Prepared for **0.2.0-alpha.1**. These are expected results to check in the actual Forever client. **Every check below is pending until observed in game.** Offline tests do not complete this checklist.

**Existing feedback:** the user reported that the parts they knew to check seemed to work. The exact checks, client build and coverage were not specified. Record that as an informal smoke report, not a full pass for this release.

Use **Pass**, **Fail** or **Not tested** in the Result column. If no suitable quest or situation is available, use Not tested. Enter slash commands in WoW chat one line at a time, outside combat unless the check explicitly says otherwise.

## Before the first login

Close WoW. In **Battle.net > World of Warcraft > World of Warcraft: Forever**, use **the gear beside Play > Show in Explorer**, then open the installed Forever client's **`Interface > AddOns`** folder containing your existing addons.

Move the old **`PriestCompanion`** folder outside AddOns as a code backup, then copy the update's **`PriestCompanion`** folder into AddOns. The display name is now Quest Companion; the internal folder, SavedVariables name and binding identifiers remain unchanged so existing settings can load. Keep the `WTF` folder. Do not create a second `QuestCompanion` installation beside it.

At **character selection > AddOns**, enable **Quest Companion**, Questie, QuestieDB and your other installed companions. Log into the character whose existing settings you want to retain.

## Five-minute smoke check

| Result | Check | Exact action | Pass result |
| --- | --- | --- | --- |
| ☐ Pending | 1. Load and identity | Enter `/qc`, then `/qc diagnostics`. | The manager says Quest Companion; diagnostics identify 0.2.0-alpha.1 and the client build. Module errors are zero. One copy of our UI appears. |
| ☐ Pending | 2. Existing data and aliases | Inspect your existing checklist, goals and notes. Enter `/qc show resources`. Close the manager and enter `/pc`. | Existing entries remain. Resources shows health and the character's current resource without the chosen-spell editor. `/pc` opens the same manager as `/qc`. |
| ☐ Pending | 3. Compact appearance and recovery | Enter `/qc compact`, then `/qc lock`. Enter `/qc appearance resources`; set Background to 0%, Content to 50%, then Content to 0%. Enter `/qc unlock`, restore Content to 85%, and enter `/qc lock`. | The background disappears independently of the bars. Configuration stays readable. Unlocking recovers the invisible panel's editing controls; locking returns to the chosen appearance. |
| ☐ Pending | 4. Direct click and Next | Enter `/qc locations next`. Plain left-click an incomplete quest title in Questie's tracker on the right side of the screen. Also enter `/qc show quests` and click that quest's row in our Quest Helper. | Either click opens the map at one supported nearest unfinished checkpoint for that quest. No separate Map-button click is needed. Other quests keep their existing icon behavior. |
| ☐ Pending | 5. All checkpoints | Enter `/qc locations all`, then click a quest with multiple supported rendered locations for unfinished objectives. | The clicked quest's supported unfinished pins are available on their respective maps, with completed objectives excluded. Questie's clustering and existing hidden-icon preferences still apply. A quest with only one known location cannot establish that All works for multiple locations. |
| ☐ Pending | 6. Hide, map close and Off | Enter `/qc locations hide`, then click the same tracked quest. Close the map with its X and reopen with **M** (the default Map key). Next enter `/qc locations off` and click the title again. | Hide temporarily suppresses the clicked quest's supported Questie location icons only. Closing the map restores Questie's normal icon display. Off restores its existing tracker-click behavior. Questie's saved icon preferences remain unchanged. |

The location checks concern the clicked quest's checkpoint behavior. Compare that quest's markers before and after each mode. The adapter selects from Questie's valid rendered pins; All does not expand every raw database spawn or override Questie's clustering, phase checks or hidden-icon preferences. Closing the map clears the temporary filter, but the selected mode remains saved for the next click. Nearest is a location selection, not a guarantee of the shortest walkable route.

## Longer checks during normal play

| Result | Check | Exact action | Pass result |
| --- | --- | --- | --- |
| ☐ Pending | 7. Movement and separate layouts | Enter `/qc unlock`, drag and resize Resources, then `/qc lock`. Change its scale in `/qc appearance resources`. Use `/qc layout healing` and `/qc layout leveling` to arrange each differently. | Unlock/lock does not grow or shift the panel. Scaling preserves its screen center except when a screen edge forces clamping. Each layout retains its own arrangement. |
| ☐ Pending | 8. Objective progress and turn-in | Enter `/qc locations next`, finish one objective during ordinary play and click that quest again. When a quest becomes ready to turn in, click its tracked title again. | Selection advances past finished objectives. A finished quest uses a supported rendered finisher location. Missing finisher data restores Questie's original tracker action; our Quest Helper opens details. |
| ☐ Pending | 9. Existing click actions | Compare Shift-click, Ctrl-click, Alt-click and right-click on a tracked quest with the behavior you normally use in Questie. | The adapter changes the supported plain-left title click only. Questie's other actions remain available; no click produces two competing map/navigation actions. |
| ☐ Pending | 10. Missing location | Click a quest for which no valid current checkpoint is supplied, or repeat with a quest that previously had no location. Try `/qc locations next` and `/qc locations all` before each click. | There is no invented 0,0 marker, stale checkpoint from the previous quest or Lua error. Your personal waypoint is unchanged. The tracker retains Questie's action; our Quest Helper opens details, or readable objective text if the details helper is unavailable. |
| ☐ Pending | 11. Reload | Choose a location mode and appearance values, then enter `/reload`. Repeat one plain-left tracker click. | Settings persist and one click performs one navigation action. The adapter is not installed twice after reload. |
| ☐ Pending | 12. Full restart | Use **Escape > Exit Game**, start Forever again and log into the same character. | Location mode, appearance, layouts, goals, checklist and notes remain. This checks saved-file loading beyond `/reload`. |
| ☐ Pending | 13. Combat | During ordinary combat, click a tracked quest and request the other layout using `/qc layout healing` or `/qc layout leveling`. If a filtered map was already open, close it. Leave combat normally. | No forbidden-action or Lua error occurs. Tracker clicks use Questie's existing action. The queued layout applies after combat; any pending icon restoration completes, and a later normal click can navigate again. |
| ☐ Pending | 14. Provider missing | Log out to **character selection > AddOns**. Disable Questie and QuestieDB together, log in, then open `/qc` and `/qc diagnostics`. After the check, log out, re-enable both and log back in. | Our addon remains usable and reports the unavailable integration without an error loop. Re-enabling the provider restores supported tracker integration. Missing provider data does not become invented locations or confirmed availability. |
| ☐ Pending | 15. Other installed addons | With the full installed set enabled, repeat the map click while OpenMap is active and open an ordinary quest offer with Dialogue UI. Check `/qc diagnostics` after normal questing. | The correct map remains visible, the adapter adds no duplicate marker layer, and the quest offer remains usable. Our existing auto-accept preference is retained. Module errors remain zero. |
| ☐ Pending | 16. Rollback readiness | Confirm the previous `PriestCompanion` folder is saved outside AddOns. If this update causes a problem, follow the rollback steps below. | The previous code is available without deleting saved settings or other addons. If rollback was not needed, record readiness only; do not mark a native rollback test passed. |

## Rollback if needed

1. For an immediate disable, log out to **character selection > AddOns**, uncheck **Quest Companion**, then log in again.
2. To restore the previous code, close WoW completely. In the same Forever **`Interface > AddOns`** folder, move the updated **`PriestCompanion`** folder outside AddOns and copy the saved previous folder back.
3. Start Forever and enable the restored addon at **character selection > AddOns**.

This restores addon code. It does not undo settings changed during testing. Keep `WTF` and any existing settings backup; do not delete them to troubleshoot a display problem.

## Separate experimental dungeon checks

The dungeon prototype in **PR #1** is separate from this release. Run these only after intentionally installing a build containing that prototype. Its existing commands below use the legacy `/pc` prefix.

| Result | Check | Exact action | Pass result |
| --- | --- | --- | --- |
| ☐ Pending | 17. Character progress | Enter `/pc dungeons deadmines`. Compare a known accepted quest, a ready-to-turn-in quest and a previously turned-in quest with your actual log/history. | Accepted and ready-to-turn-in quests remain In Log; historical character completion shows Completed. Unresolved evidence shows Unknown. An accepted prerequisite is not treated as turned in. |
| ☐ Pending | 18. Pickup and coverage | Inspect a missing quest's giver and reported predecessor; visit that giver when practical. Select the other supported dungeons with `/pc dungeons thanes` and `/pc dungeons ragefire`. | Known restrictions remain visible, partial coverage stays explicit, and zero Missing rows does not become an all-ready verdict. Record the actual NPC offer or unmet requirement before treating a provisional relationship as verified. |

## Record a failure

Record the check number, expected and observed result, whether combat was active, the quest ID/title if relevant, and the output of **`/qc diagnostics`**. Include the Questie/QuestieDB versions and location mode shown by the new diagnostics. If an error dialog appears, copy its exact text. A screenshot of the map and tracker helps distinguish incorrect location data from incorrect marker display; crop names or chat you do not want to share.
