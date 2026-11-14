# Quest Companion development notes

Working release: 0.2.0-alpha.3. Target: WoW Forever interface 16001, matching the user's alpha.1 diagnostic and inspected Questie Forever manifests. The alpha.2 UI rendered in the user's screenshot, but Questie initialization failed after reload with this addon enabled. Alpha.3 removes the conflicting callback hook; native hotfix validation remains pending. Original code; Questie is optional for tracker navigation and guide markers. The guide checklist remains usable without it. Source aims for Lua 5.1-compatible syntax; the executed parser/harness is Lua 5.4. No combat automation, arbitrary file/network access, or protected-data bypasses.

## Shared module interface

Every Lua file begins `local addonName, ns = ...`.

Core loads before UI, then Spells, QuestieBridge, GuideData, GuideModel and GuideWaypoints, followed by feature modules, the panel manager and QuickMenu. The legacy folder/TOC/save key are intentional; visible titles use ns.PRODUCT_NAME. Resources replaces the old priest module. Do not remove old saved keys during additive migration. Module registration at file load:

```lua
ns.RegisterModule({
  id = "moduleid", title = "Title", description = "Description",
  width = 320, height = 280, minWidth = 280, minHeight = 200,
  defaultEnabled = { Healing = true, Leveling = true },
  Create = function(self) -- self.frame and self.body exist
  end,
  Refresh = function(self) -- called initially and by ns.Refresh(id)
  end,
})
```

Create runs after saved variables initialize. Use self.body as widget parent. All positions passed to UI helpers use positive y downward. Body resizes with panel. Every panel supplies its own title drag handle, resize grip, close button, saved placement, per-layout visibility, font scaling, and combat-aware lock through core/UI.

Available helpers:

- `ns.Readable(value)` returns false for secret/inaccessible values. Check before indexing tables, comparing, formatting, storing, or using as keys.
- `ns.Number(value, fallback)` returns readable finite numeric value or fallback.
- `ns.Text(value, fallback)` returns readable string/number as text or fallback. Does NOT escape display markup.
- `ns.CleanText(value, limit)` sanitizes user text (controls, markup removal, max length); use on user input before persistence/display.
- `ns.Call(fn, ...)` protected API call, returns up to six API values or nil if absent/failed. Further secret checks still required.
- `ns.IsCombat()` boolean; do not mutate secure UI.
- `ns.ModuleDB(id, defaults)` persistent per-character settings, recursive missing-default merge.
- `ns.On(event, callback)` registers safely, returns true/false; callback receives `(event, ...)`.
- `ns.Refresh(id)` coalesced refresh, only rendered when panel shown; `ns.RefreshAll()`.
- `ns.Notify(text)` user-facing message.
- `ns.RegisterCommand(name, function(rest) ... end)` adds `/qc name rest`.
- `ns.UI.Text(parent, text, x, y, size, width, color)` -> FontString. color optional `{r,g,b}`. Wrapping enabled.
- `ns.UI.Button(parent, text, x, y, width, height, onClick)` -> Button.
- `ns.UI.TrackerAction(parent, text, x, y, width, height, onClick)` -> transparent tracker-style Button. Both button helpers expose `SetSelected(bool)`. Tracker actions default to a one-line label; explicitly use `label:SetMaxLines(0)` for wrapping checklist rows.
- `ns.UI.Input(parent, x, y, width, height, placeholder, onEnter)` -> EditBox. callback(text, box). Enter commits; Escape blurs.
- `ns.UI.Check(parent, text, x, y, onClick)` -> CheckButton, use SetChecked.
- `ns.UI.ScrollArea(parent, top, bottom)` -> scrollFrame, contentFrame. Full width, reserves scrollbar. Set content height after rendering. Bottom is positive inset.
- `ns.UI.Tooltip(widget, textOrFunction)`.
- `ns.UI.MakeCopyBox(title, text)` opens a movable text selection panel for copying; transient edits are not saved. No clipboard API.
- `ns.UI.Slider(parent,label,x,y,width,low,high,step,onChanged)` returns a 48-unit control with `.slider`, `.label`, `.valueText`, `SetDisplayValue(value,mixed)` and `SetEnabled(bool)`. Appearance uses percentage units; synchronization never invokes the writer.
- `ns.IsCustomizablePanel(id)` excludes configuration/copy dialogs; `ns.SetPanelAppearance(idOrAll,key,value)` validates `scale`, `opacity`, `contentOpacity`, `hideHeader` and guards combat.
- `ns.OpenAppearance(id)`, `ns.ApplyCompactLayout()` and `ns.OpenQuickMenu()` provide public UI actions. The minimap launcher is a separate ordinary frame with a saved angle and no per-frame polling.
- Panel roots stay at alpha 1. Background/chrome are styled individually; body alpha controls content. Zero content hides the body and clears focus. Editing may add `pcHeaderExtra` to frame height; SavePlacement excludes it and the live frame is centered before changing this height.

Self-contained module model logic should be exported under `ns.Models.<Name>` for deterministic tests. Keep module creation and refresh functions idempotent. Event handlers may receive secret values; never stringify raw events/errors or persist them. Register only relevant events. No per-frame polling. Current live local state must be presented as unavailable if API missing or restricted.

## Source structure

- `Core.lua`: settings lifecycle, guarded helpers, events, commands and layouts.
- `UI.lua`: shared frames, controls and copy dialog.
- `Spells.lua`: class-neutral spell lookup for the copyable macro reference.
- `QuestieBridge.lua`: version/shape-guarded optional adapter; see docs/QUESTIE-INTEGRATION.md before editing its hooks.
- `GuideData.lua`: original structured version of the supplied route, stable action IDs, source-step references, class variants and coordinate provenance. No external quest database copy.
- `GuideModel.lua`: pure route expansion, automatic evidence, manual marks, skip/undo and progress. Automatic state is derived from readable evidence; only manual changes are persisted.
- `GuideWaypoints.lua`: owned world/minimap pins through the loaded Questie map provider, capped at 24 unique positions. Resolve explicit guide points through ZoneDB; preserve phase and secret-value guards. Do not call personal-waypoint setters.
- `Modules/Guide.lua`: evidence reader, guide controls, pooled checklist rows and event-driven marker refresh. Travel, training and partial interactions remain manual unless a later change adds verified per-action evidence.
- `Modules/QuickMenu.lua`: minimap launcher and UI-first entry points for guide, navigation and settings.
- `Modules`: feature implementations, the panel manager and appearance controls.
- `tests`: pure-model cases and bounded WoW UI/API doubles.
- `tools/check.py`: runs the optional offline checks with Python 3 and liblua5.4.
- `tools/build.py`: validates and builds deterministic installable/source archives.

Run both tools from this directory. The addon itself has no external runtime dependency. Keep API failures visible, preserve unrelated settings, and do not mistake mock results for in-game validation. Before expanding a combat feature, inspect the relevant client APIs and test it in the matching Forever build.

Do not hook or replace `QuestieMap.ProcessQueue`: Questie passes its exact function value to `C_Timer.NewTicker`. Schedule the bridge's own coalesced `C_Timer.After(0, callback)` from `QueueDraw` instead. The callback must run after queued frames are registered; never use a synchronous fallback. Reject missing scheduling support before hook mutations and release owned filtering if scheduling later fails.

## Verification scope

Use `python3 tools/check.py` for the bounded Lua 5.4 harness and `python3 tools/build.py` for manifest and archive checks. Source inspection and mocks do not establish live WoW behavior. Keep native checks pending until a tester records the client build and outcome. The dungeon prototype is separate and has no complete eligibility dataset.

When adding a guide, keep stable per-action IDs, source/provenance notes and explicit manual-only boundaries. Preserve existing saved action IDs during revisions. The current UI opens only the bundled Deathknell route; there is no arbitrary text-import interface. See docs/LEVELING-GUIDE.md and docs/DEATHKNELL-SOURCES.md for this route's verified and provisional details.
