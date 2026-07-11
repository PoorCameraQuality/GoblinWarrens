# Phase 3 — Terrain3D Movement Integration Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-10  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Integrate the Phase 2 baked semantic grid with **Terrain3D** in an **isolated dev scene** (not `colony.tscn`):

1. Load Terrain3D terrain from authored heightmap  
2. Load compiled semantic grid  
3. Place one test agent (editor scene)  
4. Move along `AStarGrid2D` (editor)  
5. Project Y from Terrain3D height queries  
6. Confirm roads, swamp costs, and blockers  

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

# Phase 3 headless gate
& $Godot --headless --path . --script tests/smoke/test_terrain3d_movement_spike.gd

# Phase 2 regression (still required before compiler changes)
& $Godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
```

**Editor visual test:** open `scenes/dev/terrain3d_movement_spike.tscn` — red capsule walks the north–south path over Terrain3D with walkability overlay.

---

## Latest headless result

```
[terrain3d-movement-smoke] ok path=251 road=255 swamp=26 delta=0.00
exit 0 (~7 s)
```

| Check | Result |
| --- | --- |
| Terrain3D loads authored height | Pass |
| Grid compiles | Pass |
| North–south path | 251 tiles |
| Road movement cost | 255 (full speed) |
| Swamp movement cost | 26 (~10% speed) |
| Terrain vs grid height on path | 0.00 m max delta |
| Blocker cells on path | None |
| Colony scene touched | No |

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/terrain/authored_terrain3d_loader.gd` | Bakes `01_heightmap.png` → Terrain3D region data |
| `scripts/dev/terrain3d_movement_run.gd` | Single static validation entry (headless + editor) |
| `scripts/dev/terrain3d_movement_spike.gd` | Editor scene: agent animation + overlay |
| `scenes/dev/terrain3d_movement_spike.tscn` | Isolated Phase 3 dev scene |
| `tests/smoke/test_terrain3d_movement_spike.gd` | Thin headless smoke (no heavy `.tscn` boot) |
| `scripts/agents/movement_adapter.gd` | `set_point_weight_scale()` for swamp/road costs |
| `scripts/world/map/compiled_grid_map.gd` | Applies movement weights when binding grid |
| `data/maps/three_lane_swamp_valley/terrain3d_data/` | Generated Terrain3D region cache (first run) |

---

## Architecture notes

- **Grid authority unchanged:** walkability, buildability, and costs still come from baked semantic layers + `baked_grid_compile.gd`.
- **Terrain3D is physical/visual height only** in this phase — queried via `terrain_surface_adapter.gd`.
- **Headless smoke** creates a bare `Terrain3D` node programmatically; it does **not** load the full dev `.tscn` (see [`GODOT_HEADLESS_PITFALLS.md`](GODOT_HEADLESS_PITFALLS.md)).
- **Movement costs** map to `AStarGrid2D` weight scales: `255 / cost` (swamp paths are expensive vs roads).

---

## Limitations

- Terrain3D region data is **generated on first run** if `terrain3d_data/` is empty (~4 regions for 350×350 m).
- Full `.tscn` with Terrain3D + camera may be slow to boot headless; use the smoke script for CI.
- Collision raycast on Terrain3D remains **editor-verify** (same as Phase 1 spike).
- Colony still uses procgen — authored map is not wired to production gameplay.

---

## Next step

Phase 4+ per [`TERRAIN3D_HYBRID_MAP_PLAN.md`](TERRAIN3D_HYBRID_MAP_PLAN.md): map definition resources, semantic painter plugin, or Warren placement — **only after explicit approval** and Phase 2/3 gates stay green.
