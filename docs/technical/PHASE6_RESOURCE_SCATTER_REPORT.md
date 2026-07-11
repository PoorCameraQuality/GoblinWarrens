# Phase 6 — Resource Scatter Compiler Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-11  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Bake-time gameplay resource + tree scatter from authored semantic layers:

1. Read `resource_affinity` palette (gold / stone / food)
2. Place deterministic harvestable nodes with stable `placement_id`
3. Scatter blocking wood trees on forest terrain (separate `seed_harvestable`)
4. Add save-state hooks on `ResourceNode` / `TreeResource` (colony wiring deferred)
5. Headless smoke gate

**Not in scope:** colony spawn wiring, procgen `PropScatterer` rewrite, save load from `_ready()`.

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tests/smoke/test_resource_scatter_smoke.gd
```

---

## Latest headless result

```
[resource-scatter-smoke] ok resources=937 trees=1560 total=2497 gold=475 stone=216 food=246
exit 0
```

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/map/resource_scatter_compiler.gd` | Phase 6 compile entry |
| `scripts/world/map/compiled_resource_map.gd` | Placements + stats DTO |
| `scripts/dev/resource_scatter_run.gd` | Headless validation runner |
| `tests/smoke/test_resource_scatter_smoke.gd` | CI gate |
| `scripts/world/mapgen/prop_placement.gd` | `placement_id` field |
| `scripts/world/resource_node.gd` | `placement_id` + export/apply save state |
| `scripts/world/tree_resource.gd` | Save state includes felled/fall_locked |
| `scripts/save/colony_save_data.gd` | `resource_states`, `map_id`, `map_version` prep fields |
| `scripts/world/map/resources/baked_map_data.gd` | `compile_resources()` |

---

## Rules enforced

| Input | Resource nodes | Decorative trees |
| --- | --- | --- |
| `resource_affinity` color | Required (gold/stone/food) | Must be none |
| Walkable grid | Required | Required |
| `no_scatter` ≥ 250 | **Ignored** (explicit resources win) | Blocks placement |
| Min spacing | 3 cells | 2 cells |
| `placement_id` | `{map_id}/res/{tag}/{x}_{y}` | `{map_id}/tree/{x}_{y}` |

---

## Limitations

- One placement per spaced resource pixel cluster (not merged pockets yet)
- Colony still uses procgen `PropScatterer` — authored compile is dev/bake only
- `ColonySaveData.resource_states` is stored but not loaded at runtime yet
- Tree count is high (1560) — may need budget caps in a polish pass

---

## Next step

Phase 7: player-selected Warren placement (`warren_placement_controller.gd`, suitability overlay) — after explicit approval and gates stay green.
