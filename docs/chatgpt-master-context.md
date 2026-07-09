# Goblin Warrens — Master Context for AI Assistants (ChatGPT / Cursor)

**Last updated:** 2026-07-01  
**Project root:** `E:\Projects\goblin-colony`  
**Repo name:** `goblin-colony` (working title; game name is **Goblin Warrens**)

Use this document to onboard any AI assistant. Read it before suggesting features, writing code, or changing design.

---

## 1. What we are building

**Goblin Warrens** is a **3D above-ground goblin colony survival builder** with **siege-defense combat** and **light RTS controls**.

The player grows a weak goblin camp into a dangerous monster warren by managing food, shelter, breeding, labor, faith, magic, defenses, and goblin chaos while enemies scout, raid, and assault the settlement.

**Core fantasy:**

> Farthest Frontier / Dawn of Man survival progression — but you are building a **filthy goblin monster camp**, not a human village.

**Secondary inspirations:**

- **Life Reset** — goblin clan growth, monster-side survival, dirty mechanics, escalation
- **Warcraft III** — readable RTS camera, selection, right-click commands, economy *shape* (not exact numbers)
- **RimWorld / Dwarf Fortress** — memorable colonists and stories, but **not** deep simulation complexity for MVP

**Genre labels:** colony survival builder, above-ground settlement sim, monster-side base-building, siege-defense strategy, light RTS hybrid, single-player.

---

## 2. Documentation hierarchy (authority order)

When documents conflict, follow this order:

| Priority | Document | Role |
| ---: | --- | --- |
| 1 | `docs/goblin-warrens-design.md` | **Master game design** — north star, hard rules, MVP, milestones, glossary |
| 2 | `AGENTS.md` | **Engineering contract** — Godot version, MCP bridge, tests, logging, pathfinding |
| 3 | `docs/architecture-reconciliation.md` | Technical overrides vs external reports |
| 4 | `docs/economy-wc3-reference.md` | WC3-inspired economy shape (population, upkeep, foblins) |
| 5 | `docs/technical-reference.md` | Pinned Godot version, paths, performance budgets |
| 6 | `docs/procedural-map-plan.md` | **Procedural map generation** — heightmap terrain, biome, splat shader, scatter, phase plan |
| 7 | `docs/asset-list.md` | Asset authoring checklist indexed to `visual_catalog.gd` |
| 8 | `HANDOFF.md` | Session resume (may lag behind; verify in code) |
| 9 | This file | **AI onboarding summary** — synthesizes the above for chat assistants |

**Rule:** If design and engineering conflict, **stop and ask the user** — do not silently override design.

---

## 3. Hard design rules (non-negotiable)

### 3.1 No underground mechanics

Single **above-ground** map only. No tunnels, cave layers, excavation, or burrow networks.

Names like **Warren**, **Sleeping Pit**, **Burial Grounds** are **thematic only** — all buildings sit on the surface.

### 3.2 Colony survival first, RTS second

RTS controls exist (select, right-click move/gather/build/fight), but the game is **not** a competitive RTS build-order sim. Favor colony survival fantasy when they conflict.

### 3.3 Preserve the worker loop

Do **not** break the gather → haul → storehouse loop unless explicitly instructed. Refactor incrementally.

### 3.4 Technical bindings (from AGENTS.md)

- **Engine:** Godot **4.7.stable** (project targets 4.6+)
- **Language:** GDScript
- **Pathfinding:** `AStarGrid2D` only, via `scripts/agents/movement_adapter.gd` — **not** NavigationAgent3D / navmesh
- **Autoloads:** `Log`, `Bus`, `Defs`, `Services` only — no new autoloads without ADR
- **Grid:** 1 tile = 1 meter (`Constants.TILE_SIZE`)
- **Logging:** `Log.info/warn/error` only — no raw `print`
- **UI:** must not mutate simulation directly; route through services/commands

---

## 4. MVP and playable demo (current target)

### Win condition (7-day MVP)

Survive **7 in-game days** and **repel the first human raid**, while:

- Keeping the **Warren** alive
- Building a **Shrine**
- Building **basic defenses** (Guard Post or Watchtower)

### Loss conditions

- Warren destroyed
- Food collapse (3 consecutive failed food upkeep ticks)
- All goblins dead (implicit)

### Day-by-day arc (implemented in `data/demo/demo_day_catalog.gd`)

| Day | Title | Player learns | Threat |
| --- | --- | --- | --- |
| 1 | Filthy Beginnings | Gather, build Storage/Sleeping Pit, food | Hunger |
| 2 | The Camp Breathes | Forager/Mushroom Farm | Surface beast |
| 3 | More Goblins | Breeder Hut, Foblins, housing pressure | Food demand |
| 4 | Faith in the Mud | Shrine, prayer, magic | Hunger/sickness |
| 5 | Bones Remember | Burial, revival | Beasts/starvation |
| 6 | They Found Us | Guard Post/Watchtower | Human scout |
| 7 | First Raid | Defend Warren, Bless Defenders | Human militia raid |

**Main playable scene:** `scenes/colony.tscn`

---

## 5. Current implementation status (as of 2026-07-01)

### ✅ Working (playable 7-day prototype)

User verdict: **"Works; looks terrible; prototype demo."** Gameplay loop is functional; art is placeholder/kitbash quality.

| System | Status | Key files |
| --- | --- | --- |
| Grid movement | ✅ | `movement_adapter.gd` |
| Goblin workers (×6 start) | ✅ | `goblin.gd`, `goblin.tscn` |
| Gather → haul → storehouse | ✅ | `job_service.gd`, `resource_node.gd`, `storehouse.gd` |
| RTS selection + commands | ✅ | `selection_controller.gd`, `rts_camera.gd` |
| Building placement + construction | ✅ | `build_placement.gd`, `construction_site.gd`, `building_factory.gd` |
| All MVP buildings | ✅ | Warren, Storehouse, Sleeping Pit, Forager, Mushroom Farm, Breeder, Shrine, Guard, Watchtower, Burial |
| Food upkeep + collapse loss | ✅ | `food_upkeep.gd` |
| Housing cap | ✅ | `colony.gd` → `get_housing_capacity()` |
| Foblins from Breeder Hut | ✅ | `foblin.gd`, `breeder_hut.gd` |
| Foblin zero-food upkeep | ✅ | `food_upkeep.gd` (first economy pass) |
| Population crowding penalties | ✅ | `population_brackets.gd` (−10/−15/−25% gather/build by pop) |
| Day simulation + briefings | ✅ | `day_simulation.gd`, `demo_guide.gd` |
| Threats (beast, scout, militia raid) | ✅ | `threat_scheduler.gd`, `enemy_unit.gd` |
| Combat (melee, HP, death) | ✅ | `goblin.gd`, `enemy_unit.gd` |
| Shrine + magic + rituals | ✅ | `shrine_building.gd` — Bless Defenders, Revive |
| Burial + revival | ✅ | `burial_grounds.gd`, `death_record.gd` |
| Win/loss evaluation | ✅ | `mvp_evaluator.gd`, `end_summary_panel.gd` |
| Save/load (basic) | ✅ | `colony_save.gd` |
| Minimal art pass | ✅ | `game/art/` wrappers + `visual_catalog.gd` + CSG fallback |
| Smoke tests | ✅ | `tests/smoke/test_smoke.gd`, `test_colony.gd` |

### 🚧 Partial / stubbed

| System | Status | Notes |
| --- | --- | --- |
| Gold economy | Stub | Resource exists; buildings mostly cost Wood/Stone |
| Warren upgrades (L2–L4) | Stub | `warren.level` field; L3 mitigates crowding penalty only |
| Per-unit population costs | Not implemented | All goblins count as 1 toward cap |
| Unit training costs | Not implemented | No train-from-building flow |
| Shaman hero | Not implemented | Magic via Shrine/prayer only |
| Champions | Not implemented | Design in §28 of master design doc |
| GUT unit tests in editor | Not installed | Tests exist but `GutTest` base missing |
| Walk/combat animation | Not implemented | Static T-pose / kitbash meshes |
| Morale / desertion | Not implemented | Design doc §14.3 — grace period, no instant mass desertion |

### ❌ Explicitly out of scope (MVP)

Multiplayer, full campaign, large tech tree, diplomacy, trade, underground, tunnels, complex morale sim, ten enemy factions, deep individual psychology, full megakit art dumps.

See `docs/goblin-warrens-design.md` §36.

---

## 6. Architecture overview

```
Player input (UI)
    → selection_controller / build_placement
    → colony.gd (orchestrator)
        → job_service (assign gather/build/forage/pray)
        → goblin.gd / foblin.gd (workers)
        → movement_adapter (AStarGrid2D)
        → stockpile (resources)
        → buildings (warren, farms, shrine, etc.)
        → threat_scheduler (day events)
        → food_upkeep + population_brackets
    → Bus signals (events)
    → HUD (demo_guide, labels)
```

### Resources (`Defs.ResourceKind`)

| Resource | Role |
| --- | --- |
| **Gold** | Scrap/trade (future primary spend) |
| **Wood** | Primary build material (WC3 lumber analogue) |
| **Stone** | Secondary build material |
| **Food** | Rations / upkeep every 8s |
| **Magic** | Shrine rituals (Bless, Revive) |
| **Bones** | From burial; revival economy hook |

### Unit categories (design intent)

| Unit | Pop cost (planned) | Food upkeep | Role |
| --- | ---: | ---: | --- |
| **Foblin** | 1 | 0 | Expendable swarm from Breeder Hut; poor gather/build; fights to death |
| **Goblin Worker** | 2 (planned) | 2/tick | Main labor; current demo treats all starters as workers |
| **Goblin Warrior/Archer** | 3 (planned) | 3/tick | Basic fighters — not trained yet |
| **Hobgoblin** | 5 (planned) | 4/tick | Heavy bruiser — not in demo |
| **Shaman** | 5 (planned) | magic drain | Hero caster — not in demo |
| **Champion** | special slot | magic | Rare elite — not in demo |

**Current demo:** 6 generic goblins at start; Breeder spawns Foblins. Foblins skip food upkeep; workers eat.

### Economy (WC3-inspired, first pass implemented)

See `docs/economy-wc3-reference.md`.

| Population | Gather/build penalty |
| ---: | --- |
| 0–30 | None |
| 31–50 | −10% |
| 51–75 | −15% |
| 76+ | −25% (Warren L3+ removes this) |

Food: `2 food × non-foblin goblin` every 8 seconds. Three failed ticks = loss.

---

## 7. Art and assets

### Pipeline

```
external_raw/  →  tools/promote_gltf.ps1  →  game/art/  →  visual_catalog.gd  →  gameplay spawn
                      ↑
              asset_test_scenes/ (scale QA)
```

- **Never reference `external_raw/` from production scenes.**
- **Wrapper pattern:** `game/art/**/*.tscn` instances glTF/GLB under `Model` node
- **Fallback:** CSG greybox if wrapper missing (`visual_attacher.gd`)

### Art direction (demo pass)

| Role | Source |
| --- | --- |
| Goblins | LOWPO Standout 7 (GLB) — workers |
| Foblins | **Meshy Twigskull** (FBX, animated: walk/gather/attack/death) |
| Nature / buildings | Quaternius megakit (kitbashed) |
| Resource piles | KayKit Resource Bits |
| Burial props | KayKit Halloween Bits |
| Enemies | KayKit Adventurers GLB + CSG fallback; beast = scaled rock |

Licenses: `docs/legal/THIRD_PARTY_LICENSES.md`

**Visual quality:** Intentionally prototype — no animations, kitbashed buildings, scale not tuned.

---

## 8. Key files map

| Concern | Path |
| --- | --- |
| Main scene | `scenes/colony.tscn` |
| Colony orchestrator | `scripts/world/colony.gd` |
| Goblin / Foblin | `scripts/agents/goblin.gd`, `foblin.gd` |
| Enemies | `scripts/agents/enemy_unit.gd` |
| Pathfinding | `scripts/agents/movement_adapter.gd` |
| Jobs | `scripts/jobs/job_service.gd` |
| Buildings data | `data/buildings/building_catalog.gd` |
| Demo copy | `data/demo/demo_day_catalog.gd` |
| Constants / enums | `scripts/core/constants.gd`, `defs.gd` |
| Event bus | `scripts/core/bus.gd` |
| Visual catalog | `scripts/art/visual_catalog.gd` |
| Art attach | `scripts/core/visual_attacher.gd` |
| Economy brackets | `scripts/world/population_brackets.gd` |
| Food upkeep | `scripts/world/food_upkeep.gd` |
| Day/threats | `scripts/world/day_simulation.gd`, `threat_scheduler.gd` |
| Win/loss | `scripts/world/mvp_evaluator.gd` |
| RTS UI | `scripts/ui/selection_controller.gd`, `build_placement.gd`, `rts_camera.gd` |
| Tests | `tests/smoke/`, `tests/unit/` |
| Master design | `docs/goblin-warrens-design.md` |
| Agent rules | `AGENTS.md` |

---

## 9. Implementation milestones (design doc §37)

| # | Milestone | Status |
| ---: | --- | --- |
| 1 | Stable worker loop | ✅ Done |
| 2 | Selection and commands | ✅ Done |
| 3 | Building placement | ✅ Done |
| 4 | Food and population | ✅ Done (+ crowding pass) |
| 5 | Breeder Hut and Foblins | ✅ Done |
| 6 | Basic combat | ✅ Done |
| 7 | Raid system | ✅ Done |
| 8 | Shrine and magic | ✅ Done |
| 9 | Burial and revival | ✅ Done |
| 10 | MVP demo loop (7-day arc) | ✅ Playable; polish ongoing |

**Next logical work** (not started): Warren upgrade economy, unit training, gold spend, Shaman hero, champions, art scale pass, animation, public demo sandbox expansion.

---

## 10. How AI assistants should help

### Do

- Read `docs/goblin-warrens-design.md` section relevant to the task before coding
- Follow `AGENTS.md` engineering discipline
- Preserve gather-return-store loop
- Use `AStarGrid2D` via movement adapter for all goblin movement
- Route visuals through `visual_catalog.gd` + `visual_attacher.gd`
- Use `preload()` for cross-script refs if global `class_name` fails headless
- Run smoke tests after substantive changes
- Ask before changing design rules or pathfinding approach
- Keep diffs minimal and focused

### Do not

- Implement underground mechanics
- Switch to navmesh without user approval + ADR
- Reference `external_raw/` from production scenes
- Add autoloads beyond the approved four
- Use raw `print` in committed code
- Rewrite the whole project unless asked
- Clone WC3 numbers exactly — use the **shape** (pop pressure, supply buildings, soft upkeep)
- Commit or push git unless user explicitly asks

### Verification commands

```powershell
$G = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7-stable_win64_console.exe"
cd E:\Projects\goblin-colony
& $G --headless --path . --script tests/smoke/test_smoke.gd
& $G --headless --path . --script tests/smoke/test_colony.gd
```

Note: `godot --headless --check-only` may hang when MCP/import is active — prefer smoke scripts.

### MCP (Godot AI plugin)

- Session typically: `goblin-colony@e4c8`
- Read errors: `logs_read` with `source: "editor"` or `"game"`
- Common noise: case-mismatch warnings in `external_raw/`; stale broken `basic_goblin_lowpo_gltf.gltf` import

---

## 11. Known issues / tech debt

| Issue | Severity | Notes |
| --- | --- | --- |
| Art looks bad | Expected | Prototype kitbash pass; scale untuned |
| Broken goblin glTF sidecar | Low | Delete `basic_goblin_lowpo_gltf.gltf`; use `.glb` |
| GUT not installed | Low | Unit tests won't run in editor |
| Gold underused | Design gap | Planned economy expansion |
| Per-unit pop costs missing | Design gap | All units = 1 slot today |
| Demo Day 3 briefing says foblins eat food | Copy bug | Code: foblins skip food upkeep |
| GDScript warnings | Low | Unused Bus signals, variable shadowing |
| `HANDOFF.md` outdated | Doc drift | Trust this file + code over HANDOFF |

---

## 12. Glossary (quick reference)

| Term | Meaning |
| --- | --- |
| **Warren** | Central colony hub; destruction = loss |
| **Foblin** | Cheap expendable goblin from Breeder Hut; 0 food upkeep |
| **Proper Goblin** | Full worker/warrior unit (future training) |
| **Sleeping Pit** | Housing (+4 cap); WC3 Farm analogue |
| **Storehouse** | Resource deposit target for haulers |
| **Shrine** | Faith building; generates magic via prayer |
| **Burial Grounds** | Processes dead goblins; enables revival |
| **Magic** | Spent on Bless Defenders (30) and Revive (30) |
| **Militia** | Day 7 raid enemy wave |
| **Scout** | Day 6 warning enemy |

Full glossary: `docs/goblin-warrens-design.md` §39.

---

## 13. One-paragraph elevator pitch

**Goblin Warrens** is a single-player 3D goblin colony survival game where you manage a filthy above-ground warren through a 7-day escalating demo: gather resources, build farms and housing, breed expendable foblins, worship at a shrine for magic, bury and revive fallen goblins, and defend against beasts, scouts, and a final human raid — all with Warcraft III-style selection and right-click commands over a grid-based sim. The Godot 4.7 prototype in `scenes/colony.tscn` is **playable but visually rough**; design authority lives in `docs/goblin-warrens-design.md`, engineering in `AGENTS.md`.

---

## 14. Related documents (read as needed)

| Document | When to read |
| --- | --- |
| `docs/goblin-warrens-design.md` | Any feature, balance, or scope question |
| `AGENTS.md` | Before any code change |
| `docs/economy-wc3-reference.md` | Economy tuning, population, upkeep |
| `docs/asset-pipeline.md` | 3D art workflow |
| `docs/mcp-setup.md` | Godot MCP / GRB setup |
| `docs/legal/THIRD_PARTY_LICENSES.md` | Art attribution |
| `docs/decisions/0001-engine-selection.md` | Why Godot + grid pathfinding |

---

*End of master context. When in doubt: colony survival first, preserve the worker loop, no underground, ask before overriding design.*
