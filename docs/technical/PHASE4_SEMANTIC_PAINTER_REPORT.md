# Phase 4 — Semantic Map Editor Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-10  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Deliver plan Phase 3 foundation (typed map definition resources) and Phase 4 minimal semantic painter:

1. Load authored map metadata from `manifest.json` + `import_report.json`
2. Expose `GoblinMapDefinition`, `BakedMapData`, and supporting Resources
3. Editor dock plugin to preview and paint initial semantic layers
4. Headless smoke gate (no editor UI boot)

**Not in scope:** colony integration, procgen replacement, foliage/resource bake, Warren placement.

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

# Phase 4 headless gate
& $Godot --headless --path . --script tests/smoke/test_map_definition_smoke.gd

# Prior gates (still required)
& $Godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
& $Godot --headless --path . --script tests/smoke/test_terrain3d_movement_spike.gd
```

**Editor:** enable **Goblin Map Editor** plugin (Project → Project Settings → Plugins). Dock appears top-left as **Goblin Map**.

---

## Editor workflow

1. Open Godot editor on this project.
2. In the **Goblin Map** dock, confirm map root `res://data/maps/three_lane_swamp_valley`.
3. Click **Load Map** — preview shows the active semantic layer (downscaled).
4. Choose layer: `biome_id`, `buildability`, `start_zone`, or `no_scatter`.
5. Pick paint value, adjust brush radius, left-drag on preview to paint **source** PNG pixels.
6. **Save Source** writes the source layer under `source/`.
7. **Re-bake** runs `MapSemanticImporter` to refresh `baked/350/`.

---

## Files added

| File | Role |
| --- | --- |
| `scripts/world/map/resources/*.gd` | Typed Resources (definition, biomes, placements, validation) |
| `scripts/world/map/map_definition_factory.gd` | Manifest → `GoblinMapDefinition` loader |
| `addons/goblin_map_editor/` | Editor plugin + dock + paint session |
| `tests/smoke/test_map_definition_smoke.gd` | Thin headless gate |
| `tests/unit/test_map_definition.gd` | GUT unit tests |
| `tests/unit/test_baked_map_data.gd` | GUT compile bridge tests |

---

## Paintable layers (initial)

| Layer | Paint values |
| --- | --- |
| `biome_id` | Manifest biome palette colors |
| `buildability` | Black = unbuildable, white = buildable |
| `start_zone` | Gray neutral / green allowed / red forbidden |
| `no_scatter` | Black = scatter OK, white = no scatter |

---

## Architecture notes

- **Source PNGs remain authoritative** for painted layers; re-bake resamples to `baked/350/`.
- **Phase 2 compiler unchanged** — `baked_grid_compile.gd` stability boundary preserved.
- **Colony untouched** — procgen remains production path.
- Headless tests use thin `_init` entry scripts per [`GODOT_HEADLESS_PITFALLS.md`](GODOT_HEADLESS_PITFALLS.md).

---

## Limitations

- Dock preview is downscaled (512 px max side); painting maps UV → full-resolution source pixels.
- No undo/redo stack yet; save frequently.
- Biome paint uses manifest hex palette only (no custom color picker).
- Fixed placements, raid entries, and enemy camps are load-only (no placement UI until Phase 8).

---

## Next step

Phase 5 per [`TERRAIN3D_HYBRID_MAP_PLAN.md`](TERRAIN3D_HYBRID_MAP_PLAN.md): deterministic foliage population from semantic masks — after Phase 2–4 gates stay green and explicit approval.
