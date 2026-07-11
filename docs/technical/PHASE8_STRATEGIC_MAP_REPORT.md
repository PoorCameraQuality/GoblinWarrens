# Phase 8 — Strategic Map Authoring Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-11  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Strategic semantic authoring + compile path for raids and enemy camps:

1. Editor paint modes for `raid_entry` and `enemy_camp_zone`
2. Bake-time `CompiledStrategicMap` with stable placement IDs
3. `ThreatScheduler` + `spawn_enemy()` accept authored raid cells when strategic map is provided
4. Headless smoke gate

**Not in scope:** landmark layer (no manifest file yet), colony auto-load of strategic map (procgen raids unchanged).

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tests/smoke/test_strategic_map_smoke.gd
```

**Editor:** Goblin Map dock → layers `raid_entry` / `enemy_camp_zone` → paint → Save Source → Re-bake.

---

## Latest headless result

```
[strategic-map-smoke] ok raids=4 camps=0 landmarks=0
exit 0
```

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/map/strategic_map_compiler.gd` | Cluster raid/camp markers from baked PNGs |
| `scripts/world/map/compiled_strategic_map.gd` | Raid/camp DTO + cell pickers |
| `scripts/dev/strategic_map_run.gd` | Headless validation runner |
| `tests/smoke/test_strategic_map_smoke.gd` | CI gate |
| `addons/goblin_map_editor/semantic_paint_session.gd` | Strategic paint layers |
| `addons/goblin_map_editor/goblin_map_dock.gd` | Strategic paint value UI |
| `scripts/world/threat_scheduler.gd` | Optional `strategic_map` in `setup()` |
| `scripts/world/colony.gd` | `spawn_enemy(kind, spawn_cell)` optional cell |
| `scripts/world/map/resources/baked_map_data.gd` | `compile_strategic()` |

---

## Runtime integration (opt-in)

When colony passes a `CompiledStrategicMap` into `ThreatScheduler.setup()`:

- Day 2 beast, day 6 scout, day 7 militia wave spawn at compiled **raid entry** cells (cycled by index)
- Without strategic map → **unchanged** east-edge spawn (`GRID_WIDTH - 2`)

Colony procgen path does **not** pass strategic map yet — zero behavior change in production.

---

## Limitations

- Landmark layer deferred until manifest adds a dedicated PNG
- Enemy camp count may be 0 on reference map (layer sparse); compiler supports camps when painted
- No raid route polyline compile yet (entries are point spawns only)

---

## Next step

Phase 9: colony observability overlays — or wire full authored map bootstrap into `colony.tscn` after explicit approval.
