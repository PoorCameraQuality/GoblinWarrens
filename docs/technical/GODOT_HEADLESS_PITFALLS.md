# Godot headless pitfalls (4.7)

**Status:** Reference — binding for agents and CI authors  
**Last updated:** 2026-07-10  
**Engine:** Godot **4.7.stable** (see [`docs/technical-reference.md`](../technical-reference.md))

This document records repeatable failures discovered while building **headless pipeline tooling** (semantic map import, grid compile, regression suite) and the **Terrain3D compatibility spike**. It explains why Phase 2 required “ugly” single-function scripts and why you see more errors than usual when working in this mode.

**Related:** [`PHASE2_GRID_COMPILE_REPORT.md`](PHASE2_GRID_COMPILE_REPORT.md) · [`TERRAIN3D_HYBRID_MAP_PLAN.md`](TERRAIN3D_HYBRID_MAP_PLAN.md) · [`AGENTS.md`](../AGENTS.md) §7

---

## When this applies

Read this document **before** writing or refactoring any of:

- `godot --headless --path . --script …` runners under `tools/` or `tests/smoke/`
- Static import/compile helpers (`map_semantic_importer.gd`, `baked_grid_compile.gd`)
- Headless regression or artifact writers
- Terrain3D scripts intended to run headless

Normal **colony gameplay** scripts edited and run from the editor are far less affected. The pitfalls below are specific to **headless `--script` entry points** that boot the full project.

---

## How headless `--script` differs from the editor

| Aspect | Editor / colony scene | `godot --headless --script foo.gd` |
| --- | --- | --- |
| Boot cost | Incremental | Full project + autoloads + enabled plugins every run (~5–6 s before `_init`) |
| GDExtension | Loaded once | Terrain3D registers on every launch |
| Failure mode | Output panel, debugger | Often silent stdout; errors easy to miss |
| Script shape | Multi-file helpers OK | Large multi-function **entry** scripts can stall or fast-fail |
| Logging | `Log` autoload fine | `Log` from **static** headless paths has hung runs |

Passing headless smoke does **not** guarantee the same file layout will work if you grow the entry script or split logic across helpers without re-running the suite.

---

## Failure modes (symptom → meaning)

### Exit code `4294967295` (Windows)

**Meaning:** Process was **killed**, not a Godot application error.

Common causes:

- Agent or user ran `Stop-Process -Name "Godot*"`
- Background shell timeout while Godot was hung
- Task Manager / system kill

**Do not treat as a regression** unless the same command fails with a normal exit code (0 or 1) on a fresh run after killing stray Godot processes.

### Fast exit `1` in ~200–400 ms

**Meaning:** Script failed **before** normal project boot (~5–6 s). Usually:

- GDScript **parse/analyze failure** on the `--script` entry file
- Entry file too large or too many top-level functions for the 4.7 analyzer in this mode

**Misleading:** Almost no console output; `push_error()` may not appear in captured stdout.

**Probe:** If `load("res://path/to/script.gd")` succeeds from a tiny runner but `--script` fails, you hit the **entry-point asymmetry** (see §4).

### Hang (2–5+ minutes, no output)

**Meaning:** GDScript **analyzer stall** while compiling preloads or a large loaded body—not necessarily infinite loop in your `_init`.

**Action:** Kill Godot, simplify script shape (§5), retry. Do not loop the same command unchanged.

### Noisy `ERROR:` lines but exit `0`

**Meaning:** Often **benign** in this repo when:

- Terrain3D GDExtension double-registers on rapid sequential Godot launches (see §6)
- `PagedAllocator` messages at headless exit

Trust **exit code** and the test’s own `[tag] ok` line first.

---

## 1. GDScript analyzer stalls (primary Phase 2 blocker)

### Observed behavior

Godot **4.7** repeatedly stalled or fast-failed when compile/grid logic was split across:

- Multiple typed helper functions in the same `--script` entry file
- Sibling scripts with `class_name` types and `preload()` chains
- Large RefCounted “body” modules loaded at runtime (still triggered stall on `load()`)

### What worked (stability boundary pattern)

**Compiler** — one static function, minimal surface:

- `scripts/world/map/baked_grid_compile.gd` → single `compile()`
- `scripts/world/map/grid_compiler.gd` → thin wrapper only

**Regression** — one `_init`, no helper functions:

- `tests/smoke/test_semantic_map_regression.gd` (~145 lines, single block)
- Contrast: `tests/smoke/test_grid_compiler.gd` (~38 lines) always worked

Document intentional debt in the compiler file header. **Do not refactor** multi-file without running:

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
```

Full gate: `tools/run_phase2_regression.ps1`

Phase 3 gate: `tests/smoke/test_terrain3d_movement_spike.gd` — creates a bare `Terrain3D` node; do **not** load `scenes/dev/terrain3d_movement_spike.tscn` headless (full scene can hang before `_ready`).

### Rules of thumb

| Prefer | Avoid in headless hot paths |
| --- | --- |
| One static `func` or one `_init` block | Many small `_check_*` helpers on the entry script |
| `Variant` / untyped returns from compile | `-> CompiledGridMap` across preload boundaries |
| Thin `--script` file that only calls `load(...).run()` **if body stays one function** | Thin entry + large multi-function body (still stalled in Phase 2) |
| Incremental smoke tests (`test_grid_compiler.gd`) | One 300-line “kitchen sink” entry file |

---

## 2. `--script` entry vs `load()` asymmetry

**Observed:** A script can `load()` successfully as a `GDScript` resource but **fail or hang** when used as the `--script` entry point.

**Implication:** “Parse error?” debugging must distinguish:

1. Real syntax error (fix code)
2. Analyzer stall on entry shape (change structure, not semantics)
3. Runtime failure after boot (logic/data)

**Debug pattern:**

```gdscript
# tests/smoke/_probe_load.gd — temporary only
extends SceneTree
func _init() -> void:
    print(load("res://path/to/suspect.gd") != null)
    quit(0)
```

If probe passes but `--script suspect.gd` fails in <1 s, treat as **entry-point analyzer issue**, not bad map data.

---

## 3. Real parser / API errors (fix the code)

These are genuine mistakes—not analyzer stalls:

| Mistake | Example | Fix |
| --- | --- | --- |
| Reserved keyword as identifier | Parameter named `class_name` | Rename (`terrain_class_name`, etc.) |
| Invented API | `HashingContext.as_string()` | `ctx.finish().hex_encode()` |
| GDExtension type in headless spike | `@onready var _terrain: Terrain3D` | Use `Node` + `ClassDB.class_exists("Terrain3D")` |

Always verify APIs in [official Godot 4.7 docs](https://docs.godotengine.org/en/latest/) before use (`AGENTS.md` §3).

---

## 4. Autoload `Log` in static headless paths

**Observed:** Calling the **`Log` autoload** from **static methods** during `godot --headless --script` import runs caused **hangs** (no output, no exit).

**Rule:** In static import/compile/tooling paths use `push_error()` / `print()` for failures. Reserve `Log` for runtime gameplay and editor sessions.

**Files to respect:** `scripts/world/map/map_semantic_importer.gd`, `baked_grid_compile.gd`, any future `tools/*.gd` runner.

---

## 5. Terrain3D GDExtension (Phase 0–1)

| Issue | Mitigation |
| --- | --- |
| Headless compile fails on `Terrain3D` type hints | Use `Node`; probe with `ClassDB` |
| `Terrain3D.data` null before node in tree | Defer checks to `_ready()` or after `add_child` |
| Double-register / unregister errors when launching Godot repeatedly | Ignore if exit 0; kill stray processes between batch runs |
| Raycast collision checks | **Partial** headless; verify collision in editor |

Terrain3D is **visual/physical terrain only**; grid authority remains `AStarGrid2D` + `movement_adapter.gd`.

---

## 6. Commands that mislead

### `godot --headless --check-only`

May **boot the full project** (including colony-related import paths) and appear to hang when MCP plugins or heavy imports are active. **Prefer targeted smoke scripts** over `--check-only` for day-to-day agent work.

### Sequential Godot launches in one shell

Running 4+ headless scripts back-to-back produces Terrain3D register/unregister noise. Use `tools/run_phase2_regression.ps1` and expect stderr clutter; gate on exit codes.

### `Image.load_from_file` on baked PNGs

Smoke tests may warn: *“Loaded resource as image file, this will not work on export.”* Acceptable for **tooling** that reads authored map PNGs from disk; not a Phase 2 failure.

---

## 7. Recommended workflow

### Before a headless session

```powershell
Get-Process -Name "Godot*" -ErrorAction SilentlyContinue | Stop-Process -Force
```

Use `_console.exe` path from [`docs/technical-reference.md`](../technical-reference.md).

### Minimal smoke (grid only)

```powershell
godot --headless --path . --script tests/smoke/test_grid_compiler.gd
```

### Phase 2 approval gate (import + compile + regression + artifact)

```powershell
tools/run_phase2_regression.ps1
```

Artifact: `data/maps/three_lane_swamp_valley/phase2_regression_artifact.json`

### When adding new headless tooling

1. Start from a **passing** tiny smoke (copy `test_grid_compiler.gd` shape).
2. Add behavior in **one block**; run after every ~20 lines added.
3. Use `print("[tag] …")` for failures—not only `push_error`.
4. Never call `Log` from static tool paths.
5. If stall appears, **simplify shape** before debugging map data.
6. Document stability boundaries in file headers (see `baked_grid_compile.gd`).

---

## 8. Frozen reference implementations

Copy these patterns, not abstract “clean architecture,” until analyzer behavior is understood or tests move to in-editor GUT:

| Pattern | Reference file |
| --- | --- |
| Single-function compile | `scripts/world/map/baked_grid_compile.gd` |
| Thin wrapper | `scripts/world/map/grid_compiler.gd` |
| Small smoke test | `tests/smoke/test_grid_compiler.gd` |
| Full regression + artifact | `tests/smoke/test_semantic_map_regression.gd` |
| Headless import runner | `tools/import_semantic_map.gd` |
| One-shot gate | `tools/run_phase2_regression.ps1` |

---

## 9. Checklist before merging pipeline changes

- [ ] Killed stray Godot processes; re-ran smokes from cold start
- [ ] `test_semantic_map_import.gd` exit 0
- [ ] `test_grid_compiler.gd` exit 0
- [ ] `test_semantic_map_regression.gd` exit 0
- [ ] No new `Log.*` calls in static import/compile paths
- [ ] No parameter or variable named `class_name`
- [ ] Compiler/refactor debt documented if shape stays “single function”
- [ ] New APIs verified against Godot 4.7 docs

---

## 10. Open questions

- Whether Godot 4.7.x patch releases improve analyzer behavior on multi-function `--script` entries (retest quarterly).
- Moving heavy regression (palette scan, dual compile hash) to **GUT in-editor** to reduce reliance on headless entry shape.
- CI matrix: single Godot process vs fork-per-test for Terrain3D noise.

---

## Changelog

| Date | Notes |
| --- | --- |
| 2026-07-10 | Initial reference from Phase 0–2 Terrain3D spike, semantic import, grid compile, regression debugging |
