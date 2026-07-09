extends SceneTree
const paths = {
  "warren": "res://game/art/buildings/goblin_warrens/warren.glb",
  "worker": "res://game/art/units/goblins/worker.glb",
  "foblin": "res://game/art/units/goblins/foblin.glb",
  "tree": "res://game/art/props/nature/goblin_warrens/tree_birch.glb",
}
func _init():
  for k in paths:
    var p = paths[k]
    print(k, " exists=", ResourceLoader.exists(p))
    if not ResourceLoader.exists(p):
      continue
    var ps = load(p)
    print("  type=", ps.get_class() if ps else "null")
    if ps is PackedScene:
      var n = (ps as PackedScene).instantiate()
      var aabb = _aabb(n)
      print("  aabb size=", aabb.size, " pos=", aabb.position)
      n.free()
  var tp = TerrainPalette.all_macro_textures_present()
  print("all_macro=", tp, " uv=", TerrainPalette.preferred_uv_scale())
  quit(0)
func _aabb(root: Node) -> AABB:
  var out = AABB(); var first = true
  var stack = [root]
  while stack.size() > 0:
    var n = stack.pop_back()
    if n is MeshInstance3D:
      var mi: MeshInstance3D = n
      var local: AABB = mi.get_aabb()
      var global_aabb: AABB = local
      if first: out = global_aabb; first = false
      else: out = out.merge(global_aabb)
    for c in n.get_children(): stack.push_back(c)
  return out
