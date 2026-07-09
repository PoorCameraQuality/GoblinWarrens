extends SceneTree

## One-shot: print AnimationPlayer libraries from Twigskull FBX imports.
## godot --headless --path . --script tools/inspect_fbx_scene.gd

const PATHS := [
	"res://game/art/units/goblins/twigskull/twigskull_foblin_character.fbx",
	"res://game/art/units/goblins/twigskull/twigskull_foblin_anim_walk.fbx",
	"res://game/art/units/goblins/twigskull/twigskull_foblin_anim_run.fbx",
	"res://game/art/units/goblins/twigskull/twigskull_foblin_anim_gather.fbx",
	"res://game/art/units/goblins/twigskull/twigskull_foblin_anim_attack.fbx",
	"res://game/art/units/goblins/twigskull/twigskull_foblin_anim_death.fbx",
]


func _init() -> void:
	for path in PATHS:
		_inspect(path)
	quit(0)


func _inspect(path: String) -> void:
	print("\n=== ", path, " ===")
	if not ResourceLoader.exists(path):
		print("MISSING")
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("LOAD FAILED")
		return
	var root: Node = packed.instantiate()
	print("root: ", root.name, " (", root.get_class(), ")")
	_print_tree(root, 0)
	root.free()


func _print_tree(node: Node, depth: int) -> void:
	var pad := "  ".repeat(depth)
	print(pad, node.name, " [", node.get_class(), "]")
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			print(pad, "  aabb height ~", mi.get_aabb().size.y)
	if node is AnimationPlayer:
		var ap := node as AnimationPlayer
		for anim_name in ap.get_animation_list():
			var anim: Animation = ap.get_animation(anim_name)
			print(pad, "  anim: ", anim_name, " len=", anim.length)
	for child in node.get_children():
		_print_tree(child, depth + 1)
