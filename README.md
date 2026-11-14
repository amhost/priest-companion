# Quest Companion

Questie navigation, a Deathknell leveling guide, and movable utility panels for every class in World of Warcraft: Forever.

**Version: 0.2.0-alpha.2.** Targets interface **16001**. Adds support for the reported **Questie 12.6.5 / DB 1.0.14** setup, alongside the guarded 12.8/12.9 family. The previous alpha rejected 12.6.5. The new release passes offline Lua and mocked API checks; **alpha.2 has not yet been tested inside WoW Forever**. Actual rendering, protected-value behavior, saved-variable loading and coexistence with other addons remain to be checked in the game.

Questie supplies the optional checkpoint navigation. The remaining panels can load without it. No addon manager or external service is required. Original source is included and free under the MIT license.

[Download alpha.2](https://github.com/amhost/priest-companion/releases/tag/v0.2.0-alpha.2) | [Report a bug](https://github.com/amhost/priest-companion/issues/new?template=bug_report.yml)

**Start without chat commands:** left-click the new map icon beside the minimap, then choose **Guide**, **Quest Helper**, or **Settings**. Right-click the icon to toggle the guide. Drag it around the minimap to reposition it. The menu's **Quest locations > Next / All / Hide** controls apply when you next click a tracked Questie quest title. **Normal Questie clicks** restores the original handling.

**Guide markers:** open **Guide**, then choose **Current** for the displayed action or **Route** for multiple numbered locations. **Hide** clears this guide's markers. The checklist has **Back / Done / Skip / Undo / Resume** controls and a clickable **All steps** view. See [Leveling guide](docs/LEVELING-GUIDE.md).

**Quick compact setup:** enter `/qc compact`. This shows the layout's quest or preparation panel, sets 80% scale, removes backgrounds, and leaves content at 85%. Resources stay optional and retain their previous visibility. `/qc restorelayout` undoes it. Existing arrangements are preserved until you choose the preset.

**Fine tune a panel:** choose **minimap map icon > Settings > Appearance**, or use a panel's **Appearance** button in the manager. Background and content opacity each run from 0% to 100%; scale runs from 50% to 150%. The purple treatment is replaced by game font paths, gold/white tracker text and stock controls. Fresh gameplay panels have transparent backgrounds; existing saved opacity stays unchanged. See [UI controls](docs/UI-CONTROLS.md) and the [fresh-login checklist](docs/FRESH-LOGIN-CHECKLIST.md).

## Features

| Feature | Alpha behavior |
| --- | --- |
| Movable panels | Unlock, drag the title, resize from the bottom-right corner, and lock again. Position, size, scale, opacity and visibility are saved per layout. Movement and layout changes wait for combat to end. |
| Resources | Optional compact health and current-resource bars. Mana, rage, energy and other resource types follow the character. No chosen-spell editor or rotation manager. Restricted values are used only in supported display setters. |
| Deathknell guide | The supplied 15-part level 1-6 route becomes 33 checklist actions. Readable quest acceptance, whole-quest readiness and completed history can advance their corresponding actions. Travel, training and individual interactions use Done. Priest and Warlock starter scrolls are distinct. |
| Multiple guide locations | Current / Route / Hide controls create up to 24 numbered world-map and minimap locations. Shared positions use one marker with an action list. Missing locations are reported. Your personal waypoint and other addons' markers remain separate. |
| Quest Helper | One click on a quest row or supported Questie tracker title opens its checkpoint map. Hide / Next / All controls use the clicked quest's existing Questie pins. Optional NPC quest auto-accept, with Shift bypass, defaults off. |
| Healing and Leveling layouts | Two independent arrangements. Switching layouts changes this addon's panels, not talents or gameplay bindings. |
| Dungeon preparation | Editable manual checklist, minimum equipment durability, broken-item count, and general bag-space summary. Combat shows the last out-of-combat snapshot. |
| Keybind and mouseover references | Actual bindings for the 12 main action buttons, personal notes, and copyable mouseover macro text for a spell you select. |
| Professions and shopping | Manual goals and item-quantity targets, categories, editing, manual completion and delete/undo. Readable carried inventory is compared with your target. Bank storage and charges are excluded. |
| Kill Tracker | Automatic named XP-credit kills, separate manual labeled kills, session and all-time counts, and target notes. Coverage is explicitly partial. |
| Appearance | Background/content opacity and scale sliders for one or all gameplay panels, hidden titles while locked, font sizing, optional cursor tooltips, and native Edit Mode access. |

## Install without an addon manager

1. Exit the game normally.
2. In Battle.net, select World of Warcraft and the **WoW: Forever** game version. Use the gear menu beside Play to **Show in Explorer**.
3. Open that client's `Interface\AddOns` directory. Create `Interface` and then `AddOns` only if they do not exist.
4. Extract the release ZIP. Copy its **PriestCompanion** folder into `AddOns`.
5. The file directly below the copied folder must be `PriestCompanion\PriestCompanion.toc`. Avoid an extra ZIP-name folder between `AddOns` and `PriestCompanion`.
6. Start Forever. On the character-selection screen, open **AddOns** and enable **Quest Companion** for the character.
7. Enter the world and left-click the map icon beside the minimap. Choose **Guide** or **Settings**. The manager opens automatically on a fresh profile. If the icon is unavailable, `/qc` opens the manager and `/qc guide` opens the guide.

If updating, exit the game and move the old `PriestCompanion` folder to a backup location outside `AddOns`, then copy the new folder into `AddOns`. The internal `PriestCompanion` folder and `PriestCompanionDB` save name intentionally remain unchanged for this upgrade; do not rename the folder or install a second copy. Keep your `WTF` folder and saved settings. This avoids stale addon files while retaining a recoverable code backup.

## Arrange the panels

Choose **minimap map icon > Unlock panels**, drag each panel by its title, and resize with the bottom-right grip. Choose **Lock panels** when finished. Hidden titles and zero-opacity panels temporarily reveal editing handles when unlocked. The manager's **Appearance** buttons open the sliders for each panel.

Choose **Healing** or **Leveling** in the manager to arrange that layout separately. A new Healing layout shows Dungeon preparation and Keybind references. A new Leveling layout shows Quest Helper, Professions & Shopping and Kill Tracker. Resources are optional. Existing Priest-panel placement is copied to Resources on upgrade, including its visibility, scale and opacity; the removed editor no longer reserves its old height. Every feature panel can be enabled in either layout.

Choose **Compact layout** to show Quest Helper in Leveling, or Dungeon preparation in Healing. An already-visible Resources panel stays visible. Other panels remain available in the manager. **Undo layout** restores the single arrangement saved before the latest Compact layout or Reset layout action. These actions keep goals, notes and kill history. Old chosen-spell data is retained for rollback, although its editor has been removed.

## Commands

| Command | Action |
| --- | --- |
| `/qc` or `/questcompanion` | Open or close the manager; `/pc` and `/priestcompanion` remain aliases |
| `/qc menu` | Open the compact navigation menu |
| `/qc guide` | Open the Deathknell guide |
| `/qc unlock` | Enable dragging and resizing outside combat |
| `/qc lock` | Stop movement and save placement |
| `/qc compact` | Apply the compact preset to the current layout, retaining an undo copy |
| `/qc appearance` | Open appearance controls for all gameplay panels |
| `/qc appearance resources` | Open appearance controls for Resources |
| `/qc layout healing` | Apply or queue the Healing layout |
| `/qc layout leveling` | Apply or queue the Leveling layout |
| `/qc show resources` | Show optional health/current-resource bars |
| `/qc show quests` | Show Quest Helper |
| `/qc locations next` | Enable one supported checkpoint for the clicked quest |
| `/qc locations all` | Enable all supported remaining rendered locations for the clicked quest |
| `/qc locations hide` | Hide the clicked quest's supported locations during its focused map view |
| `/qc locations off` or `/qc locations on` | Disable or re-enable the Questie adapter, retaining the selected mode |
| `/qc show prep` | Show Dungeon preparation |
| `/qc show keys` | Show Keybind and mouseover references |
| `/qc show goals` | Show Professions & Shopping |
| `/qc show kills` | Show Kill Tracker |
| `/qc show appearance` | Show Appearance |
| `/qc show all` | Show all panels |
| `/qc hide all` | Hide all panels; `/qc` still opens the manager |
| `/qc resetlayout` | Reset current arrangement, retaining a recovery copy |
| `/qc restorelayout` | Restore the arrangement saved before the latest Compact layout or Reset layout action |
| `/qc kill Practice target` | Record one manual kill under the label Practice target |
| `/qc killsession` | Start fresh session counters while retaining all-time history |
| `/qc diagnostics` | Open a copyable build/capability report |

Panel-manager, lock and layout-switch actions are also declared for WoW's keybinding interface. Their availability in the live Forever settings screen has not yet been verified. No keys are assigned automatically.

## Use the modules

### Resources

Enter `/qc show resources` for two compact bars: health and the character's current resource. There is no separate bars-only switch because the chosen-spell editor has been removed. Mouseover macro references remain in the separate References panel. No rotation guidance was added.

On a Priest, these are health and mana. This panel is not the profession-materials or shopping list; those remain under **Settings > Professions & Shopping**.

### Deathknell leveling guide

Right-click the minimap map icon, or left-click it and choose **Guide**. Use **Done** after leaving the crypt. Accepting a listed quest can advance its acceptance action; a turn-in action requires readable completed-quest history. A quest being ready to turn in does not count as turned in. **Done** and **Skip** are explicit checklist marks and never claim that the game confirmed completion. **Undo** restores the latest manual change. **Back** reviews the previous action, and **Resume** returns to the earliest unfinished action.

Choose **Current** or **Route** to open mapped locations, or click a row in **All steps** to review and map it. Route markers are ordered checklist hints, not a computed walking path. They use the supplied Tirisfal coordinates where present and the loaded Questie database for other pickup, turn-in and objective locations. Unknown or unreadable locations stay unmapped. **Hide** and closing the guide clear its own markers; closing only the world map leaves guide minimap markers available.

This is a bundled route draft, not a freeform text-import interface. The full original route has not been verified against current Forever quest offers. Quest 8 is retained from the supplied checklist with an explicit verification note. The Priest branch uses **Hallowed Scroll (3097)**; **Tainted Scroll (3099)** belongs to the Warlock branch. Travel, training, looting Samuel Fipps's skull and burying it use manual confirmation. See [guide controls and limits](docs/LEVELING-GUIDE.md) and [source record](docs/DEATHKNELL-SOURCES.md).

### Quest Helper

Plain left-click a quest title in the Questie tracker on the right side of the screen, or click a row in Quest Helper. A supported quest opens its map in the saved location mode. The helper's rows no longer require a second Map-button click; only the selected row expands its objectives. Shift-click or right-click a helper row opens quest details.

Use **minimap map icon > Quest locations > Hide / Next / All**, or the same controls in **Quest Helper**. Selecting a mode in the minimap menu changes the next quest-title click; it does not itself choose a quest or open the map. The optional commands above do the same:

- **Hide:** temporarily suppress the selected quest's supported Questie locations while its focused map view is open.
- **Next:** show one nearest supported unfinished checkpoint, with a minimap twin for the same point. When the quest is ready, use its finisher. Nearest is coordinate distance, not a walking route or prerequisite order.
- **All:** show the selected quest's supported remaining rendered locations. Questie's own clustering, phase and visibility rules still apply.

Other quests keep their own icons and preferences. Closing the world map restores the temporary filter. This is not a global filter for every tracked quest. Uncheck **Questie title clicks**, or enter `/qc locations off`, to restore ordinary Questie clicks and icon behavior. Hiding our Quest Helper panel does not disable the bridge, so `/qc hide quests` is useful once configured.

Modified clicks, right-clicks, controller input, combat and unavailable/changed Questie interfaces retain Questie's normal click handling. Our own helper falls back to quest details when checkpoint navigation cannot run. It does not replace your personal waypoint. There is no guessed fallback pin or copied world database. See [integration boundaries](docs/QUESTIE-INTEGRATION.md).

For optional acceptance, enter `/qc show quests` and check **Auto-accept NPC quests**. The setting is off initially. When enabled, opening an ordinary NPC quest offer requests acceptance outside combat. Hold **Shift before opening the offer** to leave it open for reading and manual acceptance. The setting applies in both layouts, including when the Quest Helper panel is hidden; uncheck the box to turn it off.

Shared or unknown givers, item-started quests, adventure-map and area-trigger offers, already autoaccepted quests and PvP confirmations stay with the game's own flow. Gossip choices, completion, turn-ins and rewards remain manual. Missing or restricted data leaves acceptance manual. A skipped or failed offer is not retried automatically; close and reopen it deliberately if needed. The panel states when the required APIs are unavailable. Native client behavior remains unverified in this alpha.

### Dungeon preparation

Check or uncheck each item yourself. Enter your own checklist entries and choose **Add**. Remove an entry with its row's `x`. **Clear checks** keeps the list and clears the marks. Equipment and general-bag summaries are read outside combat; these readings do not automatically check your manual preparation items.

### References and mouseover macros

Add your own binding or spell notes. For a macro, enter a learned helpful spell name or ID and choose **View / copy**. In the copy panel press **Ctrl+A**, then **Ctrl+C**. Review the macro and use WoW's normal macro editor if you want to install it. The generated priority is a living friendly mouseover, then a living friendly target, then yourself. Spells with special targeting requirements still need individual review.

### Profession and shopping goals

Choose **Shopping** or **Profession**, enter a goal name, and optionally enter an item ID or item link plus a target quantity. Leave the item field empty for a manual goal. Choose **Add**. Click a row to edit it; check its box to mark manual completion. **Delete** removes the selected goal and **Undo** restores the last deletion from the current session.

The carried count includes items the client counts as carried/equipped but excludes personal, reagent and account bank storage. A target can become ready because inventory is sufficient without being marked completed manually. An unavailable count is never presented as zero.

### Kill Tracker

Automatic counts mean **readable named kill-XP messages received by this character**. Group XP credit can count even when somebody else landed the killing blow. Grey creatures, other no-XP kills, max-level kills, unavailable event formats and restricted messages are not automatically covered. The addon does not infer a kill from generic XP changes or the current target.

Enter a target label and optional note, then choose **+1 manual** for a manual count. Manual counts never increase the automatic counter. **New session** clears session counters while keeping all-time history. Sessions also restart when the UI reloads or the client restarts. All-time history is per character. Target detail is bounded at approximately 200 named entries, after which new names are combined in an Other targets row.

### Appearance

Use Prev/Next to select a panel or **All panels**. Background opacity affects the background, border and title strip; content opacity affects bars, text and controls separately. **Hide title when locked** removes the title and close button while locked. At 0% content opacity, content is hidden and releases input focus. `/qc` and `/qc appearance` stay readable for recovery.

Appearance changes apply outside combat and are saved per layout. Configuration and copy dialogs are excluded from gameplay opacity and scale edits. Font size and optional cursor tooltips apply to both layouts. Native Edit Mode arranges Blizzard frames. These controls do not configure third-party nameplate addons.

## Privacy and scope

The addon saves its settings, notes, goals and bounded kill summaries through WoW's per-character SavedVariables system. It includes no telemetry, advertisements, remote updater or external connection. It does not send addon chat messages, alter macros, assign bindings, buy or sell items, repair gear, move your character or cast spells. This package contains original source and references to game-provided textures; it bundles no copied Blizzard art.

The diagnostic report omits character names, quest data, lists, target history and raw error text. Review a report before posting it publicly. Do not upload your whole `WTF` directory for a bug report.

## Validation status

Read [validation](docs/VALIDATION.md) for the executed checks and use the [fresh-login checklist](docs/FRESH-LOGIN-CHECKLIST.md) for the next game session. Offline tests establish behavior only in their Lua 5.4/mock scope. They do not establish WoW's native Lua compatibility, secure execution or runtime behavior.

The user's alpha.1 diagnostic reports **client 1.60.1 / 70938, interface 16001, enUS**, with zero module errors and Questie 12.6.5 rejected by the old adapter. That confirms the prior build's reported load state, not alpha.2 compatibility. The inspected [Questie 12.6.5 Forever manifest](https://github.com/Questie/Questie/blob/0214175640abba697f535b2be73787a4c2f2b32b/Questie_Forever.toc) also targets `16001`. API sourcing and deliberate fallbacks are recorded in `docs/API-NOTES.md`.

## Missing dungeon quests: current recommendation

Use the installed DungeonJournal for dungeon quest browsing while using Questie for pickup/objective locations. The separate [dungeon prototype](https://github.com/amhost/priest-companion/pull/1) is not part of this package and cannot yet give a complete pre-run readiness verdict.

The prototype has 18 provisional records: Deadmines 8, Hall of Thanes 5 and Ragefire Chasm 5. All 18 explicitly lack complete eligibility verification; none ships mandatory prerequisite groups. A list of source quests alone does not prove which gates are required. Treating these entries as pickup-ready could still send you to the dungeon before a necessary chain is complete.

The next useful database task is to verify one dungeon end to end: quest ID, faction/class restrictions, minimum level, pickup NPC and coordinates, mandatory prerequisite groups, follow-ups, and repeatable behavior. Compare those records with the character's active and completed quests, and show Completed / In log / Available / Prerequisite needed / Ineligible / Unknown. Only verified mandatory gates may yield Available. That targeted dataset, with source commit/date per record, is the next deliverable. A second whole-world crawl is not required for this release's navigation.
