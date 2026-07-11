# Third-party licenses — Goblin Warrens

Update **before merging** any Asset Library plugin, art pack, audio pack, shader, or external code snippet.

Also update [`docs/technical/ASSET_PIPELINE.md`](../technical/ASSET_PIPELINE.md) when art workflow changes.

---

## Entry template (copy for each new item)

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

## Plugins (`res://addons/`)

### Godot Runtime Bridge

```text
Name: Godot Runtime Bridge
Installed location: res://addons/godot-runtime-bridge/
Source: https://github.com/Aesthetic-Engine/godot-runtime-bridge
Author: Matt Munroe
License: See upstream repository
Godot Asset Library ID or source page: GRB repo (not AssetLib)
Imported date: 2026-06 (project bootstrap)
Used for: Cursor/MCP editor bridge, smoke automation
Production dependency? no
Can be removed later? yes (dev workflow only)
Modified? no
Notes: Dev/editor only. Not shipped in player builds.
```

### Alicenzia (License Manager)

```text
Name: Alicenzia
Installed location: res://addons/alicenzia/
Source: Godot Asset Library download (manual ZIP)
Author: Etherealxx
License: MIT (see addons/alicenzia/LICENSE)
Godot Asset Library ID or source page: Alicenzia — Digital Assets License Manager
Imported date: 2026-06-30
Used for: Editor-side third-party asset/plugin license tracking and credits export
Production dependency? no
Can be removed later? yes (dev/legal workflow only)
Modified? no
Notes: Enable via Project → Project Settings → Plugins. Complements docs/legal/THIRD_PARTY_LICENSES.md — keep both in sync.
```

### Debug Console

```text
Name: Debug Console
Installed location: res://addons/debug_console/
Source: Godot Asset Library download (manual ZIP)
Author: Abdulrahman Al-Taweel
License: MIT (see addons/debug_console/LICENSE)
Godot Asset Library ID or source page: #4210
Imported date: 2026-06-30
Used for: In-editor and in-game dev console (F12 / Ctrl+`); demo QA cheats
Production dependency? no (debug builds only; GameConsoleManager gated by OS.is_debug_build())
Can be removed later? yes
Modified? no
Notes: Adds dev autoloads DebugCore, CommandRegistry, DebugConsole, GameConsoleManager. Game commands wired in game/integrations/debug_console/register.gd.
```

### Godot AI

```text
Name: Godot AI
Installed location: res://addons/godot_ai/
Source: Manual ZIP (github.com/hi-godot/godot-ai)
Author: Godot AI contributors
License: MIT (see addons/godot_ai/LICENSE)
Godot Asset Library ID or source page: Godot AI (AssetLib)
Imported date: 2026-06-30
Used for: Editor MCP server (scene/node/script tools); optional Cursor client via dock "Configure"
Production dependency? no
Can be removed later? yes (dev workflow only)
Modified? no
Notes: Adds runtime autoload _mcp_game_helper for in-game screenshots/debugger bridge. Requires uv for Python MCP server. Coexists with GRB — use one primary MCP in Cursor (.cursor/mcp.json currently points at GRB). Do not enable both MCP servers in Cursor unless you know the port split.
```

### Terrain3D

```text
Name: Terrain3D
Installed location: res://addons/terrain_3d/
Source: https://github.com/TokisanGames/Terrain3D/releases/tag/v1.0.2-stable
Author: Cory Petkovsek (Tokisan Games) & Roope Palmroos (Outobugi Games)
License: MIT (see addons/terrain_3d/LICENSE.txt)
Godot Asset Library ID or source page: https://godotengine.org/asset-library/asset/3892
Imported date: 2026-07-10
Used for: Phase 1 compatibility spike — authored terrain evaluation for hybrid map workflow (isolated dev scene only)
Production dependency? no (pending Godot 4.7 spike pass and migration phases)
Can be removed later? yes (disable plugin; colony procgen remains fallback)
Modified? no
Notes: GDExtension plugin. Grid gameplay remains AStarGrid2D authoritative. See docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md. Official support claims Godot 4.4–4.6+; 4.7 verified via spike.
```

---

## Art packs

Raw assets live under `external_raw/` — **not referenced from production scenes**. Curated wrappers in `game/art/` are wired via `scripts/art/visual_catalog.gd` and `VisualAttacher` (demo asset pass, 2026-06-30).

### LOWPO: Goblin Assets (Standout 7)

```text
Name: LOWPO: Goblin Assets – Low Poly Fantasy 3D Assets for Games
Installed location: external_raw/itch_io/goblins/standout7_lowpo_goblin_assets/
Source: https://standout7.itch.io/goblin-lowpoly-assets
Author: Standout 7
License: CC0 1.0 Universal
Godot Asset Library ID or source page: itch.io (manual download)
Imported date: 2026-06-30
Used for: Player goblin prototypes (worker/warrior/archer), weapon scale reference
Production dependency? yes — `game/art/units/goblins/standout7_lowpo/goblin_worker_lowpo.tscn` for worker goblins
Can be removed later? yes
Modified? no
Notes: Archive copy in external_raw/itch_io/_incoming/GoblinPack_Free.zip. glTF + GLB + FBX. Foblins use Meshy Twigskull (see below).
```

### Meshy AI — Twigskull Goblin (Foblin)

```text
Name: Meshy AI Twigskull Goblin biped
Installed location: external_raw/meshy/twigskull_foblin/
Source: Meshy AI generation (user asset)
Author: User / Meshy AI
License: Meshy AI terms — verify account license for commercial use
Imported date: 2026-07-01
Used for: Production Foblin unit — rigged, textured, animated (walk/run/gather/attack/death)
Production dependency? yes — `game/art/units/goblins/twigskull/foblin_twigskull_visual.tscn`
Can be removed later? yes (revert visual_catalog GOBLIN_FOBLIN to LOWPO fallback)
Modified? Blender cleanup optional; runtime animation merge via `scripts/agents/unit_animator.gd`
Notes: FBX character + per-clip animation FBXs. Do not reference Downloads path from scenes.
```

### KayKit — Resource Bits 1.0 FREE

```text
Name: KayKit Resource Bits
Installed location: external_raw/itch_io/resources/kaykit_resource_bits/
Source: https://kaylousberg.itch.io/resource-bits
Author: Kay Lousberg
License: CC0
Godot Asset Library ID or source page: itch.io (manual download)
Imported date: 2026-06-30
Used for: Wood/stone/ore piles, storage visuals, resource node dressing
Production dependency? no
Can be removed later? yes
Modified? no
Notes: Archive in _incoming/KayKit_ResourceBits_1.0_FREE.zip. glTF under Assets/gltf/.
```

### KayKit — Forest Nature Pack 1.0 FREE

```text
Name: KayKit Forest Nature Pack
Installed location: external_raw/itch_io/nature/kaykit_forest_nature/
Source: https://kaylousberg.itch.io/kaykit-forest
Author: Kay Lousberg
License: CC0
Godot Asset Library ID or source page: itch.io (manual download)
Imported date: 2026-06-30
Used for: Trees, rocks, bushes, grass (alternative to Quaternius nature — pick one style)
Production dependency? no
Can be removed later? yes
Modified? no
Notes: Archive in _incoming/KayKit_Forest_Nature_Pack_1.0_FREE.zip.
```

### KayKit — Halloween Bits

```text
Name: KayKit Halloween Bits
Installed location: external_raw/itch_io/graveyard/kaykit_halloween_bits/
Source: https://kaylousberg.itch.io/halloween-bits
Author: Kay Lousberg
License: CC0
Godot Asset Library ID or source page: GitHub mirror + itch.io
Imported date: 2026-06-30
Used for: Burial grounds, gravestones, skulls, ritual dressing
Production dependency? no
Can be removed later? yes
Modified? no
Notes: Sorted from GitHub clone; 63 glTF in raw path.
```

### KayKit — Character Pack: Adventurers 2.0 FREE

```text
Name: KayKit Character Pack: Adventurers
Installed location: external_raw/itch_io/characters/kaykit_adventurers/
Source: https://kaylousberg.itch.io/kaykit-adventurers
Author: Kay Lousberg
License: CC0
Godot Asset Library ID or source page: itch.io (manual download)
Imported date: 2026-06-30
Used for: Enemy raider scale reference, weapons — not player goblins
Production dependency? no
Can be removed later? yes
Modified? no
Notes: Archive in _incoming/KayKit_Adventurers_2.0_FREE.zip.
```

### KayKit — Character Pack: Skeletons 1.1 FREE

```text
Name: KayKit Character Pack: Skeletons
Installed location: external_raw/itch_io/characters/kaykit_skeletons/
Source: https://kaylousberg.itch.io/kaykit-skeletons
Author: Kay Lousberg
License: CC0
Godot Asset Library ID or source page: itch.io (manual download)
Imported date: 2026-06-30
Used for: Undead enemy / burial threat tests (later)
Production dependency? no
Can be removed later? yes
Modified? no
Notes: Archive in _incoming/KayKit_Skeletons_1.1_FREE.zip.
```

### Quaternius — Stylized Nature MegaKit (Standard)

```text
Name: Quaternius Stylized Nature MegaKit (Standard)
Installed location: external_raw/quaternius/nature/stylized_nature_megakit/
Source: https://quaternius.com/packs/stylizednaturemegakit.html · https://opengameart.org/content/stylized-nature-megakit
Author: Quaternius
License: CC0
Godot Asset Library ID or source page: OpenGameArt Standard download
Imported date: 2026-06-30
Used for: Trees, rocks, mushrooms, outdoor dressing
Production dependency? no
Can be removed later? yes
Modified? no
Notes: 68 glTF + 68 .bin. Primary nature candidate vs KayKit Forest.
```

### Quaternius — Medieval Village MegaKit (Standard)

```text
Name: Quaternius Medieval Village MegaKit (Standard)
Installed location: external_raw/quaternius/buildings/medieval_village_megakit/
Source: https://quaternius.com/packs/medievalvillagemegakit.html · https://opengameart.org/content/medieval-village-megakit
Author: Quaternius
License: CC0
Godot Asset Library ID or source page: OpenGameArt Standard download
Imported date: 2026-06-30
Used for: Warren/hut kitbash, walls, enemy outpost parts (goblinize before ship)
Production dependency? no
Can be removed later? yes
Modified? no
Notes: 176 glTF + 176 .bin.
```

### Quaternius — Fantasy Props MegaKit (Standard)

```text
Name: Quaternius Fantasy Props MegaKit (Standard)
Installed location: external_raw/quaternius/props/fantasy_props_megakit/
Source: https://quaternius.com/packs/fantasypropsmegakit.html · https://opengameart.org/content/fantasy-props-megakit
Author: Quaternius
License: CC0
Godot Asset Library ID or source page: OpenGameArt Standard download
Imported date: 2026-06-30
Used for: Crates, barrels, settlement clutter, ritual props
Production dependency? no
Can be removed later? yes
Modified? no
Notes: 94 glTF + 94 .bin. Seven samples promoted to game/art/props/ (review pass).
```

**Acquisition guides:** [`docs/itch-io-acquisition.md`](../itch-io-acquisition.md) · [`docs/quaternius-acquisition.md`](../quaternius-acquisition.md).

---

## Engine

```text
Name: Godot Engine
License: MIT
Source: https://godotengine.org/license
Used for: Runtime and editor
```

---

## MIT notice (for credits screen)

```
[Plugin Name]
Copyright (c) [year] [author]
Licensed under the MIT License.
```

CC0 assets: attribution optional but appreciated in credits.
