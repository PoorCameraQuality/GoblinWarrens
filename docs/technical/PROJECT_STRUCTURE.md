# Project structure — Goblin Warrens

Maps the **target** `game/` layout from the acquisition guide to **paths in use today**.
Migrate gradually — do not mass-rename in one PR unless instructed.

---

## Authority

| Doc | Role |
|-----|------|
| `docs/goblin-warrens-design.md` | Game design (#1) |
| `AGENTS.md` | Engineering contract |
| `docs/asset-library-acquisition.md` | Godot AssetLib install rules |
| `docs/itch-io-acquisition.md` | itch.io free/CC0 art acquisition and sorting |
| `docs/quaternius-acquisition.md` | Quaternius.com CC0 art acquisition and sorting |

---

## Current production paths (use these now)

| Concern | Path today | Notes |
|---------|------------|-------|
| Main scene | `scenes/colony.tscn` | Playable MVP demo |
| Agents | `scripts/agents/` | `goblin.gd`, `foblin.gd`, `enemy_unit.gd`, `movement_adapter.gd` |
| World / colony | `scripts/world/` | `colony.gd`, buildings, day sim, threats |
| Jobs | `scripts/jobs/` | `job_service.gd` |
| UI | `scripts/ui/` | RTS camera, selection, build placement, demo guide |
| Core | `scripts/core/` | `defs.gd`, `bus.gd`, `constants.gd`, `services.gd` |
| Building data | `data/buildings/` | `building_catalog.gd`, `building_def.gd` |
| Demo copy | `data/demo/` | `demo_day_catalog.gd` |
| Static art (runtime) | `assets/` | props, characters, env — **use `.glb`**; migrating to `game/art/` |
| Art (target layout) | `game/art/` | Units, buildings, props, terrain — production wrappers |
| Asset review | `game/scenes/asset_test_scenes/` | itch.io / art pack evaluation (not shipped) |
| Raw itch.io | `external_raw/itch_io/` | Never reference from scenes |
| Raw Quaternius | `external_raw/quaternius/` | Never reference from scenes |
| Tests | `tests/` | GUT + smoke |
| Plugins | `addons/` | Third-party only |
| Raw downloads (other) | `external_raw/` | AssetLib ZIPs, blender sources, etc. |

---

## Target mapping (when migrating)

| Target (`game/`) | Current equivalent |
|------------------|-------------------|
| `game/systems/navigation/` | `scripts/agents/movement_adapter.gd` |
| `game/systems/units/` | `scripts/agents/` |
| `game/systems/jobs/` | `scripts/jobs/` |
| `game/systems/building/` | `scripts/world/` + `data/buildings/` |
| `game/scenes/maps/` | `scenes/colony.tscn` |
| `game/ui/hud/` | `scripts/ui/` + HUD nodes in `scenes/colony.tscn` |
| `game/data/buildings/` | `data/buildings/` |
| `game/dev/debug_console/` | `game/dev/debug_console/` (new) |
| `game/integrations/<plugin>/` | Wire AssetLib plugins here |
| `game/world/scatter/` | Future ProtonScatter configs |
| `game/world/blockouts/` | Future CSG blockouts |
| `game/art/props/` | `assets/props/` |
| `game/art/units/goblins/` | Future goblin `.glb` wrappers (itch.io LOWPO, etc.) |
| `game/scenes/asset_test_scenes/` | Art review scenes (see itch-io doc) |

---

## Third-party separation

```text
res://addons/              ← AssetLib plugins (MIT/CC0 only)
res://external_raw/        ← ZIP downloads, raw packs (never in scenes)
  itch_io/                 ← itch.io raw extracts (see docs/itch-io-acquisition.md)
  quaternius/              ← Quaternius.com downloads (see docs/quaternius-acquisition.md)
res://assets/              ← Game-ready .glb / .tres imports (legacy path)
res://game/art/            ← Target production art wrappers
res://game/dev/            ← Debug tools, asset review
res://game/integrations/   ← Thin glue to plugins (no forked plugin code)
res://docs/references/     ← Notes from external demos (e.g. 3D Navigation Demo)
```

---

## Scene ownership

Production scenes agents may edit: see design milestones and `scenes/colony.tscn` until `docs/scene-ownership.md` exists.

Scratch / prototypes: `game/dev/test_scenes/` or inherited scenes — not `colony.tscn` during exploration.
