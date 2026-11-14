# Quest Companion controls

For **0.2.0-alpha.1**. Enter commands in WoW chat, one line at a time. `/qc` opens the panel manager; the existing `/pc` alias still works. Appearance controls style Quest Companion's own panels.

## Compact layout and optional Resources

Outside combat, enter:

```text
/qc compact
/qc lock
```

The active layout receives 80% scale, 0% background opacity, 85% content opacity and hidden titles. Leveling shows Quest Helper; Healing shows Dungeon preparation. Compact keeps Resources visible if it was already visible in that layout. Other gameplay panels can be reopened from `/qc`.

Resources contains health and the character's current power, such as mana, rage or energy. It starts hidden on a fresh installation. Upgrading carries forward the old Priest panel's visibility and position. The chosen-spell editor and bars-only switch are removed; Resources always contains the two bars. Old chosen-spell data remains saved for rollback.

To show and configure Resources:

```text
/qc show resources
/qc appearance resources
```

Enter `/qc restorelayout` to undo the latest Compact layout or Reset layout. Applying either again replaces the single undo copy. Layout changes retain notes, goals, checklist entries and tracking data.

## Configure a panel

Enter `/qc`, then choose **Appearance** beside the panel, or enter `/qc appearance resources` directly. The legacy `/pc appearance priest` command selects Resources too.

| Control | Behavior |
| --- | --- |
| Panel selection | Prev/Next cycles through All panels and each gameplay panel. |
| Background opacity | 0-100%, in 1% steps, for the background, border and title strip. |
| Content opacity | 0-100%, in 1% steps, for bars, text and interactive content. |
| Scale | 50-150%, in 1% steps. Scaling preserves the screen center subject to screen clamping. |
| Hide title when locked | Hides the title and close button while locked. |

For partially visible bars on a transparent background, open `/qc appearance resources`, set **Background opacity** to 0%, set **Content opacity** to the percentage you want, enable **Hide title when locked**, then enter `/qc lock`. Mixed means the selected panels have different values.

Controls scroll when the configuration window is short. Appearance, the panel manager and the copy dialog remain readable and are excluded from gameplay opacity/scale changes. Appearance values and placement are separate for Healing and Leveling; font size and cursor tooltips apply to both layouts.

## Click a quest once to navigate

Enter `/qc locations next`, then plain left-click a quest title in Questie's tracker. With a supported Questie version and valid rendered location data, the map opens on one nearest unfinished checkpoint. When the quest is ready to turn in, it uses a finisher location. Shift-click, Ctrl-click, Alt-click and right-click on Questie's tracker retain Questie's existing actions.

The same direct navigation is available by clicking a quest row in our Quest Helper. Enter `/qc show quests` to open it. Shift-click a row for details, or use its **Details** button. The separate Map button and the permanent location-source footer have been removed. Objective text expands only for the selected quest.

Use the **Hide**, **Next** and **All** buttons beside **Locations** in Quest Helper, or these commands:

| Command | Selected quest behavior |
| --- | --- |
| `/qc locations hide` | Opens the quest map with that quest's supported Questie location icons temporarily hidden. |
| `/qc locations next` | Shows one nearest supported unfinished checkpoint, or one finisher for a completed quest. |
| `/qc locations all` | Shows all supported rendered locations for unfinished objectives, or supported finishers when complete. |
| `/qc locations off` | Disables the adapter and restores Questie's existing tracker-click and icon behavior. |
| `/qc locations on` | Re-enables the adapter using the previously selected Hide, Next or All mode. |

Choosing Hide, Next or All enables the adapter. The **Questie title clicks** checkbox also enables or disables it. These settings apply in both layouts and remain active when our Quest Helper panel is hidden.

### What the location modes cover

The filter applies to the clicked quest only. Other quests and unrelated icon categories keep Questie's behavior. The adapter uses Questie's existing rendered pins, respecting its clustering, phase checks and hidden-icon preferences. **All does not expand every raw database spawn**, restore icons that Questie has hidden, or establish that the database covers every location. Locations in different zones appear on their respective maps. Nearest means a coordinate comparison, not a calculated walking route.

The filter is temporary: closing the world map restores Questie's normal icon display, while the chosen mode stays saved for the next quest click. It does not change Questie's saved icon settings or add another layer of duplicate pins. If the map is closed during combat, restoration waits until combat ends.

The adapter checks Questie 12.8.x/12.9.x and the required interfaces. Unsupported versions or unavailable data leave tracker clicks with Questie. In our Quest Helper, disabled or unavailable navigation opens ordinary quest details in every mode. If the client has no compatible details helper, it opens readable objective text in a copy panel. Your personal map waypoint is preserved. Enter `/qc diagnostics` for the detected Questie/QuestieDB versions, enabled state, location mode and any integration failure.

## Move and recover

Enter `/qc unlock`, drag a title or bottom-right grip, then enter `/qc lock`. Unlocking temporarily reveals a readable title and content even when saved opacity is zero. The temporary title space is removed when locked and is not saved as a larger panel.

At 0% content opacity, the body is hidden and releases input focus. The locked outer shell does not consume mouse clicks; visible functional controls retain their interaction. `/qc` and `/qc appearance` remain available for recovery.

Appearance, compact-layout and navigation-mode changes are blocked in combat. Combat removes temporary editing controls; they return afterward if panels remain unlocked. Questie's tracker keeps its own click behavior during combat.

## Verify in the game

Follow [FRESH-LOGIN-CHECKLIST.md](FRESH-LOGIN-CHECKLIST.md), starting with its six smoke checks. The checks cover opacity, direct quest navigation, Hide versus Off, map-close restoration, saved settings and coexistence with installed addons. Native rendering, mouse hit testing, secure execution and saved-file loading remain pending until observed in the actual client.
