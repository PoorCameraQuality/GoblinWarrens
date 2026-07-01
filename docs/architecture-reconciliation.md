# Architecture reconciliation — deep-research report vs this repo

This document records where the [deep-research playbook](../HANDOFF.md) applies
as-is and where **binding project decisions override** it. Agents must not
silently adopt report recommendations that conflict with `AGENTS.md`, the master
design doc, or ADR 0001.

## Documentation hierarchy

| Priority | Document | Role |
| --- | --- | --- |
| 1 | `docs/goblin-warrens-design.md` | Game direction, hard rules, MVP, milestones |
| 2 | `AGENTS.md` | Engineering contract |
| 3 | This file | Technical overrides vs external reports |
| 4 | `HANDOFF.md` | Session resume |

The master design doc supersedes older RTS-first or underground direction.
Technical choices here (grid pathfinding, autoloads) remain binding unless the
user approves a change via new ADR **and** the design doc is updated if gameplay
impact exists.

## Applies as-is

| Report recommendation | Repo status |
|---|---|
| Cursor as control plane (rules, AGENTS.md, plan mode, MCP) | `AGENTS.md`, `.cursor/rules/`, GRB runbook |
| GDScript-first; C# only for hot paths later | ADR 0001, `docs/technical-reference.md` |
| Resources for static data; narrow autoloads | `Log`, `Bus`, `Defs`, `Services` only |
| Signals / event bus over hard coupling | `Bus` autoload |
| BLEND source → GLB static → FBX animated | `docs/asset-pipeline.md` |
| Meshy → Blender → AccuRIG/Mixamo → Cascadeur → Godot | `docs/asset-pipeline.md` |
| Phased delivery (greybox → slice → content → polish) | `HANDOFF.md` |
| GUT + headless smoke tests | `tests/smoke/`, `AGENTS.md` §7 |
| Versioned save snapshots | Phase 2+ (`scripts/save/`) |
| Job queue + needs as core sim modules | Phase 2–3 scope |

## Overridden — do not adopt without explicit user approval

| Report recommendation | This repo's decision | Rationale |
|---|---|---|
| `NavigationAgent3D` + navmesh pathfinding | **`AStarGrid2D` grid pathfinding** | 2.5D RimWorld/DF lineage; ADR 0001; `AGENTS.md` §6 |
| Freeform 3D colony sim | **Tile-based logical grid under 3D camera** | User decision; `HANDOFF.md` §11 |
| `CharacterBody3D` + physics locomotion | **Kinematic grid movement** | Goblins move tile-to-tile, not physics bodies |
| Report folder layout (`scripts/sim/…`) | **`scripts/{core,agents,jobs,world,ui,save,debug}/`** | Established in bootstrap scaffold |
| Report's simplified AGENTS.md template | **Existing `AGENTS.md`** | Stricter MCP bridge discipline, GUT, bridge-evidence |
| RTS-first or underground colony sim framing | **`docs/goblin-warrens-design.md`** | Above-ground colony survival builder; warren-first; no digging |

## Partially applies — adapt before use

| Report topic | Adaptation |
|---|---|
| Goblin scene tree with `NavigationAgent3D` | Use grid `movement_adapter.gd`; keep skeleton/animation nodes for visual polish |
| Report pathfinding wrapper | Ours is `scripts/agents/movement_adapter.gd` wrapping `AStarGrid2D`, not `NavigationServer3D` |
| Report main scene `Main.tscn` | Phase 2 entry is `scenes/colony.tscn` |
| Meshy MCP for asset batching | Complements GRB; document API keys in `.cursor/secrets/` when wired |
| `.cursorignore` patterns | Extended for Godot + Meshy paths (see repo root) |

## When to revisit

Re-open these overrides only if the user explicitly requests:

- Drifting from grid sim to freeform 3D navigation
- Replacing `AStarGrid2D` with `NavigationAgent3D`
- Changing autoload policy beyond the four approved globals

Any such change requires a new ADR in `docs/decisions/`.
