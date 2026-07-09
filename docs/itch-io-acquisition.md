# Goblin Warrens — itch.io free Godot asset acquisition, installation, and sorting

**Binding for Cursor agents.** MIT/CC0 (or explicit commercial-free) only unless human approves otherwise.

**Related:** [`docs/asset-library-acquisition.md`](asset-library-acquisition.md) (Godot AssetLib) · [`docs/quaternius-acquisition.md`](quaternius-acquisition.md) (Quaternius direct) · [`docs/technical/ASSET_PIPELINE.md`](technical/ASSET_PIPELINE.md) · [`docs/legal/THIRD_PARTY_LICENSES.md`](legal/THIRD_PARTY_LICENSES.md) · [`docs/technical/PROJECT_STRUCTURE.md`](technical/PROJECT_STRUCTURE.md)

> **Quaternius packs:** Sort under `external_raw/quaternius/` per [`quaternius-acquisition.md`](quaternius-acquisition.md), even when downloaded from itch.io.

---

## Purpose

Acquire, inspect, sort, and import useful **free itch.io assets tagged for Godot** for **Goblin Warrens** — a Godot 4.x above-ground goblin colony / RTS / settlement-defense game.

Goblin Warrens is **not** an underground/tunnel game. Do not add cave-building, digging, dungeon crawling, underground layers, voxel mining, tunnel navigation, or procedural dungeon systems.

---

## Main rule

Use itch.io assets only if they are:

```text
Free or name-your-own-price with $0 allowed
Commercial-use allowed
Preferably CC0
Compatible with Godot or provided in generic formats Godot can import
Useful to Goblin Warrens specifically
Not AI-generated unless the human explicitly approves
```

When in doubt, do **not** import the asset into production.

---

## Preferred itch.io filters

Use these search/filter pages first:

| Filter | URL |
|--------|-----|
| Free + Godot | [itch.io/game-assets/free/tag-godot](https://itch.io/game-assets/free/tag-godot) |
| **Free + Godot + CC0** (safest) | [itch.io/game-assets/assets-cc0/free/tag-godot](https://itch.io/game-assets/assets-cc0/free/tag-godot) |
| Low-poly | […/free/tag-godot/tag-low-poly](https://itch.io/game-assets/free/tag-godot/tag-low-poly) |
| UI | […/free/tag-godot/tag-user-interface](https://itch.io/game-assets/free/tag-godot/tag-user-interface) |
| Icons | […/free/tag-godot/tag-icons](https://itch.io/game-assets/free/tag-godot/tag-icons) |
| Medieval | […/free/tag-godot/tag-medieval](https://itch.io/game-assets/free/tag-godot/tag-medieval) |
| Goblin | […/free/tag-goblin](https://itch.io/game-assets/free/tag-goblin) |

The safest filter is **Free + Godot + CC0** — itch.io lists a dedicated CC0 + Godot page. Use that before browsing general free results.

---

## Downloading rules

When a page says **Download Now — Name your own price**, download the free tier only unless the human explicitly approves payment.

Do not download paid extras, paid source files, paid bundles, premium expansions, or “extra” tiers unless the human approves.

For each asset, inspect and record:

```text
Asset name:
Creator:
Source URL:
Download date:
License:
Commercial use allowed? yes/no/unclear
Godot compatible? yes/no/unclear
Formats included:
AI generated? yes/no/unclear
Production use? yes/no/reference only
Imported location:
Notes:
```

Update **`docs/legal/THIRD_PARTY_LICENSES.md`** and **`docs/technical/ASSET_PIPELINE.md`** before using the asset in production scenes.

---

## Import format rules

For 3D assets, prefer **`.glb` / `.gltf`**. Godot recommends glTF for complex or animated scenes; OBJ is limited (no skinning, animation, UV2, or PBR).

Use **`.fbx` / `.obj`** only when `.glb` or `.gltf` is unavailable or broken.

Do not keep production scenes linked directly to raw downloaded folders.

---

## Required project folders

```text
res://
  external_raw/
    itch_io/
      _incoming/
      goblins/
      characters/
      nature/
      buildings/
      resources/
      graveyard/
      prototyping/
      ui/
      audio/
      animation/
      rejected_or_reference_only/

  game/
    art/
      units/          goblins/, enemies/, neutral_characters/
      buildings/      warren/, storage_hut/, burial_grounds/, …
      props/          resources/, graveyard/, ritual/, settlement/, nature/, prototype/
      terrain/        nature/
      materials/
      ui/             themes/
      icons/
    audio/            ui/, units/, combat/, ambience/
    animation/        humanoid/, goblins/, enemies/
    scenes/
      asset_test_scenes/
      test_maps/
    dev/
      asset_review/
    ui/
      themes/
```

| Zone | Rule |
|------|------|
| `external_raw/itch_io/` | Raw downloads only — **never** reference from production scenes |
| `game/art/`, `game/audio/`, `game/animation/` | Cleaned, game-ready wrappers and exports |
| `assets/` | Legacy runtime path still in use — migrate to `game/art/` gradually |

---

## Highest-priority useful assets

### 1. LOWPO: Goblin Assets — Low Poly Fantasy 3D Assets for Games

**Priority: Very high** · [standout7.itch.io/goblin-lowpoly-assets](https://standout7.itch.io/goblin-lowpoly-assets)

Use for: prototype goblin worker/warrior/archer, early visual identity, weapon scale reference.

Includes: Basic Goblin, Goblin Warrior, Goblin Archer, Bow, Sword, Shiv, Arrow, shared PNG texture. Rigged, low-poly, Godot-compatible; `.gltf`, `.glb`, `.fbx`, `.obj`, `.png`. Listed **CC0**; page states **no generative AI**.

```text
Raw:   external_raw/itch_io/goblins/standout7_lowpo_goblin_assets/
Clean: game/art/units/goblins/standout7_lowpo/
       game/animation/goblins/standout7_lowpo/
Test:  game/scenes/asset_test_scenes/goblin_lowpo_test.tscn
```

Do not commit as final art style until tested beside the rest of the stack.

### 2. KayKit — Resource Bits

**Priority: Very high**

Use for: wood/stone/ore piles, food props, storage contents, resource node markers, carry props, production chain prototypes.

CC0; wood, stone, iron, copper, silver, gold, textiles, fuel, etc. OBJ, FBX, GLTF.

```text
Raw:   external_raw/itch_io/resources/kaykit_resource_bits/
Clean: game/art/props/resources/kaykit/
Scenes: wood_stack_kaykit.tscn, stone_stack_kaykit.tscn, ore_pile_kaykit.tscn, …
```

### 3. KayKit — Forest Nature Pack

**Priority: Very high**

Use for: trees, rocks, grass, bushes, gatherable wood visuals, map borders, outpost surroundings.

CC0; FBX, GLTF, OBJ.

```text
Raw:   external_raw/itch_io/nature/kaykit_forest_nature/
Clean: game/art/props/nature/kaykit_forest/
       game/art/terrain/nature/kaykit_forest/
```

Dress maps only — do not scatter gameplay-critical objects without explicit gameplay metadata.

### 4. Quaternius — Stylized Nature MegaKit

**Priority: Very high**

Use for: large outdoor dressing, trees/plants/flowers/rocks/bushes, biomes, natural blockers. 110+ models. CC0; FBX, OBJ, glTF.

```text
Raw:   external_raw/quaternius/nature/stylized_nature_megakit/
Clean: game/art/props/nature/quaternius/stylized_nature/
       game/art/terrain/nature/quaternius/stylized_nature/
Review: game/scenes/asset_test_scenes/quaternius_nature_review.tscn
```

Pick **KayKit Forest** or **Quaternius Nature** as primary nature style — test together first, do not use both equally without review.

### 5. Quaternius — Medieval Village MegaKit

**Priority: High**

Use for: Warren exterior prototype, hut kitbash, enemy outpost walls/camps, village ruins, fences. 300+ modular pieces. CC0; Godot support in source; FBX, OBJ, glTF.

```text
Raw:   external_raw/quaternius/buildings/medieval_village_megakit/
Clean: game/art/buildings/quaternius_parts/medieval_village/
       game/art/buildings/enemy_outposts/quaternius_medieval/
       game/art/props/settlement/quaternius_medieval/
```

Goblinize before treating as final Warrens buildings.

### 6. KayKit — Medieval Hexagon Pack

**Priority: High**

Use for: RTS building placeholders, road/river/coast tiles, barracks/market/mine references, layout prototypes. 200+ hex tiles; CC0; RTS/village-builder suitable.

```text
Raw:   external_raw/itch_io/buildings/kaykit_medieval_hexagon/
Clean: game/art/buildings/kaykit_hex_prototypes/
       game/art/terrain/kaykit_hex_prototypes/
```

**Goblin Warrens does not have to become hex-grid.** Visual prototyping only unless human chooses hex gameplay.

### 7. KayKit — Halloween Bits

**Priority: High**

Use for: Burial Grounds, gravestones, skulls, mausoleum props, ritual dressing, death/revival visual language. 60+ models; CC0.

```text
Raw:   external_raw/itch_io/graveyard/kaykit_halloween_bits/
Clean: game/art/props/graveyard/kaykit_halloween/
       game/art/buildings/burial_grounds/kaykit_halloween/
```

Above-ground graveyard only — no underground mechanics.

### 8. KayKit — Prototype Bits

**Priority: High**

Use for: greybox, blockers, footprint markers, scale/collision/selection tests. 64+ models; CC0; OBJ, FBX, GLTF.

```text
Raw:   external_raw/itch_io/prototyping/kaykit_prototype_bits/
Clean: game/dev/asset_review/kaykit_prototype_bits/
       game/art/props/prototype/
```

Do not ship prototype visuals in final scenes unless approved.

---

## Character and animation assets

| # | Pack | Priority | Use | Raw → Clean |
|---|------|----------|-----|-------------|
| 9 | KayKit Character Pack: Adventurers | Medium-high | Enemy raiders, scale ref, weapons, anim rig test | `characters/kaykit_adventurers/` → `game/art/units/enemies/kaykit_adventurers/` |
| 10 | KayKit Character Pack: Skeletons | Medium-high | Undead raids, burial tests, magic threats | `characters/kaykit_skeletons/` → `game/art/units/enemies/skeletons/kaykit/` |
| 11 | KayKit Character Animations | Medium-high | Humanoid locomotion/combat timing tests | `animation/kaykit_character_animations/` → `game/animation/humanoid/kaykit/` |
| 12 | Quaternius Universal Animation Library | Medium | See [`quaternius-acquisition.md`](quaternius-acquisition.md) | `external_raw/quaternius/animation/` → `game/animation/humanoid/quaternius_universal_2/` |

Do not make KayKit adventurers the player goblins. Do not let retargeting block the core loop.

---

## UI and audio assets

| # | Pack | Priority | Notes |
|---|------|----------|-------|
| 13 | Kenney UI Theme for Godot (Azagaya) | Medium | CC0; Godot 4.x download on page → `game/art/ui/themes/kenney_azagaya/` |
| 14 | UI Autumn (VerzatileDev) | Medium | CC0 PNG UI → `game/art/ui/themes/ui_autumn/` — **one main UI style at a time** |
| 15 | Wooden UI SFX (JDSherbert) | Medium-low | **Not CC0 on page** — inspect `LICENSE.pdf` before production → `game/audio/ui/wooden_ui_jdsherbert/` |

---

## Optional / later

**Maaack — Godot Game Template:** reference only for menus/options/credits. Do not replace this project. Prefer AssetLib Maaack plugins if already adopted.

---

## Assets to avoid or delay

Do not import unless human explicitly approves:

```text
Dungeon/cave/voxel-mining packs · Dungeon crawlers · Platformer-only · 2D pixel for 3D project
Sci-fi · Vehicles · Modern city · Hospital interiors · Card/inventory/dialogue frameworks
Paid expansions · NonCommercial · Unclear license · AI-generated packs
```

**KayKit Dungeon Pack Remastered:** CC0 but off-theme — no underground gameplay. Consider later only for above-ground ruins or stone props.

---

## Immediate recommended download list

Download and sort first (do not import all into production — use review scenes):

```text
1.  LOWPO: Goblin Assets (Standout 7)
2.  KayKit Resource Bits
3.  KayKit Forest Nature Pack
4.  KayKit Halloween Bits
5.  KayKit Prototype Bits
6.  Quaternius Stylized Nature MegaKit
7.  Quaternius Medieval Village MegaKit
8.  KayKit Medieval Hexagon Pack
9.  KayKit Character Pack: Skeletons
10. KayKit Character Animations
```

---

## Required asset review scenes

| Scene | Purpose |
|-------|---------|
| `game/scenes/asset_test_scenes/goblin_asset_review.tscn` | Goblin units |
| `game/scenes/asset_test_scenes/resource_asset_review.tscn` | Resource props |
| `game/scenes/asset_test_scenes/nature_asset_review.tscn` | Nature dressing |
| `game/scenes/asset_test_scenes/building_asset_review.tscn` | Building kitbash |
| `game/scenes/asset_test_scenes/burial_grounds_asset_review.tscn` | Graveyard / burial |
| `game/scenes/asset_test_scenes/ui_theme_review.tscn` | UI themes |
| `game/scenes/asset_test_scenes/animation_review.tscn` | Animation / rigs |

Each review scene should test: **scale, materials, collision, animation, lighting, RTS camera readability, selection outline, performance, style fit**.

See [`game/scenes/asset_test_scenes/README.md`](../game/scenes/asset_test_scenes/README.md).

---

## Naming conventions

Lowercase `snake_case`:

```text
Good: goblin_worker_lowpo.tscn · wood_stack_kaykit.tscn · tree_oak_quaternius.tscn
Bad:  GoblinFinal.fbx · New Goblin 2.glb · DungeonStuffUseLater.tscn
```

---

## Production-ready wrapper workflow

1. Open imported `.glb` / `.gltf`.
2. Create inherited or wrapper scene under `game/art/...`.
3. Add collision only if needed.
4. Assign gameplay groups in wrapper scenes only — not on raw imports.
5. Do not edit raw files in `external_raw/`.
6. Production scenes must not depend on `external_raw/`.

Example:

```text
Raw:     external_raw/itch_io/goblins/standout7_lowpo_goblin_assets/goblin_warrior.glb
Wrapper: game/art/units/goblins/standout7_lowpo/goblin_warrior_lowpo.tscn
```

---

## License manifest entry format

Append to `docs/legal/THIRD_PARTY_LICENSES.md`:

```text
## LOWPO: Goblin Assets – Low Poly Fantasy 3D Assets for Games

Creator: Standout 7
Source: https://standout7.itch.io/goblin-lowpoly-assets
License: Creative Commons Zero v1.0 Universal
Commercial use: Yes
AI-generated: No (per itch.io page)
Downloaded: YYYY-MM-DD
Imported raw location: res://external_raw/itch_io/goblins/standout7_lowpo_goblin_assets/
Clean production location: res://game/art/units/goblins/standout7_lowpo/
Used for: Goblin prototype units
Modified: yes/no
Notes:
```

---

## Art direction guardrails

**Should look like:** crude, earthy, low-poly, RTS-readable, above-ground, settlement-focused, slightly spooky (not horror-first), fantasy without noble-kingdom polish.

**Avoid drift into:** clean medieval kingdom builder, dungeon crawler, voxel game, pixel-art, cozy farming, sci-fi base builder, generic RPG inventory game.

---

## What “useful” means

An asset is useful only if it helps: goblin units, worker readability, resource/building readability, above-ground terrain, enemy outposts, Burial Grounds, Ritualist Hut, magic visuals, UI/HUD, animation testing, or prototype speed.

---

## Final instruction to Cursor

Do not hoard assets. Acquire a small set, sort correctly, test in review scenes, then promote selected assets into production.

**Prefer:** CC0 · Godot-compatible · GLB/GLTF · low-poly · fantasy/medieval · above-ground · RTS camera readable.

**Reject:** unclear license · NonCommercial · AI without approval · paid-only · underground/dungeon/voxel focus · unrelated genre.

**First candidate:** [LOWPO Goblin Assets](https://standout7.itch.io/goblin-lowpoly-assets) (CC0, on-theme). Then KayKit Resource Bits, Forest Nature, Halloween Bits, and Quaternius Medieval Village / Nature for the first art pass.
