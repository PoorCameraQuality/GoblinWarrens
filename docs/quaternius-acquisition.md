# Goblin Warrens — Quaternius asset acquisition, installation, and sorting

**Binding for Cursor agents.** CC0 from [quaternius.com](https://quaternius.com/) unless human approves otherwise.

**Related:** [`docs/itch-io-acquisition.md`](itch-io-acquisition.md) (itch.io mirrors) · [`docs/technical/ASSET_PIPELINE.md`](technical/ASSET_PIPELINE.md) · [`docs/legal/THIRD_PARTY_LICENSES.md`](legal/THIRD_PARTY_LICENSES.md)

---

## Purpose

Acquire, inspect, sort, and use **Quaternius** assets for **Goblin Warrens** — Godot 4.x above-ground goblin colony / RTS / settlement-defense.

Quaternius is especially useful for: low-poly 3D prototype art, nature props, medieval buildings, fantasy props, enemy units, weapons, and animation testing.

**No underground mechanics.** Do not use dungeon, cave, voxel, or underground-looking packs to shift the game toward tunneling, dungeon crawling, or mining simulation.

---

## License rule

Quaternius models are **CC0** — commercial, educational, and personal use; no attribution required; may be modified or combined.

Still record every pack in **`docs/legal/THIRD_PARTY_LICENSES.md`** and note workflow changes in **`docs/technical/ASSET_PIPELINE.md`**.

```text
## Quaternius — <Pack Name>

Creator: Quaternius
Source: https://quaternius.com/packs/<pack_page>.html
License: CC0
Commercial use: Yes
Attribution required: No
Attribution given anyway? yes/no
Downloaded: YYYY-MM-DD
Raw location: res://external_raw/quaternius/<category>/<pack_name>/
Clean production location: res://game/art/<category>/<pack_name>/
Used for:
Modified? yes/no
Notes:
```

---

## Downloading rules

Quaternius often offers: free download, itch.io mirror, Patreon/source version with `.blend` or engine projects.

- Use **free download** first unless human approves paid/source/member version.
- Source versions → `external_raw/quaternius/source_versions/` only — never mix into production folders.

If the same pack is downloaded from **itch.io**, still sort under `external_raw/quaternius/` and follow this doc (see itch.io doc for itch-specific checkout rules).

---

## File format rules

Prefer, in order: **`.glb` / `.gltf`** → `.blend` (source only) → `.fbx` → `.obj` (static only).

Production uses **wrapper scenes** — do not edit raw imports.

```text
Raw:     external_raw/quaternius/nature/stylized_nature_megakit/tree_oak.glb
Wrapper: game/art/props/nature/quaternius/stylized_nature/tree_oak_quaternius.tscn
```

---

## Required folder structure

```text
res://
  external_raw/quaternius/
    _incoming/
    nature/
    buildings/
    props/
    weapons/
    characters/
    monsters/
    animation/
    crops/
    ruins_reference_only/
    rejected_or_unused/
    source_versions/

  game/art/
    units/enemies/ · units/monsters/ · units/neutral_characters/
    buildings/quaternius_parts/ · enemy_outposts/
    props/nature/ · props/settlement/ · props/ritual/ · props/weapons/ · props/tools/ · props/resources/
    terrain/nature/

  game/animation/humanoid/ · goblin_tests/
  game/scenes/asset_test_scenes/
  game/dev/asset_review/
```

| Zone | Rule |
|------|------|
| `external_raw/quaternius/` | Raw downloads — **never** reference from production scenes |
| `game/art/` | Wrapper scenes and promoted art |

---

## Highest-priority packs

### 1. Stylized Nature MegaKit — **Very high**

Trees, rocks, bushes, grass, flowers, mushrooms, map borders, gather-area visuals. 116+ models; CC0; glTF/FBX/OBJ/Blend.

```text
Raw:   external_raw/quaternius/nature/stylized_nature_megakit/
Clean: game/art/props/nature/quaternius/stylized_nature/
       game/art/terrain/nature/quaternius/stylized_nature/
Review: game/scenes/asset_test_scenes/quaternius_nature_review.tscn
```

Default Quaternius nature pack unless art direction rejects it.

### 2. Medieval Village MegaKit — **Very high**

Warren kitbash, hut parts, enemy outposts, walls, roofs, doors. 304 modular pieces; CC0.

```text
Raw:   external_raw/quaternius/buildings/medieval_village_megakit/
Clean: game/art/buildings/quaternius_parts/medieval_village/
       game/art/buildings/enemy_outposts/quaternius_medieval/
       game/art/props/settlement/quaternius_medieval/
```

**Goblinize** — do not ship as a clean human village. Add junk, bones, spikes, mud, uneven fences.

### 3. Fantasy Props MegaKit — **Very high**

200+ props: crates, barrels, weapons, potions, books, cauldrons, ritual clutter. CC0.

```text
Raw:   external_raw/quaternius/props/fantasy_props_megakit/
Clean: game/art/props/settlement/quaternius_fantasy_props/
       game/art/props/ritual/quaternius_fantasy_props/
       game/art/props/weapons/quaternius_fantasy_props/
       game/art/props/tools/quaternius_fantasy_props/
Review: game/scenes/asset_test_scenes/quaternius_props_review.tscn
```

### 4. Ultimate Fantasy RTS — **High**

128 RTS-flavored buildings + nature; scale/readability prototypes only.

```text
Raw:   external_raw/quaternius/buildings/ultimate_fantasy_rts/
Clean: game/art/buildings/quaternius_parts/ultimate_fantasy_rts/
       game/dev/asset_review/quaternius_ultimate_fantasy_rts/
Review: game/scenes/asset_test_scenes/quaternius_buildings_review.tscn
```

### 5. Modular Weapons Pack — **High**

Swords, daggers, bows, shields, hammers. CC0.

```text
Raw:   external_raw/quaternius/weapons/modular_weapons_pack/
Clean: game/art/props/weapons/quaternius_modular_weapons/
Review: game/scenes/asset_test_scenes/quaternius_weapons_review.tscn
```

### 6. Ultimate Monsters — **Medium-high**

50 animated monsters — enemy variety tests. Pick tone-appropriate only.

```text
Raw:   external_raw/quaternius/monsters/ultimate_monsters/
Clean: game/art/units/monsters/quaternius_ultimate_monsters/
Review: game/scenes/asset_test_scenes/quaternius_monsters_review.tscn
```

### 7. Universal Animation Library 2 — **Medium-high (later)**

130+ humanoid animations; CC0; Godot-compatible exports. **After** core loop is playable.

```text
Raw:   external_raw/quaternius/animation/universal_animation_library_2/
Clean: game/animation/humanoid/quaternius_universal_2/
Review: game/scenes/asset_test_scenes/quaternius_animation_review.tscn
```

### 8. Universal Base Characters + Modular Outfits (Fantasy) — **Medium**

Human raiders, adventurers, scale refs — **not** player goblins unless human approves style shift.

```text
Raw:   external_raw/quaternius/characters/universal_base_characters/
       external_raw/quaternius/characters/modular_character_outfits_fantasy/
Clean: game/art/units/enemies/quaternius_humanoids/
```

### 9. Ultimate Crops Pack — **Medium**

100+ crop growth stages — food visuals only if needed; avoid cozy farming drift.

```text
Raw:   external_raw/quaternius/crops/ultimate_crops/
Clean: game/art/props/resources/quaternius_crops/
```

### 10. Farm Buildings Pack — **Medium-low**

Simple farm structures; prefer Medieval Village unless a specific piece is missing.

```text
Raw:   external_raw/quaternius/buildings/farm_buildings/
Clean: game/art/buildings/quaternius_parts/farm_buildings/
```

### 11. Ultimate Modular Ruins — **Optional / caution**

Above-ground ruin pieces only — **no** corridors, underground rooms, or dungeon floors.

```text
Raw:   external_raw/quaternius/ruins_reference_only/ultimate_modular_ruins/
Clean: game/art/props/ritual/quaternius_ruins/
       game/art/buildings/enemy_outposts/quaternius_ruins/
```

---

## Lower-priority / fallback

| Pack | When |
|------|------|
| Ultimate Nature Pack | If Stylized Nature MegaKit rejected |
| Stylized Tree Pack | Extra tree variety only |
| RPG Essentials Pack | Tiny props (coins, keys, gems) |

---

## Do not import by default

Sci-fi, space, guns, vehicles, city, tanks/mechs, card/platformer kits, restaurant interiors, voxel/cube-world, **Modular Dungeon Pack**, cute wrong-tone monsters, modern furniture.

**Cube World Kit:** wrong voxel style even if it includes a goblin.  
**Modular Dungeon Pack:** underground direction — out of scope.

---

## Immediate download order

```text
1. Stylized Nature MegaKit
2. Medieval Village MegaKit
3. Fantasy Props MegaKit
4. Ultimate Fantasy RTS
5. Modular Weapons Pack
6. Ultimate Monsters
7. Universal Animation Library 2 (when anim testing starts)
8. Ultimate Crops Pack (if food visuals needed)
9. Universal Base Characters + Outfits (when humanoid enemies needed)
```

Stop after phase 1–5; review before hoarding more.

---

## Required review scenes

| Scene | Tests |
|-------|--------|
| `quaternius_nature_review.tscn` | Nature scale, RTS readability |
| `quaternius_buildings_review.tscn` | Building kitbash, footprint |
| `quaternius_props_review.tscn` | Clutter, hut identity |
| `quaternius_weapons_review.tscn` | Weapon scale vs goblin |
| `quaternius_monsters_review.tscn` | Enemy silhouettes |
| `quaternius_animation_review.tscn` | Rig / retarget tests |
| `quaternius_settlement_style_test.tscn` | Goblinized settlement look |

Checklist per asset: scale vs goblin, RTS camera, materials, collision, nav blocking, selection outline, performance, style fit.

See [`game/scenes/asset_test_scenes/README.md`](../game/scenes/asset_test_scenes/README.md).

---

## Production wrapper rules

1. Raw file stays in `external_raw/quaternius/`.
2. Wrapper under `game/art/` — lowercase `snake_case`.
3. Collision / nav obstacle only when gameplay requires it.
4. Gameplay groups on wrappers only.
5. No worker AI, building production, raids, or magic logic in art scenes.
6. Optional metadata on wrappers: `building_visual_id`, `resource_visual_type`, `blocks_navigation`, `selection_bounds`.
7. Never reference `external_raw` from `scenes/colony.tscn` or gameplay code.

---

## Naming conventions

```text
Good: tree_oak_quaternius.tscn · outpost_wall_wood_quaternius.tscn · goblin_bow_quaternius.tscn
Bad:  TreeOakFINAL.tscn · Quaternius Stuff.tscn · monster2finalfinal.tscn
```

---

## Goblinization pass

Quaternius medieval assets are clean — Goblin Warrens should feel **crude, earthy, scavenged, dangerous**. Kitbash with:

Uneven fences · bone decorations · mud · scrap wood · torn banners · spikes · skulls · rope · junk piles · mushrooms · totems · ritual objects · broken carts · weapon racks · storage clutter.

| Building | Visual direction |
|----------|------------------|
| Warren | Central crude hub, banners, junk, smoke |
| Storage Hut | Crates, barrels, sacks, cart props |
| Breeder Hut | Warm hut, food props — avoid explicit/weird |
| Ritualist Hut | Candles, books, potions, cauldron |
| Burial Grounds | Above-ground graves, skulls, stones — no digging |
| Enemy Outpost | Walls, towers, weapon racks, patrol markers |

Combined review: `quaternius_settlement_style_test.tscn`.

---

## Art direction guardrails

**Should look:** low-poly, earthy, crude, above-ground, settlement-focused, slightly spooky, RTS-readable.

**Avoid drift:** clean noble kingdom, human village builder, dungeon crawler, voxel mining, cozy farming, sci-fi, platformer.

---

## Final instruction to Cursor

Use Quaternius as a **strong prototype and kitbash library**, not the entire game identity.

Start with Nature + Medieval Village + Fantasy Props + Ultimate Fantasy RTS + Modular Weapons → review → promote selectively.

Prefer: useful over numerous · GLB/GLTF over OBJ · wrappers over raw imports · above-ground over dungeon · goblinized over clean medieval · readable over pretty · small curated set over hoarding.
