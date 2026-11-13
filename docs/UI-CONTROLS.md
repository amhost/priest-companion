# Compact UI and transparency

Included in Priest Companion 0.1.0-alpha.2. These controls style Priest Companion's own panels.

## Quick compact setup

Enter `/pc compact` in WoW chat outside combat. The active layout receives 80% scale, 0% background, 85% content and hidden titles. Priest becomes health/mana bars only. Leveling shows Priest and Quest Helper; Healing shows Priest and Dungeon preparation. Other panels remain available from `/pc`.

Enter `/pc restorelayout` to undo. Applying Compact layout or Reset layout again replaces the single undo copy. Notes, goals, spell references and kill history are preserved.

## Configure a panel

Enter `/pc`, then choose **Appearance** beside the panel, or enter `/pc appearance priest` directly.

| Control | Behavior |
| --- | --- |
| Panel selection | Prev/Next cycles through All panels and each gameplay panel. |
| Background opacity | 0-100%, 1% steps; background, border and title strip. |
| Content opacity | 0-100%, 1% steps; bars, text and interactive content. |
| Scale | 50-150%, 1% steps; preserves screen center subject to screen clamping. |
| Hide title when locked | Hides title and close button while locked. |
| Priest: health and mana bars only | Hides the reference editor; disabling restores its saved full size. |

For transparent backgrounds and partially visible bars, select Priest, set Background to 0%, Content to the desired percentage, enable bars-only and hide-title, then lock. Mixed means the selected panels have different values.

Controls scroll when the configuration window is short. Appearance, the manager and copy dialog remain readable and are excluded from gameplay opacity/scale changes. Values are separate for Healing and Leveling; font size and cursor tooltips apply to both.

## Move and recover

Enter `/pc unlock`, drag a title or bottom-right grip, then enter `/pc lock`. Unlocking temporarily reveals a readable title and content even when saved opacity is zero. Temporary title space prevents overlap with the bars; it is removed when locked and is not saved as a larger panel.

At 0% content, the body is hidden and releases input focus. The locked outer shell does not consume mouse clicks; visible functional controls retain their interaction. `/pc` and `/pc appearance` remain available for recovery.

Appearance, compact and bars-only changes are blocked in combat. Combat removes temporary editing chrome; it returns afterward if panels remain unlocked.

## Verify in the game

1. Apply Compact layout, then lock. Check transparent backgrounds and the two selected gameplay panels.
2. Open Appearance for Priest. Drag both opacity sliders to 0%, then restore Content to 85%. The configuration should stay usable throughout.
3. Unlock, drag and resize Priest; lock again. Repeating this must not grow the saved panel or shift its location.
4. Change scale away from screen center. It should remain centered on the same point unless a screen edge forces clamping.
5. Use `/reload`, then fully exit/restart the game on the same character. Verify layout, opacity and bars-only persistence.

These are live verification steps. Offline mocks do not prove native rendering, mouse hit testing or cold-start persistence.
