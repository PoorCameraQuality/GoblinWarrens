# ADR 0001 — Engine selection: Godot 4.6

- **Status**: Accepted
- **Date**: 2026-05-24
- **Deciders**: Project owner + Cursor (synthesizing three parallel research agents)

## Context

We want to build a 2.5D grid-based goblin colony simulation (Dwarf Fortress /
RimWorld lineage) **almost entirely through AI-agent text inputs in the Cursor
editor**. 3D models will come from Meshy AI externally. Everything else —
code, scenes, levels, logic, AI behavior, UI, audio playback, save systems,
build pipeline — must be authorable from chat with minimal Editor GUI clicks.

The shortlist evaluated:

- **Unity 6 + C#** — RimWorld precedent, DOTS for huge agent counts, mature
  Unity-MCP options.
- **Godot 4.6 + GDScript** — plain-text `.tscn`/`.tres`, multiple Cursor MCP
  bridges, $0 license, official Meshy plugin.
- **Bevy 0.18 + Rust** — pure code, fastest dev loop, ECS-native, but LLM
  training data is thin and API churns.
- "AI-native" engines (nAIVE, AnvilKit, euca-engine, nexus-engine) — all
  alpha-stage and single-maintainer in mid-2026.

## Decision

**Build the goblin colony sim in Godot 4.6, with Aesthetic Engine's "Godot
Runtime Bridge" (GRB) as the Cursor MCP server, on a 2.5D foundation (3D
meshes on a logical grid).**

## Rationale

1. **Plain-text serialization.** Godot's `.tscn` and `.tres` are designed
   to be human-readable and version-control-friendly. An LLM writes them
   correctly far more often than Unity's GUID-laced YAML.
2. **Mature LLM API knowledge.** GDScript is Python-shaped and stable;
   Cursor's autocomplete and Claude/GPT-5 generate idiomatic GDScript with
   high reliability. Bevy's API churns every 6 months and pre-2026 training
   data is mostly for Bevy 0.12.
3. **Multiple Cursor-driven MCP bridges already exist** (Aesthetic Engine
   GRB, dreamer568/godot-mcp, CoplayDev/godot-mcp). The "develop → screenshot
   → verify → patch" loop the project demands is realizable today.
4. **Empty workspace, zero sunk cost.** The user's prior Unity-pinned rules
   were aspirational, not in-flight code. Switching engines now is free.
5. **No 1000+ agent scale requirement.** RimWorld and Going Medieval, the
   genre exemplars, run ~50–250 simulated colonists. `AStarGrid2D` over a
   100×100 grid with 100 goblins fits comfortably in Godot's frame budget.
6. **Meshy has an official Godot plugin.** Asset pipeline is one-click.
7. **License**: MIT; $0 forever.

## Alternatives considered, and why rejected

- **Unity 6** — colony-sim precedent and DOTS performance, but: (a) YAML
  scenes with GUID cross-refs trip LLMs more often than `.tscn` does;
  (b) Unity MCP workflows still require occasional alt-tab to the editor for
  domain-reload recovery; (c) compile/iteration is ~10–50× slower than
  Godot; (d) the user's pinned "AI Bridge" workspace rule essentially
  describes a smaller, less-tested clone of CoplayDev's Unity MCP.
- **Bevy 0.18** — best raw performance and purest code-only workflow, but
  LLM accuracy on Rust + Bevy ECS is materially worse than on GDScript,
  and there is no shipped colony-sim precedent.
- **Build a new agent-first engine** — feasibility report estimates 45–85+
  engineer-months solo. Bevy started in 2020 and is still pre-1.0 in 2026.
  Wrong move as a first project.
- **AI-native engines** (nAIVE, AnvilKit, euca-engine) — interesting but all
  alpha-stage, single-maintainer, no pathfinding/colony-sim primitives. Watch,
  do not adopt.

## Consequences

### Positive

- Iteration loop is fast: GDScript reload < 1 second; full project boot a few
  seconds.
- All gameplay state lives in text files; the agent can read and modify them
  directly without going through an editor.
- Meshy → Godot is a supported, official path.
- License-free, so future open-source release of the project is unconstrained.

### Negative

- If we ever need 1000+ goblins simultaneously, we'll have to either drop down
  to C# / GDExtension for the hot path or revisit Bevy. Mitigation: grid-based
  simulation keeps per-goblin cost small; we can also embed Bevy inside Godot
  via `godot-bevy` if needed.
- Aesthetic Engine GRB is young; we accept a real chance of swapping to
  `dreamer568/godot-mcp` mid-project.

## Escape hatches

- **Perf escape**: `godot-bevy` (Bevy ECS embedded inside Godot) if the
  simulation hot path saturates the main thread.
- **MCP escape**: swap GRB → `dreamer568/godot-mcp` if GRB blocks us; both
  can co-exist temporarily in `.cursor/mcp.json` while we evaluate.
- **Engine escape**: if Godot+MCP fundamentally cannot author this game,
  the lessons learned port cleanly to Bevy because both are ECS-shaped at
  the gameplay level.
