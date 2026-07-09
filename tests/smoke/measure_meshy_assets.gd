extends SceneTree

const PATHS := [
	"res://game/art/buildings/goblin_warrens/warren.glb",
	"res://game/art/buildings/goblin_warrens/sleep_hut.glb",
	"res://game/art/buildings/goblin_warrens/shrine.glb",
	"res://game/art/buildings/goblin_warrens/watchtower.glb",
	"res://game/art/buildings/goblin_warrens/breeder_hut.glb",
	"res://game/art/units/goblins/worker.glb",
	"res://game/art/units/goblins/foblin.glb",
	"res://game/art/units/goblins/hobgoblin_warrior.glb",
	"res://game/art/props/nature/goblin_warrens/tree_birch.glb",
	"res://game/art/props/nature/goblin_warrens/tree_pine.glb",
	"res://game/art/props/nature/goblin_warrens/tree_tall.glb",
	"res://game/art/props/nature/goblin_warrens/stump_pine.glb",
	"res://game/art/props/nature/goblin_warrens/mushroom_patch_a.glb",
	"res://game/art/props/resources/goblin_warrens/gold_vein_a.glb",
]


func _initialize() -> void:
	print("== Meshy asset AABB report (1 tile = 1.0 m) ==")
	print("path                                          size_x  size_y  size_z   pos_x   pos_y   pos_z")
	for p in PATHS:
		var scene := load(p) as PackedScene
		if scene == null:
			print("%s FAILED_LOAD" % p)
			continue
		var inst := scene.instantiate()
		var aabb := _walk(inst)
		var s: Vector3 = aabb.size
		var pos: Vector3 = aabb.position
		var file_name: String = p.get_file()
		print("%-45s  %6.2f  %6.2f  %6.2f   %6.2f  %6.2f  %6.2f" % [file_name, s.x, s.y, s.z, pos.x, pos.y, pos.z])
		inst.queue_free()
	quit(0)


func _walk(node: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [node]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var ab: AABB = mi.get_aabb()
			if first:
				out = ab
				first = false
			else:
				out = out.merge(ab)
		for c in n.get_children():
			stack.push_back(c)
	return out
