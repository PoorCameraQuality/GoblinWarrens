# Debug commands — Goblin Warrens

Development-only. Must not ship in release builds (`OS.is_debug_build()` gate).

**Router:** `game/dev/debug_console/debug_command_router.gd`  
**Registration:** `game/integrations/debug_console/register.gd` (Debug Console plugin, debug builds only)

**Toggle:** F12 or Ctrl+` in running game.

---

## Implemented (via router)

| Command | Args | Effect |
|---------|------|--------|
| `add_food` | `[amount=20]` | Deposit food to colony stockpile |
| `add_wood` | `[amount=20]` | Deposit wood |
| `add_stone` | `[amount=20]` | Deposit stone |
| `add_magic` | `[amount=10]` | Deposit magic |
| `skip_day` | — | Advance day simulation by one day |
| `start_raid` | — | Spawn militia raid wave |
| `spawn_beast` | — | Spawn surface beast at map edge |
| `damage_warren` | `[amount=25]` | Damage Warren HP |
| `heal_warren` | — | Restore Warren to full HP |
| `revive_goblin` | — | Revive one buried goblin (needs burial grounds + magic) |

---

## Planned (wire when systems exist)

| Command | Target system |
|---------|---------------|
| `spawn_goblin` | Colony spawn |
| `spawn_foblin` | Breeder / foblin spawn |
| `unlock_building` | Build catalog gating |
| `complete_building` | Nearest construction site |
| `kill_selected` | Selection + combat |
| `toggle_god_boon` | Ritual / shrine |

Console handlers must **call existing colony/services APIs** — no duplicate game logic in the console plugin.
