# Debug Console integration

**Debug Console** (MIT, AssetLib #4210) is installed at `res://addons/debug_console/`.

## Setup

1. Plugin enabled in `project.godot` → `[editor_plugins]`
2. Dev autoloads registered (DebugCore, CommandRegistry, DebugConsole, GameConsoleManager)
3. Colony `_ready()` calls `GoblinWarrensDebugRegister.try_register(self)` in debug builds

## In-game usage

- **F12** or **Ctrl+`** — toggle console
- Type `help` for built-in commands plus Goblin Warrens cheats (see `docs/technical/DEBUG_COMMANDS.md`)

## Files

| File | Role |
|------|------|
| `game/integrations/debug_console/register.gd` | Registers commands with `DebugConsole.register_command` |
| `game/dev/debug_console/debug_command_router.gd` | Dispatches to colony APIs — no duplicate game logic |

Do not register commands from UI or colony scripts directly; keep wiring in `register.gd`.
