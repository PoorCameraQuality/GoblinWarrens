class_name GoblinWarrensDebugRegister
extends RefCounted

## Wires Goblin Warrens dev commands to the AssetLib Debug Console when present.


static func try_register(colony: GoblinWarrenColony) -> void:
	if not OS.is_debug_build():
		return
	if colony == null:
		return
	var registered := _register_with_console(colony)
	if registered == 0:
		Log.warn("Debug Console autoload missing — enable plugin in Project Settings", "debug")
		return
	Log.info("Registered %d debug commands (F12 or Ctrl+` in game)" % registered, "debug")


static func _register_with_console(colony: GoblinWarrenColony) -> int:
	var debug_console: Node = colony.get_node_or_null("/root/DebugConsole")
	if debug_console == null or not debug_console.has_method("register_command"):
		return 0
	var count := 0
	count += 1 if _reg(debug_console, "add_food", colony, "Deposit food [amount=20]", _run_add_food) else 0
	count += 1 if _reg(debug_console, "add_wood", colony, "Deposit wood [amount=20]", _run_add_wood) else 0
	count += 1 if _reg(debug_console, "add_stone", colony, "Deposit stone [amount=20]", _run_add_stone) else 0
	count += 1 if _reg(debug_console, "add_magic", colony, "Deposit magic [amount=10]", _run_add_magic) else 0
	count += 1 if _reg(debug_console, "skip_day", colony, "Advance day simulation by one day", _run_skip_day) else 0
	count += 1 if _reg(debug_console, "start_raid", colony, "Spawn militia raid wave", _run_start_raid) else 0
	count += 1 if _reg(debug_console, "spawn_beast", colony, "Spawn surface beast at map edge", _run_spawn_beast) else 0
	count += 1 if _reg(debug_console, "damage_warren", colony, "Damage Warren HP [amount=25]", _run_damage_warren) else 0
	count += 1 if _reg(debug_console, "heal_warren", colony, "Restore Warren to full HP", _run_heal_warren) else 0
	count += 1 if _reg(debug_console, "revive_goblin", colony, "Revive one buried goblin", _run_revive_goblin) else 0
	count += 1 if _reg(
		debug_console,
		"print_mapgen_status",
		colony,
		"Print procedural map runtime stats",
		_run_print_mapgen_status,
	) else 0
	count += 1 if _reg(
		debug_console,
		"toggle_class_overlay",
		colony,
		"Toggle saturated terrain-class debug colors on procgen mesh",
		_run_toggle_class_overlay,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_visual_scale_audit",
		colony,
		"Print measured visual scale audit for MVP assets",
		_run_print_visual_scale_audit,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_prop_scatter_status",
		colony,
		"Print procgen prop spawn counts and missing paths",
		_run_print_prop_scatter_status,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_camera_status",
		colony,
		"Print RTS camera projection, zoom, and focus",
		_run_print_camera_status,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_camera_presets",
		colony,
		"Print RTS camera zoom/pitch preset values",
		_run_print_camera_presets,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_terrain_material_status",
		colony,
		"Print terrain macro texture binding status",
		_run_print_terrain_material_status,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_terrain_blend_status",
		colony,
		"Print terrain transition blend control map stats",
		_run_print_terrain_blend_status,
	) else 0
	count += 1 if _reg(
		debug_console,
		"show_terrain_transition_overlay",
		colony,
		"Toggle terrain transition blend debug overlay",
		_run_show_terrain_transition_overlay,
	) else 0
	count += 1 if _reg(
		debug_console,
		"print_map_validation",
		colony,
		"Print procedural map gameplay validation report",
		_run_print_map_validation,
	) else 0
	return count


static func _reg(
	console: Node,
	name: String,
	colony: GoblinWarrenColony,
	description: String,
	handler: Callable,
) -> bool:
	return console.register_command(name, handler.bind(colony), description, "game")


static func _parse_int_arg(args: Array, default_value: int) -> int:
	if args.is_empty():
		return default_value
	return int(args[0])


static func _run_add_food(colony: GoblinWarrenColony, args: Array) -> String:
	var amount := _parse_int_arg(args, 20)
	GoblinWarrensDebugRouter.add_food(colony, amount)
	return "Deposited %d food." % amount


static func _run_add_wood(colony: GoblinWarrenColony, args: Array) -> String:
	var amount := _parse_int_arg(args, 20)
	GoblinWarrensDebugRouter.add_wood(colony, amount)
	return "Deposited %d wood." % amount


static func _run_add_stone(colony: GoblinWarrenColony, args: Array) -> String:
	var amount := _parse_int_arg(args, 20)
	GoblinWarrensDebugRouter.add_stone(colony, amount)
	return "Deposited %d stone." % amount


static func _run_add_magic(colony: GoblinWarrenColony, args: Array) -> String:
	var amount := _parse_int_arg(args, 10)
	GoblinWarrensDebugRouter.add_magic(colony, amount)
	return "Deposited %d magic." % amount


static func _run_skip_day(_colony: GoblinWarrenColony, _args: Array) -> String:
	GoblinWarrensDebugRouter.skip_day(_colony)
	return "Advanced one day."


static func _run_start_raid(_colony: GoblinWarrenColony, _args: Array) -> String:
	GoblinWarrensDebugRouter.start_raid(_colony)
	return "Raid wave triggered."


static func _run_spawn_beast(_colony: GoblinWarrenColony, _args: Array) -> String:
	GoblinWarrensDebugRouter.spawn_beast(_colony)
	return "Beast spawned."


static func _run_damage_warren(colony: GoblinWarrenColony, args: Array) -> String:
	var amount := _parse_int_arg(args, 25)
	GoblinWarrensDebugRouter.damage_warren(colony, amount)
	return "Warren took %d damage." % amount


static func _run_heal_warren(_colony: GoblinWarrenColony, _args: Array) -> String:
	GoblinWarrensDebugRouter.heal_warren(_colony)
	return "Warren restored to full HP."


static func _run_revive_goblin(colony: GoblinWarrenColony, _args: Array) -> String:
	var ok := colony.try_revive_goblin()
	return "Goblin revived." if ok else "Revival failed (burial grounds, magic, or no body)."


static func _run_print_mapgen_status(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_mapgen_status()


static func _run_toggle_class_overlay(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_toggle_class_overlay()


static func _run_print_visual_scale_audit(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_visual_scale_audit()


static func _run_print_prop_scatter_status(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_prop_scatter_status()


static func _run_print_camera_status(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_camera_status()


static func _run_print_camera_presets(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_camera_presets()


static func _run_print_terrain_material_status(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_terrain_material_status()


static func _run_print_terrain_blend_status(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_terrain_blend_status()


static func _run_show_terrain_transition_overlay(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_toggle_transition_overlay()


static func _run_print_map_validation(colony: GoblinWarrenColony, _args: Array) -> String:
	return colony.dev_print_map_validation()
