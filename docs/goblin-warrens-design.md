# Goblin Warrens — Master Design and Cursor Guidance Document

## Purpose

This document is the current master design reference for **Goblin Warrens**.

It is meant to guide Cursor or another AI coding assistant while developing the Godot project. It defines the game's current direction, rules, systems, implementation priorities, MVP scope, and public demo target.

This document supersedes all older direction that described the game as "RTS-first" or suggested underground mechanics.

**Documentation hierarchy:** This file is **#1 — highest authority** for game design. Engineering rules live in `AGENTS.md`; technical overrides in `docs/architecture-reconciliation.md`. When design and engineering conflict, stop and ask — do not silently override design.

---

# 1. Final North Star

**Goblin Warrens** is a **3D above-ground goblin colony survival builder** with **siege-defense combat** and **light RTS controls**.

The player grows a weak goblin camp into a dangerous monster warren by managing food, shelter, breeding, labor, faith, magic, defenses, and goblin chaos while stronger enemies discover, scout, raid, and eventually assault the settlement.

RTS controls provide clarity, but the **warren — the above-ground goblin settlement — is the heart of the game.**

The game should feel like:

> **Farthest Frontier / Dawn of Man survival progression, but you are building a filthy goblin monster camp instead of a human village.**

Secondary inspirations:

* **Life Reset** for goblin clan growth, monster-side survival, dirty mechanics, crafting, escalation, and settlement pressure.
* **Warcraft III** for readable RTS camera, unit selection, right-click commands, and clear combat control.
* **RimWorld / Dwarf Fortress** lightly for memorable colonists and emergent stories, but not deep simulation complexity for MVP.

---

# 2. Hard Design Rules

These rules are non-negotiable unless the user explicitly reverses them later.

## 2.1 No Underground Mechanics

Do **not** implement underground gameplay mechanics.

Do not implement:

* tunnel digging
* underground rooms
* cave-layer navigation
* multi-layer maps
* subterranean base expansion
* mining tunnels
* burrow networks
* underground/surface transition mechanics
* hidden underground building placement
* Dwarf Fortress-style excavation
* RimWorld-style mountain digging
* Dungeon Keeper-style dungeon digging

The game is a **single above-ground map**.

Words like **Warren**, **Pit**, **Den**, or **Burial Grounds** are thematic only. They do not imply underground gameplay.

Examples:

| Name                      | Correct Interpretation                                   |
| ------------------------- | -------------------------------------------------------- |
| Warren                    | Main above-ground town center / goblin hub               |
| Breeder Hut / Breeder Den | Above-ground population/spawning building                |
| Sleeping Pit              | Above-ground housing/rest building with pit-like visuals |
| Burial Grounds            | Above-ground corpse/bone/revival building                |
| Ritualist Hut / Den       | Above-ground magic/ritual building                       |
| Mushroom Farm             | Above-ground food production building                    |
| Storage Hut               | Above-ground storage building                            |
| Guard Post                | Above-ground defensive post                              |
| Watchtower                | Above-ground tower                                       |

## 2.2 Colony Survival First, RTS Second

The game should no longer be treated as a pure RTS.

It still has RTS controls, selected units, right-click commands, combat, raids, enemy camps, and base building.

However, when RTS structure conflicts with colony survival, favor the colony survival fantasy.

The player is not primarily executing a competitive RTS build order.

The player is managing a growing goblin society.

## 2.3 Preserve Existing Working Features

The current proof-of-concept already includes goblins moving to resources, gathering resources, and returning resources to a resource hut.

Cursor must not destroy this working gather-return-store loop unless specifically instructed.

Refactor incrementally.

Do not rewrite the whole project unless explicitly asked.

---

# 3. Game Identity

## 3.1 Genre

Goblin Warrens is a:

* 3D colony survival builder
* above-ground goblin settlement simulator
* monster-side base-building strategy game
* siege-defense strategy game
* light RTS / colony hybrid
* single-player survival strategy game

## 3.2 Core Fantasy

The player starts with a pathetic goblin camp in the wilderness and grows it into a filthy, dangerous monster warren.

The player should feel like:

> "I am not building a heroic kingdom. I am growing the monster camp the civilized world wants to wipe out."

The goblins should feel:

* greedy
* cowardly
* hungry
* dirty
* superstitious
* chaotic
* weak alone
* dangerous in numbers
* funny
* occasionally heroic
* memorable

## 3.3 One-Sentence Pitch

Build and manage a chaotic goblin warren: keep your goblins fed, breeding, faithful, armed, and alive while heroes, beasts, rival factions, and civilized kingdoms try to wipe you out.

## 3.4 Short Pitch

**Goblin Warrens** is a colony survival builder where you grow a fragile goblin camp into a thriving monster settlement. Manage food, shelter, breeding, faith, magic, labor, defenses, and goblin morale while surviving raids, beasts, disease, divine demands, and enemy faction pressure. Your goblins are cowardly, greedy, chaotic, and weak alone — but with Foblins, guards, traps, rituals, watchtowers, walls, and rare champions, the warren can become terrifying.

---

# 4. Development Rules for Cursor

## 4.1 Engine

The active implementation is in **Godot**.

Cursor must use Godot-compatible architecture and terminology.

Default to **GDScript** unless the existing project clearly uses another language.

Do not use Unity architecture.

Treat this as a 3D Godot strategy project with:

* 3D navigation
* ground raycasting
* RTS camera
* drag-box unit selection
* selection indicators
* 3D building placement
* pathfinding
* command targeting
* building foundations
* worker tasks
* resource deposit behavior
* basic enemy AI
* UI panels

## 4.2 Cursor Work Style

Cursor should:

* inspect existing files before editing
* preserve working systems
* build modularly
* avoid giant scripts
* avoid hardcoded one-off logic
* make systems data-driven where practical
* make small safe changes
* provide test steps after meaningful changes
* avoid rewriting working systems without permission
* explain what files were changed
* explain known limitations

## 4.3 Suggested Folder Structure

Use clear organization such as:

```text
/scripts/units/
/scripts/workers/
/scripts/tasks/
/scripts/resources/
/scripts/buildings/
/scripts/combat/
/scripts/magic/
/scripts/enemies/
/scripts/managers/
/scripts/ui/
/scenes/units/
/scenes/buildings/
/scenes/resources/
/scenes/ui/
/data/
```

Avoid names like:

```text
new_script.gd
worker2.gd
final_test.gd
manager_backup.gd
```

## 4.4 Implementation Philosophy

Build in this order:

1. Stable worker gather-return-store loop.
2. Unit selection and right-click commands.
3. Building placement and construction.
4. Basic resources and storage.
5. Food and population pressure.
6. Breeder Hut and Foblins.
7. Basic combat.
8. Defensive raid system.
9. Shrine and prayer magic.
10. Burial and revival.
11. MVP demo loop.

Do not build advanced systems before the core loop is playable.

---

# 5. Map and Setting

## 5.1 Single Above-Ground Map

The game uses a **single above-ground playable map**.

The player builds and manages a goblin settlement on the surface.

The settlement should visually feel like a filthy monster camp made from:

* huts
* tents
* dens
* pits
* pens
* scrap piles
* bone piles
* shrines
* ritual circles
* crude towers
* wooden walls
* stone walls
* farms
* workshops
* burial grounds
* guard posts

Again: pits, dens, and warrens are visual/thematic. They are not underground mechanics.

## 5.2 Map Contents

The map should include:

* starting goblin clearing
* nearby forest
* food sources
* stone deposits
* gold or scrap deposits
* berry bushes
* mushroom patches
* animal dens
* ruins
* roads
* patrol routes
* human camps
* dwarf camps
* elf camps
* enemy raid paths
* resource-rich expansion areas

## 5.3 Core Map Tension

The goblin camp is exposed and vulnerable.

The player must expand outward for food, materials, and territory while preparing for enemies that scout, raid, and eventually assault the warren.

The core tension is:

> "The warren needs to grow, but every expansion makes it more visible and harder to defend."

---

# 6. Core Gameplay Loop

The main gameplay loop is:

1. Start with a small goblin camp and a Warren.
2. Gather food, wood, stone, gold/scrap, bones, and loot.
3. Build storage, sleeping, food, breeding, shrine, workshop, and defense structures.
4. Assign goblins to jobs.
5. Keep goblins fed, housed, faithful, rested, and safe.
6. Spawn or train more goblins.
7. Scout the map and discover threats/resources.
8. Prepare defenses using guard posts, towers, walls, traps, and militia.
9. Survive beasts, scouts, raids, disease, and divine demands.
10. Use magic for boons, revival, emergency food, blessings, and champion empowerment.
11. Recover, bury, rebuild, breed, and grow stronger.

The game should constantly ask:

> "Can my warren survive one more day?"

---

# 7. MVP and Demo Strategy

There are two development targets:

1. **Internal MVP**
2. **Public Demo**

They are related, but not identical.

---

## 7.1 Internal MVP

The internal MVP proves the core game loop.

It should be small, focused, and playable.

### MVP Goal

The player starts with a tiny goblin settlement and must survive long enough to repel the first serious raid.

Recommended objective:

> **Survive 7 days and repel the first human raid.**

### MVP Starting Conditions

The MVP can start with:

* 5 to 10 goblins
* one Warren
* small above-ground starting camp
* nearby resources
* no Foblins at match start
* no Hobgoblins
* no champions
* optional Shaman only if magic is ready

If Shaman/magic is not ready, delay the Shaman until later.

### MVP Buildings

The MVP should include:

* Warren
* Storage Hut
* Sleeping Pit
* Mushroom Farm
* Forager Post
* Breeder Hut
* Shrine
* Guard Post
* Watchtower
* Workshop
* Burial Grounds

Optional if easy:

* Cook's Camp / Cooking Hut
* Wooden Wall
* Basic Trap

### MVP Resources

Use only:

* Food
* Wood
* Stone
* Gold or Scrap
* Bones
* Magic
* Goblins

Do not add too many resources early.

### MVP Jobs

Use simple jobs:

* Gather
* Haul
* Build
* Farm
* Forage
* Pray
* Guard
* Craft
* Breed
* Bury

### MVP Threats

Use a small set of threats:

* hunger
* surface beast
* sickness or injury
* human scout
* final human raid

### MVP Magic

Magic should have only a few uses at first:

* Revive Goblin
* Bless Defender
* Mushroom Bloom
* Fear Totem

### MVP Win Condition

The player wins if they:

* survive 7 days
* keep the Warren alive
* build a Shrine
* build basic defenses
* repel the first human raid

### MVP Loss Conditions

The player loses if:

* all goblins die
* the Warren is destroyed
* food collapse causes the settlement to fail
* morale collapse causes goblins to abandon the warren

---

## 7.2 Public Demo

The public demo can be more sandbox-like.

There does not need to be a formal victory condition for the first public demo.

The player should be able to:

1. Start with 10 Goblins.
2. Start with one Warren.
3. Start with one unique Goblin Shaman hero near the Warren.
4. Gather wood, stone, gold/scrap, and food.
5. Build the first settlement structures.
6. Train basic workers and warriors.
7. Spawn Foblins passively from Breeder Huts.
8. Scout the map.
9. Encounter Humans, Dwarves, and Elves.
10. Defend from raids.
11. Build toward magic and shaman systems.
12. Use burial/revival.
13. Optionally destroy all enemy camps.

Optional secondary victory:

> Destroy all hostile enemy camps on the map.

The public demo should demonstrate the core loop even without a formal win screen.

---

# 8. Demo Emotional Target

By the end of the MVP or public demo, the player should remember specific goblins.

The player should say things like:

* "Mog held the gate."
* "Snik-Snik saved us with a ritual."
* "Grubba died but I revived him."
* "The Breeder Hut almost got destroyed."
* "I need more traps next time."
* "I overbred and almost starved."
* "The Foblins died first, but they bought enough time."

This is how we know the game is working.

---

# 9. Camera and Controls

## 9.1 Camera

The game uses a 3D RTS camera.

Expected behavior:

* pan
* zoom
* optional rotation later
* mouse edge scrolling
* keyboard scrolling
* tactical angled view
* terrain/ground raycasting

## 9.2 Unit Selection

Classic RTS selection rules:

* Left-click selects a unit or building.
* Drag-select selects multiple units.
* Shift-click adds/removes units from selection.
* Selected units show selection indicators.
* Buildings show command panels when selected.
* Units show command panels when selected.

## 9.3 Right-Click Commands

Right-click behavior depends on target:

* Right-click ground = move.
* Right-click resource node = harvest/work.
* Right-click enemy = attack.
* Right-click unfinished building/foundation = construct.
* Right-click allied valid target = interact/deposit/repair if supported.

Right-click ground is always pure movement.

Attack-move requires a separate command or hotkey.

## 9.4 Attack-Move

Attack-move is available to:

* Foblins
* Goblin Warriors
* Hobgoblins
* Champions
* Goblin Workers only while in militia mode

Normal workers should not behave like soldiers unless drafted or directly threatened.

---

# 10. Resources and Economy

## 10.1 Core Resources

Confirmed resources:

* Wood
* Stone
* Food
* Bones
* Magic Power
* Goblins

Likely resources:

* Gold
* Scrap
* Loot

The magic/prayer resource final name is not locked.

Possible names:

* Magic Power
* Dark Devotion
* Prayer
* Faith
* Deity Favor

## 10.2 Resource Uses

Wood, stone, gold, and scrap are used for:

* buildings
* upgrades
* tools
* weapons
* defenses
* traps
* tech

Food is used for:

* feeding the settlement
* supporting population
* training certain units
* breeding/goblin growth

Bones are used for:

* burial
* rituals
* revival
* bone crafting
* traps
* death magic

Magic Power is used for:

* rituals
* deity boons
* champion upgrades
* revival
* fertility rites
* defensive wards
* emergency spells
* legendary summon progress later

Loot is used for:

* goblin morale
* status
* upgrades
* tribute
* shaman/deity offerings

## 10.3 Storage Model

Storage is hybrid.

Resources become abstract usable totals when deposited, but storage buildings should visually show growing piles.

Do not simulate every individual log, stone, bone, or coin.

Use staged visual piles:

* logs
* rocks
* crates
* barrels
* bone heaps
* scrap heaps
* meat racks
* mushroom baskets
* loot piles

## 10.4 Resource Nodes

Resources are gathered from above-ground nodes or visible map objects.

Examples:

* trees
* stone piles
* gold deposits
* scrap piles
* berry bushes
* mushroom patches
* animal carcasses
* bone piles
* ruins
* enemy camp loot

Resource nodes are not capture points.

Enemies may contest, camp, raid, or patrol around resources, but the resource node itself should not be destroyed.

Do not implement mining tunnels or underground extraction.

If mining is added later, it should be represented as a normal above-ground node or building interaction.

---

# 11. Food System

Food can be:

* gathered
* hunted
* farmed
* grown through Mushroom Farms
* produced through Pig Farms later
* created magically through Mushroom Bloom

For the MVP, food should be simple but meaningful.

Food should matter enough that overpopulation is dangerous.

MVP food rule:

* Food is required to support the goblin population.
* Food is consumed periodically or checked through a simple upkeep tick.
* Starvation causes morale loss, work slowdown, injury, desertion, or death.
* Do not build a deep spoilage simulation yet.

Later food systems may include:

* raw food
* cooked food
* spoilage
* food quality
* meat
* mushrooms
* pig farming
* emergency food rules

---

# 12. Buildings

## 12.1 Full Building List

The full design may include:

* Warren
* Storage Hut
* Sleeping Pit
* Breeder Hut
* Goblin Barracks
* Shrine
* Ritualist Hut / Ritualist Den / Ritualist Warren
* Watchtower
* Guard Post
* Wooden Wall
* Stone Wall
* Hunter's Hut
* Pig Farm
* Burial Grounds
* Totem Tower
* Workshop
* Cook's Camp / Cooking Hut
* Worker's Hut
* Mushroom Farm
* Forager Post
* Trap Workshop
* Scrap Yard
* Sick Pit / Shaman Hut
* Loot Pile
* Raid Camp

All buildings are above-ground structures.

## 12.2 Building Roles

| Building        | Purpose                                        |
| --------------- | ---------------------------------------------- |
| Warren          | Central hub, colony heart, population anchor   |
| Storage Hut     | Stores basic resources                         |
| Sleeping Pit    | Housing and rest                               |
| Breeder Hut     | Foblin spawning / population growth            |
| Goblin Barracks | Trains warriors, supports militia organization |
| Shrine          | Prayer, magic generation, deity favor          |
| Ritualist Hut   | Expensive rituals, revival, champion upgrades  |
| Watchtower      | Detection and ranged defense                   |
| Guard Post      | Patrol zone and defensive rally area           |
| Wooden Wall     | Early blocker / delay structure                |
| Stone Wall      | Stronger blocker / late defense                |
| Hunter's Hut    | Hunting and animal food source                 |
| Pig Farm        | Food production                                |
| Burial Grounds  | Corpse handling, bones, revival, death magic   |
| Totem Tower     | Advanced magic defense / morale / fear         |
| Workshop        | Tools, weapons, traps, crafting                |
| Cook's Camp     | Food processing                                |
| Worker's Hut    | Worker production or labor organization        |
| Mushroom Farm   | Reliable food production                       |
| Forager Post    | Gathering-zone support                         |
| Trap Workshop   | Builds traps                                   |
| Scrap Yard      | Processes scrap into usable material           |
| Sick Pit        | Healing and disease control                    |
| Loot Pile       | Goblin morale and status                       |
| Raid Camp       | Automated scavenging/raiding missions          |

## 12.3 Building Placement

Core buildings should use structured RTS-style placement.

Building placement should support:

* ghost preview
* valid/invalid placement feedback
* terrain blocking
* pathing blockers
* resource cost preview
* construction foundation
* worker construction task
* completed building activation

Recommended model:

* Core buildings use hidden grid/footprint logic.
* Visuals can still look crooked, dirty, and goblin-made.
* Important buildings must remain readable for pathing and RTS control.

Flexible placement can be used for:

* wooden walls
* stone walls
* traps
* decorations
* props
* corpse piles
* barricades
* settlement clutter

## 12.4 Construction

Buildings require workers to construct.

Multiple workers increase construction speed.

Foblins can help build, but poorly.

Goblin Workers build better.

Workers must physically go to the foundation and construct it.

The Shaman's Dark Chant can increase construction speed later.

---

# 13. Warren Progression

The Warren is the heart of the settlement.

Population cap, tech access, champion slots, and major progression are tied to Warren upgrades.

## 13.1 Warren Level 1 — Rat-Hole Camp

Available:

* Warren
* Goblin Worker training from Warren
* Storage Hut
* Sleeping Pit
* Forager Post
* basic gathering
* basic building
* basic food collection

Purpose:

* survive the first days
* gather resources
* avoid starvation
* create basic shelter

## 13.2 Warren Level 2 — Hidden Warren

Unlocks:

* Breeder Hut
* Mushroom Farm
* Cook's Camp
* basic walls
* Guard Post
* early defense
* Foblin spawning

Purpose:

* stabilize food
* grow population
* prepare for first attacks

## 13.3 Warren Level 3 — Sacred Warren

Unlocks:

* Shrine
* Ritualist Hut
* Burial Grounds
* early magic economy
* Shaman revival if Shaman exists
* basic rituals
* first deity boons
* Watchtower

Purpose:

* add faith/magic layer
* introduce death/revival
* prepare for larger raids

## 13.4 Warren Level 4 — War Warren

Unlocks:

* Workshop
* improved Barracks
* traps
* Totem Tower
* Stone Walls
* advanced resources
* Hobgoblins
* champion upgrades
* late demo threats

Purpose:

* organized defense
* stronger units
* advanced goblin society
* major raid survival

There is no Warren Level 5 planned for now.

---

# 14. Population and Upkeep

## 14.1 Population Cap

Population cap comes from:

* Warren level
* Sleeping Pits
* Breeder Huts
* housing structures
* certain upgrades

Different unit types have different population costs.

Working assumptions:

* Foblin = 1 population
* Goblin Worker = more than Foblin
* Goblin Warrior = more than Foblin
* Hobgoblin = significantly more
* Shaman = unique hero
* Champions = Champion Slot system, not normal population
* Legendary summon = no population/cap cost

Exact numbers are balance values.

## 14.2 Death Frees Population

When a normal population unit dies, it no longer counts against population cap.

Champions use separate rules.

## 14.3 Upkeep

Foblins do not require food upkeep.

Proper Goblins and higher-tier units may require:

* food
* gold/scrap
* special resources depending on tier

If upkeep cannot be paid:

1. Player receives a grace period.
2. Units do not vanish instantly.
3. Units gradually abandon the leader, starve, or become inactive.
4. Abandoning units disappear into fog of war.
5. Units abandon faster the farther they are from the Warren.

No instant mass desertion.

---

# 15. Unit Categories

## 15.1 Foblins

Foblins are expendable trash goblins.

They are meant to:

* absorb attacks
* meet the enemy vanguard
* die first
* swarm
* scout
* gather poorly
* build poorly
* be sacrificed
* buy time for proper Goblins and Hobgoblins

Foblins are not chaotic or disobedient.

Their weakness comes from bad stats, not bad controls.

Working output ratio:

> 1 Goblin Worker ≈ 2 Foblins in labor output

Foblins:

* count against population cap
* do not require food upkeep
* can be directly controlled
* can gather poorly
* can build poorly
* can fight
* can use combat stances
* can use attack-move
* can be sacrificed
* cannot pray
* cannot receive Shrine boons
* cannot be manually trained
* spawn passively from Breeder Huts

Foblins fight until death unless the player commands otherwise.

They do not auto-flee at low health.

## 15.2 Proper Goblins

Proper Goblins are full-fledged units.

They are more valuable than Foblins.

Goblin types may include:

* Goblin Worker
* Goblin Warrior
* Goblin Hunter / Slinger
* Goblin Builder if separated later
* Goblin Crafter
* Goblin Guard

Proper Goblins may require food/gold upkeep.

Proper Goblins are trained from buildings or assigned from population depending on final implementation.

## 15.3 Hobgoblins

Hobgoblins are the smarter, stronger, more advanced goblin variant.

They are:

* more intelligent
* more lethal
* more valuable
* more painful to lose
* more industrial/magical in theme
* able to use some magic outside the Shaman class

Hobgoblins are trained separately.

They are not evolved from normal Goblins.

Hobgoblins do not rout under normal morale pressure.

They may still be affected by special magical fear, panic, mind control, stun, or scripted effects later.

## 15.4 Goblin Shaman

The Goblin Shaman is a single unique hero unit.

The Shaman starts near the Warren at the beginning of the public demo.

For the internal MVP, the Shaman is optional until magic is ready.

There is only one main Goblin Shaman hero.

The Shaman:

* chooses the deity/magic path
* casts universal spells
* unlocks path spells through progression
* can fight, but is fragile
* uses a short-range magic attack
* transforms into the legendary summon later
* must be revived at the Ritualist Hut if killed

The Shaman does not gain XP.

The Shaman does not level from combat, rituals, or spell use.

Abilities unlock through:

* Warren progression
* ritual tech
* buildings
* chosen magic path
* upgrades

---

# 16. Goblin Colonist System

Even with RTS controls, goblins should feel like colonists.

Each proper goblin should eventually have:

* name
* role/job
* hunger
* rest
* health
* morale
* faith
* cowardice/bravery
* combat skill
* traits or quirks

Possible traits:

* Cowardly
* Greedy
* Lazy
* Sturdy
* Faithful
* Brawler
* Sneaky
* Glutton
* Lucky
* Scarred
* Deity-touched

Do not build full RimWorld-level simulation for MVP.

The goal is to make goblins memorable, not to simulate every thought.

---

# 17. Unit Production

## 17.1 Goblin Workers

Goblin Workers use a mixed model.

Early game:

* trained from the Warren

Later economy:

* Worker's Hut becomes the dedicated worker-production/economy building

This prevents soft-locking if all workers are lost.

## 17.2 Goblin Warriors

Goblin Warriors require the Goblin Barracks.

The Warren does not train combat units.

Before Barracks, early defense comes from:

* Foblins
* Workers in militia mode
* walls
* traps
* Guard Posts
* retreating
* positioning

## 17.3 Foblins

Foblins are not manually trained.

They spawn passively from Breeder Huts.

## 17.4 Shamans

The unique Shaman exists at public demo match start.

Shaman revival uses Ritualist Hut.

Additional full Shaman heroes are not planned.

## 17.5 Hobgoblins

Hobgoblins are trained separately.

They likely require:

* Warren Level 4
* advanced buildings
* special resources
* advanced resource unlocks

Exact production structure is not fully locked.

---

# 18. Breeder Hut and Foblin Spawning

Breeder Huts passively spawn Foblins.

Rules:

* no food cost
* no gold cost
* spawn only if global population cap allows
* only global population cap limits Foblin count
* multiple Breeder Huts increase spawn rate
* each Breeder Hut spawns Foblins at its own physical location
* each Breeder Hut can have its own rally point
* if no rally point is set, Foblins idle near the hut

Future upgrade layer:

* filth
* corpses
* waste
* dark goblin resources
* fertility rites
* shrine blessing

These may later increase Foblin spawn speed, quality, or variants.

The Breeder Hut should be a critical strategic asset.

If damaged or destroyed:

* Foblin spawning stops
* population growth slows
* morale may drop
* enemies may target it during raids

---

# 19. Worker System

## 19.1 Hybrid Worker Control

Workers can be controlled directly like RTS units.

After a work command, they may automate continuation.

Example:

The player selects Goblin Workers or Foblins and right-clicks a tree. They harvest that tree, return wood, and continue harvesting nearby valid trees until the local area is depleted or they receive a new command.

## 19.2 Work Zones

The player can place scalable work-zone flags.

A work zone defines an area where assigned workers automatically perform a labor type.

Work zones should support:

* resizing
* worker slot limits
* manual worker assignment
* automatic worker assignment
* priority setting
* depletion detection
* continuation to nearest valid resource node

If the player adds an automatic worker slot, the game should assign an idle available worker not already busy.

## 19.3 Idle Behavior

A unit becomes idle after finishing a task unless:

* it is assigned to a work zone
* it has auto-work enabled
* it has a queued command
* it is continuing a local gathering chain from a direct command
* it is resuming a remembered interrupted task

## 19.4 Task Priority

Tasks should have priority numbers.

The long-term goal is player-controlled task priority.

Cursor should not hardcode all tasks as equal.

---

# 20. Goblin Worker Militia Mode

Goblin Workers can enter militia mode.

Militia mode is a manual toggle.

Rules:

* Workers stay in militia mode until the player turns it off.
* Militia workers are removed from the labor pool.
* They cannot gather, build, repair, pray, or do normal labor.
* They are treated as weak combat units.
* They can attack and attack-move.
* They fight worse than Goblin Warriors.
* They can resume valid previous tasks after returning to worker mode.

Normal Goblin Workers do not fight by default.

If attacked while not in militia mode:

* they stop work
* run toward nearest defensive building or Warren
* resume work if safe and task remains valid

---

# 21. Foblin Auto-Defense

Foblins automatically respond when player buildings are attacked.

Rules:

* applies only to Foblins
* only triggers on attacks against player-owned buildings
* does not trigger for every wilderness skirmish
* if multiple buildings are attacked, Foblins split between threat locations
* they fight until all nearby attackers are dead
* surviving Foblins return to previous assignment if still valid
* if previous task is invalid, they become idle or follow normal reassignment
* direct player commands override auto-defense

Goblin Warriors do not auto-respond globally.

Workers do not auto-respond globally unless directly threatened or manually drafted.

---

# 22. Combat

## 22.1 Combat Philosophy

Combat should be defensive, messy, and preparation-based.

The ideal combat loop is:

> Warning → preparation → attack → chaos → survival → recovery.

The player should win by:

* building defenses
* assigning guards
* using traps
* spending magic wisely
* rallying goblins
* protecting key buildings
* using Foblins as disposable bodies
* preserving proper Goblins
* relying on champions later

## 22.2 Combat Stances

Foblins, Goblin Warriors, Hobgoblins, and likely champions use a stance system.

### Aggressive

* pursues nearby enemies
* chases farther
* useful for attacks

### Defensive

* attacks nearby enemies
* does not chase too far
* useful for guarding areas

### Hold Position

* stays in place
* only attacks enemies in range
* useful for walls, choke points, and towers

Foblins use the same stance system as Goblin Warriors.

Their weakness comes from stats, not lack of control.

## 22.3 Morale and Routing

Foblins:

* do not flee automatically
* fight until death unless commanded otherwise

Goblin Workers:

* flee when attacked unless in militia mode

Goblin Warriors:

* may eventually rout or hold based on morale systems

Possible morale factors:

* nearby Shaman
* nearby Champion
* nearby Hobgoblin
* Guard Post
* Shrine aura
* Totem Tower
* stance
* magic buffs
* enemy fear effects
* battle conditions

Hobgoblins:

* do not rout under normal morale pressure
* may still be affected by special magic or scripted panic effects

Morale is a future combat layer.

## 22.4 Rally Bell

A Rally Bell or alarm command should eventually exist.

When used:

* available guards move to defensive positions
* Foblins may gather near the threatened area
* workers may flee or enter militia if toggled
* towers and guard posts become priority defense points

---

# 23. Walls and Defenses

Walls are Warcraft-style blockers.

They buy time but are not the main defense.

Wall types:

* Wooden Wall
* Stone Wall

Other defenses:

* Guard Post
* Watchtower
* Totem Tower
* traps
* barricades
* choke points
* gates later

Walls should:

* block enemy movement
* be attackable
* delay raids
* guide enemies into traps
* protect key buildings

Walls should not make the warren invincible.

---

# 24. Traps and Dirty Engineering

Traps are core to goblin identity.

Possible traps:

* spike trap
* pit trap
* snare trap
* swinging log trap
* bone spike trap
* stink bomb trap
* poison dart trap
* alarm trap

Important note:

A "pit trap" is an above-ground trap object. It is not an underground mechanic.

MVP should include only one or two simple traps.

Later, traps can be crafted from:

* wood
* stone
* bones
* scrap
* poison
* magic

Traps should help weak goblins defeat stronger enemies.

---

# 25. Shrine, Magic, and Deity Boons

## 25.1 Magic Generation

Magic is generated safely and steadily by prayer at the Shrine.

Only proper Goblins can pray.

Foblins cannot pray.

Magic can also come from:

* Burial Grounds
* sacrifices
* divine events
* relics
* rituals
* death magic

## 25.2 Deity Boons

Occasionally, the deity may grant a boon to a praying goblin.

Possible boons:

* unique weapon
* unique armor
* aura
* blessing
* mutation
* combat trait
* defensive power
* strange curse with upside

Boons should be rare and memorable.

A random goblin receiving a boon can become the seed of a champion.

## 25.3 Magic Spending

Magic can be spent on:

* revival
* champion upgrades
* defensive wards
* mushroom bloom
* fertility rites
* fear aura
* curse invaders
* deity requests
* legendary summon progress later

Magic should be powerful but costly.

The player should face hard choices like:

> "Do I revive my dead champion, bless the Breeder Hut, or save magic for the next raid?"

---

# 26. Ritualist Hut

The Ritualist Hut / Ritualist Warren is where expensive magical decisions happen.

Uses:

* Shaman revival
* champion upgrade
* goblin resurrection
* fertility rite
* special rituals
* mutations
* dark upgrades
* legendary summon progress

The Ritualist Hut should not be an early spam building.

It should feel important, dangerous, and expensive.

---

# 27. Burial Grounds

The Burial Grounds are a core identity building.

It is an above-ground building/area.

Uses:

* corpse handling
* bone generation
* death magic
* revival
* champion memory
* morale/faith effects

Dead goblins should matter.

If a goblin dies and is recovered:

* body can be buried
* bones can be harvested
* magic can revive them
* champion memories can be preserved later

If corpses are left unmanaged:

* morale drops
* disease risk rises
* predators may appear
* undead events may occur later

Revival should cost magic and possibly bones.

---

# 28. Champion System

Champions are rare, powerful named goblins.

They are significantly stronger than normal units.

A champion's main ability is their presence on the battlefield.

Champions:

* do more damage
* survive longer
* inspire nearby goblins
* reduce routing
* may carry deity boons
* may have unique weapons or armor
* may have auras
* may be revived at high cost
* use Champion Slots instead of normal population

Champions can emerge from:

* surviving battles
* deity boons
* Ritualist Hut upgrade
* rare birth/mutation
* revival after heroic death
* killing a powerful enemy

Champion examples:

* Fear Aura Champion
* Rage Champion
* Poison Blade Champion
* Shield Champion
* Beast Rider Champion
* Blessed Armor Champion
* Undead Survivor Champion
* Firestarter Champion
* Goblin Idol

Champions should be memorable and painful to lose.

---

# 29. Enemies and Threat Escalation

## 29.1 Enemy Factions

Enemy factions may include:

* Humans
* Dwarves
* Elves
* rival goblins
* beasts
* adventurers
* hero parties

For the public demo, include:

* Humans
* Dwarves
* Elves

For MVP, include only:

* beasts
* human scout
* human raid

## 29.2 Threat Progression

Early threats:

* hunger
* rats
* wolves
* sickness
* minor scouts

Mid-game threats:

* hunters
* adventurers
* militia raids
* dwarven patrols
* shrine desecration
* breeder hut attacks
* rival goblin raids

Late-game threats:

* hero parties
* organized sieges
* monster rebellion
* divine demands
* faction purge
* coalition assault

## 29.3 Raid Warnings

Major attacks should be telegraphed.

Examples:

* "Human scouts found goblin tracks."
* "A hunter escaped and will warn the village."
* "Dwarves have marked your camp for cleansing."
* "An adventurer party has accepted a goblin-clearing contract."
* "The elves have marked the forest as corrupted."

Warnings create preparation gameplay.

---

# 30. Enemy Camps and Map Control

Enemy camps can exist on the map.

Possible camps:

* human hunting camp
* dwarf mining post
* elf grove
* adventurer camp
* militia outpost

Enemy camps should:

* spawn patrols
* send raids
* grow stronger over time
* react to player threat
* be optional targets in public demo

The player may destroy all hostile camps as an optional sandbox victory.

The game should not require constant enemy base assault in MVP.

---

# 31. Monster Recruitment

Monster recruitment is a later system, not MVP-critical.

Possible recruitable monsters:

* rats
* wolves
* wargs
* spiders
* trolls
* ogres
* hobgoblins
* undead goblins
* bone golems
* scrap golems

Each monster should create a colony problem, not just a combat upgrade.

Examples:

* Trolls eat huge amounts of food.
* Spiders scare goblins.
* Undead hurt morale.
* Ogres need special housing.
* Golems require rare resources.

---

# 32. Dirty Crafting

Goblin crafting should feel improvised and ugly.

Crafting categories:

* crude weapons
* scrap weapons
* bone armor
* stolen gear
* traps
* poison
* stink bombs
* ritual masks
* cursed blades
* totems
* golems
* champion relics

MVP should include only:

* basic tool/weapon crafting
* maybe one trap
* maybe one magic item later

---

# 33. Life Reset-Inspired Mechanics to Adapt

Do not copy story, names, characters, factions, terminology, or lore.

Do adapt the underlying gameplay ideas:

* weak monster start
* monster-side perspective
* settlement growth
* clan identity
* dirty survival
* goblin breeding/population growth
* threat countdowns
* stronger enemies coming
* crafting and magical crafting
* monster recruitment
* named elite units
* burial/revival
* clan reputation/status
* leader/shaman magic
* settlement-to-war-camp progression

Do not include:

* VRMMO framing
* trapped player premise
* AI/higher-being story elements
* exact character arcs
* exact clan names
* exact locations
* exact plot events

The Goblin Warrens version is:

> A weak goblin colony begins in a filthy camp in hostile lands. The player grows the warren through scavenging, breeding, crafting, worship, traps, and dirty tactics. Every goblin is a fragile colonist with a job, hunger, faith, fear, and possible future. As the warren expands, civilized factions notice and escalate from hunters to heroes to full sieges.

---

# 34. UI Requirements

MVP UI should show:

* selected unit/building info
* current resources
* population cap
* food status
* current day/time
* alerts
* selected unit command buttons
* building construction menu
* worker idle count
* raid warning messages

Later UI:

* work zone panel
* job priority panel
* magic/ritual panel
* goblin details panel
* burial grounds panel
* champion panel
* enemy threat meter
* warren upgrade panel

---

# 35. MVP Day-by-Day Target

## Day 1 — Filthy Beginnings

Player learns:

* select goblins
* gather resources
* deposit resources
* build Storage Hut
* build Sleeping Pit

Threat:

* hunger

## Day 2 — The Camp Breathes

Player learns:

* Forager Post
* Mushroom Farm
* basic job assignment

Threat:

* surface beast or food shortage

## Day 3 — More Goblins

Player learns:

* Breeder Hut
* population growth / Foblin spawning
* housing pressure

Threat:

* food demand increases

## Day 4 — Faith in the Mud

Player learns:

* Shrine
* prayer
* magic generation

Threat:

* divine demand or minor sickness

## Day 5 — Bones Remember

Player learns:

* Burial Grounds
* dead goblin handling
* revival

Threat:

* wolf attack or sickness

## Day 6 — They Found Us

Player learns:

* Guard Post
* Watchtower
* basic trap or wall
* raid warning

Threat:

* human scout

## Day 7 — First Raid

Player learns:

* rally defense
* defensive combat
* magic spending
* recovery after battle

Threat:

* human militia raid

End screen should show:

* surviving goblins
* dead goblins
* revived goblins
* buildings built
* food remaining
* enemies killed
* warren status

---

# 36. What Not to Build Yet

For MVP, do not build:

* multiplayer
* full RTS campaign
* large tech tree
* ten enemy factions
* diplomacy
* complex trade
* complex food spoilage
* full morale simulation
* huge world map
* deep individual psychology
* advanced enemy AI
* underground mechanics
* tunnels
* cave layers
* digging systems
* legendary summon
* full champion roster
* full monster recruitment
* full coalition war

The MVP must prove:

> Managing goblins is fun, dangerous, funny, and emotionally memorable.

---

# 37. Implementation Milestones

## Milestone 1 — Stable Worker Loop

Goal:

* goblins gather resources
* goblins return resources to storage
* resource totals increase
* multiple goblins can work without breaking

Must preserve existing gather-return-store behavior.

## Milestone 2 — Selection and Commands

Goal:

* left-click selection
* drag selection
* right-click move
* right-click resource harvest
* right-click deposit/construct behavior where valid

## Milestone 3 — Building Placement

Goal:

* ghost preview
* cost check
* valid/invalid placement
* foundation appears
* worker constructs
* completed building activates

## Milestone 4 — Food and Population

Goal:

* food resource matters
* population cap exists
* goblins consume or require food
* starvation or shortage consequences exist
* Sleeping Pit or Warren affects cap

## Milestone 5 — Breeder Hut and Foblins

Goal:

* Breeder Hut spawns Foblins over time
* Foblins count against cap
* Foblins gather/build poorly
* Foblins fight
* Foblins auto-defend buildings

## Milestone 6 — Basic Combat

Goal:

* enemies can attack
* goblins can attack
* health/damage/death works
* workers flee unless militia
* Foblins fight to death
* basic stance system if possible

## Milestone 7 — Raid System

Goal:

* human scout appears
* warning triggers
* raid spawns later
* raid targets Warren or key buildings
* player can defend

## Milestone 8 — Shrine and Magic

Goal:

* Shrine can be built
* goblins can pray
* magic resource increases
* one or two rituals exist

## Milestone 9 — Burial and Revival

Goal:

* dead goblins create corpse/death record
* Burial Grounds can process corpse
* player can spend magic to revive one goblin

## Milestone 10 — MVP Demo Loop

Goal:

* 7-day playable arc
* first raid
* win/loss condition
* end summary
* stable enough to show externally

---

# 38. Cursor Acceptance Criteria

When Cursor implements a system, it should provide:

1. What files were changed.
2. What was added.
3. What existing behavior was preserved.
4. How to test it in Godot.
5. Known limitations.
6. Next suggested step.

Cursor should not silently change design direction.

Cursor should not convert the game back into a pure RTS.

Cursor should not remove colony-survival systems to simplify combat.

Cursor should not destroy the working worker/resource loop.

Cursor should not implement underground mechanics.

---

# 39. Glossary

## Warren

The above-ground goblin settlement and central hub.

Not an underground tunnel system.

## Foblin

A weak expendable goblin-like unit spawned passively from Breeder Huts.

Useful for swarming, scouting, dying first, poor labor, and auto-defense.

## Proper Goblin

A full goblin unit with better labor/combat potential than a Foblin.

Proper Goblins can eventually have names, roles, morale, faith, and traits.

## Hobgoblin

Advanced goblin variant. Stronger, smarter, more expensive, and later-game.

## Shaman

Unique hero unit tied to deity path, magic, rituals, and eventual legendary summon.

## Champion

Rare elite named goblin. Strong battlefield presence. Uses Champion Slots.

## Shrine

Prayer building that generates steady magic.

## Ritualist Hut

Expensive ritual building for revival, champion upgrades, mutations, and major magic.

## Burial Grounds

Above-ground corpse, bone, death magic, and revival structure.

## Breeder Hut

Population/Foblin spawning structure.

Not an underground mechanic.

---

# 40. Final Guiding Statement

**Goblin Warrens is a colony survival builder where the player grows a weak above-ground goblin camp into a dangerous monster warren. The player manages food, shelter, breeding, labor, faith, magic, defenses, and goblin chaos while stronger enemies discover and attack the settlement. Combat is defensive and preparation-based, using Foblins, guards, traps, watchtowers, walls, rituals, and rare champions to survive. RTS controls provide clarity, but the warren — the above-ground goblin settlement — is the heart of the game. No underground, tunnel, cave-layer, or digging mechanics should be implemented.**
