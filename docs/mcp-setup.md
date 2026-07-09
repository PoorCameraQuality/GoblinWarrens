# MCP setup — wiring Cursor to Godot via Aesthetic Engine GRB

This document is the runbook for getting Cursor talking to a live Godot
editor / runtime. It is intentionally explicit because the bridge is the
critical path for everything else.

## Goal

By the end of this runbook:

- Godot 4.6 is installed and on `PATH`.
- The Aesthetic Engine "Godot Runtime Bridge" (GRB) server is cloned and
  built locally.
- `.cursor/mcp.json` in this repo points Cursor at the GRB server bound to
  `127.0.0.1:7777` with an auth token.
- The smoke test `tests/smoke/test_smoke.gd` runs headlessly and exits 0.
- A Cursor agent can: list scenes, open the main scene, take a screenshot,
  read editor errors — all without clicking inside Godot.

## Prerequisites

- Windows 10/11 (confirmed: `win32 10.0.19045`).
- Node.js ≥ 18.x. Bundled with Cursor or installed at `C:\Program Files\nodejs`.
- `winget` available (confirmed).

## Step 0 — Install Godot 4.6

```powershell
winget install --id GodotEngine.GodotEngine --silent
```

Or download the 4.6 stable zip from `https://godotengine.org/download/windows/`
and unzip somewhere stable (e.g. `C:\Tools\Godot\`).

After install, capture the absolute path and fill it into
`docs/technical-reference.md` under "Pinned values".

Verify:

```powershell
godot --version
```

Expected: a string beginning with `4.6.`.

## Step 1 — Clone GRB

Pick a stable location outside this project (so GRB upgrades don't churn
this repo). Suggested: `C:\Tools\godot-runtime-bridge`.

```powershell
git clone https://github.com/Aesthetic-Engine/godot-runtime-bridge C:\Tools\godot-runtime-bridge
cd C:\Tools\godot-runtime-bridge
npm install
```

If GRB ships a build step, run it (`npm run build` is typical). Read the
README before running anything else.

## Step 2 — Auth token

```powershell
$token = -join ((1..48) | ForEach-Object { '{0:x}' -f (Get-Random -Max 16) })
New-Item -ItemType Directory -Force -Path 'E:\Projects\goblin-colony\.cursor\secrets' | Out-Null
$token | Out-File -Encoding ascii -NoNewline 'E:\Projects\goblin-colony\.cursor\secrets\grb.token'
```

The `.cursor/secrets/` folder is gitignored. Never check this token in.

## Step 3 — Wire `.cursor/mcp.json`

A starter config is checked in at `.cursor/mcp.json`. Adjust paths if your Godot
or GRB clone lives elsewhere. GRB 2.0 uses `grb_launch` to auto-discover port
and token for the MCP helper path.

Authoritative schema: `C:\Tools\godot-runtime-bridge\mcp\README.md`.

## Step 3b — GRB addon in this project

The addon lives at `addons/godot-runtime-bridge/` (copied from the GRB repo).
Open the project in Godot and enable **Project → Project Settings → Plugins →
Godot Runtime Bridge**, or re-run `godot --headless --path . --import`.

## Step 4 — Smoke test (no Cursor required)

```powershell
cd E:\Projects\goblin-colony
godot --headless --script tests\smoke\test_smoke.gd
```

Expected: exit 0 and a single line of output `[smoke] ok`.

## Step 5 — Smoke test (Cursor + GRB)

In a Cursor chat in this workspace, ask:

> "Use the godot-runtime-bridge MCP to list scenes in this project and
>  capture a screenshot of the editor."

Success criteria:

- The agent returns the list of `.tscn` files (initially just whatever exists
  in `scenes/`).
- The screenshot file appears in `.logs/screenshots/` (or wherever GRB
  configures).
- No errors in `.logs/bridge.log`.

## Fallback — `dreamer568/godot-mcp`

If GRB blocks us at any step, switch to `dreamer568/godot-mcp`:

```powershell
git clone https://github.com/dreamer568/godot-mcp C:\Tools\godot-mcp
```

…and re-do steps 2–5 against its config. Keep both entries in `.cursor/mcp.json`
temporarily while comparing.

## Alternative — Godot AI (installed)

Godot AI (`res://addons/godot_ai/`, v2.7.4) is installed and enabled. It runs its
own Python MCP server (via [uv](https://docs.astral.sh/uv/)) and exposes editor
tools (scene tree, nodes, scripts, tests, etc.) through the **Godot AI** dock.

**Coexistence with GRB:** Both plugins can be enabled in Godot. Cursor should use
**one primary MCP server** at a time — this repo's `.cursor/mcp.json` still points
at **godot-runtime-bridge** (GRB). To switch to Godot AI for Cursor:

1. Install **uv** (Windows): `powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"`
2. Open Godot → **Godot AI** dock → select **Cursor** → **Configure**
3. Optionally disable or remove the GRB entry from `.cursor/mcp.json` to avoid duplicate Godot MCP tools

Godot AI adds runtime autoload `_mcp_game_helper` for in-game screenshots and
debugger eval. It is dev-only and not used in release exports.

Docs: [github.com/hi-godot/godot-ai](https://github.com/hi-godot/godot-ai)
