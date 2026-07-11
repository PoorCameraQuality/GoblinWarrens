# Workstream 3 — Stabilize & Ship Report

**Status:** Documentation + smoke battery complete (commits pending user approval)  
**Date:** 2026-07-11

---

## Deliverables

| Item | Path |
| --- | --- |
| Full smoke script | `tools/run_all_smokes.ps1` |
| Authored scene smoke | `tools/run_authored_colony_smoke.ps1` |
| Handoff update | `HANDOFF.md` |
| Technical reference | `docs/technical-reference.md` (map_mode, smoke battery) |
| Integration guide | `docs/technical/COLONY_AUTHORED_MAP_INTEGRATION.md` |

---

## Run full battery

```powershell
cd E:\Projects\goblin-colony
.\tools\run_all_smokes.ps1
```

**Includes:** 15 headless script smokes + authored colony scene spawn (env vars).  
**Latest run:** 16 checks passed in ~320 s (exit 0).

---

## Manual regression checklist

- [ ] Procgen: `colony.tscn` with `game/map_mode=procgen` — 7-day loop
- [ ] Authored: `game/map_mode=authored` — Warren pick → gather → day 7 raid at painted entries
- [ ] Authored dev shortcut: `scenes/dev/authored_demo.tscn`
- [ ] Save/load mid-authored-game (schema v2 resource_states)
- [ ] Debug console: `inspect_goblins`, `toggle_walkability_overlay`
- [ ] Goblin Map Editor: load map, rebake 350

---

## Suggested commits (await user approval)

1. `feat(map): phases 4–9 authored pipeline + observability`
2. `feat(map): phase 10 demo map + authored bootstrap`
3. `feat(colony): authored map_mode integration + save v2`
4. `docs: handoff, smoke battery, integration guides`

---

## Limitations

- Full battery not run in CI yet (local PowerShell only)
- `test_visual_integration.gd` omitted from battery (optional asset check)
- Default remains procgen until explicitly changed

---

## Next step

User-approved git commits + manual authored 7-day sign-off.
