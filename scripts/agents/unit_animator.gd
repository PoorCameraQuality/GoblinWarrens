class_name UnitAnimator
extends Node3D

## Merges Meshy per-clip FBX animations onto the character rig and drives playback from unit state.

const CHARACTER_FBX := "res://game/art/units/goblins/twigskull/twigskull_foblin_character.fbx"

const CLIP_SOURCES := {
	"walk": "res://game/art/units/goblins/twigskull/twigskull_foblin_anim_walk.fbx",
	"run": "res://game/art/units/goblins/twigskull/twigskull_foblin_anim_run.fbx",
	"gather": "res://game/art/units/goblins/twigskull/twigskull_foblin_anim_gather.fbx",
	"attack": "res://game/art/units/goblins/twigskull/twigskull_foblin_anim_attack.fbx",
	"death": "res://game/art/units/goblins/twigskull/twigskull_foblin_anim_death.fbx",
}

const LIB_NAME := &"twigskull"

var _player: AnimationPlayer
var _unit: Goblin
var _current: StringName = &""
var _death_started: bool = false


func _ready() -> void:
	_unit = _find_goblin_ancestor()
	call_deferred("_setup_animations")


func _process(_delta: float) -> void:
	if _player == null or _unit == null:
		return
	_sync_playback()


func _setup_animations() -> void:
	var model := get_node_or_null("Model")
	if model == null:
		Log.warn("UnitAnimator: missing Model node", "unit_animator")
		return
	_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _player == null:
		Log.warn("UnitAnimator: no AnimationPlayer on Model", "unit_animator")
		return
	if _player.has_animation_library(LIB_NAME):
		_player.remove_animation_library(LIB_NAME)
	var library := AnimationLibrary.new()
	_player.add_animation_library(LIB_NAME, library)
	_import_clip_from_fbx(CHARACTER_FBX, "idle")
	for clip_name in CLIP_SOURCES:
		_import_clip_from_fbx(CLIP_SOURCES[clip_name], clip_name)
	_play_loop(&"idle")


func _import_clip_from_fbx(path: String, short_name: String) -> void:
	if not ResourceLoader.exists(path):
		Log.warn("UnitAnimator: missing clip %s" % path, "unit_animator")
		return
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return
	var temp: Node = packed.instantiate()
	var src_player := temp.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if src_player == null:
		temp.free()
		return
	var names: PackedStringArray = src_player.get_animation_list()
	if names.is_empty():
		temp.free()
		return
	var anim: Animation = src_player.get_animation(names[0])
	if anim == null:
		temp.free()
		return
	var copy: Animation = anim.duplicate()
	copy.resource_name = short_name
	var library: AnimationLibrary = _player.get_animation_library(LIB_NAME)
	if library.has_animation(short_name):
		library.remove_animation(short_name)
	library.add_animation(short_name, copy)
	temp.free()


func _sync_playback() -> void:
	if not _unit.is_alive():
		if not _death_started:
			_death_started = true
			_play_once(&"death")
		return
	if _death_started:
		_death_started = false
	if _unit.is_moving():
		_play_loop(&"walk")
		_sync_walk_playback_speed()
		return
	match _unit.job_kind:
		Defs.JobKind.FIGHT:
			_play_loop(&"attack")
		Defs.JobKind.GATHER, Defs.JobKind.BUILD, Defs.JobKind.FORAGE:
			if _unit.worker_phase == Defs.WorkerPhase.WORK:
				_play_loop(&"gather")
			else:
				_play_loop(&"idle")
		_:
			_play_loop(&"idle")


func _play_loop(name: StringName) -> void:
	if _current == name and _player.is_playing():
		return
	var key := String(name)
	var library: AnimationLibrary = _player.get_animation_library(LIB_NAME)
	if not library.has_animation(key):
		return
	var anim: Animation = library.get_animation(key)
	anim.loop_mode = Animation.LOOP_LINEAR
	_current = name
	_player.speed_scale = 1.0
	_player.play("%s/%s" % [LIB_NAME, key])


func _play_once(name: StringName) -> void:
	var key := String(name)
	var library: AnimationLibrary = _player.get_animation_library(LIB_NAME)
	if not library.has_animation(key):
		return
	var anim: Animation = library.get_animation(key)
	anim.loop_mode = Animation.LOOP_NONE
	_current = name
	_player.speed_scale = 1.0
	_player.play("%s/%s" % [LIB_NAME, key])


func _sync_walk_playback_speed() -> void:
	if _player == null or _unit == null:
		return
	var move_speed: float = (
		Constants.FOBLIN_MOVE_SPEED if _unit.is_foblin() else Constants.GOBLIN_MOVE_SPEED
	)
	var expected: float = Constants.FOBLIN_TILES_PER_WALK_CYCLE / Constants.FOBLIN_WALK_CYCLE_SEC
	if expected <= 0.0:
		return
	_player.speed_scale = move_speed / expected


func _find_goblin_ancestor() -> Goblin:
	var node: Node = get_parent()
	while node != null:
		if node is Goblin:
			return node as Goblin
		node = node.get_parent()
	return null
