# Input actions — Goblin Warrens

Document project input map here before installing **Maaack's Input Remapping** (Phase 3).

**Current state:** hotkeys and mouse are handled in scripts (`build_placement.gd`, `selection_controller.gd`, `rts_camera.gd`) — not yet centralized in InputMap.

---

## Planned actions (for future InputMap)

| Action | Default | Handler today |
|--------|---------|---------------|
| `camera_pan_up` | W | `rts_camera.gd` |
| `camera_pan_down` | S | `rts_camera.gd` |
| `camera_pan_left` | A | `rts_camera.gd` |
| `camera_pan_right` | D | `rts_camera.gd` |
| `select_add` | Shift | `selection_controller.gd` |
| `command_move` | RMB | `selection_controller.gd` |
| `build_slot_1` … `build_slot_9` | 1–9 | `build_placement.gd` |
| `build_cancel` | Esc / RMB | `build_placement.gd` |
| `debug_console_toggle` | F12, Ctrl+` | Debug Console in-game overlay |

Do not hard-code new binds in unit scripts — add rows here first, then InputMap + remapping plugin.
