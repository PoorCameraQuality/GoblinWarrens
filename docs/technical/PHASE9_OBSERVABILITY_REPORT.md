# Phase 9 — Colony Observability Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-11  
**Design ref:** `TERRAIN3D_HYBRID_MAP_PLAN.md` §12, Phase 9

---

## Goal

Colony debug observability before broader simulation expansion:

1. Goblin inspector — job, phase, path, carry, needs, target, idle hint
2. Colony job inspector — worker counts + available/reserved job targets
3. Debug overlays — runtime walkability, procgen buildability, live goblin paths
4. Debug console commands wired through existing `register.gd`
5. Headless smoke gate (no live colony scene required)

**Not in scope:** full overlay suite from plan §12 (heat maps, raid routes, scatter preview), colony authored-map wiring.

---

## Commands

```powershell
$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tests/smoke/test_colony_observability_smoke.gd
```

**In-game (debug build, F12 / Ctrl+`):**

| Command | Description |
| --- | --- |
| `inspect_goblin [id\|index]` | Snapshot one worker |
| `inspect_goblins` | Snapshot all living workers |
| `inspect_jobs` | Worker + job-target summary |
| `toggle_walkability_overlay` | AStar walkability quads |
| `toggle_buildability_overlay` | Procgen buildability quads |
| `toggle_goblin_paths` | Live path polylines |

---

## Latest headless result

```
[colony-observability-smoke] ok mock_lines=4 inventory_keys=8
exit 0
```

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/debug/colony_observability.gd` | Goblin snapshots, job inventory scan, formatters |
| `scripts/debug/movement_grid_overlay.gd` | Walkability / buildability texture overlay |
| `scripts/debug/goblin_path_overlay.gd` | Live goblin path line renderer |
| `scripts/dev/colony_observability_run.gd` | Headless validation runner |
| `tests/smoke/test_colony_observability_smoke.gd` | CI gate |
| `scripts/agents/goblin.gd` | `dev_observation_extra()` for debug snapshots |
| `scripts/world/colony.gd` | Dev inspect/toggle methods + HUD flags |
| `game/integrations/debug_console/register.gd` | Six new console commands |

---

## Preserved behavior

- Colony still boots procgen map by default — zero gameplay change
- Gather → carry → store loop untouched
- Existing mapgen debug commands and overlays remain
- Beauty mode hides new observability overlays with other debug layers

---

## Test steps (manual)

1. Run colony in debug build
2. Open console → `inspect_goblins` — expect non-empty worker lines
3. `inspect_jobs` — expect gather/build target counts
4. `toggle_walkability_overlay` — green/red grid over terrain
5. `toggle_goblin_paths` — colored lines while workers move
6. `toggle_beauty_mode` — observability overlays cleared

---

## Limitations

- Buildability overlay reads procgen `MapPlan.tile_classes`, not authored bake layers
- Path overlay rebuilds every frame while active (debug-only)
- Job inspector counts reservations, not travel-time or blocked/unreachable analysis
- No dedicated reservation-line or raid-route overlays yet

---

## Next step

Phase 10: one polished demonstration map and 7-day demo loop on authored terrain — or wire authored map bootstrap into `colony.tscn` after explicit approval.
