# Goblin Warrens — Asset Library acquisition & sorting

**Binding for Cursor agents.** MIT/CC0 only unless human approves otherwise.
AssetLib items are free but use varied licenses — verify before install.
([Godot Asset Library docs](https://docs.godotengine.org/en/stable/community/asset_library/what_is_assetlib.html))

**Related:** [`docs/legal/THIRD_PARTY_LICENSES.md`](legal/THIRD_PARTY_LICENSES.md) · [`docs/third-party-tools.md`](third-party-tools.md) · [`docs/technical/PROJECT_STRUCTURE.md`](technical/PROJECT_STRUCTURE.md) · [`docs/itch-io-acquisition.md`](itch-io-acquisition.md) · [`docs/quaternius-acquisition.md`](quaternius-acquisition.md)

---

## Core rules

1. Prefer **MIT** and **CC0**.
2. Avoid GPL, AGPL, NonCommercial, proprietary, or unclear licenses.
3. One tool per problem — no overlapping plugins.
4. Third-party code in `addons/`; third-party raw downloads in `external_raw/`; production art in `assets/` (migrating toward `game/art/`).
5. Document every import in `docs/legal/THIRD_PARTY_LICENSES.md`.
6. Do not rewrite architecture around a plugin.
7. Study demos in separate projects — do not drop demo scenes into `scenes/colony.tscn`.
8. **No underground** tunnel/cave/dig mechanics.
9. Prefer **glTF / `.glb`** for shipped 3D ([Godot import guidance](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/importing_3d_scenes.html)).
10. Simple, Godot-native, readable folders over framework-heavy stacks.

---

## Acquisition workflow (Godot editor)

1. Open **AssetLib** tab → search exact name.
2. Before install, verify: name, Godot 4.x compatibility, **license**, category, last updated, plugin vs demo.
3. Plugins must land in `res://addons/<plugin_name>/` with `plugin.cfg` if editor plugin.
4. Enable: **Project → Project Settings → Plugins**.
5. Update `docs/legal/THIRD_PARTY_LICENSES.md` same session.
6. Demos/templates → **never** into main game; notes in `docs/references/`.

Manual ZIP: extract only the `addons/<name>/` folder into `res://addons/`.

---

## Approved tools by phase

### Phase 1 — Core prototype (install first)

| # | Asset | License | Production? | Location |
|---|-------|---------|-------------|----------|
| 1 | **Alicenzia** (License Manager) | MIT | Dev/credits — **installed** | `addons/alicenzia/` |
| 2 | **Debug Console** | MIT | Dev only — **installed** | `addons/debug_console/` + `game/dev/debug_console/` |
| 3 | **3D Navigation Demo** | MIT | **Reference only** | Separate project / `docs/references/` |
| 4 | **Godot AI** | MIT | Editor MCP — **installed** | `addons/godot_ai/` — GRB remains primary in `.cursor/mcp.json` |
| 5 | **Simple Blender Pipeline** | CC0 | Workflow | `addons/` when using `.blend` sources |

### Phase 2 — Map readability (visuals pass)

| # | Asset | License | Use |
|---|-------|---------|-----|
| 6 | **ProtonScatter** | MIT | Surface props: mushrooms, rocks, bones, clutter → `game/world/scatter/` |
| 7 | **CSG Toolkit** | MIT | Above-ground blockout only → `game/world/blockouts/` |

### Phase 3 — Playable shell

| # | Asset | License | Use |
|---|-------|---------|-----|
| 8 | **Maaack's Input Remapping** | MIT | Rebind RTS/camera keys |
| 9 | **Maaack's Options / Menus Template** | MIT | Main/pause/options/credits |

### Phase 4 — Evaluate later (one at a time)

Terrain3D (MIT), DynamicMinimap, **one of** Beehave / LimboAI / State Charts.

---

## Do not install (unless human changes direction)

Underground/tunnel/cave tools, voxel dungeons, multiplayer/cloud/leaderboard, NFT, RPG quest/inventory frameworks, GPL/AGPL/NC assets, paid proprietary without review.

---

## Folder policy

See [`docs/technical/PROJECT_STRUCTURE.md`](technical/PROJECT_STRUCTURE.md) for **current repo paths** vs target `game/` layout.

| Content | Raw / reference | Production-ready |
|---------|-----------------|------------------|
| Plugins | — | `res://addons/<name>/` |
| Art packs | `external_raw/art_packs/` | `assets/` → `game/art/` |
| Audio packs | `external_raw/audio_packs/` | `game/audio/` |
| Blender sources | `external_raw/blender_sources/` | export → `.glb` in `assets/` |
| AssetLib demos | `external_raw/assetlib_downloads/` | adapt into `scripts/` / `scenes/` |
| Debug commands | — | `game/dev/debug_console/` |
| Plugin glue code | — | `game/integrations/<plugin>/` |

**Never** reference `external_raw/` from production scenes.

---

## Naming

- Files/folders: `snake_case`
- Scenes: `storage_hut.tscn`, `goblin_worker.tscn`
- Data: `.tres` under `data/` (→ `game/data/` when migrated)

---

## Manifest entry template

After every install, append to `docs/legal/THIRD_PARTY_LICENSES.md`:

```text
Name:
Installed location:
Source:
Author:
License:
Godot Asset Library ID or source page:
Imported date:
Used for:
Production dependency? yes/no
Can be removed later? yes/no
Modified? yes/no
Notes:
```

---

## Cursor decision defaults

```text
Simple over clever.
MIT/CC0 over complicated licenses.
Godot-native over framework-heavy.
Above-ground gameplay only.
Readable folders over fast dumping.
One good tool over five overlapping tools.
AStarGrid2D over NavigationAgent3D (see AGENTS.md).
```
