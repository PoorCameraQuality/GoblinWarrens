# Procedural Map Generation — Plan

**Status:** Phases **1–3 shipped**; Phase **4 corridor metadata shipped** (enemy AI hookup pending); Phase **5 partial**  
**Owner:** Cursor + project owner  
**Last updated:** 2026-07-09  
**Runtime authority:** `colony.gd` `_setup_world()` + debug command `print_mapgen_status`

> **Direction pivot (2026-07-10):** Future map development moves to a **Terrain3D hybrid** workflow (authored terrain + semantic paint + baked grid + player Warren placement). This document remains the authority for the **currently shipped** runtime procgen pipeline until migration phases complete. See [`docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md`](technical/TERRAIN3D_HYBRID_MAP_PLAN.md).

## Runtime status (verified 2026-07-08)

`project.godot` main scene is `res://scenes/colony.tscn`. At runtime:

| Item | Active value |
|---|---|
| Map size | **350 × 350** tiles (`Constants.GRID_WIDTH/HEIGHT`) |
| Map seed | **424242** (`MapConfig.default_for_demo()`) |
| Terrain source | **Generated `ArrayMesh`** via `TerrainMeshBuilder` |
| Legacy `Ground` CSG | Present in scene, **hidden** at runtime (`visible = false`) |
| `HeightmapGenerator` | **Yes** — called from `MapGenerator.build()` |
| `TerrainClassifier` | **Yes** |
| `TerrainMeshBuilder` | **Yes** |
| Prop scatter | **Yes** — `prop_scatterer.gd` (cluster + border + pocket budgets) |
| Corridor planner | **Yes** — `corridor_planner.gd` writes `main_raid_path_cells` / approach lanes |
| Composition masks | **Yes** — irregular clearing + path arms via `MapAuthoringData` |
| `MapPlan` applied | **Yes** — `colony._setup_world()` |
| Macro textures | **Yes** — all seven `*_macro.png` present; `macro_texture_mode=true` |
| Chunked grass / ambient life | **Yes** — `FoliagePlanner` + MultiMesh grass + shared wind globals + particle zones |
| `EnvironmentDresser.populate()` | **No** — dead code path, not called |
| Hand-placed demo resources | **No** — `_spawn_demo_resources()` not called |
| Resources | **Procgen scatter** → `_apply_prop_placements()` |

**Composition pass (2026-07-09):** irregular clearing, raid lane + footpaths, resource pockets, dense border trees, darker fog/horizon skirt, `toggle_composition_overlay` / `toggle_beauty_mode`. Enemy spawn-from-corridor still pending.

**Separate scenes:**

| Scene | Purpose |
|---|---|
| `scenes/colony.tscn` | Production — full procgen map |
| `game/scenes/asset_test_scenes/terrain_texture_review.tscn` | 7-class texture QA strips only |
| Other `asset_test_scenes/*` | Per-asset scale review, not procgen |

## 1. Purpose

Replace `colony.gd._setup_world()`'s hand-placed resources + `EnvironmentDresser`'s hardcoded prop list with a **data-driven, seeded, heightmap-based procedural map generator**.

The generator produces a 3D terrain mesh with hills and valleys, classifies every gameplay tile by slope + height + zone, scatters props from `VisualCatalog` according to classification, plans enemy approach corridors, and produces a `MapPlan` that `colony.gd` applies at world setup.

## 2. Authority

- **Design authority** — `docs/goblin-warrens-design.md`: single above-ground map (§5.1), map contents (§5.2), map tension (§5.3).
- **Engineering contract** — `AGENTS.md`: `AStarGrid2D`-only pathfinding, no autoloads beyond `Log`/`Bus`/`Defs`/`Services`, `Log.info/warn/error` (no raw `print`), no runtime mutation of committed art.
- **Asset pipeline** — `docs/asset-pipeline.md`: GLB for props, PNG for textures.
- **This document** — authoritative for map-generation architecture, data model, texture palette, and phase plan.

## 3. Non-goals (MVP)

Out of scope for this iteration:

- Multiple biomes (Goblin Forest Valley only)
- Rivers, streams, ponds, or any water body
- Erosion simulation
- Chunk streaming or infinite maps (single fixed-size map)
- Terrain slopes above ~45° (capped in noise)
- Runtime terrain deformation during play (build sites use only spawn-time flattening)
- Runtime map regeneration during gameplay (debug regen reloads the scene)

## 4. Architecture

### 4.1 Data flow

```
MapConfig ──▶ MapGenerator.build()
                │
                ├─▶ Heightmap.generate()           ────▶ float grid
                │       ├─ layered fBm noise
                │       ├─ camp flatten
                │       └─ smoothing pass
                │
                ├─▶ TerrainClassifier.classify()   ────▶ TileClass grid
                │                                        + slope, height,
                │                                          walkable, buildable
                │
                ├─▶ CorridorPlanner.plan()         ────▶ approach lanes marked walkable
                │
                ├─▶ TerrainMesh.build()            ────▶ ArrayMesh with vertex colors
                │
                └─▶ PropScatterer.scatter()        ────▶ Array[PropPlacement]

MapPlan { mesh, tile_classes, placements, corridors, warren_cell }

colony._setup_world():
    plan = MapGenerator.build(config)
    _apply_terrain(plan.mesh)     # replaces $Ground
    _apply_grid(plan.tile_classes) # feeds MovementAdapter walkable/buildable
    _apply_props(plan.placements)  # replaces EnvironmentDresser + hand-placed nodes
    _apply_camp(plan.warren_cell)  # Warren + Storehouse at flattened center
```

### 4.2 Modules

| File | Responsibility |
|---|---|
| `data/mapgen/map_config.gd` | Resource: size, seed, biome id, noise params, thresholds |
| `data/mapgen/biome_def.gd` | Resource: texture palette + prop palette + densities |
| `data/mapgen/biome_catalog.gd` | Static factory: `goblin_forest_valley()` |
| `scripts/world/mapgen/map_rng.gd` | Seeded `RandomNumberGenerator` wrapper |
| `scripts/world/mapgen/heightmap.gd` | Layered fBm + camp flattening + smoothing |
| `scripts/world/mapgen/terrain_mesh.gd` | Heightmap → `ArrayMesh` with vertex colors |
| `scripts/world/mapgen/terrain_classifier.gd` | Per-tile `{class, slope, height, walkable, buildable}` |
| `scripts/world/mapgen/prop_scatterer.gd` | Class-aware scatter via `VisualCatalog` *(inlined into `map_generator.gd` as `_scatter_props`; separate file removed)* |
| `scripts/world/mapgen/corridor_planner.gd` | Mark 2–3 enemy approach lanes |
| `scripts/world/mapgen/map_plan.gd` | Data class: mesh + tile classes + placements |
| `scripts/world/mapgen/map_generator.gd` | Orchestrator: `MapConfig` in, `MapPlan` out |
| `game/art/terrain/materials/terrain_blend.gdshader` | 7-texture vertex-color splat shader |
| `scripts/world/colony.gd` *(modified)* | Replaces `_setup_world()` with `MapGenerator.build()` + applier |

## 5. Terrain classes

Enum extension (`Defs.TerrainClass`):

| Value | Name | Walkable | Buildable | Design role |
|---:|---|:-:|:-:|---|
| 0 | `MUD_CLEARING` | yes | yes | Central flattened camp floor |
| 1 | `MOSS` | yes | yes | Flat mid-elevation "grass" |
| 2 | `FOREST_FLOOR` | yes | **no** | Dense forest, trees scatter here |
| 3 | `ROCKY_SLOPE` | slow | **no** | 20–40° slopes, rocks scatter here |
| 4 | `MUD_MOSSY` | yes | yes | Wet lowlands + transition zones |
| 5 | `CLIFF` | **no** | **no** | Slopes >40°, unbuildable |
| 6 | `WARREN_GROUND` | yes | yes | Small decorative ring around Warren |

`FOREST_FLOOR` is deliberately unbuildable — preserves the "clear trees to expand the camp" gameplay hook implied by the design doc.

## 6. Classification rules

Evaluated per tile, in this exact order:

```gdscript
if inside_camp_radius(cell):   return MUD_CLEARING
if inside_warren_ring(cell):   return WARREN_GROUND
if slope > CLIFF_ANGLE:        return CLIFF        # 40°
if slope > ROCKY_ANGLE:        return ROCKY_SLOPE  # 20°
if norm_height > FOREST_TOP:   return FOREST_FLOOR # 0.80
if norm_height < LOWLAND_TOP:  return MUD_MOSSY    # 0.30
return MOSS
```

- **Slope**: computed from the height difference to 4-neighborhood tiles, converted to degrees.
- **Normalized height**: `(h - h_min) / (h_max - h_min)` per generated map.
- **Camp radius**: configured in `MapConfig` (default 4 tiles).
- **Warren ring**: `warren_cell` outer perimeter (default 1 tile thick outside the Warren footprint).

## 7. Camp flattening

Circular blend around `warren_cell` (default = map center):

```
r_flat  = 4 tiles  → force height = camp_height
r_blend = 7 tiles  → smoothstep blend camp_height → natural
```

`camp_height` = mean natural height across the blend radius, so the clearing sits at local average elevation, avoiding awkward mesas or pits.

## 8. Noise design

Layered fBm using Godot's `FastNoiseLite`:

```
h(x, z) = height_scale * (
    1.00 * simplex(x·base_scale,   z·base_scale)   +
    0.55 * simplex(x·hill_scale,   z·hill_scale)   +
    0.30 * simplex(x·detail_scale, z·detail_scale)
)
```

Defaults for 32×32 map, `TILE_SIZE = 1m`:

| Parameter | Value | Meaning |
|---|---:|---|
| `height_scale` | 4.0 m | Total elevation range |
| `base_scale` | 0.03 | Broad hills (~30m period) |
| `hill_scale` | 0.10 | Medium bumps (~10m period) |
| `detail_scale` | 0.35 | Small surface (~3m period) |
| `octaves` | 3 | fBm octave count |
| `persistence` | 0.55 | Amplitude falloff |
| `lacunarity` | 2.0 | Frequency growth |
| `smoothing_passes` | 1 | Box-blur post-process |

Seed drives all four calls (base, hill, detail, jitter) via distinct `FastNoiseLite` instances with `seed = base_seed + N`.

## 9. Texture palette

All under `game/art/terrain/goblin_warrens/`:

| File | Class | Role |
|---|---|---|
| `dirt_packed.png` | `MUD_CLEARING` | Primary |
| `dirt_smooth.png` | `MUD_CLEARING` | Variant |
| `mud_wet.png` | `MUD_CLEARING` | Variant |
| `forest_floor_moss.png` | `MOSS` | Primary |
| `forest_floor_flowered.png` | `MOSS` | Variant |
| `forest_floor_roots_heavy.png` | `FOREST_FLOOR` | Primary |
| `forest_floor_leaves.png` | `FOREST_FLOOR` | Variant |
| `forest_floor_roots_mixed.png` | `FOREST_FLOOR` | Variant |
| `forest_floor_dark_cracked.png` | `FOREST_FLOOR` | Variant |
| `forest_floor_rocky.png` | `ROCKY_SLOPE` | Primary |
| `forest_floor_stony.png` | `ROCKY_SLOPE` | Variant |
| `path_stony.png` | `ROCKY_SLOPE` | Variant |
| `mud_mossy.png` | `MUD_MOSSY` | Primary |
| `dirt_leafy.png` | `MUD_MOSSY` | Variant |
| `mud_bedrock.png` | `CLIFF` | Only |
| `mud_root_lattice.png` | `WARREN_GROUND` | Only |

Import settings (add to `docs/import-settings.md`): `filter=Linear`, `mipmaps=on`, `repeat=on`, `compress=VRAM Compressed` (revisit if quality drops).

## 10. Rendering — vertex-color splat shader

Approach: each terrain-mesh vertex carries a per-class weight; the shader samples the class primaries and blends. Variant selection is per-triangle via a hash of world position, so a `FOREST_FLOOR` triangle randomly picks one of the four forest variants for a coherent, non-repetitive look.

Implementation detail is deliberately deferred to Phase 2 — first pass may use a simpler "one dominant class per vertex" scheme if the 7-way splat proves finicky. Fallback: `StandardMaterial3D` per-class atlas.

## 11. Prop scatter rules

| Class | Prop palette (from `VisualCatalog`) | Density | Path-blocking |
|---|---|---:|---|
| `MUD_CLEARING` | *(none — scatter-free)* | 0% | — |
| `MOSS` | `ENV_GRASS`, `ENV_BUSH`, occasional `ENV_BERRY_BUSH` | 40% | bushes yes, grass no |
| `FOREST_FLOOR` | `ENV_TREE`, `ENV_TREE_PINE`, `ENV_TREE_DEAD`, `RESOURCE_FOOD` (mushrooms) | 55% | trees + mushrooms yes |
| `ROCKY_SLOPE` | `ENV_ROCK`, `ENV_ROCK_SMALL`, occasional `RESOURCE_GOLD` | 30% | rocks yes |
| `MUD_MOSSY` | `RESOURCE_FOOD`, `ENV_BERRY_BUSH`, `ENV_BONE_PILE`, `ENV_BUSH` | 45% | mushrooms + bushes yes, bones no |
| `CLIFF` | *(none — unreachable)* | 0% | — |
| `WARREN_GROUND` | `ENV_BONE_PILE`, `ENV_CRATE`, `ENV_BARREL` | 10% | no |

Per-instance placement rules:
- Seeded weighted roll per tile
- Sub-tile jitter ±0.3m X/Z for decorative props; tile-centered for blockers
- Random Y-rotation 0–360°
- Scale variance 0.85–1.15
- Spacing: no two blocker props within 1 tile of each other (Poisson-lite reject)
- **Reachability check**: BFS from `warren_cell` to every placed resource node; any unreachable node is removed and re-scattered elsewhere

## 12. Corridor planner

Marks 2–3 approach corridors from map edge inward:

- Endpoints chosen at random edge segments (seeded)
- Width: 2 tiles
- Path: smoothed diagonal or curved toward camp
- Corridor tiles are force-set walkable and buildable=false (no obstruction, no player building)
- Prop scatter density along corridor is `0.1×` normal (near-empty)
- Endpoint at map edge = enemy spawn point (replaces hardcoded east-edge spawn)

## 13. Grid integration

After classification, feed the existing `MovementAdapter`:

```gdscript
for x in width:
    for y in height:
        var cls := tile_classes[x][y]
        _movement.set_solid(Vector2i(x, y), not is_walkable(cls))
```

`PlacementValidator` gains an `is_buildable(cell)` check reading `plan.tile_classes` — stricter than walkable (excludes `FOREST_FLOOR`, `ROCKY_SLOPE`).

## 14. Seed policy

`fixed_locked` (user decision, 2026-07-03):

- Seed hardcoded in `MapConfig.default_for_demo()`
- Same map every launch for the shipped demo
- Debug-only: `F6` regen with new seed (reloads scene)
- Save game persists `map_config.seed` so reload reproduces the exact map

## 15. Debug tools

Debug-only additions to `game/dev/debug_console/`, gated on `OS.is_debug_build()`:

| Command | Effect |
|---|---|
| `dev_regen_map()` | Reload scene with a new random seed |
| `dev_set_seed(int)` | Reload scene with a specific seed |
| `dev_toggle_class_overlay()` | Colored overlay of all 7 classes |
| `dev_toggle_walkable_overlay()` | Red/green tile overlay |
| `dev_toggle_buildable_overlay()` | Red/green tile overlay |
| `dev_print_map_stats()` | Counts + walkable% + buildable% |
| `print_mapgen_status` | **Shipped** — full runtime map/procgen stats (debug console) |
| `toggle_class_overlay` | **Shipped** — saturated 7-class terrain colors on procgen mesh |

Hotkey: `F6` bound to `dev_regen_map()`.

## 16. Phase plan

| Phase | Scope | Status |
|---|---|---|
| **1** | Heightmap + terrain mesh + classifier | **Shipped** |
| **2** | Texture palette + splat shader (7 albedo, per-triangle class) | **Shipped** (macro texture pass pending art) |
| **3** | Class-aware prop scatter, replace hand-placed resources | **Shipped** |
| **4** | Corridor planner, enemy spawn from corridor endpoints | **Partial** — lane metadata + mud paint shipped; enemy spawn hookup pending |
| **5** | Debug tools (regen, overlays, stats), F6 hotkey | **Partial** — `print_mapgen_status`, class/composition overlays, beauty mode shipped; F6 regen pending |

**Total:** 2–2.5 focused days, each phase committable and reversible.

### 16.1 Phase-1 acceptance

- Colony scene loads with a 3D undulating terrain (7 solid colors)
- Warren + Storehouse land at flattened camp
- 6 initial goblins walk without falling
- `godot --headless --script tests/smoke/test_colony.gd` passes
- `tests/unit/test_heightmap.gd` proves determinism per seed

### 16.2 Phase-2 acceptance

- Terrain looks like the user's textures blended by class
- No visible tile seams within a class
- Class transitions blur naturally across triangles
- No overlapping variants inside a single triangle

### 16.3 Phase-3 acceptance

- Trees cluster in `FOREST_FLOOR`, rocks in `ROCKY_SLOPE`, mushrooms in `MUD_MOSSY`
- All resource nodes reachable from Warren (BFS-verified)
- Camp clearing has zero scatter
- No two blocker props on adjacent tiles

### 16.4 Phase-4 acceptance

- 2–3 visible enemy approach lanes
- Enemies spawn from corridor endpoints (not hardcoded east edge)
- Existing 7-day arc plays through end-to-end

### 16.5 Phase-5 acceptance

- `F6` in debug builds regenerates a fresh map
- Class overlay shows all 7 classes distinctly
- Stats print includes tree/rock/mushroom counts

## 17. Risks & mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Splat shader gives visible seams | Medium | Fall back to `StandardMaterial3D` per-class atlas |
| Reachability BFS slow at 48×48 | Low | Pre-compute during generation, cache |
| Camp flatten breaks Warren placement math | High | Warren cell configurable per `MapConfig`; adjacent Storehouse follows |
| Corridors look like ugly straight lines | Medium | Add curve jitter + tile edge softening |
| Repo bloat from 16 PNG × ~3 MB (~48 MB) | High | Enable Git LFS for `*.png` > 1 MB per `AGENTS.md` §10 |
| Save files break on new terrain | Medium | Bump save version; if load fails, start fresh; document in `docs/decisions/` |
| Sub-tile mesh detail confuses slope | Medium | Compute slope from **heightmap grid**, not from mesh normals |

## 18. Test plan

**Unit** (`tests/unit/`):
- `test_heightmap.gd` — Deterministic output per seed
- `test_terrain_classifier.gd` — Slope/height rules produce expected classes
- `test_prop_scatterer.gd` — Density, spacing, reachability

**Smoke** (`tests/smoke/`):
- Extend `test_colony.gd` — Boot procgen map, tick 100 frames, assert no errors, ≥1 goblin walkable, Warren + Storehouse spawned

**Manual QA** (per phase):
- Load colony scene, verify visual look
- Force scene reload with F6 (debug)
- Play 7-day demo end-to-end, verify no unreachable nodes / stuck goblins

## 19. Follow-ups (post-MVP)

- Second biome (Rocky Steppe, Bone Wastes, Deep Marsh) — expand `BiomeCatalog`
- Water bodies (need water texture + water shader + shoreline)
- True cliff face texture for near-vertical slopes
- Path/road overlay for high-traffic goblin trails
- Runtime terrain deformation (mining bites into rocky slopes)
- Larger maps (60×60+) with chunk streaming
