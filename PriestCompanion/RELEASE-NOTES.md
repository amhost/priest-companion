# Priest Companion 0.1.0-alpha.2

This UI alpha makes Priest Companion smaller and gives each gameplay panel independent transparency controls.

## Compact setup

After updating, enter `/pc compact` outside combat. This applies 80% scale, 0% background, 85% content, hidden titles and a health/mana-only Priest panel. Leveling shows Priest and Quest Helper; Healing shows Priest and Dungeon preparation. Other panels remain accessible from `/pc`. Enter `/pc restorelayout` to undo the preset.

For individual controls, enter `/pc appearance priest` or choose a panel's **Appearance** button in `/pc`:

- **Background opacity:** 0-100%, including the border and title strip.
- **Content opacity:** 0-100%, separately controlling bars, text and interactive content.
- **Scale:** 50-150%, keeping the panel centered on its current position subject to screen clamping.
- **Hide title when locked:** removes the title and close button.
- **Priest bars only:** hides the reference editor and restores its prior full size when switched off.

Each slider moves in 1% steps. Values are saved separately for Healing and Leveling. Configuration windows stay readable. `/pc unlock` temporarily reveals drag handles and faint content, including when saved opacity is zero; `/pc lock` restores the chosen appearance. Existing settings, notes, goals, spell references and kill history are retained. Installing the update does not automatically replace an existing layout with Compact.

## Install or update

Download `PriestCompanion-0.1.0-alpha.2.zip`. Close WoW, move the previous `PriestCompanion` folder outside `Interface\AddOns` as a backup, and copy the new archive's `PriestCompanion` folder into the Forever client's `Interface\AddOns`. Keep the `WTF` folder and saved settings. No addon manager is required.

The package also includes `docs/UI-CONTROLS.md` and a manual download guide for the ten suggested companion addons. Those third-party addons are not bundled. Priest Companion's appearance controls apply to its own panels; nameplate styling remains in the nameplate addon's settings.

## Validation and scope

**884 assertions passed** in offline Lua 5.4 with bounded WoW UI/API mocks, including zero-opacity callbacks, hidden-panel recovery, scale/position preservation, temporary edit-header sizing, layout undo, focus handling and combat guards. Packaging checks validate manifest paths, XML, ZIP integrity and checksums.

**Native WoW Forever testing is still pending.** The declared target is interface 16001. Offline checks do not establish live rendering, mouse hit testing, secure execution, saved-file loading, locale behavior or coexistence with other addons.

This release is a UI update to the original alpha. It does **not** include the separate dungeon quest prototype in [PR #1](https://github.com/amhost/priest-companion/pull/1). The released quest helper still reads the current quest log and available client-provided map guidance; it does not have a complete database of missing dungeon quests.

The original feature panels and optional NPC quest auto-accept remain available. Quest auto-accept starts off, supports Shift bypass and does not choose gossip, turn in quests or select rewards. Automatic kill counts cover named XP-credit messages; manual counts remain separate.

Useful feedback: client version/build, panel, reproduction steps, expected and actual appearance, and whether combat was active. `/pc diagnostics` creates a report without character names or personal lists.

Free, original source, MIT licensed. English interface text; XP-message parsing uses the client's available localized templates, with native-locale verification still pending.
