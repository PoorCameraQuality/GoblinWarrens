# Asset pipeline (technical index)

**Full pipeline:** [`../asset-pipeline.md`](../asset-pipeline.md) (Meshy, Blender, AccuRIG, Mixamo, Godot import paths).

**Acquisition rules:** [`../asset-library-acquisition.md`](../asset-library-acquisition.md) (AssetLib) · [`../itch-io-acquisition.md`](../itch-io-acquisition.md) (itch.io) · [`../quaternius-acquisition.md`](../quaternius-acquisition.md) (Quaternius).

**Licenses:** [`../legal/THIRD_PARTY_LICENSES.md`](../legal/THIRD_PARTY_LICENSES.md).

---

## Quick rules for AssetLib art

| Rule | Detail |
|------|--------|
| Shipped 3D format | **`.glb` / glTF** preferred |
| Raw pack drop | `external_raw/quaternius/<category>/<pack>/`, `external_raw/itch_io/...`, or `external_raw/art_packs/...` |
| Game-ready import | `game/art/...` (target) or `assets/props/`, `assets/env/`, `assets/characters/` (legacy) |
| Art review | `game/scenes/asset_test_scenes/` before promoting to colony |
| Reference in game | `uid://` via `.tres` — no raw filenames in gameplay code |
| Scale | 1 tile = 1 meter (`Constants.TILE_SIZE`) |
| Source masters | `.blend` in `external_raw/blender_sources/` |

When a new art pack is imported, append an entry to `docs/legal/THIRD_PARTY_LICENSES.md` and note any import setting changes in `docs/import-settings.md`.
