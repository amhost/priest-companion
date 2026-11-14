# Deathknell leveling guide

Open **Quest Companion's minimap button > Guide** to follow the supplied Deathknell 1-6 checklist. The 15 original instructions are split into **33 actions**, so accepting a quest, doing its objectives, and turning it in can advance separately.

## Open and arrange it

- **Left-click the map icon beside the minimap > Guide** to show or hide the panel. **Right-click the minimap icon** is the direct show/hide shortcut.
- **Drag the minimap icon** to move it around the minimap.
- To move or resize the guide, **left-click the minimap icon > Unlock panels**, drag the guide's title or lower-right resize grip, then return to the menu and click **Lock panels**.
- If the minimap icon is unavailable, enter `/qc guide` in chat. The panel starts hidden and saves its visibility separately for each layout.

Use navigation and progress controls outside combat. The first action is leaving the crypt: do that, then click **Done**. That travel instruction has no map pin.

## Checklist controls

| Control | Result |
| --- | --- |
| **Done** | Mark the displayed action manually complete and continue forward. It does not perform the action in the game. |
| **Skip** | Move past the displayed action with a separate skipped mark. It does not complete its quest. |
| **Undo** | Restore the previous manual Done/Skip state and show that action. It cannot undo a quest you completed in the game. |
| **Back** | Review the previous action without changing progress. |
| **Resume** | Return to the earliest unfinished action and follow readable quest progress again. |
| **All steps** | Show the whole checklist. Click a row to review it and, when markers are enabled, open its mapped location. **Upcoming steps** returns to the shorter list. |

Selecting a row or using Back pauses automatic advancement while you review it. Done or Skip continues from that selected action; Resume returns to the earliest unfinished action. Selecting a later row does not mark the earlier rows complete.

Progress is saved per character. The action count includes automatically confirmed actions, manually completed actions, and skipped actions; skipped rows retain their **[Skip]** label.

## What advances automatically

Acceptance advances when the quest is in your log or already completed. A whole-quest objective action advances when the quest is ready to turn in or already completed. A turn-in advances only when the character's completed-quest history confirms it. Actions naming several quests require confirmation for all of them.

Travel, training, reminders, looting Samuel Fipps's skull, and clicking the grave require **Done** after you perform them. Missing or restricted quest information remains unavailable, so check the action before marking it manually.

The class starter quest is **Hallowed Scroll (3097)** for Priests and **Tainted Scroll (3099)** for Warlocks. Other classes receive a manual reminder to follow the starter quest actually offered to them. The route is for the Undead starting area in Tirisfal Glades.

## Multiple guide markers

| Guide button | Result |
| --- | --- |
| **Map** | Open the map for the displayed action when a location is available. If markers were hidden, switch to Current. |
| **Current** | Show mapped locations for the displayed action. One action can have several locations. |
| **Route** | Show numbered locations for the displayed action and later unfinished actions, up to **24 distinct markers**. |
| **Hide** | Remove the guide's own world-map and minimap markers. |

Questie and QuestieDB must be enabled and ready for guide mapping. Locations at the same position share a marker; hover it to see the associated instructions. The status line reports unmapped actions and the marker limit. These are ordered checklist hints, not a calculated walking path or a guarantee that a quest is currently available. Your personal waypoint is preserved. Hiding the guide panel also removes its markers.

The quick menu's **Quest locations > Hide / Next / All** controls apply separately to clicked Questie tracker quests. The guide's own map controls are **Current / Route / Hide**.

## Forever validation and adding more guides

The five coordinate pairs are preserved from the supplied route. Their Tirisfal map context was checked, but the locations and complete route still need validation in **Forever 1.60.1 / build 70938**. The final **A Rogue's Deal** action retains supplied quest ID **8**; confirm the quest actually offered in game. A database page alone does not verify that current offer. See [sources and verification limits](DEATHKNELL-SOURCES.md).

This release contains one bundled guide. Another checklist can be converted into guide data with travel, accept, objective, turn-in, interaction, training, and reminder actions. Item or book interactions can be manual checklist actions. There is no freeform paste/import editor or automatic route generator in this build.
