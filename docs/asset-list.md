# Asset List — Goblin Warrens Demo

Authoring checklist for the 3D art you are producing in Meshy (+ Blender cleanup + AccuRIG for humanoids). Every asset here maps to a slot in `scripts/art/visual_catalog.gd`, or, where marked ➕, needs a **new** slot added.

- **Master design authority**: `docs/goblin-warrens-design.md`
- **Pipeline & tool roles**: `docs/asset-pipeline.md`
- **Visual code index**: `scripts/art/visual_catalog.gd`
- **Grid**: 1 tile = 1 meter. Most buildings are `2×2` (Watchtower is `1×1`). Visual scales live in `scripts/core/constants.gd` (`VISUAL_*_M` targets).
- **Current map size**: **350 × 350 tiles** (`Constants.GRID_WIDTH/HEIGHT` in `scripts/core/constants.gd`). Procgen active in `scenes/colony.tscn`. Older 20×20 / 48×48 figures below are **obsolete placement estimates** — kept for reference only.

Scope is the **7-day MVP demo** first, **public sandbox demo** second. Anything outside that is called out explicitly.

---

## 1. Style guide — "Filthy Goblin Monster Camp"

From master design §3.2 and §5.1. Every asset should read as **improvised, dirty, and goblin-made**, not heroic or medieval-clean.

- **Materials**: rough-hewn wood, mud daub, thatch, animal hide, bone lashings, scrap iron, rust, moss. Not sawn timber, not clean stone masonry.
- **Silhouette**: crooked, leaning, cobbled together. No 90° corners; posts tilt; roofs sag.
- **Color palette**: mossy greens, mud browns, bone off-white, dried-blood rust, dirty ochre. Avoid saturated primaries and clean whites.
- **Decoration**: bones, skulls, feathers, trophies, warpaint, ritual scratches, drying meat, filth.
- **Do not**: use polished medieval banners, clean plaster, symmetrical architecture, or knight-fantasy heroic look.
- **Enemy factions inverted**: Humans look **clean and organized** — a deliberate contrast. Dwarves look industrial. Elves look pristine and unwelcoming.

Read like: **Farthest Frontier** or **Dawn of Man** houses, but if the "peasants" were goblins scavenging junk. **Not** RimWorld-cute, **not** Warcraft-heroic.

---

## 2. Authoring specs (all assets)

Copy these into your Meshy prompts and Blender export defaults.

| Spec | Value | Notes |
|---|---|---|
| Runtime format (static) | **`.glb`** | Buildings, props, trees, rocks, resource piles |
| Runtime format (animated) | **`.fbx`** | Goblins, foblins, enemies — humanoid rigs |
| Editable source | `.blend` | Not shipped |
| Scale | 1 tile = 1 meter | Verify in Blender before export |
| Orientation | -Z forward, +Y up | glTF default; Godot handles it |
| Pivot (buildings/props) | Bottom-center of footprint | So placement lands on the ground plane |
| Pivot (characters) | Between the feet | Not pelvis, not root offset |
| Base texture | **1024×1024** PBR | 512 for tiny props; 2048 only for hero pieces |
| PBR channels | BaseColor + Normal + MetalRoughness (packed OK) | Roughness in G; Metal in B is fine |
| Poly targets | Building ≤ 5k · Character ≤ 2k · Prop ≤ 500 | Meshy Lowpoly preset generally lands here |
| Naming | `snake_case.glb` / `.fbx` | Match `visual_catalog.gd` constants |
| Drop root | `game/art/**/goblin_warrens/` | Keep separated from placeholder kitbash sources so we can swap the wrapper `.tscn` in one step |

Wrapper pattern (unchanged): each `.glb` gets a matching wrapper `.tscn` (e.g. `warren_visual.tscn`) that instances the model under a `Model` node at correct pivot, and `visual_catalog.gd` points its `BUILDING_*` constant at that wrapper.

---

## 3. Buildings — MVP (11 unique meshes)

Every entry below already has a wrapper slot in the code. Author the mesh, drop it in `game/art/buildings/<name>/goblin_warrens/`, then swap the wrapper `.tscn` to instance the new `.glb`.

Footprints come from `data/buildings/building_catalog.gd`.

| # | Building | Footprint | VisualCatalog slot | Design role | Meshy prompt hint | Priority |
|---:|---|---:|---|---|---|---|
| 1 | **Warren** | 2×2 | `BUILDING_WARREN` | Central colony hub, colony heart, destruction = loss | "large goblin longhouse of piled logs, bone-lashed roof, mud-daub walls, skull totem on top, tribal banners, weathered, tilted, muddy base, low-poly stylized" | ★★★ MVP |
| 2 | **Storehouse / Storage Hut** | 2×2 | `BUILDING_STOREHOUSE` | Resource deposit target | "squat goblin storage shack, thatch roof, wooden crates and barrels visible through open sides, sacks piled at door, low-poly stylized" | ★★★ MVP |
| 3 | **Sleeping Pit** | 2×2 | `BUILDING_SLEEPING_PIT` | Housing (+4 cap), Farm analogue | "shallow round earthen pit with wooden lean-to over half of it, straw bedding, hides draped, sunken half-dug look but visually above ground, low-poly" | ★★★ MVP |
| 4 | **Mushroom Farm** | 2×2 | `BUILDING_MUSHROOM_FARM` | Reliable food production | "wooden goblin shed with mushroom beds spilling out, giant mushrooms visible, damp mossy planks, small chimney venting spores, low-poly stylized" | ★★★ MVP |
| 5 | **Forager Post** | 2×2 | `BUILDING_FORAGER_POST` | Gathering zone support | "small goblin outpost hut on stilts, drying racks with berries and roots, mud-daub walls, watchpost feel but not military, low-poly" | ★★★ MVP |
| 6 | **Breeder Hut** | 2×2 | `BUILDING_BREEDER_HUT` | Foblin spawning | "large filthy goblin hut with domed straw roof, animal skulls at entrance, muddy churned ground, cages and pens visible on sides, low-poly stylized" | ★★★ MVP |
| 7 | **Shrine** | 2×2 | `BUILDING_SHRINE` | Prayer, magic generation | "small stone-and-wood shrine, crude idol of a goblin deity, bone offerings, painted stones, ritual smoke, candles or torches, low-poly stylized" | ★★★ MVP |
| 8 | **Burial Grounds** | 2×2 | `BUILDING_BURIAL_GROUNDS` | Corpse handling, bones, revival | "small goblin burial plot with 4 wooden grave markers, piled bones in a corner, one shallow open grave, tribal warding sticks, low-poly stylized" | ★★★ MVP |
| 9 | **Guard Post** | 2×2 | `BUILDING_GUARD_POST` | Patrol / defensive rally | "small fortified goblin platform with rough wooden palisade, a fire barrel, weapon rack of crude spears, hide banners, low-poly stylized" | ★★★ MVP |
| 10 | **Watchtower** | **1×1** | `BUILDING_WATCHTOWER` | Detection + ranged defense | "tall spindly goblin lookout tower on four wooden legs, ladder up the side, thatched cap, warning bell of scrap metal, low-poly stylized" | ★★★ MVP |
| 11 | **Generic Hut** *(fallback)* | 2×2 | `BUILDING_GENERIC` | Fallback for any building without its own visual | "generic filthy goblin hut, mud walls, thatch roof, one door, one window, weathered, low-poly stylized" | ★★☆ Nice-to-have |

**Extras that the code doesn't wire yet but the catalog defines** (stubs — build the mesh, but no VisualCatalog slot yet — will need slot added):

| Building | Footprint | Note |
|---|---|---|
| **Lumber Hut** ➕ | 2×2 | `data/buildings/building_catalog.gd` has it; `BuildingKind.LUMBER_HUT` exists. Priority ★★☆. |
| **Quarry** ➕ | 2×2 | Same — `BuildingKind.QUARRY`. Priority ★★☆. |

**Also needed once, shared by every building**:

| Asset | Purpose | Notes |
|---|---|---|
| **Construction Foundation / Site** ➕ | Placeholder that shows while a building is being built | Simple staked outline of poles + rope + a pile of building materials. One asset scaled 1×1 to 2×2 covers everything. Priority ★★★. |

---

## 4. Units — MVP (5 characters)

Humanoids need Blender cleanup + AccuRIG or Mixamo, per `docs/asset-pipeline.md` §"Rigging choices". Animation set minimum: **idle, walk, gather, attack, death** (5 clips). If you can only ship two: **walk + attack**.

| # | Unit | VisualCatalog slot | Height | Design role | Meshy prompt hint | Priority |
|---:|---|---|---|---|---|---|
| 1 | **Goblin Worker** *(proper goblin)* | `GOBLIN_WORKER` | ~1.1m | Main labor unit, food eater | "small green goblin, ragged leather loincloth, tool belt, big pointed ears, hunched posture, carrying a wooden club or crude pickaxe, cartoon low-poly game character" | ★★★ MVP |
| 2 | **Foblin** *(swarm)* | `GOBLIN_FOBLIN` | ~0.85m | Cheap expendable spawn from Breeder Hut | "tiny scrawny goblin runt, pale sickly green, oversized ears, twig-thin arms, wearing dirty rags and a bone necklace, twitchy nervous posture, cartoon low-poly" | ★★★ MVP |
| 3 | **Beast** *(surface fauna)* | `ENEMY_BEAST` | ~1.2m | Day 2/5 threat — wolf/boar/bear | "large scarred forest boar with dark bristly fur, tusks, angry red eyes, muddy hooves, low-poly stylized game creature" *(alternative: dire wolf)* | ★★★ MVP |
| 4 | **Human Scout** | `ENEMY_SCOUT` | ~1.8m | Day 6 telegraph enemy | "human ranger scout, clean leather armor, hood up, short bow across back, small sword at hip, alert cautious posture, cartoon low-poly game character — deliberately clean contrast to filthy goblins" | ★★★ MVP |
| 5 | **Human Militia** | `ENEMY_MILITIA` | ~1.8m | Day 7 raid enemy | "human peasant militia, plain leather jerkin with tabard, iron half-helm, short spear and small round shield, determined stance, cartoon low-poly — organized and grim" | ★★★ MVP |

**Public demo add-ons** (not MVP, but design authority §7.2 lists them):

| Unit | Slot needed | Notes |
|---|---|---|
| **Goblin Shaman** *(hero)* ➕ | `GOBLIN_SHAMAN` | Unique hero. Robed, staff, antler headdress, bone charms. Height ~1.15m. Priority ★★☆ (public demo, not MVP). |
| **Goblin Warrior** ➕ | `GOBLIN_WARRIOR` | Trained from Barracks (post-MVP). Bigger goblin, hide armor, cleaver. Priority ★☆☆. |
| **Goblin Archer / Slinger** ➕ | `GOBLIN_ARCHER` | Ranged goblin. Priority ★☆☆. |
| **Dwarf Miner** ➕ | `ENEMY_DWARF` | Public demo dwarven mining post. Priority ★☆☆. |
| **Elf Ranger** ➕ | `ENEMY_ELF` | Public demo elf grove. Priority ★☆☆. |

---

## 5. Terrain — ground tiles (5 base types) ➕

Currently the world is a flat plane. For visual variety a `GridMap` or MultiMeshInstance-driven tile system needs 5 base tile meshes (or 5 material variants of one tile mesh). This will need a new `TERRAIN_*` section in `visual_catalog.gd`.

| # | Tile | Where used | Meshy / material prompt hint | Priority |
|---:|---|---|---|---|
| 1 | **Grass** | Default outside the camp | "1m stylized grass tile, short grass mesh strip variety, low-poly, top-down readable" | ★★★ |
| 2 | **Dirt / Mud** | Around buildings, paths, high-traffic | "1m stylized dirt/mud tile, churned footprints, wet patches, low-poly" | ★★★ |
| 3 | **Rocky ground** | Near stone deposits, mountain edges | "1m stylized rocky ground tile, scree, small embedded stones, low-poly" | ★★☆ |
| 4 | **Sand / dry** | Ruins area, desert edges | "1m stylized dry sandy ground tile, cracked earth, low-poly" | ★☆☆ (public demo only) |
| 5 | **Water edge** | Ponds, streams (visual only — pathing blocked) | "1m stylized water tile, shallow murky pond edge with muddy border, low-poly, subtle animated shader-friendly UVs" | ★★☆ |

**Alternative if 3D tiles are too much work**: author 5 seamless 1024×1024 diffuse textures instead of meshes, and tint a shared quad. Fastest path to variety.

---

## 6. Environment props — nature (7 unique + optional variants)

These are placed in the world to decorate wilderness and provide harvestable resources.

| # | Prop | VisualCatalog slot | Meshy prompt hint | Instance role | Priority |
|---:|---|---|---|---|---|
| 1 | **Oak Tree** | `ENV_TREE` | "stylized oak tree, 3m tall, dense round canopy, brown bark trunk, low-poly game asset" | Decorative + becomes wood resource node when harvested | ★★★ |
| 2 | **Pine Tree** | `ENV_TREE_PINE` | "stylized pine tree, 4m tall, conical dark green canopy, straight trunk, low-poly game asset" | Same | ★★★ |
| 3 | **Dead Tree / Stump** ➕ | `ENV_TREE_DEAD` | "stylized dead tree, bare gnarled branches, gray weathered trunk, foreboding, low-poly" | Ambience near ruins / burial grounds | ★★☆ |
| 4 | **Large Rock / Boulder** | `ENV_ROCK` | "stylized large moss-topped boulder, 1.5m, low-poly game asset" | Decorative + stone resource node | ★★★ |
| 5 | **Rock Cluster (small)** ➕ | `ENV_ROCK_SMALL` | "stylized small rock cluster of 4 stones on dirt patch, ~0.5m spread, low-poly" | Filler + minor stone node | ★★☆ |
| 6 | **Bush (decorative)** | `ENV_BUSH` | "stylized dense green bush, 0.8m, no berries, low-poly" | Decorative only | ★★☆ |
| 7 | **Berry Bush (harvestable)** ➕ | `ENV_BERRY_BUSH` | "stylized berry bush with clusters of red-purple berries, 0.9m, foragable feel, low-poly" | Foragable food source (design §10.4) | ★★★ |
| 8 | **Grass Tuft** | `ENV_GRASS` | "stylized grass tuft, 0.3m clump, low-poly" | Ground detail scatter | ★★☆ |
| 9 | **Mushroom Cluster** | `RESOURCE_FOOD` *(existing wrapper)* | "stylized mushroom cluster of 5 mushrooms, red spotted caps, on mossy dirt patch, low-poly" | Food resource node + wilderness ambience | ★★★ |
| 10 | **Ruins Pillar / Rubble** ➕ | `ENV_RUINS` | "stylized broken stone pillar or ruined wall segment, moss-covered, cracked, low-poly, ~1.5m tall" | Design §5.2 map contents. Kit-piece: one broken pillar + one rubble pile + one arch. | ★★☆ |
| 11 | **Bone Pile** ➕ | `ENV_BONE_PILE` | "stylized pile of animal bones and skulls, 0.6m, cartoon low-poly" | Wilderness dread; also visual for storage staging | ★★☆ |

---

## 7. Resource-node visuals (4 slots — already wired)

These are the "harvestable" prop the code spawns as a resource node. Currently they use kitbash — replace with your goblin-styled versions.

| # | Node | VisualCatalog slot | Meshy prompt hint | Priority |
|---:|---|---|---|---|
| 1 | **Wood stack / cut logs** | `RESOURCE_WOOD` | "stylized pile of 6 cut wooden logs stacked crossways, ~0.8m tall, low-poly" | ★★★ |
| 2 | **Stone pile** | `RESOURCE_STONE` | "stylized pile of raw quarried stone chunks, ~0.7m tall, gray with moss, low-poly" | ★★★ |
| 3 | **Gold nuggets** | `RESOURCE_GOLD` | "stylized cluster of gold nuggets sticking out of a rocky outcrop, glinting, low-poly" | ★★☆ |
| 4 | **Mushroom / food cluster** | `RESOURCE_FOOD` | (same as §6 #9 — one asset serves both slots) | ★★★ |

---

## 8. Settlement clutter & storage piles (2 slots + stretch)

These decorate the camp and (later) drive the "staged visual piles" from master design §10.3.

**MVP (existing slots):**

| Prop | Slot | Priority |
|---|---|---|
| Barrel | `ENV_BARREL` | ★★☆ |
| Wooden Crate | `ENV_CRATE` | ★★☆ |

**Stretch — staged storage piles ➕** (master design §10.3, not wired yet):

| Pile | Suggested slot | Purpose |
|---|---|---|
| Log stack | `PILE_WOOD` | Shows around Storehouse as wood stockpile grows |
| Rock heap | `PILE_STONE` | Same for stone |
| Bone heap | `PILE_BONES` | Around Burial Grounds |
| Scrap heap | `PILE_SCRAP` | Around Scrap Yard (post-MVP) |
| Meat rack | `PILE_MEAT` | Around Cook's Camp (post-MVP) |
| Mushroom baskets | `PILE_MUSHROOMS` | Around Mushroom Farm |
| Loot pile | `PILE_LOOT` | Around Warren after successful defense |
| Gold pile | `PILE_GOLD` | Small chest or open bag |

**Priority ★★☆** — great polish, not MVP-blocking.

---

## 9. Public demo — enemy camps (deferred)

Master design §5.2 / §30 lists Human, Dwarf, and Elf camps on the demo map. These are **public demo, not internal MVP**.

| # | Structure | Notes | Priority |
|---:|---|---|---|
| 1 | Human Hunter's Camp ➕ | Clean wood cabin, wagon, tent, small campfire, one flag | ★★☆ public demo |
| 2 | Dwarf Mining Post ➕ | Stone-hewn entry, ore carts, forge chimney, banner | ★☆☆ public demo |
| 3 | Elf Grove Marker ➕ | Pristine stone circle, sapling ring, ethereal look | ★☆☆ public demo |

Each is roughly one 3×3 "signature" prop cluster — not a full building set.

---

## 10. UI icons (nice-to-have)

The HUD currently uses either text or shared icons. Author one **48×48** flat icon per building + per resource for polish. Total: **11 building icons + 6 resource icons = 17**. Low priority; do these after 3D is landed.

---

## 11. Priority "core 20" if time is tight

If you can only ship 20 unique assets before the demo, do these — in this order:

1. Warren
2. Storehouse
3. Sleeping Pit
4. Mushroom Farm
5. Breeder Hut
6. Shrine
7. Guard Post
8. Watchtower
9. Burial Grounds
10. Forager Post
11. Goblin Worker (+ walk/attack animations)
12. Foblin (already animated via Twigskull — polish later)
13. Human Militia (+ walk/attack)
14. Human Scout (+ walk)
15. Beast — boar or wolf (+ walk/attack)
16. Oak Tree
17. Pine Tree
18. Large Rock
19. Berry Bush (harvestable) — replaces mushroom for variety
20. Construction Foundation

That gets the whole 7-day arc looking coherent. Everything after that is polish.

---

## 12. Placement plan — how many to put in the map

> **Obsolete sizing note:** This section was written for 20×20 / 48×48 hand-placed maps. The **runtime colony scene** now uses **350×350 procedural scatter** (`MapGenerator._scatter_props`). Use the counts below as **density inspiration**, not literal instance targets. Verify live counts with debug command `print_mapgen_status`.

The historical baseline was **20×20 tiles = 400 tiles**, with a recommendation to bump to **48×48 = 2304 tiles**. Neither matches the current procgen map.

### Zone layout (48×48 recommended)

```
   .......FFFFFFFFFFFFFFF..........
   ....FFFFFFFFFFFFFFFFFFF.........
   ...FFFFFFF...........FF..R.R....
   ..FFFF...................R.R....   Zone key
   ..FF........[STARTING].R.R.R....   S  = starting clearing (center-left, ~10×10)
   ..F..........[CAMP: S].R.R......   F  = forest (trees)
   .F...........[  ]......R........   R  = rocky outcrop (stones)
   .F...........[  ]..............   G  = gold seam (rock+gold cluster)
   .F.....................M.........   M  = mushroom patches
   .FF.......BBB..........MM........   B  = berry bushes
   ..FF.....BBBB...................   U  = ruins cluster
   ...FFF................UU........   H  = enemy human hunter's camp
   ....FFFF...............UU.H.H...      (public demo only)
   ......FFF............H.H.H......   .  = open grass
   ........FFFFFFF..FFFFFFF.........   (schematic — actual layout by designer)
   ..............FFFFF..............
```

### Instance counts

| Category | 20×20 map (current) | 48×48 map (recommended) | Notes |
|---|---:|---:|---|
| **Trees (oak + pine mixed)** | 30–45 | **90–140** | Denser at map edges (forest ring), sparser near camp |
| **Dead Trees / Stumps** | 4–6 | **10–15** | Cluster near ruins + burial |
| **Large Rocks** | 8–12 | **25–40** | Cluster into 2–3 "stone deposit" pockets |
| **Small Rock clusters** | 12–18 | **35–50** | Scatter filler |
| **Berry Bushes (harvestable)** | 6–10 | **15–25** | Cluster into 2–3 patches — foragable |
| **Decorative Bushes** | 10–15 | **30–45** | Ground filler |
| **Mushroom Clusters** | 4–6 | **10–15** | Cluster into 1–2 "patches" |
| **Grass Tufts** | 40–80 | **150–300** | Pure decoration, MultiMesh recommended |
| **Ruins pieces** | 3–5 | **8–12** | One "ruined tower" cluster |
| **Bone Piles** | 2–3 | **6–8** | Near burial + wilderness dread |
| **Terrain "mud" patches** | 4–6 patches | **10–15 patches** | Around building sites + high-traffic |
| **Terrain "rocky" patches** | 2–3 patches | **6–8 patches** | Under/around stone deposits |
| **Terrain "water"** | Optional pond | **1–2 ponds or 1 stream** | Visual only for MVP |
| **Enemy camps** (public demo) | 0 | **1 human + 1 dwarf + 1 elf** | Corners of the map |

### Starting placement (day 1 spawn)

| Object | Count | Location |
|---|---:|---|
| Warren | 1 | Center of the starting clearing |
| Goblin Workers | 6 | Around the Warren |
| Foblins | 0 | Spawned by Breeder Hut later |
| Nearby forest edge (trees) | ~15 trees within 8 tiles | For Day 1 wood gathering |
| Nearby stone (large rocks) | 3–5 within 10 tiles | For Day 1 stone |
| Berry bushes / mushrooms | 3–4 within 10 tiles | For Day 1 food |
| Gold nuggets | 1 cluster within 15 tiles | Deferred use |

### Placement principle

- **Random rotation + slight random scale (0.85–1.15) per instance** so a small mesh library reads as much bigger variety. Do this in code (or Godot editor) at spawn — don't author 20 tree meshes.
- **Cluster resources, don't sprinkle.** Real biomes clump. Player scouting a "gold seam" is more fun than gold randomly littering the map.
- **Buffer around the starting camp** (5–7 tiles clear) so day 1 building isn't blocked.

---

## 13. Filename & wrapper alignment

Author each `.glb` under a per-building or per-unit folder:

```
game/art/buildings/warren/goblin_warrens/warren.glb
game/art/buildings/warren/goblin_warrens/warren.glb.import
game/art/buildings/warren/goblin_warrens/warren_visual.tscn         ← wrapper you make
```

Then edit `scripts/art/visual_catalog.gd` to repoint the constant:

```gdscript
const BUILDING_WARREN := "res://game/art/buildings/warren/goblin_warrens/warren_visual.tscn"
```

**Keep the old placeholder wrapper on disk** until the new one is verified in-game. Do not delete Quaternius/KayKit paths yet — the fallback CSG greybox pipeline expects them if the new asset fails to load (`visual_attacher.gd`).

**Batch swap**: I can update `visual_catalog.gd` in one commit once your first pass of assets is on disk. Ping me with the folder paths and I'll rewire.

---

## 14. Deliverable summary — total count

If we do the full list:

| Category | Meshes to author |
|---|---:|
| MVP buildings + extras + foundation | **14** |
| MVP units | **5** |
| Public demo units | +5 |
| Terrain tiles | 5 (or 5 textures) |
| Nature props | **11** |
| Resource nodes | **4** (one overlaps with props) |
| Settlement clutter | 2 |
| Staged storage piles (stretch) | +8 |
| Enemy camps (public demo) | +3 |
| **Grand total** | **~55 unique assets** for full public demo |
| **MVP-only "core 20"** | **20** unique assets |

Ship the core 20 first. Everything past that is a polish sprint.

---

## 15. Non-3D assets to think about later

Out of scope for you right now, but flagging so we're aligned on total demo scope:

- **UI theme** — Godot Theme resource with goblin-tribal panel look
- **Icons** — 17 flat icons (see §10)
- **Sound design** — user acknowledged is the other AI-hard problem
- **VFX** — shrine glow, revival particle, blood hit, building-place dust, magic ritual swirl
- **Terrain shader** — grass/dirt/mud blend via vertex color or splat map

None of these block the art you're currently making.
