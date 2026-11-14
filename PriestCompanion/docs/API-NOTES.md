# API evidence and implementation boundaries

Original API research: November 10, 2026. Questie integration update: November 14, 2026 (UTC). This document distinguishes inspected source from native runtime evidence. No actual Forever client was available in the build environment.

## Target declaration

The current [Questie Forever manifest](https://github.com/Questie/Questie/blob/master/Questie_Forever.toc) and [Camelot manifest](https://github.com/Questie/Questie/blob/master/Questie_Camelot.toc) declare interface 16001. This is evidence of the current author's source declaration, not proof of any user's installed build. Quest Companion's legacy-named TOC targets 16001 and reports a mismatch in chat if loaded elsewhere.

## Combat data

Blizzard's [UI customization explanation](https://news.blizzard.com/en-gb/article/24244638/how-midnights-upcoming-game-changes-will-impact-combat-addons) and [combat addon explanation](https://news.blizzard.com/en-gb/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight) describe the distinction between presenting protected combat values and interpreting them in custom logic. These articles concern the modern API model; exact Forever behavior still needs in-game validation.

Core guards use the available `issecretvalue`, `issecrettable` and `canaccessvalue` functions before ordinary inspection. The Resources panel permits values to pass directly into supported StatusBar setters, wrapped with `pcall`; it does not compare protected health or resource values. Unsupported display calls fall back to an explicit unavailable state. No combat log bypass or protected-value reconstruction is attempted.

## Quests

Inspected [Blizzard-generated QuestLog documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua). Current quest-log reads use `GetNumQuestLogEntries`, `GetInfo`, `GetQuestObjectives` and `IsComplete` under `C_QuestLog` when available. Navigation now uses the guarded Questie adapter described in [QUESTIE-INTEGRATION.md](QUESTIE-INTEGRATION.md). The previous `GetNextWaypoint`/personal-waypoint fallback is no longer called: an unavailable bridge falls back to ordinary quest details without overwriting the player's personal point.

The helper contains no borrowed world database, guessed quest locations or leveling route. Missing data is not interpreted as quest completion.

For optional quest acceptance, inspected the [extracted Blizzard quest-frame source at commit 70ef1b2](https://github.com/Gethe/wow-ui-source/blob/70ef1b2fd78061a73f886c4a1e79dc5b5cff6d5e/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua). It processes `QUEST_DETAIL`, identifies the giver through `questnpc`, and calls `AcceptQuest()` for an ordinary offer. It handles PvP confirmation, already autoaccepted quests, item-started offers, adventure-map offers and area triggers separately. This source evidence does not establish that an addon may successfully call every function in the user's native client; live acceptance remains part of alpha verification.

The optional acceptance path requires a readable, existing, non-player `questnpc`. This is a conservative giver filter, not proof that every shared-quest edge case has been validated. The per-character preference starts off and applies in both layouts, even with the panel hidden. Shift, combat, a special offer or unavailable data leaves that displayed offer manual. A successful API call is shown only as an acceptance request; the addon does not claim server confirmation from the call's return alone.

## Inventory and professions

Inspected [Blizzard-generated Item documentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua). Shopping targets call `C_Item.GetItemCount(itemID, false, false, false, false)`, excluding bank, charge, reagent-bank and account-bank counts. Values must be readable, nonnegative whole numbers before calculation.

Primary profession summaries capability-check `GetProfessions` and `GetProfessionInfo`. The manual goal editor remains usable without those APIs. Preparation uses capability-checked equipment durability and modern container APIs. General-space totals exclude specialized bag families and treat failed readings as partial coverage.

## Spell references and macro text

Spells are resolved through `C_Spell.GetSpellInfo` rather than hardcoded Forever ability IDs. Modern learned-spell checks use `C_SpellBook.IsSpellInSpellBook` when available, with a checked legacy fallback. A helpful-spell check is used when available. Newlines, macro commands, custom condition fragments and oversized inputs are rejected by the copyable macro builder.

The builder produces text only. Spell-specific targeting behavior still requires a player review in the actual game.

## XP-credit tracking

The generated event surface includes `CHAT_MSG_COMBAT_XP_GAIN`; the implementation checks event registration and actual available localized `COMBATLOG_XPGAIN_*` globals. Only known named kill-XP templates are compiled. Positional format arguments are supported. A secret or unrecognized message is skipped; an unnamed XP event is not counted as a kill.

This is partial XP-credit history, not a full combat log or proof of a player's killing blow. Consecutive identical messages are separate events and are not deduplicated by text. Manual entries remain separate. Native locale formats and live event receipt remain untested.

## Distribution

Blizzard's [UI Add-On Development Policy](https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534) informs the free, visible-source distribution. This original package includes no ads, paid feature gate or in-game donation prompt.

The shared UI uses game-provided fonts and textures by path. No Blizzard texture or sound files are included in either ZIP.
