# AGENTS.md — Working agreement for AI agents in this repo

These rules are binding for any AI agent (Cursor, Claude, GPT-5, etc.) making
changes in this repository. They are a Godot-adapted descendant of the user's
original Unity-pinned rules; every discipline from the original is preserved,
only the engine-specific bindings have changed.

If a rule conflicts with what the user asks for in chat, **stop and ask** —
do not silently override.

---

## 0. Design authority (read first)

**`docs/goblin-warrens-design.md`** is the **master design document** and the
highest authority for game direction, scope, and feature priorities.

| Priority | Document | Role |
| --- | --- | --- |
| 1 | `docs/goblin-warrens-design.md` | North star, hard rules, MVP, milestones, acceptance criteria |
| 2 | `AGENTS.md` (this file) | Engineering contract, bridge discipline, code standards |
| 3 | `docs/architecture-reconciliation.md` | Technical overrides vs external reports |
| 4 | `HANDOFF.md` | Session resume, current phase status |

Read the relevant sections of the master design doc **before every feature task**.
It supersedes older RTS-first or underground direction in `HANDOFF.md`, prior
chats, and external reports when they conflict.

### Hard design rules (binding summary)

- **No underground mechanics** — single above-ground map only. Warren, Pit, Den,
  and Burial Grounds are thematic names, not digging systems.
- **Colony survival first, RTS second** — favor warren management over pure RTS
  build-order gameplay when they conflict.
- **Preserve gather-return-store loop** — refactor incrementally; do not rewrite
  working systems without explicit instruction.
- **Build milestones in order** — see design doc §37; no advanced systems before
  the core loop is playable.

### Per-task checklist

Before implementing, state which design section and milestone apply. After
implementing, satisfy acceptance criteria in design doc §38 (files changed,
preserved behavior, test steps, limitations, next step).

---

## 1. Environment & version pinning

- The Godot version is pinned in `docs/technical-reference.md` (major.minor.patch).
  Never bump it without updating that file in the same change.
- Godot 4.x scenes (`.tscn`) and resources (`.tres`) are plain text by default.
  Do not introduce binary scene/resource formats (`.scn`, `.res`) unless
  explicitly approved.
- Resource UIDs (`uid://...`) must remain stable: never delete/recreate an asset
  to "rename" it. Use Godot's rename which rewrites references; verify with
  `git diff` that UIDs did not churn.
- Editor-only code must live under `addons/<plugin>/` or be guarded with
  `if Engine.is_editor_hint(): return`. Mark editor scripts `@tool` only when
  they truly need to run in-editor.

## 2. MCP bridge discipline (formerly "AI Bridge")

- **Idempotent commands only**: every bridge command must be safe to retry.
  No duplicate nodes, no double-increment, no leaked listeners.
- **State-before-mutate**: always call a read/inspect command (e.g.
  `getProjectInfo`, `getSceneTree`) before any mutating command. Abort on
  parse errors or compile errors.
- **Scratch-first**: perform changes in an inherited scratch scene or a
  variant; verify; then apply to production scenes. Do not edit `main.tscn`
  directly during exploratory work.
- **Backoff & timeouts**: if a bridge request fails, stop, log the error, and
  do not loop retries without changing inputs.
- **Extend the bridge, don't bypass**: if a needed command doesn't exist,
  propose an MCP server extension (new tool name + JSON schema + handler) and
  await approval before touching Godot APIs directly via shell.
- **Auth & locality**: the MCP bridge must bind to `127.0.0.1` and require an
  auth token loaded from `.cursor/secrets/` (gitignored). Never expose on
  LAN/WAN.
- **Journal every command**: append `{timestamp, cmd, args, result, scene, requestId}`
  to `.logs/bridge.log` (gitignored). Every chat-driven mutation must carry a
  `requestId` traceable to a Cursor turn.

## 3. Implementation checks (agent)

- **Official Godot docs are binding**: [https://docs.godotengine.org/en/latest/](https://docs.godotengine.org/en/latest/).
  Cross-check every class, method, signal, and property before use. See also
  `docs/technical-reference.md` (engine table + doc index).
- **Verify before use**: fail fast if a class, autoload, scene path, or
  resource path is not found. Never assume.
- **Never invent API**: if a method/class isn't in the Godot docs for the pinned
  engine version or this repo, stop and request clarification. No "looks plausible" code.
- **Main-thread discipline**: any scene-tree mutation from a non-main thread
  must go through `call_deferred(...)`.
- **Undo-friendly**: editor mutations performed through the bridge must use
  `EditorUndoRedoManager` so the user can `Ctrl+Z` your work.
- **No silent catches**: every `try`/`except`-style swallow must log via
  `Log.error("what, where, next step")`. Raw `print` is forbidden in committed
  code — see §7.

## 4. Scenes, resources & assets

- **One source of truth per scene**: the agent may only modify scenes listed
  in `docs/scene-ownership.md` (created when we have more than one). Others
  are read-only.
- **Prefer scene inheritance** over duplicating hierarchies. Never mutate a
  base scene at runtime.
- **Central definitions**: layers, groups, tags, and enum values live in
  `scripts/core/defs.gd`. Do not hardcode group/layer strings anywhere else.
- **Deterministic import settings**: texture/mesh/audio importers are
  standardized via `.import` settings checked in. Document any deviation in
  `docs/import-settings.md`.
- **Asset loading**: prefer `ResourceLoader.load_threaded_request` for anything
  larger than a few KB. Avoid synchronous `load()` in hot paths.
- 3D models from Meshy land in `assets/meshy/` and are referenced by `uid://`
  from `.tres` resources. Never reference raw filenames from gameplay code.

## 5. Coding & architecture

- `@export var` for inspector-visible fields; default to private (`_name`)
  otherwise. Use getters/setters only where needed.
- Methods ≤ ~40 lines. Refactor longer methods into well-named helpers.
- Separate edit-mode tools from runtime: `@tool` scripts and editor plugins
  live in `addons/`; runtime code lives in `scripts/`.
- Avoid Autoload singletons for systems. Prefer constructor injection or a
  thin service locator (`scripts/core/services.gd`). The only acceptable
  **gameplay** autoloads are: `Log`, `Bus` (event bus), `Defs`, `Services`.
  Plugin-owned **dev-tool** autoloads (e.g. Debug Console, Godot AI
  `_mcp_game_helper`) are allowed when they live under `addons/`, are
  registered by the plugin, and stay export-safe / non-gameplay. Do not add
  new gameplay autoloads without an ADR.
- No magic numbers: extract constants to `scripts/core/constants.gd`. Always
  document units in a comment (meters, seconds, tiles, degrees).

## 6. Pathfinding & gameplay integrations

- **Pathfinding**: `AStarGrid2D` (built-in) is the approved pathfinding for
  this project. Do not substitute external libraries (NavigationServer,
  third-party A* plugins) without explicit approval.
- All goblin movement goes through `scripts/agents/movement_adapter.gd`.
  No direct pathfinding calls from UI, jobs, or unrelated systems.

## 7. Testing & CI

- Tests use **GUT** (Godot Unit Test) under `tests/`. Every new system gets
  EditMode-style unit tests (happy path + at least one failure case) and at
  least one PlayMode-style integration test.
- The MCP bridge has its own smoke tests under `tests/smoke/` that run headless:
  `godot --headless --script tests/smoke/test_smoke.gd` must exit 0.
- **Headless pipeline tooling:** read [`docs/technical/GODOT_HEADLESS_PITFALLS.md`](docs/technical/GODOT_HEADLESS_PITFALLS.md)
  before writing or refactoring `tools/*.gd` or large `tests/smoke/*` entry
  scripts. Do not split `baked_grid_compile.gd` or the Phase 2 regression
  without re-running `tools/run_phase2_regression.ps1`.
- Every PR must satisfy: GUT tests green, smoke tests green, and a bridge
  dry-run log attached. Prefer targeted smoke scripts over
  `godot --headless --check-only` when MCP/Terrain3D plugins are enabled
  (see headless pitfalls doc).

## 8. Performance & profiling

- No per-frame allocations in hot paths. Pre-size `Array` / `PackedArray`
  buffers; reuse them.
- Document frame-time targets per scene in `docs/perf-budgets.md`. Verify with
  the Godot profiler before merging perf-sensitive changes.
- Avoid starting/stopping `Tween`/`Timer` every frame. Prefer long-lived
  signals or guarded `_process` checks.

## 9. Logging & diagnostics

- All logging goes through `Log` (autoload in `scripts/core/log.gd`):
  `Log.info`, `Log.warn`, `Log.error`. **Never** use raw `print` / `printerr`
  in committed code.
- Tag every agent-driven log line with the bridge `requestId` when applicable.
- Temporary logs must include the literal marker `TODO: remove before release`
  so they can be grepped before tagging a build.

## 10. Source control & review

- Git LFS for binaries: `.glb`, `.gltf`, `.png > 1 MB`, `.wav`, `.ogg`, `.mp3`,
  `.fbx`. Configure via `.gitattributes` when LFS is enabled.
- `.tscn`, `.tres`, `.gd` are text — they merge. Resolve conflicts manually,
  never by deleting one side.
- One change per PR: code + test + doc + (optional) bridge tool spec.
- **Conventional Commits**: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`,
  `test:`. Reference the chat session / task when relevant.

## 11. Error handling & recovery

- On a failed scene mutation, revert the working scene/resource to its last
  saved state and exit with a clear error.
- If a bridge command partially succeeds, log a repair hint (what to undo /
  what to redo) and do **not** chain further commands.

## 12. Bridge-evidence template (PR exception process)

When an edge case forces a bypass of the bridge, the PR must include:

```
BRIDGE-EVIDENCE
- Need: <one sentence>
- Tried commands: [<cmd1>, <cmd2>, ...]  (include args)
- Logs: <path to bridge.log snippet>
- Why the bridge is insufficient: <clear reason>
- Proposed extension: <new command name, args schema, expected result>
- Approval: <owner initials / date>
```

## 13. Quality-of-life (encouraged, not strict)

- Treat warnings as errors in editor assemblies / GDScript:
  `debug/gdscript/warnings/treat_warnings_as_errors=true` in
  `project.godot`. Whitelist intentional exceptions narrowly.
- **Plan mode**: before running a multi-step mutation, the agent should print
  the sequence of bridge commands it intends to run and wait for approval.
- A `docs/command-catalog.json` is auto-generated from the MCP server's tool
  list so agents can discover capability programmatically.
