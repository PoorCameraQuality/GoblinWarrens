# Phase 10 — Demonstration Map Report

**Status:** Workstream 1 complete (headless smoke passing)  
**Date:** 2026-07-11  
**Map:** `three_lane_swamp_valley`  
**Demo scene:** `scenes/dev/authored_demo.tscn`

---

## Goal

Polished authored demo map playable for 7 days in a **dev-only** scene — production `colony.tscn` still procgen.

---

## Commands

```powershell
$G = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

# Phase 10 gate
& $G --headless --path . --script tests/smoke/test_authored_demo_smoke.gd

# Editor play
# Open scenes/dev/authored_demo.tscn → Play → Warren pick UI → 7-day loop
```

---

## Latest headless results

**Bootstrap runner:**
```
ok warren=(104, 286) walkable=96845 resources=937 trees=1560 raids=4 candidates=32
```

**Scene spawn verify:**
```
[authored-demo-smoke] ok resources=2497 warren=(104, 286) store=(106, 286) raids=4
exit 0
```

**Warren candidates:** 32 valid sites (≥3 required)

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/map/authored_colony_bootstrap.gd` | Compile grid/resources/strategic/foliage → colony package |
| `scripts/world/map/authored_map_plan_adapter.gd` | Minimal `MapPlan` from compiled data |
| `scripts/ui/warren_pick_panel.gd` + `scenes/ui/warren_pick_panel.tscn` | Pre-game Warren selection UI |
| `scripts/dev/authored_demo_colony.gd` | Extends colony; deferred authored bootstrap |
| `scenes/dev/authored_demo.tscn` | Inherits `colony.tscn`, `defer_world_setup=true` |
| `scripts/dev/authored_demo_run.gd` | Headless bootstrap validation |
| `tests/smoke/test_authored_demo_smoke.gd` | CI gate (bootstrap + scene spawn) |
| `scripts/world/colony.gd` | `defer_world_setup`, `apply_authored_world()`, Terrain3D path |

---

## Preserved behavior

- `scenes/colony.tscn` unchanged (procgen default)
- Gather → carry → store loop untouched
- All prior authored-map smokes still valid

---

## Manual 7-day test (editor)

1. Open `scenes/dev/authored_demo.tscn` → Play
2. Cycle Warren candidates → **Start Here**
3. Verify workers gather from compiled resources
4. Day 2 beast / day 6 scout / day 7 militia spawn at **authored raid entries** (not east edge)
5. Survive or lose with understandable cause

---

## Limitations

- Map content polish (biome painting, extra start zones) is incremental — 32 candidates already exist
- Grass uses procgen foliage path near Warren chunk (not full-map grass bake in demo)
- Manual 7-day playtest not automated in CI
- Landmark layer still deferred

---

## Next step

**Workstream 2:** Wire authored bootstrap into production `colony.tscn` via `map_mode` flag + save schema v2.
