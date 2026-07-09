extends SceneTree


func _initialize() -> void:
	print("hello from tree init")
	var scene := load("res://game/art/buildings/goblin_warrens/warren.glb") as PackedScene
	if scene == null:
		print("scene null")
		quit(1)
		return
	print("scene loaded ok")
	var inst := scene.instantiate() as Node3D
	print("instantiated: name=%s children=%d" % [inst.name, inst.get_child_count()])
	quit(0)
