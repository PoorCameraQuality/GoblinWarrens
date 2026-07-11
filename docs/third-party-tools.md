# Third-party tools & assets — Goblin Warrens

**Policy:** MIT or CC0 for anything shipped in a commercial build. GPL/AGPL/NC = do not use.
Track every addition in [`docs/legal/THIRD_PARTY_LICENSES.md`](legal/THIRD_PARTY_LICENSES.md).
Full acquisition workflow: [`docs/asset-library-acquisition.md`](asset-library-acquisition.md).

**Engine pin:** Godot 4.7 (4.6+ compatible) — see `docs/technical-reference.md`.

---

## Already in this repo

| Tool | License | Role | Notes |
|------|---------|------|-------|
| **Godot Runtime Bridge (GRB)** | Check upstream GRB repo | Cursor/MCP bridge, smoke automation | `addons/godot-runtime-bridge/` — dev only, not gameplay |
| **Built-in AStarGrid2D** | Godot MIT | All unit movement | Do **not** replace with NavigationAgent3D or navmesh plugins |
| **Custom save (`ColonySave`)** | — | Colony persistence | Skip “Save Made Easy” unless we outgrow it |
| **CSG placeholders** | — | Current blockout art | Replace incrementally with GLB |

---

## Install now (dev & license hygiene)

Safe, high value, minimal gameplay risk.

| Tool | License | Why for Goblin Warrens | Install |
|------|---------|----------------------|---------|
| **Alicenzia** | MIT | License/credits tracking in editor (installed) | `addons/alicenzia/` — enabled |
| **License Manager** | MIT | Alternative to Alicenzia — **do not install both** | Skip if using Alicenzia |
| **Debug Console** | MIT | Dev cheats: skip day, spawn food, trigger raid | `addons/debug_console/` — enabled |
| **Debug Menu (FPS overlay)** | MIT | Perf while placing buildings / raids | AssetLib → `addons/debug_menu/` |

**Optional (workflow, not gameplay):**

| Tool | License | Why | Notes |
|------|---------|-----|-------|
| **Godot AI** | MIT | Editor MCP (scene/script tools) | `addons/godot_ai/` — enabled; use dock **Configure** for Cursor |

---

## Install for the visuals pass (next milestone)

Matches current CSG-cube prototype → readable above-ground warren.

| Tool | License | Why | Use in project |
|------|---------|-----|----------------|
| **Simple Blender Pipeline** | CC0 | GLB import conventions, scale, origin | Pair with `docs/asset-pipeline.md` |
| **ProtonScatter** | MIT | Scatter mushrooms, rocks, bones, clutter on ground plane | Mushroom farms, burial grounds, map dressing |
| **CSG Toolkit** | MIT | Faster blockout of pits, huts, walls before final GLB | Above-ground Warren shapes — thematic, not underground |

**Art sources (download, no plugin):**

| Source | License | First assets to pull |
|--------|---------|----------------------|
| **Kenney** | CC0 | Nature kit, rocks, simple structures |
| **Quaternius** | CC0 | Low-poly nature, props, simple characters |
| **KayKit** | CC0 | Adventurers/workers as human enemy reference; stylized props |

Drop paths: `assets/env/`, `assets/props/`, `assets/characters/` per `docs/asset-pipeline.md`.
Reference by `uid://` from `.tres` — never raw paths in gameplay code.

---

## Install later (pre-demo / pre-Early Access)

| Tool | License | When | Why |
|------|---------|------|-----|
| **Maaack's Menus Template** | MIT | Main menu + pause + credits | Before public demo build |
| **Maaack's Options Menus** | MIT | With menus template | Audio, graphics toggles |
| **Maaack's Input Remapping** | MIT | When rebinding matters | RTS hotkeys 1–9, camera |
| **Terrain3D** | MIT | **Spike in progress (2026-07-10)** — authored terrain for hybrid map workflow | Grid sim stays `AStarGrid2D`; Terrain3D owns physical land only. See [`docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md`](technical/TERRAIN3D_HYBRID_MAP_PLAN.md). Not production map authority until spike passes on Godot 4.7. |

---

## Reference only — do not integrate into movement

| Tool | License | Verdict |
|------|---------|---------|
| **3D Navigation Demo** | MIT | **Study only.** We use `movement_adapter.gd` + `AStarGrid2D`. Navmesh conflicts with `AGENTS.md`. |
| **Beehave / LimboAI** | MIT | **Defer.** Enemy AI is simple melee + day schedule. Add one behavior-tree plugin only if militia/scouts need complex tactics. |
| **Save Made Easy** | MIT | **Skip** unless `ColonySave` becomes unmaintainable. |

---

## Do not use

| Category | Examples | Reason |
|----------|----------|--------|
| GPL / AGPL plugins | — | Source-sharing obligations |
| NC / NonCommercial art | Many itch “free” packs | Cannot sell the game |
| CC BY-SA art as core kit | — | Share-alike complicates derived work |
| Proprietary license without legal read | — | Case-by-case only |

---

## Recommended stack (summary)

```text
NOW (dev)
  Alicenzia (installed)     MIT
  Debug Console (installed) MIT
  Godot AI (installed)      MIT
  GRB (already)             dev MCP — primary in .cursor/mcp.json

VISUALS (next)
  Kenney / Quaternius / KayKit   CC0  → assets/
  Simple Blender Pipeline        CC0
  ProtonScatter                  MIT
  CSG Toolkit                    MIT

LATER (shipping UI)
  Maaack Menus + Options + Input Remapping   MIT

SKIP FOR NOW
  Beehave, LimboAI, Save Made Easy, NavigationAgent3D

TERRAIN3D (spike)
  v1.0.2-stable — compatibility spike only; not yet production map authority
```

---

## What we can do in this repo (Cursor)

1. Add `THIRD_PARTY_LICENSES.md` entry for each installed plugin/asset pack.
2. Install AssetLib plugins into `addons/` and enable in `project.godot`.
3. Import CC0 GLB packs under `assets/` with standardized `.import` settings.
4. Replace CSG in `scenes/colony.tscn` / building scenes with instanced props.
5. Use Debug Console commands for demo QA (advance day, spawn raid, grant resources).
6. Keep Meshy → Blender pipeline for custom goblin bodies (`docs/asset-pipeline.md`).

---

## Decision log

| Date | Decision |
|------|----------|
| 2026-06-30 | MIT/CC0 only for shipped content. GRB stays primary MCP bridge. Grid pathfinding stays built-in. |
| 2026-07-10 | Terrain3D pivot approved. Phase 1 compatibility spike on Godot 4.7; procgen remains production until migration phases complete. |
