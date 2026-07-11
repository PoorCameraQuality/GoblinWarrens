class_name DemoGuide
extends Node

## MVP demo UX: day briefings, objective tracker, banners, and threat telegraph.

var _colony: GoblinWarrenColony
var _day_sim: DaySimulation
var _briefing_label: Label
var _objectives_label: Label
var _build_hint_label: Label
var _day_banner: Label
var _threat_flash: ColorRect
var _food_label: Label

var _banner_timer: float = 0.0
var _flash_timer: float = 0.0


func setup(colony: GoblinWarrenColony, day_sim: DaySimulation) -> void:
	_colony = colony
	_day_sim = day_sim
	var ui: Node = get_parent()
	_briefing_label = ui.get_node_or_null("HUD/BriefingLabel") as Label
	_objectives_label = ui.get_node_or_null("HUD/ObjectivesLabel") as Label
	_build_hint_label = ui.get_node_or_null("HUD/BuildHintLabel") as Label
	_day_banner = ui.get_node_or_null("DayBanner") as Label
	_threat_flash = ui.get_node_or_null("ThreatFlash") as ColorRect
	_food_label = ui.get_node_or_null("HUD/FoodLabel") as Label
	if _day_banner != null:
		_day_banner.visible = false
	if _threat_flash != null:
		_threat_flash.visible = false
		_threat_flash.modulate.a = 0.0
	if not Bus.day_advanced.is_connected(_on_day_advanced):
		Bus.day_advanced.connect(_on_day_advanced)
	if not Bus.threat_warning.is_connected(_on_threat_warning):
		Bus.threat_warning.connect(_on_threat_warning)
	if not Bus.raid_started.is_connected(_on_raid_started):
		Bus.raid_started.connect(_on_raid_started)
	if not Bus.food_shortage.is_connected(_on_food_shortage):
		Bus.food_shortage.connect(_on_food_shortage)
	if not Bus.goblin_died.is_connected(_on_goblin_died):
		Bus.goblin_died.connect(_on_goblin_died)
	_show_day(1)


func show_day(day: int) -> void:
	_show_day(day)


func pulse_banner(text: String) -> void:
	_pulse_banner(text)


func tick_hud() -> void:
	_update_objectives()
	_update_food_warning()
	var delta: float = get_process_delta_time()
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0 and _day_banner != null:
			_day_banner.visible = false
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _threat_flash != null:
			var t: float = clampf(_flash_timer / Constants.THREAT_FLASH_DURATION, 0.0, 1.0)
			_threat_flash.modulate.a = t * 0.45
			if _flash_timer <= 0.0:
				_threat_flash.visible = false


func format_day_line() -> String:
	if _day_sim == null:
		return "Day: 1 / 7"
	var secs: float = _day_sim.seconds_until_next_day()
	if _day_sim.current_day >= 7:
		return "Day: %d / 7" % _day_sim.current_day
	return "Day: %d / 7  (next in %s)" % [_day_sim.current_day, _format_duration(secs)]


static func _format_duration(seconds: float) -> String:
	var total: int = maxi(0, int(ceil(seconds)))
	var mins: int = total / 60
	var secs: int = total % 60
	if mins > 0:
		return "%d:%02d" % [mins, secs]
	return "%ds" % secs


func format_selection(selected: Array) -> String:
	if selected.is_empty():
		return "Selected: 0 — click a goblin"
	if selected.size() == 1:
		var goblin := selected[0] as Goblin
		if goblin == null:
			return "Selected: 1"
		var status := "OK"
		if goblin.starvation_level > 0.0:
			status = "STARVING"
		elif goblin.hp < goblin.max_hp:
			status = "Wounded"
		return "%s — HP %d/%d  [%s]" % [
			goblin.display_name,
			goblin.hp,
			goblin.max_hp,
			status,
		]
	var names: PackedStringArray = PackedStringArray()
	for unit in selected:
		if unit is Goblin:
			names.append((unit as Goblin).display_name)
	return "Selected (%d): %s" % [selected.size(), ", ".join(names)]


func _on_day_advanced(day: int) -> void:
	_show_day(day)
	_pulse_banner(DemoDayCatalog.day_title(day))
	if day >= 6:
		_pulse_threat(0.35)


func _on_threat_warning(_message: String) -> void:
	_pulse_threat(0.25)


func _on_raid_started(_day: int) -> void:
	_pulse_banner("RAID INCOMING!")
	_pulse_threat(0.55)


func _on_food_shortage(_tick: int) -> void:
	if _food_label != null:
		_food_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))


func _on_goblin_died(goblin: Node, _killer: Node) -> void:
	if goblin is Goblin and not (goblin as Goblin).is_foblin():
		_pulse_banner("%s has fallen!" % (goblin as Goblin).display_name)
		_pulse_threat(0.2)


func _show_day(day: int) -> void:
	if _briefing_label != null:
		_briefing_label.text = DemoDayCatalog.briefing(day)
	if _build_hint_label != null:
		_build_hint_label.text = DemoDayCatalog.build_hint(day)
	_update_objectives()


func _update_objectives() -> void:
	if _objectives_label == null or _colony == null:
		return
	if _day_sim != null and _day_sim.current_day <= 1:
		_objectives_label.text = "Goals: food buffer · shrine · defense · survive Day 7 raid"
		return
	var stock := _colony.get_stockpile()
	var food_ok := false
	if stock != null:
		var reserve: int = _colony.count_living_goblins() * Constants.FOOD_PER_GOBLIN_PER_TICK * 2
		food_ok = stock.get_amount(Defs.ResourceKind.FOOD) >= reserve
	var lines: PackedStringArray = PackedStringArray([
		"Win checklist:",
		"%s Food buffer" % ("[x]" if food_ok else "[ ]"),
		"%s Shrine built" % ("[x]" if _colony.has_building_kind(Defs.BuildingKind.SHRINE) else "[ ]"),
		"%s Guard Post or Watchtower"
		% ("[x]" if _colony.has_basic_defense() else "[ ]"),
		"%s Repel Day 7 raid"
		% ("[x]" if _colony.is_raid_cleared() else "[ ]"),
		"%s Warren standing"
		% (
			"[x]"
			if (
				_colony.get_warren() != null
				and is_instance_valid(_colony.get_warren())
				and not _colony.get_warren().is_destroyed()
			)
			else "[ ]"
		),
	])
	_objectives_label.text = "\n".join(lines)


func _update_food_warning() -> void:
	if _food_label == null or _colony == null:
		return
	var stock := _colony.get_stockpile()
	if stock == null:
		return
	var reserve: int = maxi(4, _colony.count_living_goblins() * Constants.FOOD_PER_GOBLIN_PER_TICK * 2)
	if stock.get_amount(Defs.ResourceKind.FOOD) >= reserve:
		_food_label.remove_theme_color_override("font_color")
	elif stock.get_amount(Defs.ResourceKind.FOOD) > 0:
		_food_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.2))
	else:
		_food_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))


func _pulse_banner(text: String) -> void:
	if _day_banner == null:
		return
	_day_banner.text = text
	_day_banner.visible = true
	_banner_timer = Constants.DAY_BANNER_DURATION


func _pulse_threat(intensity: float) -> void:
	if _threat_flash == null:
		return
	_threat_flash.visible = true
	_threat_flash.modulate.a = intensity
	_flash_timer = Constants.THREAT_FLASH_DURATION
