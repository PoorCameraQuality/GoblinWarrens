# Technical reference

Single source of truth for pinned versions, tool paths, and architectural
constants. Any change here must be paired with the change it documents.

## Engine

| Item | Pinned value | Notes |
|---|---|---|
| Godot version | **4.7.stable** (winget `GodotEngine.GodotEngine`, 2026-06-28) | Project targets 4.6+; 4.7 verified headless. Pin exact patch after team agrees. |
| Godot executable | `C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe` | Use `_console.exe` for CI/smoke tests. |
| **Official API docs** | [https://docs.godotengine.org/en/latest/](https://docs.godotengine.org/en/latest/) | **Binding reference for all engine APIs.** Verify classes, methods, signals, and properties here before use. Prefer `stable` docs when `latest` differs from the pinned engine. |
| Renderer | `forward_plus` | Switch to `mobile` only if Vulkan 1.2 unavailable. |
| Language | GDScript | C# reserved as hot-path escape valve. |
| Physics | Built-in (Jolt optional later) | Goblins are kinematic on a grid, not rigid bodies. |

### Godot documentation — what to use when

| Task | Start here |
|---|---|
| Any class or method (`Camera3D`, `AStarGrid2D`, signals, etc.) | Class reference → [All classes](https://docs.godotengine.org/en/latest/classes/index.html) |
| GDScript syntax, typing, `@onready`, signals | [GDScript documentation](https://docs.godotengine.org/en/latest/tutorials/scripting/gdscript/index.html) |
| Scene tree, nodes, instancing, groups | [Scene organization](https://docs.godotengine.org/en/latest/getting_started/step_by_step/scenes_and_nodes.html) |
| Input, `_unhandled_input`, mouse events | [Input documentation](https://docs.godotengine.org/en/latest/tutorials/inputs/index.html) |
| Custom Resources (`.tres`) for data | [Resources](https://docs.godotengine.org/en/latest/tutorials/scripting/resources.html) |
| Project layout, autoloads | [Project organization](https://docs.godotengine.org/en/latest/tutorials/best_practices/project_organization.html) |
| Headless smoke / `--script` tooling | [`docs/technical/GODOT_HEADLESS_PITFALLS.md`](technical/GODOT_HEADLESS_PITFALLS.md) — **read before pipeline or smoke refactors** |

Agents must **not invent Godot APIs**. If a method or property is not in the
official docs for the pinned engine version, stop and ask.

## Pathfinding

| Item | Value |
|---|---|
| Library | `AStarGrid2D` (built-in) — **not** NavigationAgent3D |
| Wrapper | `scripts/agents/movement_adapter.gd` |
| Grid resolution | 1 tile = 1 meter |
| Diagonal movement | Allowed; cost `√2 ≈ 1.4142` |
| Heuristic | `OCTILE` (default) |

See `docs/architecture-reconciliation.md` for why navmesh pathfinding from the
deep-research report does not apply here.

## File format policy

| Format | Role |
|---|---|
| `.blend` | Editable source (internal only) |
| `.glb` / `.gltf` | Static runtime assets (props, env) |
| `.fbx` | Animated character interchange (AccuRIG / Mixamo / Cascadeur) |
| `.usd` | Side-branch only |
| `.dae` | Fallback interchange |

Full pipeline: `docs/asset-pipeline.md`. Import defaults: `docs/import-settings.md`.
Third-party plugins and CC0 art policy: `docs/asset-library-acquisition.md`, `docs/third-party-tools.md`.
License tracking: `docs/legal/THIRD_PARTY_LICENSES.md`.
Project folders: `docs/technical/PROJECT_STRUCTURE.md`.

## Asset pipeline

| Stage | Tool / location |
|---|---|
| Draft generation | Meshy AI (web or API) |
| Cleanup / source | Blender |
| Rigging | AccuRIG (production), Mixamo (placeholder) |
| Animation polish | Cascadeur |
| Static runtime | `.glb` → `assets/props/`, `assets/env/` |
| Characters | `.fbx` → `assets/characters/` |
| Meshy plugin drop | `assets/meshy/` |

## Agent control plane

| Item | Value |
|---|---|
| Cursor MCP bridge (primary) | Aesthetic Engine GRB |
| Cursor MCP bridge (fallback) | `dreamer568/godot-mcp` |
| Meshy MCP (optional) | Meshy API MCP for asset batching — see Meshy docs |
| Bind address | `127.0.0.1` only |
| Port | `7777` (default) |
| Auth | `.cursor/secrets/grb.token` (gitignored) |

## Performance budgets

| Scene | CPU frame budget | GPU frame budget | Notes |
|---|---|---|---|
| `main_menu.tscn` | 4 ms | 4 ms | Static UI |
| `colony.tscn` (~10 goblins) | 8 ms | 8 ms | Phase 2 vertical slice |
| `colony.tscn` (~100 goblins) | 12 ms | 12 ms | Phase 3 target; 60 fps floor |

## Tooling

| Tool | Required version | How installed |
|---|---|---|
| Node.js | ≥ 18.x | Cursor bundled or system |
| GUT | latest 4.x | Asset library → `addons/gut/` |
| Meshy Godot plugin | latest | Asset library → `addons/meshy/` |
| **Terrain3D** | **v1.0.2-stable** (spike) | GitHub release → `addons/terrain_3d/` — see [`docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md`](technical/TERRAIN3D_HYBRID_MAP_PLAN.md) |

### Headless testing

| Item | Value |
|---|---|
| Reference doc | [`docs/technical/GODOT_HEADLESS_PITFALLS.md`](technical/GODOT_HEADLESS_PITFALLS.md) |
| Console binary | `Godot_v4.7-stable_win64_**console**.exe` for CI/smoke |
| Phase 2 gate | `tools/run_phase2_regression.ps1` |
| Phase 3 gate | `tests/smoke/test_terrain3d_movement_spike.gd` |
| Prefer | Targeted `tests/smoke/*.gd` scripts |
| Avoid | Loading full dev `.tscn` files headless (Terrain3D + camera scenes may hang); use thin smoke + programmatic nodes |
| Avoid | Relying on `--check-only` when plugins/MCP active (may hang) |

### Terrain3D (compatibility spike)

| Item | Value |
|---|---|
| Plugin | Terrain3D v1.0.2-stable |
| Source | https://github.com/TokisanGames/Terrain3D/releases/tag/v1.0.2-stable |
| License | MIT |
| Official Godot support | 4.4–4.6+ (4.7 must be proven by spike) |
| Install location | `res://addons/terrain_3d/` |
| Production dependency | **No** — spike/isolated dev scene only until migration |
| Gameplay authority | **No** — `AStarGrid2D` + `movement_adapter.gd` remain authoritative |
| Blender | 4.x LTS recommended | Manual — cleanup pass |
| AccuRIG | latest free | Manual — production rigs |
| Cascadeur | free tier+ | Manual — animation polish |

## Open questions

- C# vs GDScript if goblin count > 200.
- Jolt physics for prop knockdowns.
- Custom Meshy thumbnail pipeline.
