# Priest Companion 0.1.0-alpha.1

Priest Companion brings a priest's leveling and dungeon routine into a set of movable panels for WoW: Forever.

Every panel can be moved, resized, shown or hidden. Healing and Leveling keep separate arrangements. Start with `/pc`, then use `/pc unlock` to arrange your screen.

This first alpha includes:

- Your health, mana and chosen spell references.
- Current quests, objective progress and available client-provided map guidance.
- Optional NPC quest auto-accept, off by default, with Shift bypass for reading.
- A dungeon preparation checklist with equipment and general-bag summaries.
- Main action-button binding references, personal notes and copyable mouseover macros.
- Profession and shopping goals with carried item counts and quantities still needed.
- XP-credit kill counts, separate manual counts, session totals and all-time history.
- Addon text and background controls, plus optional out-of-combat cursor tooltips.

Download `PriestCompanion-0.1.0-alpha.1.zip` and copy its `PriestCompanion` folder into the Forever client's `Interface\AddOns` folder. No addon manager is required.

**Alpha status:** The target is interface 16001. Offline syntax and mocked behavior checks pass. The addon has not yet been tested in the actual WoW Forever client, so native rendering, saved-variable loading, protected combat behavior and other-addon compatibility remain unverified.

The quest helper uses the current log and coordinates the client supplies. The automatic kill counter covers named XP-credit messages, including shared group credit; it does not cover every kill. Manual counts remain separate. The addon does not choose healing targets or cast spells.

To enable quest acceptance, enter `/pc show quests` and check **Auto-accept NPC quests**. Hold **Shift before opening an offer** to keep it manual. Only ordinary NPC quest details are eligible outside combat. Shared/unknown givers, special quest flows and PvP confirmations stay manual. The addon does not select gossip options, complete quests or choose rewards. The preference stays active across both layouts and while its panel is hidden; uncheck it to disable.

Useful early feedback: exact client build, which panel you used, reproduction steps, expected result, actual result and whether it occurred in combat. `/pc diagnostics` creates a concise report without character names or personal lists.

Free, original source, MIT licensed. English interface text; XP-message parsing uses the client's available localized templates, with native-locale verification still pending.
