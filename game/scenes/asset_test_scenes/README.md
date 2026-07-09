# Asset test / review scenes

Scratch scenes for evaluating third-party art **before** promoting into `scenes/colony.tscn` or gameplay prefabs.

**Rules:** [`docs/itch-io-acquisition.md`](../../../docs/itch-io-acquisition.md) · [`docs/quaternius-acquisition.md`](../../../docs/quaternius-acquisition.md)

## Generic review scenes

| File | Drop test assets under |
|------|------------------------|
| `goblin_asset_review.tscn` | `ReviewRoot` |
| `resource_asset_review.tscn` | `ReviewRoot` |
| `nature_asset_review.tscn` | `ReviewRoot` |
| `building_asset_review.tscn` | `ReviewRoot` |
| `burial_grounds_asset_review.tscn` | `ReviewRoot` |
| `terrain_texture_review.tscn` | Built-in 7-class strips; keys 1/2/3 for zoom presets |
| `ui_theme_review.tscn` | `ReviewRoot` (Control) |
| `animation_review.tscn` | `ReviewRoot` |

## Quaternius review scenes

| File | Purpose |
|------|---------|
| `quaternius_nature_review.tscn` | Stylized Nature MegaKit |
| `quaternius_buildings_review.tscn` | Medieval Village, Ultimate Fantasy RTS |
| `quaternius_props_review.tscn` | Fantasy Props MegaKit |
| `quaternius_weapons_review.tscn` | Modular Weapons Pack |
| `quaternius_monsters_review.tscn` | Ultimate Monsters |
| `quaternius_animation_review.tscn` | Universal Animation Library 2 |
| `quaternius_settlement_style_test.tscn` | Goblinized Warren / hut kitbash |

Use `ScaleReference` for a goblin worker wrapper when comparing scale.

## Checklist per asset

- Scale vs `Constants.TILE_SIZE` (1 m tile)
- Material / lighting at RTS camera height (~90m default; 18m close, 520m overview — see `terrain_texture_review.tscn`)
- Collision footprint if used in gameplay
- Navigation blocking if applicable
- Animation compatibility (if character)
- Selection outline readability
- Style fit with Goblin Warrens art guardrails

## Promotion path

Only after review: wrapper scenes under `game/art/...` — never link `external_raw/` directly.
