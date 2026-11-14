# Quest Companion development notes

Working release: 0.2.0-alpha.1. Target: WoW Forever interface 16001, declared by current Questie Forever manifests. Runtime compatibility is unverified until tested in the user's game. Original code; Questie is optional for the checkpoint bridge. Lua 5.1-compatible syntax. No combat automation, arbitrary file/network access, or protected-data bypasses.

## Shared module interface

Every Lua file begins `local addonName, ns = ...`.

Core loads before UI, then Spells and QuestieBridge, followed by feature modules and the panel manager. The legacy folder/TOC/save key are intentional; visible titles use ns.PRODUCT_NAME. Resources replaces the old priest module. Do not remove old saved keys during additive migration. Module registration at file load:

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
- `ns.UI.Input(parent, x, y, width, height, placeholder, onEnter)` -> EditBox. callback(text, box). Enter commits; Escape blurs.
- `ns.UI.Check(parent, text, x, y, onClick)` -> CheckButton, use SetChecked.
- `ns.UI.ScrollArea(parent, top, bottom)` -> scrollFrame, contentFrame. Full width, reserves scrollbar. Set content height after rendering. Bottom is positive inset.
- `ns.UI.Tooltip(widget, textOrFunction)`.
- `ns.UI.MakeCopyBox(title, text)` opens a movable text selection panel for copying; transient edits are not saved. No clipboard API.
- `ns.UI.Slider(parent,label,x,y,width,low,high,step,onChanged)` returns a 48-unit control with `.slider`, `.label`, `.valueText`, `SetDisplayValue(value,mixed)` and `SetEnabled(bool)`. Appearance uses percentage units; synchronization never invokes the writer.
- `ns.IsCustomizablePanel(id)` excludes configuration/copy dialogs; `ns.SetPanelAppearance(idOrAll,key,value)` validates `scale`, `opacity`, `contentOpacity`, `hideHeader` and guards combat.
- `ns.OpenAppearance(id)` and `ns.ApplyCompactLayout()` provide public UI actions.
- Panel roots stay at alpha 1. Background/chrome are styled individually; body alpha controls content. Zero content hides the body and clears focus. Editing may add `pcHeaderExtra` to frame height; SavePlacement excludes it and the live frame is centered before changing this height.

Self-contained module model logic should be exported under `ns.Models.<Name>` for deterministic tests. Keep module creation and refresh functions idempotent. Event handlers may receive secret values; never stringify raw events/errors or persist them. Register only relevant events. No per-frame polling. Current live local state must be presented as unavailable if API missing or restricted.

## Source structure

- `Core.lua`: settings lifecycle, guarded helpers, events, commands and layouts.
- `UI.lua`: shared frames, controls and copy dialog.
- `Spells.lua`: class-neutral spell lookup for the copyable macro reference.
- `QuestieBridge.lua`: version/shape-guarded optional adapter; see docs/QUESTIE-INTEGRATION.md before editing its hooks.
- `Modules`: feature implementations, the panel manager and appearance controls.
- `tests`: pure-model cases and bounded WoW UI/API doubles.
- `tools/check.py`: runs the optional offline checks with Python 3 and liblua5.4.
- `tools/build.py`: validates and builds deterministic installable/source archives.

Run both tools from this directory. The addon itself has no external runtime dependency. Keep API failures visible, preserve unrelated settings, and do not mistake mock results for in-game validation. Before expanding a combat feature, inspect the relevant client APIs and test it in the matching Forever build.

## Verification scope

Use `python3 tools/check.py` for the bounded Lua 5.4 harness and `python3 tools/build.py` for manifest and archive checks. Source inspection and mocks do not establish live WoW behavior. Keep native checks pending until a tester records the client build and outcome. The dungeon prototype is separate and has no complete eligibility dataset.
