# HANDOFF — Goblin Warrens

> **Start here when resuming this project.**

- **Last updated**: 2026-07-11
- **Project root**: `E:\Projects\goblin-colony`
- **Master design**: **`docs/goblin-warrens-design.md`** (highest design authority)
- **AI onboarding summary**: `docs/chatgpt-master-context.md`

---

## 0. Design north star

**Read `docs/goblin-warrens-design.md` before any feature work.**

Goblin Warrens is a 3D **above-ground** goblin colony survival builder with
siege-defense combat and light RTS controls. Colony survival first; RTS second.
No underground mechanics. Preserve the gather-return-store worker loop.

**Current status:** playable **7-day MVP prototype** on procgen terrain, plus a
complete **authored-map pipeline** (Phases 0–10) integrated into production
colony via opt-in `map_mode`. Next focus: stabilization commits, manual authored
7-day playtest, then post-MVP economy (Warren upgrades, unit training, gold spend).

---

## 1. What this project is

A 2.5D grid-based goblin colony survival sim (Farthest Frontier / Dawn of Man
lineage, monster-side), rendered under a 3D RTS camera. AI agents in Cursor
author code and scenes; 3D art comes from Meshy with Blender / AccuRIG / Cascadeur
polish, plus kitbash packs (Quaternius, KayKit, etc.).

---

## 2. Decided stack

| Layer | Choice |
|---|---|
| Engine | Godot **4.7.stable** (see `docs/technical-reference.md`) |
| Language | GDScript |
| Pathfinding | `AStarGrid2D` via `movement_adapter.gd` — **not navmesh** |
| Terrain (authored) | Terrain3D v1.0.2 + compiled semantic grid (opt-in) |
| Art pipeline | Meshy → Blender → GLB/FBX → Godot (`docs/asset-pipeline.md`) |
| MCP bridge | Aesthetic Engine GRB + Godot AI plugin (see `docs/mcp-setup.md`) |
| Deep-research report | Ingested; overrides documented in `docs/architecture-reconciliation.md` |

---

## 3. Map modes (colony)

| Mode | Setting | Scene | Notes |
|---|---|---|---|
| **Procgen** (default) | `game/map_mode=procgen` | `scenes/colony.tscn` | Original 7-day demo |
| **Authored** | `game/map_mode=authored` | `scenes/colony.tscn` | Warren pick → baked map |
| **Dev shortcut** | (unchanged procgen setting) | `scenes/dev/authored_demo.tscn` | Colony + `defer_world_setup` |

Authored map pack: `data/maps/three_lane_swamp_valley/`  
Integration guide: `docs/technical/COLONY_AUTHORED_MAP_INTEGRATION.md`  
Roadmap: `docs/technical/PHASE10_INTEGRATION_ROADMAP.md`

---

## 4. What has been done

### Bootstrap + MVP (`scenes/colony.tscn`)
- Grid movement, gather → haul → store, RTS selection/commands
- Building placement, food/population, Foblins, 7-day threats/combat
- Shrine, burial/revival, win/loss, basic save/load
- Phase reports: `docs/technical/PHASE4_*` through `PHASE10_*`

### Authored map pipeline (Phases 0–10)
- Semantic map import, grid compiler, map editor plugin
- Foliage/resource/strategic scatter compilers
- Warren placement validation, colony observability (Phase 9)
- Production colony integration + save schema v2 (Workstream 2)

### Gameplay autoloads
`Log`, `Bus`, `Defs`, `Services` — plus plugin-owned dev autoloads only.

---

## 5. What is NOT done yet / known gaps

- GUT addon not installed — `tests/unit/*` won't run in editor
- Warren upgrade economy, unit training, gold-as-spend
- Shaman hero, champions, animation polish
- Manual **7-day playtest on authored colony** not yet signed off
- Landmark layer / enemy camp spawn logic deferred
- Git commit for Phases 4–10 + integration work (pending user request)
- `colony.gd` still large — split helpers before big features

---

## 6. How to resume

1. Read **`docs/goblin-warrens-design.md`** and **`docs/chatgpt-master-context.md`**.
2. Read `AGENTS.md` and `docs/architecture-reconciliation.md`.
3. Run full smoke battery (~3–6 min):
   ```powershell
   cd E:\Projects\goblin-colony
   .\tools\run_all_smokes.ps1
   ```
4. **Procgen:** Play `scenes/colony.tscn` (default).
5. **Authored:** Project Settings → `game/map_mode` = `authored` → Play `colony.tscn`,
   or play `scenes/dev/authored_demo.tscn` without changing settings.
6. Next sensible work (pick one):
   - **Commit + tag** stabilization (Workstream 3)
   - Manual authored 7-day playtest sign-off
   - Post-MVP economy (Warren upgrades → training → gold spend)

---

## 7. Acceptance reminders

- Design doc §38: files changed, preserved behavior, test steps, limitations, next step
- Do not break gather-return-store; no underground mechanics
- Do not flip default `map_mode` to authored without explicit approval
- No new **gameplay** autoloads without ADR

## 8. Remember

- **`docs/goblin-warrens-design.md` overrides** older RTS-first or underground direction.
- Do **not** switch to `NavigationAgent3D` without user approval and new ADR.
- Do **not** commit `.cursor/secrets/`.
- Prefer this file + design doc + code over stale chat summaries.

— end of handoff —
