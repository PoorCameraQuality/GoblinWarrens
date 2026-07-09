# Import settings

Godot import defaults for Goblin Colony assets. Deviations from defaults must
be documented here in the same PR that introduces them.

## Static meshes (GLB / glTF)

| Setting | Value | Notes |
|---|---|---|
| Format | `.glb` preferred | Single-file; fewer path breaks in exports |
| Root type | `Node3D` or `MeshInstance3D` | Scene root depends on asset; props often `Node3D` |
| Scale | 1 Godot unit = 1 meter = 1 grid tile | Match Blender export scale before import |
| Materials | PBR metallic-roughness | Author lighting in Godot, not in DCC |
| Generate colliders | Off by default | Add collision in scene assembly when needed |

## Animated characters (FBX)

| Setting | Value | Notes |
|---|---|---|
| Format | `.fbx` until animation set is stable | AccuRIG / Mixamo / Cascadeur shuttle |
| Root type | `Node3D` with `Skeleton3D` child | See `docs/asset-pipeline.md` scene tree |
| Bone map | Do not rename bones after animation authoring | Breaks retargeting |
| Animation import | Import all; filter in `AnimationLibrary` | Name clips consistently: `walk`, `idle`, `eat`, etc. |
| Root motion | Strip or bake per clip in Cascadeur | Grid sim moves via `movement_adapter`, not root motion |

## Textures

| Setting | Value |
|---|---|
| Compress | VRAM compressed for runtime |
| Size cap | 2048×2048 default; 4096 only with documented reason |
| sRGB | Albedo/base color yes; normal/ORM no |

### Terrain albedo (`game/art/terrain/goblin_warrens/`)

Applied to procedural ground via `terrain_blend.gdshader`. See `docs/terrain-texture-brief.md`.

| Setting | Value | Notes |
|---|---|---|
| Filter | Linear | |
| Mipmaps | **On** | Required for RTS zoom 18–520m |
| Repeat | On | Shader sampler uses `repeat_enable` |
| Compress | VRAM Compressed (`compress/mode=2`) | Use Lossless if banding appears |
| sRGB | On (default for albedo PNG) | |

Legacy and `_macro.png` files share these import rules. Reimport after changing `.import` params.

## Audio (future)

| Setting | Value |
|---|---|
| Format | `.ogg` for music/SFX loops; `.wav` for short one-shots |
| Bus | Route through Godot audio buses; no raw path refs in gameplay code |

## Placeholder assets

Phase 2 uses `CSGBox3D` / primitive meshes until Meshy assets land. No custom
import rules required.
