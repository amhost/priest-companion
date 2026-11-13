# Companion addons: manual installation

**Checked: November 12, 2026 (America/Chicago).**

Download **12 ZIPs for these 10 addons**. Atlas needs its map module, and Questie needs QuestieDB. The linked releases list **World of Warcraft: Forever / 1.60.1** support. These are optional companions; Priest Companion itself has no addon dependency.

## Download the ZIPs

Open each linked file page and click **Download**. The separate **Install Via App** button is unnecessary; no CurseForge app is required.

| Addon | Verified release | Manual download |
| --- | --- | --- |
| What's Training? by Fusionpit | 11.4.5 | [What's Training 11.4.5](https://www.curseforge.com/wow/addons/whats-training/files/9578588) |
| Atlas and its Kalimdor & Eastern Kingdoms maps | Core 1.54.07; maps 1.54.05 | Download both: [Atlas core](https://www.curseforge.com/wow/addons/atlas/files/9560531) and [Atlas map module](https://www.curseforge.com/wow/addons/atlas-classicwow/files/9572117) |
| OpenMap | 0.8.7 Forever | [OpenMap 0.8.7 Forever](https://www.curseforge.com/wow/addons/openmap/files/9583217) |
| Dialogue UI | 1.0.7-c | [Dialogue UI 1.0.7-c](https://www.curseforge.com/wow/addons/dialogueui/files/9575134) |
| Forever Loot Sparkles | 2.0.0-forever | [Forever Loot Sparkles 2.0.0](https://www.curseforge.com/wow/addons/forever-loot-sparkles/files/9533118) |
| Questie and QuestieDB | Questie 12.8.0; database 1.1.0 Forever | Download both: [Questie](https://www.curseforge.com/wow/addons/questie/files/9576443) and [QuestieDB Forever](https://www.curseforge.com/wow/addons/questiedb/files/9582240) |
| Platynator | 545 | [Platynator 545](https://www.curseforge.com/wow/addons/platynator/files/9577945) |
| DungeonJournal by ExehnTV | 2.0.4 | [DungeonJournal 2.0.4](https://www.curseforge.com/wow/addons/dungeonjournal/files/9583985) |
| Waypoint UI | 1.7.5 | [Waypoint UI 1.7.5](https://www.curseforge.com/wow/addons/waypointui/files/9449968) |
| Plumber | 1.9.7-d | [Plumber 1.9.7-d](https://www.curseforge.com/wow/addons/plumber/files/9528168) |

These are links to the authors' published files. This Priest Companion package does not include or redistribute their ZIPs.

## Find the correct folder and install

1. **Close WoW completely.**
2. In **Battle.net**, select **World of Warcraft** and choose **World of Warcraft: Forever** in the game-version selector. Click **the gear beside Play > Show in Explorer**.
3. From the revealed installation folder, open **`_forever_ > Interface > AddOns`**. If Explorer already opened `_forever_`, go straight to **`Interface > AddOns`**. Create `Interface` and then `AddOns` only if absent. This uses your actual installation location rather than assuming a drive or full path.
4. In Windows File Explorer, right-click each downloaded ZIP and choose **Extract All**. Open the extracted contents and copy the actual addon folders into **AddOns**, keeping their original folder names and any companion folders included in the ZIP.
5. **Check the nesting:** each addon's `.toc` file must be directly inside its own addon folder. An extra ZIP-name or extraction folder between `AddOns` and the addon folder prevents detection.
6. Start Forever. At **character selection > AddOns**, enable the addons, including **QuestieDB** and the **Atlas map module**. If a newly installed addon is missing, check its folder nesting and fully restart WoW; `/reload` alone does not discover new addons.

Folder and menu references: [CurseForge's Forever live-folder guide](https://blog.curseforge.com/wow-forever-migrate-addons-beta-to-live/) and [maintainer manual-install instructions, under Installing > By hand](https://www.curseforge.com/wow/addons/mithril-ui). The latter is an installation reference, not an additional addon to install.

## Dependencies and first setup

- **Atlas:** keep both Atlas core and the map module enabled. The [map module requires Atlas](https://www.curseforge.com/wow/addons/atlas-classicwow/relations/dependencies).
- **Questie:** keep both Questie and QuestieDB enabled. Questie's [database check](https://github.com/Questie/Questie/blob/master/Modules/VersionCheckDB.lua) requires a compatible loaded database for normal initialization.
- **QuestieTrace is optional for normal questing.** Its author describes it as a separate [recorder for database contributions](https://www.curseforge.com/wow/addons/questietrace). Although CurseForge's [dependency metadata](https://www.curseforge.com/wow/addons/questie/relations/dependencies) marks it required, the [Questie 12.8.0 manifest](https://github.com/Questie/Questie/commit/968dd36747e58df157934b73d7781e8cfe560668) lists it as optional. It is not part of the 12 downloads above.
- **DungeonJournal:** type `/dj` in game. For checking dungeon quests before entering, leave **RPG Mode** disabled initially. If you enable RPG Mode, also enable its **Show dungeon quests** option to see quests for locked dungeons. That option was added in [2.0.4](https://www.curseforge.com/wow/addons/dungeonjournal/files/9583985) and defaults off.
- **OpenMap and Questie:** use the linked versions together. [OpenMap 0.8.7](https://www.curseforge.com/wow/addons/openmap/files/9583217) fixes Questie 12.8 map icons being hidden when a zone map first opens.

The links establish published compatibility, not an in-game test of this complete addon combination.
