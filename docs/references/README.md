# External demo & reference projects

Do **not** copy demo scenes or scripts from Asset Library demos into `scenes/colony.tscn`.

Study separately, then adapt patterns into `scripts/` and `scenes/` following [`PROJECT_STRUCTURE.md`](../technical/PROJECT_STRUCTURE.md).

**Internal reference (not external):** [`GODOT_HEADLESS_PITFALLS.md`](../technical/GODOT_HEADLESS_PITFALLS.md) — headless smoke and pipeline tooling on Godot 4.7.

---

## 3D Navigation Demo (MIT, AssetLib)

| Field | Value |
|-------|-------|
| Purpose | Reference for path visualization and movement patterns |
| Install | **Separate Godot project** or extract to `external_raw/assetlib_downloads/3d_navigation_demo/` |
| Production use | **No** — Goblin Warrens uses `AStarGrid2D` via `scripts/agents/movement_adapter.gd` |
| Notes | Above-ground grid only. Do not adopt NavigationAgent3D/navmesh without ADR. |

After review, note useful patterns here (one paragraph max) before adapting code.

---

## Template for new references

```text
Name:
AssetLib ID:
License:
Location (external project path):
Useful patterns:
Do not copy:
```
