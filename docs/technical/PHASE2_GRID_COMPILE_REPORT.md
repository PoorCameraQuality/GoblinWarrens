# Phase 2 — Grid Compile Completion Report

**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)  
**Status:** Complete (approval gate passed from clean headless runs)  
**Date:** 2026-07-10

---

## Exact commands run

From repo root (`E:\Projects\goblin-colony`), after stopping stray Godot processes:

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tools/import_semantic_map.gd
& $Godot --headless --path . --script tests/smoke/test_semantic_map_import.gd
& $Godot --headless --path . --script tests/smoke/test_grid_compiler.gd
& $Godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
```

One-shot gate (import + regression artifact):

```powershell
tools/run_phase2_regression.ps1
```

---

## Godot version

**4.7-stable (official)** — `5b4e0cb0f`

---

## Elapsed time (clean sequential run)

| Step | Approx. wall time |
| --- | --- |
| `import_semantic_map.gd` | ~4 s |
| `test_semantic_map_import.gd` | ~4 s |
| `test_grid_compiler.gd` | ~3 s |
| `test_semantic_map_regression.gd` | ~6 s (includes fresh import + dual compile) |
| **Full suite total** | **~16 s** |

Regression script internal `elapsed_ms`: **~1034 ms** (import + validation + dual compile + pathfind + artifact write, after project boot).

Earlier `4294967295` exits and multi-minute hangs are **stale debugging artifacts** from GDScript analyzer stalls; not reproduced on the current frozen implementation.

---

## Metrics (latest passing run)

| Metric | Value |
| --- | --- |
| Walkable cells | **96,845** |
| Blocked cells | **25,655** |
| Buildable cells | **41,647** |
| North–south path length | **251** tiles `(175,300) → (175,50)` |
| Swamp/road overlap | **0** |
| Road pixels not full speed | **0** |
| Road pixels not no-scatter | **0** |
| Compile fingerprint (SHA-256) | `bf732dd6a09f93ab46b93254464dc41d7ae6e58fafeacab03b1e785e2f20941b` |
| Source image dimensions | **1254 × 1254** px (native) |
| Compiled grid dimensions | **350 × 350** (122,500 cells) |
| Palette validation | **pass** (via import validation pipeline) |

Artifact: `data/maps/three_lane_swamp_valley/phase2_regression_artifact.json`

---

## Files changed (Phase 2)

| File | Role |
| --- | --- |
| `scripts/world/map/compiled_grid_map.gd` | Compiled grid DTO |
| `scripts/world/map/baked_grid_compile.gd` | Single-function compiler (**stability boundary**) |
| `scripts/world/map/grid_compiler.gd` | Thin compile wrapper |
| `scripts/world/map/map_semantic_importer.gd` | Semantic layer import + validation |
| `scripts/world/terrain/terrain_surface_adapter.gd` | Height sampling helpers |
| `scripts/world/map/debug/compiled_grid_overlay.gd` | Dev walk/build overlay |
| `scripts/agents/movement_adapter.gd` | Instance grid bounds (not hardcoded constants) |
| `tools/import_semantic_map.gd` | Headless import runner |
| `tests/smoke/test_semantic_map_import.gd` | Import smoke test |
| `tests/smoke/test_grid_compiler.gd` | Compile + path smoke test |
| `tests/smoke/test_semantic_map_regression.gd` | Phase 2 regression + artifact writer |
| `tools/run_phase2_regression.ps1` | One-shot approval gate script |
| `scenes/dev/authored_map_spike.tscn` | Isolated grid overlay preview (no colony) |
| `data/maps/three_lane_swamp_valley/**` | Manifest, baked 350×350 layers, reports |

---

## Regression coverage

`tests/smoke/test_semantic_map_regression.gd` verifies:

- Reserved keyword `class_name` is not used as a parameter name in compiler/importer sources
- Fresh import from a clean process succeeds
- Import validation passes (road/swamp overlap, full speed, no-scatter, layer alignment)
- Movement blocker cells are not walkable in compiled grid
- All packed arrays are 122,500 entries
- Two consecutive compiles produce identical SHA-256 fingerprints
- North–south A* path exists
- No `colony.tscn` or Terrain3D runtime dependency

---

## Warnings

- **None** on latest clean runs (exit code 0 across full suite).
- **Godot 4.7 GDScript analyzer:** Large multi-function `--script` entry files can fail fast (exit 1) or hang. Regression suite is intentionally kept as a **single `_init` block** without helper functions — same stability pattern as `baked_grid_compile.gd`. Do not refactor without re-running the headless suite before and after. **Full reference:** [`docs/technical/GODOT_HEADLESS_PITFALLS.md`](GODOT_HEADLESS_PITFALLS.md).
- **Palette check:** Full per-pixel terrain-class palette scan is delegated to the import validation pipeline for regression stability; compile-time palette mapping still runs in `baked_grid_compile.gd`.

---

## Intentional technical debt

`baked_grid_compile.gd` is kept as **one function** because distributing the same logic across typed helper functions and sibling scripts caused repeatable Godot 4.7 analyzer stalls in headless `--script` mode. This is a **stability boundary**, not the ideal long-term architecture.

Before any compiler refactor, run:

```text
godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
```

---

## Phase 2 approval gate

| # | Criterion | Result |
| --- | --- | --- |
| 1 | Semantic manifest loads | Pass |
| 2 | All layers normalize to 350×350 | Pass |
| 3 | Exact palettes validate | Pass (import validation) |
| 4 | Packed grid arrays = 122,500 | Pass |
| 5 | Road precedence | Pass |
| 6 | Blocker compilation | Pass |
| 7 | North–south route exists | Pass |
| 8 | Two consecutive runs identical | Pass |
| 9 | No colony / Terrain3D dependency | Pass |
| 10 | Report saved as artifact | Pass (`phase2_regression_artifact.json`) |

**Phase 2 is complete.**

---

## Next step — Phase 3 (approved target)

**Complete.** See [`docs/technical/PHASE3_TERRAIN3D_MOVEMENT_REPORT.md`](PHASE3_TERRAIN3D_MOVEMENT_REPORT.md).

Editor scene: `scenes/dev/terrain3d_movement_spike.tscn`  
Headless gate: `tests/smoke/test_terrain3d_movement_spike.gd`
