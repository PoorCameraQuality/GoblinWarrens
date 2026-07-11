# Phase 5 — Deterministic Foliage Scatter Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-11  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Compile deterministic decorative grass scatter from authored semantic layers:

1. Read `foliage_density` + `no_scatter` baked PNGs  
2. Combine with compiled grid walkability + terrain class  
3. Produce a full-cell `FoliagePlan` (density/style buffers + chunks)  
4. Use independent `seed_foliage` from map definition  
5. Visual preview on `terrain3d_movement_spike.tscn` (editor only)

**Not in scope:** colony wiring, gameplay tree/resource scatter (Phase 6), ambient life zones.

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tests/smoke/test_foliage_scatter_smoke.gd
```

**Editor visual:** open `scenes/dev/terrain3d_movement_spike.tscn` — grass MultiMeshes appear near the agent path start.

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/map/decorative_scatter_compiler.gd` | Phase 5 compile entry from semantic layers |
| `scripts/dev/foliage_scatter_run.gd` | Headless validation runner |
| `tests/smoke/test_foliage_scatter_smoke.gd` | CI gate |
| `scripts/world/foliage/foliage_planner.gd` | `plan_from_authored()` delegate |
| `scripts/world/foliage/grass_field_renderer.gd` | `build_authored()` + density buffer probe |
| `scripts/dev/terrain3d_movement_spike.gd` | Editor grass preview hook |
| `scenes/dev/terrain3d_movement_spike.tscn` | `AuthoredGrass` node |

---

## Rules enforced

| Mask / input | Effect |
| --- | --- |
| `no_scatter` ≥ 250 | Zero density (roads, clearings) |
| Not walkable | Zero density |
| `foliage_density` R8 | Base density 0–1 |
| Terrain class | Style + scale multiplier |
| `seed_foliage` | Per-cell jitter + per-chunk instance seed |

---

## Limitations

- Ambient zones (fireflies/butterflies) not compiled from authored map yet  
- Grass builds only near focus cell (same radius as procgen camp)  
- Colony still uses procgen `FoliagePlanner.plan()` — authored path is dev-only  
- Re-bake required after semantic paint changes to `foliage_density` / `no_scatter`

---

## Next step

Phase 6: bake-time resource compiler + stable `placement_id` on resource nodes.
