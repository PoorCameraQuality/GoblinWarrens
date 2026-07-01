# Goblin Warrens

A 3D **above-ground** goblin colony survival builder with siege-defense combat
and light RTS controls — grow a filthy camp into a dangerous monster warren.
Built primarily by AI agents (Cursor) inside the chat window, with 3D models
sourced from Meshy AI and polished in Blender, AccuRIG/Mixamo, and Cascadeur.

## Stack

- **Engine**: Godot 4.6 (stable). See `docs/technical-reference.md`.
- **Language**: GDScript (primary).
- **Pathfinding**: Built-in `AStarGrid2D` over a logical grid; agents render on a
  3D plane under an RTS camera (not navmesh freeform 3D).
- **3D art**: Meshy → Blender → GLB (static) / FBX (animated) → Godot.
- **Agent control plane**: Aesthetic Engine GRB over MCP. See `docs/mcp-setup.md`.

## Working agreement

This repo is co-authored by humans and AI agents. The rules in `AGENTS.md` are
binding for both. **Game design direction** lives in the master design doc below.

## Quick reference

| Topic | File |
|---|---|
| **Master design (read first for features)** | **`docs/goblin-warrens-design.md`** |
| **Resuming this project** | **`HANDOFF.md`** |
| How agents must behave in this repo | `AGENTS.md` |
| Why we picked Godot over Unity / Bevy | `docs/decisions/0001-engine-selection.md` |
| Report vs repo architecture | `docs/architecture-reconciliation.md` |
| Art pipeline (Meshy, Blender, rigging) | `docs/asset-pipeline.md` |
| Pinned versions and tool paths | `docs/technical-reference.md` |
| Installing & wiring the MCP bridge | `docs/mcp-setup.md` |

## Status

Phase 2 vertical slice: `scenes/colony.tscn` with grid goblins, gather-haul-store
loop, construction, HUD, and autosave. Milestone 1 (worker loop) largely in place;
Milestone 2 (selection and commands) is next. See `docs/goblin-warrens-design.md` §37.

Godot install and GRB wiring may still be pending — see `HANDOFF.md`.
