# Goblin Warrens — WC3-Inspired Economy Reference

## Purpose

This note translates useful Warcraft III economy patterns into Goblin Warrens without cloning Warcraft III directly.

Goblin Warrens is a slower colony / settlement-defense game, so WC3's economy shape is useful, but its exact punishments are too harsh for this prototype.

The goal is to use:

- Population pressure
- Housing investment
- Food/ration pressure
- Soft anti-snowball penalties
- Cheap expendable foblins
- More expensive proper goblins and elites

## WC3 → Goblin Warrens vocabulary

| Warcraft III | Goblin Warrens | Current prototype |
| --- | --- | --- |
| Gold | Gold / scrap | `GOLD` exists but is lightly used |
| Lumber | Wood | `WOOD` is primary build resource |
| Food cap | Housing / population cap | `get_housing_capacity()` |
| Upkeep | Rations / crowding pressure | `FOOD` upkeep every 8s |
| Farm / Burrow | Sleeping Pit / Warren upgrades | Sleeping Pit gives cap |
| Peasant | Goblin Worker | Generic starter goblins |
| Mass cheap unit | Foblin swarm | Breeder spawns foblins |
| Hero | Shaman / Champion | Not implemented yet |
| Upkeep tax | Gather/build slowdown | `PopulationBrackets` (implemented) |

## Current prototype economy

The prototype already has:

- Multi-resource stockpile: Gold, Wood, Stone, Food, Magic, Bones
- Housing cap from Warren and Sleeping Pits
- Food upkeep every 8 seconds
- Food loss condition after repeated failed upkeep ticks
- Breeder Hut spawning foblins until cap
- Mushroom Farm / Forager Post food support
- Building costs using mostly Wood and Stone

**Implemented (first pass, 2026-07-01):**

- Foblin zero-food upkeep (`FoodUpkeep.count_food_consumers`)
- Population bracket gather/build multiplier (`PopulationBrackets`)
- HUD crowding line on colony jobs label
- Unit tests: `test_food_upkeep.gd`, `test_population_brackets.gd`

**Not yet implemented:**

- Per-unit population costs
- Unit training costs
- Gold as a primary spend resource
- Warren upgrade economy (level field exists; upgrades not wired)
- Champion / Shaman economy

## Recommended population brackets

| Population | Penalty | Narrative |
| ---: | --- | --- |
| 0–30 | No penalty | Small camp, everyone productive |
| 31–50 | −10% gather/build speed | Crowded but manageable |
| 51–75 | −15% gather/build speed | Overstretched colony |
| 76+ | −25% gather/build speed unless Warren L3+ | Chaotic goblin sprawl |

Implementation: `scripts/world/population_brackets.gd` + `goblin.crowding_work_multiplier`.

## Code touchpoints

| Feature | File |
| --- | --- |
| Foblin zero-food upkeep | `scripts/world/food_upkeep.gd` |
| Population brackets | `scripts/world/population_brackets.gd` |
| Gather/build multiplier | `scripts/agents/goblin.gd`, `scripts/world/colony.gd` |
| HUD bracket indicator | `scripts/world/colony.gd` → `get_crowding_hud_line()` |
| Warren level (future) | `scripts/world/warren.gd` → `level` |

## Testing

```text
tests/unit/test_food_upkeep.gd
tests/unit/test_population_brackets.gd
```

## Design guardrail

Population growth should be powerful but messy. Foblins disposable and swarmy. Proper goblins more valuable. Large colonies require infrastructure. Food pressure scary but not unfair.
