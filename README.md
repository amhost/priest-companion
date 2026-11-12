# Priest Companion

Movable panels for a priest's leveling and dungeon routine in World of Warcraft: Forever.

**Version: 0.1.0-alpha.1.** Targets interface **16001**. This first alpha has passed offline Lua and mocked API checks. It has **not yet been tested inside WoW Forever**. Actual rendering, protected-value behavior, saved-variable loading and coexistence with other addons remain to be checked in the game.

No addon manager, external service or additional addon is required. All code is included and readable. The addon is free under the MIT license.

[Download releases](https://github.com/amhost/priest-companion/releases) | [Report a bug](https://github.com/amhost/priest-companion/issues/new?template=bug_report.yml)

## Features

| Feature | Alpha behavior |
| --- | --- |
| Movable panels | Unlock, drag the title, resize from the bottom-right corner, and lock again. Position, size, scale, opacity and visibility are saved per layout. Movement and layout changes wait for combat to end. |
| Priest information | Own health and mana displays, plus a list of spell references you choose using real client spell names or IDs. Restricted values are used only in supported display setters; readable numbers are not assumed. |
| Quest Helper | Current quest titles and objective progress. Select a quest for Details or Map. Map guidance uses coordinates returned by the client. Optional NPC quest auto-accept, with Shift bypass, defaults off. |
| Healing and Leveling layouts | Two independent arrangements. Switching layouts changes this addon's panels, not talents or gameplay bindings. |
| Dungeon preparation | Editable manual checklist, minimum equipment durability, broken-item count, and general bag-space summary. Combat shows the last out-of-combat snapshot. |
| Keybind and mouseover references | Actual bindings for the 12 main action buttons, personal notes, and copyable mouseover macro text for a spell you select. |
| Professions and shopping | Manual goals and item-quantity targets, categories, editing, manual completion and delete/undo. Readable carried inventory is compared with your target. Bank storage and charges are excluded. |
| Kill Tracker | Automatic named XP-credit kills, separate manual labeled kills, session and all-time counts, and target notes. Coverage is explicitly partial. |
| Interface preferences | Addon font sizing, panel background opacity, optional out-of-combat cursor tooltips, and access to native Edit Mode when available. |

## Install without an addon manager

1. Exit the game normally.
2. In Battle.net, select World of Warcraft and the **WoW: Forever** game version. Use the gear menu beside Play to **Show in Explorer**.
3. Open that client's `Interface\AddOns` directory. Create `Interface` and then `AddOns` only if they do not exist.
4. Extract the release ZIP. Copy its **PriestCompanion** folder into `AddOns`.
5. The file directly below the copied folder must be `PriestCompanion\PriestCompanion.toc`. Avoid an extra ZIP-name folder between `AddOns` and `PriestCompanion`.
6. Start Forever. On the character-selection screen, open **AddOns** and enable **Priest Companion** for the character.
7. Enter the world and type `/pc` in chat. The manager opens automatically the first time.

If updating an existing installation, exit the game and rename the old addon folder to `PriestCompanion-backup` before copying the new one. A renamed folder whose basename no longer matches its TOC is not loaded as this addon. Keep the backup outside `AddOns` if you prefer an uncluttered list. Saved settings are stored by WoW separately from addon code.

## Arrange the panels

Type `/pc unlock`, drag each panel by its title, and resize with the bottom-right grip. Type `/pc lock` when finished. The manager's minus/plus controls adjust each panel's scale.

Choose **Healing** or **Leveling** in the manager to arrange that layout separately. The initial Healing layout shows Priest information, Dungeon preparation and Keybind references. The initial Leveling layout shows Priest information, Quest Helper, Professions & Shopping and Kill Tracker. Every feature panel can be enabled in either layout.

Use the manager's **Reset layout** button if an arrangement becomes inconvenient. **Undo reset** restores the last arrangement saved before a reset. Resetting a layout keeps goals, notes and kill history.

## Commands

| Command | Action |
| --- | --- |
| `/pc` or `/priestcompanion` | Open or close the manager |
| `/pc unlock` | Enable dragging and resizing outside combat |
| `/pc lock` | Stop movement and save placement |
| `/pc layout healing` | Apply or queue the Healing layout |
| `/pc layout leveling` | Apply or queue the Leveling layout |
| `/pc show priest` | Show Priest information |
| `/pc show quests` | Show Quest Helper |
| `/pc show prep` | Show Dungeon preparation |
| `/pc show keys` | Show Keybind and mouseover references |
| `/pc show goals` | Show Professions & Shopping |
| `/pc show kills` | Show Kill Tracker |
| `/pc show appearance` | Show Interface preferences |
| `/pc show all` | Show all panels |
| `/pc hide all` | Hide all panels; `/pc` still opens the manager |
| `/pc resetlayout` | Reset current arrangement, retaining a recovery copy |
| `/pc restorelayout` | Restore the arrangement saved before the last reset |
| `/pc kill Practice target` | Record one manual kill under the label Practice target |
| `/pc killsession` | Start fresh session counters while retaining all-time history |
| `/pc diagnostics` | Open a copyable build/capability report |

Panel-manager, lock and layout-switch actions are also declared for WoW's keybinding interface. Their availability in the live Forever settings screen has not yet been verified. No keys are assigned automatically.

## Use the modules

### Priest information

Enter a spell name or numeric spell ID and choose **Add**. The client supplies its spell name and learned status where available. The references are a list you choose. They are not live healing priorities or an automatic spell selector.

### Quest Helper

Select a quest in your current log. **Details** opens its client details, with a readable objective-text fallback if that helper is unavailable. **Map** uses a client-provided waypoint. It reports missing location data instead of substituting coordinates from a different version of WoW. This alpha does not contain a world-wide quest-location database or an optimized leveling route.

For optional acceptance, enter `/pc show quests` and check **Auto-accept NPC quests**. The setting is off initially. When enabled, opening an ordinary NPC quest offer requests acceptance outside combat. Hold **Shift before opening the offer** to leave it open for reading and manual acceptance. The setting applies in both layouts, including when the Quest Helper panel is hidden; uncheck the box to turn it off.

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

### Interface preferences

Font and opacity controls apply to this addon's panels. The optional cursor-tooltip setting defaults off and applies only outside combat. Native Edit Mode remains the place to arrange Blizzard's own frames.

## Privacy and scope

The addon saves its settings, notes, goals and bounded kill summaries through WoW's per-character SavedVariables system. It includes no telemetry, advertisements, remote updater or external connection. It does not send addon chat messages, alter macros, assign bindings, buy or sell items, repair gear, move your character or cast spells. This package contains original source and references to game-provided textures; it bundles no copied Blizzard art.

The diagnostic report omits character names, quest data, lists, target history and raw error text. Review a report before posting it publicly. Do not upload your whole `WTF` directory for a bug report.

## Validation status

### Unpublished dungeon-quest prototype

An optional **Dungeon quests (prototype)** panel adds a small, attributed MIT
community catalog for The Deadmines, Hall of Thanes and Ragefire Chasm.
Use **/pc dungeons** or enable it in **/pc**. It shows Missing, In Log, Completed
and Unknown progress separately from uncertain pickup eligibility. Every dungeon
is explicitly partial and provisional; Missing does not mean available.

See [the prototype review](docs/DUNGEON-QUEST-PROTOTYPE.md) for provenance,
licensing, 523 passing offline assertions and the unrun live validation plan.
The Quest Helper, optional auto-accept and manual preparation checklist retain
their existing behavior. No additional addon or CurseForge installation is needed.

### Alpha validation

Read `docs/VALIDATION.md` for the exact executed checks and the short in-game verification plan. Offline tests establish behavior only in their Lua 5.4/mock scope. They do not establish WoW's native Lua compatibility, secure execution or runtime behavior.

The `16001` target is grounded in the current [Questie Forever manifest](https://github.com/Questie/Questie/blob/master/Questie_Forever.toc), not an observation of the user's installed client. API sourcing and deliberate fallbacks are recorded in `docs/API-NOTES.md`.
