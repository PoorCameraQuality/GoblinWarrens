# Colony Authored Map Integration

**Status:** Workstream 2 complete  
**Date:** 2026-07-11

---

## Overview

Production `scenes/colony.tscn` can boot from the authored map pipeline while **procgen remains the default**.

| Setting | Default | Authored |
| --- | --- | --- |
| `game/map_mode` | `procgen` | `authored` |
| `game/authored_map_root` | `res://data/maps/three_lane_swamp_valley` | same or other pack |
| Terrain | Procgen mesh | Terrain3D + compiled grid |
| Warren | Auto-centered | Player pick UI |
| Raids | East edge | Compiled raid entries |

---

## Enable authored mode

**Project Settings → game:**

```
map_mode = authored
authored_map_root = res://data/maps/three_lane_swamp_valley
```

Or environment variables (CI / headless):

```
GC_MAP_MODE=authored
GC_AUTHORED_AUTO_WARREN=1
GC_AUTHORED_COLONY_SMOKE=1   # quit after bootstrap verify
```

**Dev shortcut:** `scenes/dev/authored_demo.tscn` — colony with `defer_world_setup=true` (Warren pick, no project setting change).

---

## Flow

1. Colony `_ready()` detects authored mode → defers world setup
2. **Warren pick panel** (`UI/WarrenPickPanel`) or auto-pick (headless)
3. `authored_colony_bootstrap.gd` compiles grid/resources/strategic/foliage
4. `apply_authored_world()` → Terrain3D, resources, Warren, storehouse
5. `finish_deferred_startup(strategic_map)` → 7-day loop with authored raids

---

## Save schema v2

When `_authored_mode`:

- `schema_version = 2`
- `map_id`, `map_version`, `warren_cell`
- `resource_states[]` with `placement_id`, `remaining`, tree felled state

Procgen saves remain schema v1.

---

## Tests

```powershell
# Bootstrap DTO (fast)
godot --headless --path . --script tests/smoke/test_authored_colony_bootstrap.gd

# Procgen regression
godot --headless --path . --script tests/smoke/test_colony.gd

# Full authored colony scene (env vars)
./tools/run_authored_colony_smoke.ps1
```

---

## Rollback

Set `game/map_mode=procgen` — all authored code paths dormant.

---

## Next step

Workstream 3: commits, `run_all_smokes` script, HANDOFF update.
