# HANDOFF — Goblin Warrens

> **Start here when resuming this project.**

- **Last updated**: 2026-07-09
- **Project root**: `E:\Projects\goblin-colony`
- **Master design**: **`docs/goblin-warrens-design.md`** (highest design authority)
- **AI onboarding summary**: `docs/chatgpt-master-context.md`

---

## 0. Design north star

**Read `docs/goblin-warrens-design.md` before any feature work.**

Goblin Warrens is a 3D **above-ground** goblin colony survival builder with
siege-defense combat and light RTS controls. Colony survival first; RTS second.
No underground mechanics. Preserve the gather-return-store worker loop.

**Current status:** playable rough **7-day MVP prototype** (design milestones
1–10 largely done). Next focus is **stabilization + post-MVP economy** (Warren
upgrades, unit training, gold spend), not re-doing early milestones. See design
doc §37 and `docs/chatgpt-master-context.md` §9.

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
| Art pipeline | Meshy → Blender → GLB/FBX → Godot (`docs/asset-pipeline.md`) |
| MCP bridge | Aesthetic Engine GRB + Godot AI plugin (see `docs/mcp-setup.md`) |
| Deep-research report | Ingested; overrides documented in `docs/architecture-reconciliation.md` |

---

## 3. What has been done

### Bootstrap
- Repo scaffold, `AGENTS.md`, ADR 0001, MCP runbook, smoke tests
- Cursor rules, architecture/docs, asset pipeline notes

### Playable 7-day prototype (`scenes/colony.tscn`)
- Grid movement (`movement_adapter.gd`), goblin workers, gather → haul → store
- RTS selection + right-click commands
- Building placement + construction (MVP buildings)
- Food upkeep, housing cap, population crowding brackets
- Breeder Hut → Foblins (zero food upkeep)
- Day simulation + demo briefings, threats, combat
- Shrine rituals, burial/revival, win/loss (`mvp_evaluator.gd`)
- Basic save/load, minimal art pass via `visual_catalog.gd`
- Smoke tests under `tests/smoke/`; unit scripts under `tests/unit/` (need GUT)

### Gameplay autoloads
`Log`, `Bus`, `Defs`, `Services` — plus **plugin-owned** Debug Console / Godot AI
autoloads (dev tools only; see `AGENTS.md`).

---

## 4. What is NOT done yet / known gaps

- GUT addon not installed — `tests/unit/*` extends `GutTest` but won't run in editor
- Warren upgrade economy, unit training, gold-as-spend (stubs / missing)
- Shaman hero, champions, walk/combat animation polish
- `colony.gd` / `goblin.gd` growing large — prefer safe modular splits before big features
- Demo Day 3 briefing copy still says foblins eat food (code: they do not)
- Art remains prototype kitbash quality

---

## 5. How to resume

1. Read **`docs/goblin-warrens-design.md`** (relevant section) and
   **`docs/chatgpt-master-context.md`** for current status.
2. Read `AGENTS.md` and `docs/architecture-reconciliation.md`.
3. Prefer **Godot 4.7.stable** (path in `docs/technical-reference.md`).
4. Run smoke tests:
   ```powershell
   $G = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
   cd E:\Projects\goblin-colony
   & $G --headless --path . --script tests\smoke\test_smoke.gd
   & $G --headless --path . --script tests\smoke\test_colony.gd
   ```
5. Open `scenes/colony.tscn` in the editor and play the 7-day loop.
6. Next sensible work (pick one track):
   - Doc/config already reconciled — prefer **architecture stabilization**
     (split `colony.gd` helpers without gameplay changes), or
   - **Warren upgrade economy** → unit training → gold spend → Shaman → champions

---

## 6. Acceptance reminders

- Design doc §38: files changed, preserved behavior, test steps, limitations, next step
- Do not break gather-return-store; no underground mechanics
- No new **gameplay** autoloads without ADR

## 7. Remember

- **`docs/goblin-warrens-design.md` overrides** older RTS-first or underground direction.
- Do **not** switch to `NavigationAgent3D` without user approval and new ADR.
- Do **not** commit `.cursor/secrets/`.
- `AGENTS.md` overrides the deep-research report where they conflict.
- Prefer this file + `docs/chatgpt-master-context.md` + code over stale chat summaries.

— end of handoff —
