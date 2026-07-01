# HANDOFF — Goblin Warrens

> **Start here when resuming this project.**

- **Last updated**: 2026-06-30
- **Project root**: `E:\Projects\goblin-colony`
- **Master design**: **`docs/goblin-warrens-design.md`** (highest design authority)

---

## 0. Design north star

**Read `docs/goblin-warrens-design.md` before any feature work.**

Goblin Warrens is a 3D **above-ground** goblin colony survival builder with
siege-defense combat and light RTS controls. Colony survival first; RTS second.
No underground mechanics. Preserve the gather-return-store worker loop.

Current milestone focus: **Milestone 1 done** → next **Milestone 2** (selection
and right-click commands). See design doc §37.

---

## 1. What this project is

A 2.5D grid-based goblin colony survival sim (Farthest Frontier / Dawn of Man
lineage, monster-side), rendered under a 3D RTS camera. AI agents in Cursor
author code and scenes; 3D art comes from Meshy with Blender / AccuRIG / Cascadeur
polish.

## 2. Decided stack

| Layer | Choice |
|---|---|
| Engine | Godot 4.6 |
| Language | GDScript |
| Pathfinding | `AStarGrid2D` via `movement_adapter.gd` — **not navmesh** |
| Art pipeline | Meshy → Blender → GLB/FBX → Godot (`docs/asset-pipeline.md`) |
| MCP bridge | Aesthetic Engine GRB (primary) |
| Deep-research report | Ingested; overrides documented in `docs/architecture-reconciliation.md` |

## 3. What has been done

### Bootstrap (Phase 1)
- Repo scaffold, `AGENTS.md`, ADR 0001, MCP runbook, smoke test
- `.cursorignore`, `.cursorindexingignore`, `.cursor/rules/goblin-colony.mdc`
- Docs: `asset-pipeline.md`, `architecture-reconciliation.md`, `import-settings.md`

### Vertical slice scaffold (Phase 2 — in progress)
- **Main scene**: `scenes/colony.tscn` — 10×10 ground, camera, light, HUD
- **Goblin**: `scenes/agents/goblin.tscn` + `scripts/agents/goblin.gd`
- **Movement**: `scripts/agents/movement_adapter.gd` (`AStarGrid2D`)
- **Food job**: `scripts/jobs/food_spawner.gd`, `scenes/world/food.tscn`
- **Autoloads**: `Log`, `Bus`, `Defs`, `Services`
- **Save/load**: `scripts/save/colony_save.gd` (autosave every 5s to `user://colony_save.tres`)
- **Tests**: `tests/smoke/test_smoke.gd`, `tests/smoke/test_colony.gd`

## 4. What is NOT done yet

- Godot **4.7.stable** installed via winget (project targets 4.6+; see `docs/technical-reference.md`)
- Headless smoke tests pass after `godot --headless --path . --import`
- GRB cloned at `C:\Tools\godot-runtime-bridge`; MCP npm installed; addon copied to `addons/godot-runtime-bridge/`
- `.cursor/mcp.json` written (restart Cursor to load MCP server)
- Enable GRB plugin in Godot editor; end-to-end GRB screenshot loop not yet verified from chat
- No git commits yet
- Meshy / GUT addons not installed
- Placeholder CSG boxes only — no rigged goblin assets yet
- Colony smoke test not verified headless until Godot is installed

## 5. How to resume

1. Read **`docs/goblin-warrens-design.md`** (relevant section + current milestone).
2. Read `AGENTS.md` and `docs/architecture-reconciliation.md`.
2. Install Godot 4.6; record exact patch in `docs/technical-reference.md`.
3. Run smoke tests (requires one-time `godot --headless --path . --import`):
   ```powershell
   $G = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
   cd E:\Projects\goblin-colony
   & $G --headless --path . --import
   & $G --headless --path . --script tests\smoke\test_smoke.gd
   & $G --headless --path . --script tests\smoke\test_colony.gd
   ```
4. Wire GRB per `docs/mcp-setup.md` Steps 1–5.
5. Open `scenes/colony.tscn` in editor; confirm goblins path toward food.
6. Commit scaffold when ready (user must request commit explicitly).

## 6. Phase 2 acceptance (from original plan)

- [ ] Headless `test_smoke.gd` exits 0
- [ ] Headless `test_colony.gd` exits 0 after 100 frames with ≥1 goblin
- [ ] Goblins seek food when hunger crosses threshold
- [ ] GRB screenshot loop works from Cursor chat
- [ ] Save round-trip restores goblin/food state (manual check)

## 7. Phase 3+ (unchanged intent)

Job system expansion (chop, mine, haul, build, sleep), structures, Meshy assets,
day/night, raids — see prior handoff §10 in git history or ADR.

## 8. Remember

- **`docs/goblin-warrens-design.md` overrides** older RTS-first or underground direction.
- Do **not** switch to `NavigationAgent3D` without user approval and new ADR.
- Do **not** commit `.cursor/secrets/`.
- `AGENTS.md` overrides the deep-research report where they conflict.

— end of handoff —
