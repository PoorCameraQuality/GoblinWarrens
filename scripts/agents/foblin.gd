class_name Foblin
extends Goblin

## Weak expendable goblin spawned from Breeder Huts.


func setup_foblin(start_cell: Vector2i, movement: MovementAdapter, colony: GoblinWarrenColony) -> void:
	is_foblin_unit = true
	display_name = "Foblin"
	max_hp = Constants.FOBLIN_MAX_HP
	hp = max_hp
	attack_damage = Constants.FOBLIN_ATTACK_DAMAGE
	gather_multiplier = Constants.FOBLIN_GATHER_MULTIPLIER
	build_multiplier = Constants.FOBLIN_BUILD_MULTIPLIER
	setup(start_cell, movement, colony)
	add_to_group(Defs.GROUP_FOBLIN)
	_ensure_nameplate()
	_update_status_visual()


func is_foblin() -> bool:
	return true


func should_flee() -> bool:
	return false


func _apply_foblin_visual() -> void:
	var body := get_node_or_null("VisualRoot/Body") as CSGBox3D
	if body == null:
		return
	body.size = Vector3(0.45, 0.6, 0.45)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.55, 0.25)
	body.material = mat
