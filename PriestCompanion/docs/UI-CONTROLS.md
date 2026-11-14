# Quest Companion controls

For **0.2.0-alpha.3**. Start with the **map icon beside the minimap**. Routine guide, quest-location and appearance controls are available by clicking; slash commands are optional. Make configuration changes outside combat.

## Start from the minimap

| Action | Click path |
| --- | --- |
| Open the quick menu | Left-click the minimap map icon. Click it again to close the menu. |
| Show or hide the leveling guide | Minimap map icon > **Guide**, or right-click the icon directly. |
| Show or hide our quest list | Minimap map icon > **Quest Helper**. |
| Open the panel manager | Minimap map icon > **Settings**. Check a panel's name to show it in the current layout. |
| Configure all gameplay panels | Minimap map icon > **Settings > Appearance**. |
| Configure one panel | Minimap map icon > **Settings**, then **Appearance** beside that panel. |
| Move or resize panels | Minimap map icon > **Unlock panels**. Drag a title or bottom-right grip, then use **Lock panels**. |
| Move the minimap icon | Drag the icon around the minimap. Its angle is saved. |
| Copy diagnostics | Minimap map icon > **Settings > Diagnostics**, then **Ctrl+A**, **Ctrl+C** in the copy dialog. |

The menu shows whether Questie navigation is ready and gives a reason when it is unavailable. A saved **enabled** preference does not establish that the provider loaded successfully. If the minimap is unavailable, `/qc menu` opens the quick menu and `/qc` opens Settings.

## Deathknell leveling guide

Open **Guide** to use **Deathknell 1-6**. The supplied 15 numbered instructions are split into **33 checklist actions**, so accepting, completing and turning in a quest can advance separately. The heading retains the original instruction number; the progress counter counts checklist actions.

For a Priest, the guide uses **Hallowed Scroll (3097)** and **Dark Cleric Duesten**. For a Warlock, it uses **Tainted Scroll (3099)** and **Maximillion**. Other classes receive a manual reminder to follow their actual starter quest. This is a route draft for in-game checking, not a claim that every supplied quest or coordinate is verified on Forever. See [DEATHKNELL-SOURCES.md](DEATHKNELL-SOURCES.md) for the correction and location provenance.

| Guide control | Behavior |
| --- | --- |
| **Back** | Review the preceding action without changing its progress. |
| **Done** | Mark the displayed action done after performing it, then continue. |
| **Skip** | Skip the displayed checklist action, then continue. It does not complete a game quest. |
| **Undo** | Reverse the most recent manual Done or Skip and return to that action. It cannot undo an actual quest acceptance or turn-in. |
| **Resume** | Return to the earliest unfinished action and resume following readable quest progress. |
| **All steps** | Show the full scrollable checklist. The button changes to **Upcoming steps** to return to the compact list. |
| Checklist row | Review that action. When guide markers are enabled and a location is available, also open its map. |

Acceptance, whole-quest readiness and turn-in actions can advance from readable quest evidence. A ready-to-turn-in quest is not treated as turned in. Travel, training, reminders, looting Samuel Fipps's skull and the grave interaction require **Done** after performing them. Unknown progress remains unavailable until readable evidence or your manual mark resolves it. Done and Skip only update this checklist; neither performs a game action.

### Guide markers and multiple waypoints

| Guide control | Marker behavior |
| --- | --- |
| **Current** | Show mapped locations for the displayed action and open the relevant map. |
| **Route** | Show numbered locations for the displayed action plus later unfinished actions, up to 24 unique markers. |
| **Hide** | Remove this guide's markers from the world map and minimap. Questie icons keep their own settings. |
| **Map** | Open the displayed action's map using the selected marker mode. After Hide, Map switches back to Current and updates the selected control. |

Several actions at one coordinate share a marker; hover it to see the visits and source. The status line reports unmapped, partly mapped or capped steps. Pickup and turn-in points use the loaded provider; supplied coordinates remain labeled route hints. Missing locations do not become invented pins. The route is a checklist order, not a computed walking path or a guarantee that every quest is currently offered. Your personal map waypoint remains unchanged.

Closing the Guide panel clears its own markers. Reopening it restores its saved mode and progress. Guide markers require Questie map support, but the written checklist and manual controls remain usable without it.

## Click a Questie quest title to navigate

Choose **minimap map icon > Quest locations > Next**, then plain left-click a quest title in Questie's tracker on the right side of the screen. Choosing the mode alone does not open a map. With a ready provider and a supported location, clicking the title opens the map at one nearest unfinished checkpoint, or a finisher when the quest is ready to turn in.

The same navigation is available by clicking a row in our **Quest Helper**. Shift-click that row or use **Details** for quest details. Objective text expands only for the selected quest; there is no permanent location-source footer or extra Map button.

| Quick-menu control | Clicked quest behavior |
| --- | --- |
| **Hide** | Open the map with that quest's supported Questie location icons temporarily hidden. |
| **Next** | Show one nearest supported unfinished checkpoint, or one supported finisher when complete. |
| **All** | Show the supported rendered locations for unfinished objectives, or supported finishers when complete. |
| **Normal Questie clicks** | Disable our tracker-click adapter and restore Questie's existing clicks and icon behavior. |

Quest Helper also provides **Hide**, **Next**, **All**, and the **Questie title clicks** checkbox. Choosing a location mode enables the adapter; the checkbox can disable it. These preferences apply in both layouts even when Quest Helper is hidden. Questie's Shift-click, Ctrl-click, Alt-click and right-click actions remain its own.

These controls filter the **clicked quest**, using Questie's valid rendered pins. All does not expand every raw database spawn, override clustering or hidden-icon preferences, or establish complete database coverage. Locations in other zones appear on their respective maps. Nearest is a coordinate comparison, not the shortest walkable route.

Closing the world map restores Questie's normal icon display; the chosen mode stays saved for the next quest click. Restoration waits until combat ends if necessary. The adapter does not rewrite Questie's saved icon preferences or replace your personal waypoint. This temporary Questie filter is separate from the Guide's **Current / Route / Hide** markers.

The adapter checks **Questie 12.6.5, 12.8.x and 12.9.x** and the required interfaces. Missing or unsupported providers leave Questie's original tracker actions available. Our Quest Helper falls back to quest details, or a readable objective copy panel if the details helper is unavailable. Check the quick-menu status or **Settings > Diagnostics** for the detected versions and failure reason.

## Native style, opacity and scale

Gameplay panels use the client's fonts, gold headings and white text. Locked panels have no border or colored title strip. Configuration windows use stock WoW controls and visible native borders. New gameplay panel settings start with **0% background opacity**; existing saved opacity values are retained when upgrading.

Open **minimap map icon > Settings**, then **Appearance** beside the panel you want to change.

| Appearance control | Behavior |
| --- | --- |
| **Prev / Next** | Select All panels or an individual gameplay panel. |
| **Background opacity** | 0-100%, in 1% steps. Changes the backdrop independently of text and bars. Locked gameplay borders remain hidden. |
| **Content opacity** | 0-100%, in 1% steps. Changes bars, text and interactive content. At 0%, the body is hidden and releases input focus. |
| **Scale** | 50-150%, in 1% steps. Preserves the screen center subject to screen clamping. |
| **Hide title when locked** | Hide the title and close button while locked. Unlocking exposes them for editing. |

For partly visible resource bars, choose **Appearance** beside **Resources**, set **Background opacity** to 0%, choose the desired **Content opacity**, and enable **Hide title when locked**. Finish with **minimap map icon > Lock panels** if panels are unlocked. Mixed means selected panels have different values.

Unlocking temporarily reveals editing bounds and readable content without overwriting saved opacity. The extra title space is removed on locking. Configuration and copy windows remain readable, so **minimap map icon > Settings > Appearance** can recover fully transparent gameplay panels. The locked outer shell does not consume mouse clicks; visible controls still work.

Appearance values, placement and panel visibility are separate for **Healing** and **Leveling**, selected in **Settings**. Text size and cursor tooltips apply to both layouts. Short configuration windows scroll. Combat blocks configuration and guide actions, removes editing handles, and leaves Questie's tracker behavior in place; controls recover after combat.

### Compact layout and Resources

**Settings > Compact layout** applies 80% scale, 0% background opacity, 85% content opacity and hidden titles to the active layout. Leveling shows Quest Helper; Healing shows Dungeon preparation. Resources stays visible if it was already visible. Other gameplay panels, including Guide, are hidden by this preset and can be reopened from the minimap menu or Settings.

**Settings > Undo layout** restores the arrangement saved before the latest Compact layout or Reset layout. Applying either again replaces that single undo copy. Goals, notes, checklist entries and tracking data remain saved.

**Resources** contains health and the character's current power, such as mana, rage or energy. It starts hidden on a fresh installation; upgrading carries forward the former Priest panel's position and visibility. It does not contain a spell reference or leveling-resource database. The removed chosen-spell data remains saved for rollback.

## Optional chat commands

Enter these in WoW chat. `/pc` remains an alias for `/qc`.

| Command | Action |
| --- | --- |
| `/qc` | Open Settings / the panel manager. |
| `/qc menu` | Toggle the quick menu. |
| `/qc guide` | Show the leveling guide. |
| `/qc show resources` | Show Resources. |
| `/qc appearance resources` | Open appearance controls for Resources. |
| `/qc locations next` | Enable Next mode; click a quest afterward. Also accepts hide, all, off, or on. |
| `/qc diagnostics` | Open the copyable status report. |

Follow [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md) for native checks. Actual Forever rendering, input behavior, secure execution and saved-file loading remain pending until observed in the client.
