# `.cursor/` — Cursor / MCP configuration

This folder configures how Cursor and AI agents interact with the project.

| Path | Purpose | Tracked? |
|---|---|---|
| `mcp.json` | MCP server registrations (added after GRB is installed). | Yes |
| `rules/` | Project-specific Cursor rules (`goblin-colony.mdc`). | Yes |
| `secrets/` | Auth tokens (e.g. `grb.token`). | **No** (gitignored) |
| `*.log` | Local bridge logs from MCP servers. | **No** (gitignored) |

See `docs/mcp-setup.md` for the runbook that creates `mcp.json` and the
secrets folder.
