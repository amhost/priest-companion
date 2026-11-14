# Quest Companion 0.2.0-alpha.3

This hotfix removes the Questie timer-callback hook implicated in the reported alpha.2 reload failure.

## The failure and correction

The user reported Questie failing during initialization with `C_Timer.NewTicker` bad argument #2 at `QuestieMap.lua:235`, then loading after Quest Companion was disabled. At that line, Questie passes `QuestieMap.ProcessQueue` directly as its repeating timer callback. Alpha.2 hooked that same field during early login.

Alpha.3 leaves Questie's timer callback untouched. Our adapter now schedules its own coalesced deferred refresh when Questie queues map icons. The deferral lets Questie finish registering those icons before selection is recalculated. Missing or failing scheduling support releases our temporary filtering and reports the failure.

Delaying the old hook would not solve both startup orders: a timer created first retains the original callback and can bypass a later hook. The new tests explicitly cover both orders.

## Update and check

1. Download **QuestCompanion-0.2.0-alpha.3.zip**.
2. Exit WoW normally. Move the old **PriestCompanion** folder outside the Forever client's `Interface\AddOns` directory as a backup, then copy the replacement **PriestCompanion** folder from the ZIP into `AddOns`. Keep the existing `WTF` directory and saved settings.
3. At **character selection > AddOns**, enable **Quest Companion**, **Questie**, and **QuestieDB**. Log in and wait for Questie to finish loading.
4. Press **Enter**, type `/reload`, press **Enter**, and wait for loading to finish. Repeat once. The previous `C_Timer.NewTicker` / `InitializeQueue` error should not return.
5. Use **minimap map icon > Quest locations > Next**, then click a tracked Questie title. Check **All** and **Hide**, then **Guide > Route**. Open **Settings > Diagnostics** and confirm **0.2.0-alpha.3**.

If the same startup error returns, disable **Quest Companion** at **character selection > AddOns** and log in again. Preserve the error screenshot and diagnostic report if available. An in-addon navigation switch does not undo hooks already installed by an older build; use the full update and reload sequence above.

## Verification

**17 addon Lua files parsed and 2,389 assertions passed** in offline Lua 5.4 with bounded WoW mocks. The new startup fixture fails on unchanged alpha.2 and passes with this fix. It covers both timer-registration orders, saved enabled/disabled navigation, callback identity, actual captured-callback invocation, repeated resume events, Next/Hide/All redraws, partially registered frames and scheduler failures.

The test models the callback constraint reported by the native client. It does not emulate Blizzard's secure runtime. **The alpha.3 native reload check is still pending.** The supplied alpha.2 screenshot establishes that its settings panel rendered, while the error report and disable/reload result establish the reported interaction.

The Deathknell guide, numbered route markers, native-style controls and saved preferences remain included. The complete source archive is **QuestCompanion-0.2.0-alpha.3-source.zip**.

See [the reload checklist](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.3/docs/FRESH-LOGIN-CHECKLIST.md), [integration details](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.3/docs/QUESTIE-INTEGRATION.md), and [validation record](https://github.com/amhost/priest-companion/blob/v0.2.0-alpha.3/docs/VALIDATION.md).
