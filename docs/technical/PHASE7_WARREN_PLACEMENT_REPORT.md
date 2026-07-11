# Phase 7 — Warren Placement Report

**Status:** Complete (headless smoke passing)  
**Date:** 2026-07-11  
**Map:** Three-Lane Swamp Valley (`three_lane_swamp_valley_reference`)

---

## Goal

Player-selected Warren placement foundation for authored maps:

1. Load baked grid + semantic layers (`start_zone`, roads, enemy camps, raid entries)
2. Validate + score Warren footprint candidates (2×2)
3. Rank candidates with suitability labels
4. Dev suitability heat-map overlay
5. Optional `MapGenerator.build(config, override_warren_cell)` hook (procgen default unchanged)

**Not in scope:** colony `_ready()` flow change, fog reveal, confirm UI in production.

---

## Commands

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force

$Godot = "C:\Users\shkin\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"

& $Godot --headless --path . --script tests/smoke/test_warren_placement_smoke.gd
```

**Editor:** open `scenes/dev/warren_placement_spike.tscn` — suitability heat-map + top candidates. Use **A/D** or **Left/Right** to cycle.

---

## Latest headless result

```
[warren-placement-smoke] ok candidates=32 top=(104, 286) score=100 label=Defensible
exit 0 (~32 s — candidate scan is intentionally exhaustive)
```

---

## Files added / changed

| File | Role |
| --- | --- |
| `scripts/world/warren/warren_placement_controller.gd` | Validate, score, rank candidates |
| `scripts/world/warren/warren_suitability_overlay.gd` | Dev heat-map overlay |
| `scripts/dev/warren_placement_run.gd` | Headless validation runner |
| `scripts/dev/warren_placement_spike.gd` | Editor candidate browser |
| `scenes/dev/warren_placement_spike.tscn` | Dev scene |
| `tests/smoke/test_warren_placement_smoke.gd` | CI gate |
| `scripts/world/mapgen/map_generator.gd` | Optional `override_warren_cell` param |

---

## Validation rules

| Check | Fail reason |
| --- | --- |
| 2×2 footprint in bounds | `out_of_bounds` |
| Border distance ≥ 8 cells | `too_close_to_border` |
| Start zone not forbidden | `start_zone_forbidden` |
| All footprint cells walkable + buildable | `blocked_cell` / `unbuildable_cell` |
| Height delta ≤ 0.45 m | `slope_too_steep` |
| Walkable exits ≥ 2 | `walkable_exits` |
| Buildable tiles near camp ≥ 80 | `buildable_near` |
| Not on road clearance | `on_protected_road` |
| South-half preference (manifest rule) | filtered in candidate search |

Tags: **Rich**, **Defensible**, **Dangerous**, **Exposed** from resources / border / enemy / raid layers.

---

## Limitations

- Candidate scan is O(n) over grid — ~30 s headless on 350×350 (acceptable for gate, optimize later)
- Colony still auto-centers Warren via procgen `MapGenerator.build(config)`
- No click-to-place in editor yet (keyboard cycle only)
- Confirm → spawn Warren + goblins not wired

---

## Next step

Phase 8: strategic map authoring (raid entrances, enemy camps, landmarks in map editor) — or wire Phase 7 into `colony.tscn` after explicit approval.
