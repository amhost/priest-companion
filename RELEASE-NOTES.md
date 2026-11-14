# Quest Companion 0.2.0-alpha.2

This update addresses the reported Questie 12.6.5 rejection, replaces the purple panel treatment, adds minimap controls, and turns the supplied Deathknell 1-6 checklist into a playable guide.

## What changed

- **Questie 12.6.5 support:** the previous release rejected this version. The adapter now recognizes its older LibStub map-library registration, as well as the guarded 12.8/12.9 module interface. Missing or changed providers produce a visible reason. This is source-inspected and mock-tested support; native validation remains pending.
- **Minimap controls:** left-click the map icon for Guide, Quest Helper, Settings, lock controls and Questie location modes. Right-click to toggle the guide. Drag the icon to reposition it. Chat commands remain optional.
- **WoW-style presentation:** game font paths and shadows, gold/white tracker actions, stock button/dialog textures and transparent fresh gameplay panels replace the purple window treatment. Existing saved opacity is preserved. Background and content opacity remain independent 0-100% sliders, with 50-150% scale.
- **Deathknell guide:** 33 actions represent the supplied 15 steps. Acceptance, whole-quest readiness and turn-ins follow readable quest state. Travel, training and individual interactions use Done. Back, Done, Skip, Undo, Resume and All steps are clickable controls. Manual marks never claim the game confirmed a quest completion.
- **Class scroll correction:** Priests receive Hallowed Scroll (3097); Warlocks receive Tainted Scroll (3099). Other classes receive manual starter-quest reminders.
- **Multiple locations:** Guide > Current maps the selected action. Guide > Route shows up to 24 numbered locations for remaining actions on the world map and minimap. Shared positions are grouped. Explicit supplied points use the loaded zone mapping; other actions use the loaded Questie quest/NPC/object/item data. Missing, partial and capped coverage is reported. These are route hints, not an automatically calculated walking path.
- **Marker ownership:** Guide > Hide or closing the guide removes its own markers. Other Questie icons and the player's personal waypoint are preserved. Closing only the world map leaves guide minimap markers available. Guide modes are independent of Questie's Hide / Next / All modes.

Resources still shows health and the current resource. For a Priest, that is health and mana. Profession materials and shopping goals remain in their own panel.

## First use without commands

| Action | Click path |
| --- | --- |
| Open the guide | Minimap map icon > Guide, or right-click the icon |
| Mark leaving the crypt | Guide > Done |
| Map the next pickup | Guide > Current or Map |
| See multiple guide locations | Guide > Route |
| Review and map a later action | Guide > All steps > click its row |
| Navigate from Questie's tracker | Minimap map icon > Quest locations > Next or All; then plain left-click a tracked Questie quest title |
| Restore original Questie clicks | Minimap map icon > Normal Questie clicks |
| Move panels | Minimap map icon > Unlock panels; drag title or lower-right corner; Lock panels |
| Change opacity or scale | Minimap map icon > Settings > Appearance |

Choosing Next / All / Hide in the minimap menu sets the next quest-title click behavior; selecting the mode alone does not open a quest map. The first crypt-exit guide action has no invented coordinate. Mark it Done after leaving the crypt to reach the first quest pickup.

## Update

1. Download **QuestCompanion-0.2.0-alpha.2.zip**, the installable asset.
2. Exit WoW normally. In the same Forever client's `Interface\AddOns` directory used for alpha.1, move the existing `PriestCompanion` folder to a backup location outside `AddOns`.
3. Extract the new archive and copy its **PriestCompanion** folder into `Interface\AddOns`. Keep the existing `WTF` directory and saved settings.
4. At character selection, open **AddOns** and enable **Quest Companion**. Enter the world and use the minimap map icon.

The installed folder, TOC filename and `PriestCompanionDB` save key remain unchanged for upgrade continuity. Do not rename the folder or install a second copy. The complete source, tests and build tools are in **QuestCompanion-0.2.0-alpha.2-source.zip**.

## Validation and limits

**2,236 offline assertions passed**, with 17 addon Lua files parsed in Lua 5.4 and bounded WoW UI/API mocks. Coverage includes both Questie library shapes, real menu/guide callbacks, multi-marker ownership and cleanup, phase handling, item-source cycles, manual versus automatic progress, restricted values, persistence models and appearance recovery. Two review findings, wrapped rows retaining a one-line limit and Map after Hide retaining the wrong highlight, have regression coverage.

**Alpha.2 has not been tested in the actual WoW client.** The user's alpha.1 report identifies client 1.60.1 / 70938, interface 16001, enUS, Questie 12.6.5 / DB 1.0.14 and zero module errors. It also confirms the old version rejection; it does not validate this new code. Native rendering, secure execution, combat coexistence and cold-start saved-file loading remain pending.

The Deathknell route is a draft derived from the supplied checklist. Its complete quest sequence and supplied coordinates have not been verified against current Forever gameplay. Quest 8 remains explicitly provisional. This release bundles the route as data; it does not provide arbitrary pasted-text guide import. The separate incomplete dungeon prototype is outside this package.

Start with [the fresh-login checklist](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.2/docs/FRESH-LOGIN-CHECKLIST.md). See [guide controls](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.2/docs/LEVELING-GUIDE.md), [route sources](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.2/docs/DEATHKNELL-SOURCES.md), and [validation scope](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.2/docs/VALIDATION.md).

Bug reports should include client and Questie versions, the selected guide action, exact clicks, expected/actual behavior, combat state and `/qc diagnostics`. The report omits character names, quest data, personal lists and raw errors. Source is MIT licensed, with no telemetry or external updater.
