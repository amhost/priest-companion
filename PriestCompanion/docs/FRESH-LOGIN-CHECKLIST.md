# Quest Companion: fresh-login checklist

Prepared for **0.2.0-alpha.3**, targeting the reported **Forever 1.60.1 / build 70938 / interface 16001 / enUS**, with **Questie 12.6.5 / QuestieDB 1.0.14**. Record different versions if the installed client or addons have changed. **Every check below remains pending until observed in game.** Offline tests do not complete this checklist.

The alpha.1 report established displayed versions and zero module errors, but navigation was unavailable. The later alpha.2 screenshot showed the settings UI and Questie failing in `InitializeQueue` with `C_Timer.NewTicker` bad argument #2. The user reported that Questie reloaded after disabling Quest Companion. Alpha.3 removes the conflicting hook; all hotfix results remain pending.

## Reload regression first

1. Exit WoW normally, install alpha.3 using the folder replacement below, then enable **Quest Companion**, **Questie**, and **QuestieDB** at **character selection > AddOns**.
2. Log in and wait for Questie to finish loading. Confirm the previous `C_Timer.NewTicker` / `InitializeQueue` error does not appear.
3. Press **Enter**, type `/reload`, press **Enter**, and wait for loading to finish. Repeat once. Both reloads should complete without that error.
4. Use **minimap map icon > Quest locations > Next**, then click a tracked Questie title. Repeat with **All** and **Hide**. Open **Guide > Route** to check numbered guide markers. Finish at **Settings > Diagnostics** and confirm version **0.2.0-alpha.3**.
5. If the same startup error returns, use **character selection > AddOns** to disable **Quest Companion**, then log in again. Keep the error screenshot and copy the diagnostic report if available.

A passing reload confirms this scenario on the reported installation, not every rendering or combat check below.

Use **Pass**, **Fail** or **Not tested** in the Result column. Use Not tested when no suitable quest or situation is available. Start outside combat. Routine actions below use the minimap menu; optional recovery and diagnostics commands are at the end.

## Install while WoW is closed

In **Battle.net > World of Warcraft > World of Warcraft: Forever**, use **the gear beside Play > Show in Explorer**, then open the installed client's **Interface > AddOns** folder containing your existing addons.

Move the old **PriestCompanion** folder outside AddOns as a code backup, then copy the update's **PriestCompanion** folder into AddOns. Keep the **WTF** folder. Do not install a second QuestCompanion folder beside it. The display name is Quest Companion; the internal folder, saved-variable name and bindings remain unchanged so existing settings can load.

At **character selection > AddOns**, enable **Quest Companion**, Questie, QuestieDB and the other installed companions. Log into the character whose settings you want to retain. For route-progress checks, use an Undead character with unfinished Deathknell quests; an older character can still check the UI and review the route.

## Start here: six smoke checks

In this table, **map icon** means Quest Companion's map icon beside the minimap.

| Result | Check | Exact action | Pass result |
| --- | --- | --- | --- |
| ☐ Pending | 1. Load, provider and identity | Left-click **map icon > Settings > Diagnostics**. Copy the report with **Ctrl+A**, **Ctrl+C**. Close it, then reopen the map-icon menu. | Report says **0.2.0-alpha.3**, records the client and addon versions, and has zero module errors. With Questie ready, the quick menu says **Questie navigation ready**. An enabled-but-unavailable status includes a reason and is not a pass for navigation. One copy of the UI appears. |
| ☐ Pending | 2. Guide and class correction | Click **map icon > Guide > All steps**. Inspect original steps 05 and 06, then right-click the map icon twice. | **Deathknell 1-6** opens with 33 checklist actions derived from 15 source instructions. A Priest sees **Hallowed Scroll / Dark Cleric Duesten**; a Warlock sees **Tainted Scroll / Maximillion**. Other classes get a manual reminder. Right-click hides and reopens the guide without typed commands. |
| ☐ Pending | 3. Multiple guide locations and Hide | In **Guide > All steps**, select the Samuel Fipps action, then click **Current**, **Route**, **Hide**, and **Map** in that order. Hover a numbered route marker before hiding it. | Current maps that action; Route shows multiple supported remaining locations with numbered tooltips and an honest unmapped/partial count. Hide clears only guide-owned markers. Map after Hide restores **Current**, its selected state, markers and map. An unavailable provider gives a visible reason instead of a stale pin. |
| ☐ Pending | 4. Questie title clicks and modes | Choose **map icon > Quest locations > Next**, then click an incomplete quest title in Questie's tracker. Repeat with **All** on a quest with several supported locations, then **Hide**. Close the map with its X, reopen with **M** if that is your Map binding, then choose **Normal Questie clicks** and click the title again. | Next uses one supported unfinished checkpoint; All exposes that quest's supported unfinished locations. Hide temporarily filters that quest's icons; closing the map restores their normal display. Normal Questie clicks restores its original action. Selecting a mode alone does not open the map. Other quests keep their behavior. |
| ☐ Pending | 5. Native appearance and recovery | Use **map icon > Settings**, check **Resources**, then choose **Appearance** beside it. Set **Background opacity** to 0%, **Content opacity** to 50%, then 0%. Use **map icon > Unlock panels**, restore Content to 85%, enable **Hide title when locked**, then **Lock panels**. | The bars fade independently of the background. Gold/white native-font text and stock settings controls replace purple chrome. Settings remain readable. Unlock recovers editing controls for invisible panels; locking removes the editing border. Existing saved opacity was not reset merely by installing the update. |
| ☐ Pending | 6. Existing data, launcher and reload | In **Settings**, inspect existing checklist, goals and notes. Drag the map icon to a new minimap position. Choose a guide marker mode and a Questie location mode, then enter `/reload` and reopen Guide. | Existing entries remain; Resources contains health/current power only. Launcher position, selected guide action, manual marks, guide marker mode, Questie mode and appearance persist. One click performs one action after reload. |

Guide **Current / Route / Hide** draws and clears this guide's numbered markers. Questie **Hide / Next / All** temporarily filters the clicked quest's existing supported rendered pins. These are separate controls. All respects Questie's clustering, phases and hidden-icon preferences; a quest with only one location cannot test multiple-location behavior. Route markers are hints, not a computed walking path or proof that a quest is available.

## Focused checks during normal play

| Result | Check | Exact action | Pass result |
| --- | --- | --- | --- |
| ☐ Pending | 7. Manual guide progress | In Guide, select a travel or reminder action you have already performed. Click **Done**, then **Undo**. Click **Skip**, then **Undo**, and finally **Resume**. Use **Back** once to review a preceding action. | Done/Skip advance the checklist and are distinguishable. Undo reverses the last manual mark and returns to that action. Resume selects the earliest unfinished action; Back only reviews. None of these accepts, completes or turns in a game quest. |
| ☐ Pending | 8. Automatic quest evidence | On an unfinished Deathknell route, accept a listed quest normally, finish its objectives, then turn it in. Observe the guide at each stage. For a combined action such as The Damned plus Rattling the Rattlecages, leave one quest unfinished before completing both. | Acceptance, whole-quest readiness and turn-in advance only with readable evidence. Ready to turn in is not turned in. Combined actions require every listed quest. Travel, training, Fipps's skull and grave interaction still require a manual mark. Missing evidence is unavailable rather than automatically complete. |
| ☐ Pending | 9. Wrapping, movement and layouts | Use **map icon > Unlock panels**. Narrow and enlarge Guide with its bottom-right grip; inspect a long row in **All steps**, such as the spell-training instruction at step 06. Move Guide, then **Lock panels**. Use **Settings > Healing / Leveling** and set different panel arrangements. | Long checklist rows wrap to their full text without overlap or a one-line cutoff. Titles/grips permit movement and resizing; locking does not grow or shift panels. Native appearance remains usable at both sizes. Layouts retain separate visibility, scale and placement. |
| ☐ Pending | 10. Personal waypoint and missing locations | If the client supports personal waypoints, open the map with its configured key and use **Ctrl+left-click** to place one; note its location. In Guide, use **Current > Route > Hide**, then repeat Questie's **Next > All > Hide** on a quest. Also select an action or quest with no known location. | The personal waypoint remains at the same location. No invented 0,0 pin, previous quest's checkpoint or Lua error appears. Guide reports missing coverage; Questie retains its original action when navigation cannot resolve, and our Quest Helper opens details or readable objective text. If this client lacks personal waypoints, record that subcheck as Not tested. |
| ☐ Pending | 11. Quest progress and other clicks | Choose **map icon > Quest locations > Next**. Finish an objective and click its tracked title; repeat when the quest is ready to turn in. Also compare Shift-click, Ctrl-click, Alt-click and right-click with normal Questie behavior. Open **map icon > Quest Helper** and click the same quest row. | Next skips completed objectives and uses a supported finisher when ready. Missing finisher data falls back cleanly. Modified clicks keep Questie's actions without duplicate navigation. Our Quest Helper provides direct navigation, and Shift-click or **Details** still opens details. |
| ☐ Pending | 12. Combat and recovery | Open Guide and the quick menu before ordinary combat. During combat, inspect disabled controls and click a tracked Questie title. If a filtered map is open, close it. Leave combat, then repeat **Guide > Map** and a Next-mode quest-title click. | Guide/menu changes are blocked, editing handles disappear, and Questie keeps its own tracker behavior. No forbidden-action or Lua error occurs. Pending marker updates/cleanup finish after combat, controls recover, and navigation works again. |
| ☐ Pending | 13. Provider unavailable | Log out to **character selection > AddOns**, disable Questie and QuestieDB together, and log in. Open **map icon > Guide**, then the quick menu. Afterward, log out, re-enable both addons and log back in. | The written checklist/manual controls remain usable. Navigation states a reason for being unavailable; there is no error loop, invented location or claim that enabled means ready. The re-enabled provider can become ready and restore navigation. |
| ☐ Pending | 14. Full restart and coexistence | Use **Escape > Exit Game**, restart Forever and log into the same character with the installed addon set enabled. Open Guide and a quest map while OpenMap is active; open a normal quest offer with Dialogue UI. Finish at **map icon > Settings > Diagnostics**. | Saved settings, guide progress, goals and notes survive a full restart. The correct map stays visible; guide and Questie markers remain distinguishable without duplicate guide layers. Quest dialogue and the existing auto-accept preference remain usable. Module errors remain zero. |

The supplied coordinates and quest offers still need checking in this exact client. In particular, compare the Fipps/cave/grave locations with what is actually present, and verify the offered **A Rogue's Deal** quest in source step 15. A marker drawing successfully does not establish that the NPC or quest is there. Record mismatches rather than marking the route verified.

The separate [dungeon prototype in PR #1](https://github.com/amhost/priest-companion/pull/1) is not included in this package; its eligibility checks are outside this release checklist.

## Recovery and rollback

If the icon is unavailable, enter one optional command at a time in WoW chat:

```text
/qc menu
```

Use `/qc` for Settings, `/qc guide` to show Guide, `/qc appearance` to recover transparent gameplay panels, and `/qc diagnostics` for the report. `/pc` remains an alias. **Settings > Undo layout** reverses the most recent Compact layout or Reset layout; it does not reset guide progress or notes.

For an immediate disable, log out to **character selection > AddOns**, uncheck **Quest Companion**, then log in. To restore the previous code:

1. Close WoW completely.
2. In the same **Interface > AddOns** folder, move the updated **PriestCompanion** folder outside AddOns and copy the saved previous folder back.
3. Start Forever and enable the restored addon at **character selection > AddOns**.

Keep **WTF** and any settings backup. Code rollback does not undo settings changed while testing. Confirm that the old code folder is available; only mark an actual rollback test passed if you performed it.

## Record a failure

Record the check number, the exact click path, expected and observed results, whether combat was active, and the quest ID/title or guide source-step number. Open **map icon > Settings > Diagnostics** and copy the report with **Ctrl+A**, **Ctrl+C**. Include the client, Questie/QuestieDB versions, provider readiness and location mode. If an error dialog appears, copy its exact text. A screenshot showing the tracker, guide controls and map helps distinguish a missing location from a display problem; crop names or chat you do not want to share.
