# Terrain texture brief — Goblin Forest Valley

**Status:** Phase A engine prep (macro texture contract)  
**Owner:** Art + engineering  
**Last updated:** 2026-07-08  
**Engine:** Godot **4.7.stable** (project targets 4.6+; see `docs/technical-reference.md`)  
**Related:** `docs/procedural-map-plan.md`, `data/mapgen/terrain_palette.gd`

## 1. Purpose

Procedural map generation (heightmap, classification, mesh, prop scatter) is **already shipped** for the current milestone. The open problem is **terrain readability at RTS camera distances**: ground albedos repeat too frequently and read as noisy moiré, not as a coherent 350m wilderness.

This document defines the **macro terrain texture contract** for Phase A–D. Phase A is engine prep + documentation only; authored `_macro.png` files land later.

## 1.1 Visual gap (code vs screenshots)

Procgen **is active in code** in `scenes/colony.tscn`, but the game may still **look** like a flat prototype board because:

1. **Subtle height** — ~4m elevation range over 350m reads as flat from RTS camera.
2. **Legacy textures** — green moss albedo at `uv_scale=0.35` (~3m repeat) looks like a flat green square.
3. **Sparse props** — stride-4 scatter on 350×350 keeps prop count ~200–300, not a dense forest.
4. **Map edge** — terrain mesh ends abruptly against sky background (no fog/horizon).
5. **Scale drift** — addressed in `constants.gd` meter targets (buildings/units/props); per-wrapper tuning may still be needed in `game/art/`.
6. **Stale screenshots** — may predate procgen or show `asset_test_scenes`, not `colony.tscn`.

Texture macro pass (Phase A) addresses item 2 only. Scale normalization and prop density are separate passes.

**Do not rewrite procgen for this pass.** Textures are visual only.

## 2. Game context

- **Title:** Goblin Warrens — above-ground goblin colony survival builder with light RTS controls.
- **Biome (MVP):** Goblin Forest Valley — damp forest, muddy clearings, rocky slopes, filthy goblin camp.
- **Map size:** **350 × 350 tiles**, **1 tile = 1 meter** → **350m × 350m** playable area.
- **Elevation range:** ~4m total (gentle hills, not mountains).
- **Demo seed:** `424242` (fixed for shipped demo).
- **Art tone:** Filthy monster camp in wilderness; stylized/low-poly Meshy buildings and props. Terrain complements that — not hyper-detailed ground photography.

### Procgen pipeline (existing in `scenes/colony.tscn`)

```
MapConfig → MapGenerator.build()
  ├─ HeightmapGenerator      → float height grid
  ├─ TerrainClassifier       → 7 terrain classes per tile
  ├─ TerrainMeshBuilder      → vertex-colored ArrayMesh (class ID in COLOR.r)
  ├─ _scatter_props()        → class-aware props + resources (inlined in map_generator.gd)
  └─ MapPlan applied in colony._setup_world()
```

Verify at runtime: debug command `print_mapgen_status` or debug HUD `Map 350x350 seed 424242 | procgen`.

## 3. Terrain classes (7)

Each gameplay tile has exactly **one** dominant class. The shader samples **one** albedo per triangle (no splat blending yet).

| ID | Enum | Walkable | Buildable | Role |
|---:|---|:-:|:-:|---|
| 0 | `MUD_CLEARING` | yes | yes | Flattened camp floor at map center |
| 1 | `MOSS` | yes | yes | Default open ground |
| 2 | `FOREST_FLOOR` | yes | no | Dense forest; trees scatter here |
| 3 | `ROCKY_SLOPE` | yes | no | 20–40° slopes; rocks scatter |
| 4 | `MUD_MOSSY` | yes | yes | Wet lowlands |
| 5 | `CLIFF` | no | no | Slopes > 40° |
| 6 | `WARREN_GROUND` | yes | yes | 1-tile ring around Warren footprint |

### Classification rules (order matters)

1. Inside camp flatten radius → `MUD_CLEARING`
2. Warren footprint ring → `WARREN_GROUND`
3. Slope > 40° → `CLIFF`
4. Slope > 20° → `ROCKY_SLOPE`
5. Normalized height > 0.80 → `FOREST_FLOOR`
6. Normalized height < 0.30 → `MUD_MOSSY`
7. Else → `MOSS`

Slope is computed from the heightmap grid, not mesh normals.

## 4. Prop scatter by class (3D models)

Props carry close-up visual interest. Ground textures must read at RTS zoom.

| Class | Scattered props |
|---|---|
| `MUD_CLEARING` | none |
| `MOSS` | grass, bushes, berry bushes |
| `FOREST_FLOOR` | trees, mushrooms |
| `ROCKY_SLOPE` | rocks, gold veins |
| `MUD_MOSSY` | mushrooms, berry bushes, bone piles |
| `WARREN_GROUND` | bone piles, crates, barrels |
| `CLIFF` | none |

## 5. Camera and the current visual failure

| Setting | Value |
|---|---|
| Default camera distance | **90m** |
| Close zoom | **18m** |
| Overview zoom | **520m** (full 350m map) |
| Camera pitch | ~35° |

### Shader UV math (today)

```glsl
terrain_uv = vec2(world_x, world_z) * uv_scale;
```

| Mode | `uv_scale` | Meters per texture repeat |
|---|---:|---:|
| Legacy (current files) | **0.35** | ~2.86m |
| Macro (target) | **0.05** | ~20m |

Legacy **1254×1254** close-up forest-floor photos at `uv_scale = 0.35` repeat every ~3m. At 90m camera height the ground shows **30–40 repeats** across the view → noise and moiré. Macro textures fix this by putting largest features at **8–24m** scale.

## 6. Current shader limitations

File: `game/art/terrain/materials/terrain_blend.gdshader`

- 7× albedo `sampler2D` only (no normal/ORM).
- World XZ × `uv_scale`, repeat enabled.
- **One texture per triangle** from vertex color class ID — hard class edges, no blending.
- Single uniform roughness (0.92).

**Not in scope for Phase A:** variant hashing, splat blending, normal maps, path overlay, vertical cliff projection, Terrain3D, water.

## 7. Current texture inventory

**Path:** `game/art/terrain/goblin_warrens/`

18 legacy PNGs at **1254×1254** (close-up scale). **7** wired as primaries; **11** variants on disk but unused in code.

| Class | Legacy primary (fallback) |
|---|---|
| `MUD_CLEARING` | `dirt_packed.png` |
| `MOSS` | `forest_floor_moss.png` |
| `FOREST_FLOOR` | `forest_floor_roots_heavy.png` |
| `ROCKY_SLOPE` | `forest_floor_rocky.png` |
| `MUD_MOSSY` | `mud_mossy.png` |
| `CLIFF` | `mud_bedrock.png` |
| `WARREN_GROUND` | `mud_root_lattice.png` |

**Do not delete or rename legacy files yet.** Add `_macro.png` siblings; deprecate in place when macros are authored.

## 8. Required macro primaries (Phase A art deliverable)

Seven files — one per class. Must tile seamlessly and read at **90m** default zoom.

| File | Class | Visual direction | Macro feature scale |
|---|---|---|---|
| `dirt_packed_macro.png` | `MUD_CLEARING` | Trampled camp soil | 10–20m |
| `forest_floor_moss_macro.png` | `MOSS` | Open mossy turf | 12–24m |
| `forest_floor_litter_macro.png` | `FOREST_FLOOR` | Dark forest floor, large shadow patches | 8–16m |
| `rocky_slope_macro.png` | `ROCKY_SLOPE` | Gravel and scree on hillside | 8–20m |
| `mud_mossy_macro.png` | `MUD_MOSSY` | Wet lowland, broad moss in mud | 10–20m |
| `cliff_face_macro.png` | `CLIFF` | Rock/dirt face (top-down approximation until vertical UV) | 8–16m |
| `warren_ground_macro.png` | `WARREN_GROUND` | Filthy goblin traffic ring | 4–8m |

### Debug color anchors (hue family)

| Class | Approx RGB |
|---|---|
| `MUD_CLEARING` | `#856640` |
| `MOSS` | `#476B38` |
| `FOREST_FLOOR` | `#2E4D24` |
| `ROCKY_SLOPE` | `#6B6157` |
| `MUD_MOSSY` | `#575A38` |
| `CLIFF` | `#38383D` |
| `WARREN_GROUND` | `#754830` |

## 9. Variant texture plan (Phase B)

2–4 variants per class, same macro scale, seamless, slight hue/pattern shift:

| Class | Planned variant names |
|---|---|
| `MUD_CLEARING` | `dirt_smooth_macro.png`, `mud_wet_macro.png` |
| `MOSS` | `forest_floor_flowered_macro.png`, `grass_patchy_macro.png` |
| `FOREST_FLOOR` | `forest_floor_roots_heavy_macro.png`, `forest_floor_roots_mixed_macro.png`, `forest_floor_dark_cracked_macro.png` |
| `ROCKY_SLOPE` | `forest_floor_stony_macro.png`, `path_stony_macro.png` |
| `MUD_MOSSY` | `dirt_leafy_macro.png` |
| `CLIFF` | `mud_bedrock_macro.png`, `granite_macro.png` |
| `WARREN_GROUND` | `mud_root_lattice_macro.png` |

Requires per-triangle variant hashing in shader — **not Phase A**.

## 10. Optional detail layer (Phase D)

Dual-scale shader (future): `_detail.png` at 512×512, 1–3m features, paired with each macro primary. Not required for Phase A.

## 11. File naming convention

```
game/art/terrain/goblin_warrens/<category>_<descriptor>_macro.png
```

**Rules:**

- `snake_case` only.
- **Primary macros** use `_macro.png` suffix.
- **Variants** share class prefix; descriptor distinguishes look.
- Future biomes: `game/art/terrain/<biome_id>/`.
- Shader params: `tex_mud_clearing`, `tex_moss`, etc. (unchanged).

**Hard constraints:**

- No underground / cave textures.
- No water for MVP.
- No seasonal variants for MVP.
- MIT/CC0 or owned art only.
- Textures must live in `game/art/terrain/goblin_warrens/`.
- Primary macro textures use `category_descriptor_macro.png` naming.

## 12. Technical specs

| Property | Requirement |
|---|---|
| Format | PNG, sRGB albedo |
| Resolution | **1024×1024** macro; **512×512** detail (optional later) |
| Tiling | Seamless mandatory |
| Alpha | None — opaque ground |
| Normal / ORM | Not used yet |
| Contrast | Low–medium; avoid fine high-contrast detail |
| Lighting baked in | Flat/neutral — Godot lighting is authoritative |

### Godot import settings (terrain)

Documented in `docs/import-settings.md` § Terrain albedo:

```
filter = Linear
mipmaps = ON
repeat = ON (sampler repeat_enable in shader)
compress = VRAM Compressed (Lossless if banding)
sRGB = ON for albedo
```

## 13. UV scale guidance

Engine constants (`scripts/core/constants.gd`):

| Constant | Value | When used |
|---|---:|---|
| `TERRAIN_UV_SCALE_MACRO` | **0.05** | All 7 `_macro.png` primaries present |
| `TERRAIN_UV_SCALE_LEGACY` | **0.35** | Any macro missing — legacy fallback |

`TerrainPalette` resolves texture path per class (macro if exists, else legacy + one-time `Log.warn`). `TerrainMaterialBuilder` picks UV scale only when **all** macro primaries exist; otherwise legacy scale for the whole material.

## 14. Visual roadmap

| Phase | Scope |
|---|---|
| **A** (current) | Macro file paths, palette fallback, UV scale switch, mipmaps, review scene |
| **B** | Variant randomization, anti-tiling noise tint |
| **C** | Vertex-weight splat blending across class borders |
| **D** | Detail layer, normal maps, cliff vertical UV, path/corridor overlay |

## 15. Visual QA

**Review scene:** `game/scenes/asset_test_scenes/terrain_texture_review.tscn`

Checks:

- Default distance ~90m (key `2`)
- Close zoom ~18m (key `1`)
- Overview ~520m (key `3`)
- All 7 classes visible in strips
- Texture repeat scale and mipmap behavior
- Class readability and moiré

## 16. Acceptance checklist (per texture batch)

- [ ] Tiles seamlessly at target resolution
- [ ] Readable at **90m** camera
- [ ] No severe moiré at **520m** overview
- [ ] Hue matches class debug color family
- [ ] Matches filthy goblin camp tone
- [ ] Filename follows `category_descriptor_macro.png`
- [ ] Placed in `game/art/terrain/goblin_warrens/`
- [ ] All 7 primaries cover classes 0–6
- [ ] License documented

## 17. Gameplay preservation

This pass must **not** change:

- `AStarGrid2D` pathing via `movement_adapter.gd`
- Walkability / buildability rules per `TerrainClassifier`
- Gather → haul → storehouse loop
- Prop scatter logic or densities
- Colony startup or seed `424242`

Textures are visual only.
