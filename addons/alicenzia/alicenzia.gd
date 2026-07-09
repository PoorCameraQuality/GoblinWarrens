@tool
extends EditorPlugin

const ALICENZIA_MAIN_WINDOW_SCENE_PATH = "uid://ch5mnmkieer5x"
const ALICENZIA_RIGHT_DOCK_SCENE_PATH = "uid://cdgcops15lly0"
const ALICENZIA_INTRO_GUIDE_SCENE_PATH = "uid://beqcglktcyvic"

var alicenzia_main_window_node : Control
var alicenzia_right_dock_node : Control
var anz_intro_guide_window : Window

var connected_signals : Dictionary[Signal, Callable]


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_load_addon_mainscreen()
		_load_rightdock_scene()
		anz_intro_guide_window = load(ALICENZIA_INTRO_GUIDE_SCENE_PATH).instantiate()
		
		#var test_dock = load("uid://dk5jia7tjw1p5").instantiate()
		#add_control_to_dock(DOCK_SLOT_RIGHT_UL, test_dock)
		pass


func _enable_plugin() -> void:
	_on_trigger_view_guide()
	
	
func _load_addon_mainscreen():
	alicenzia_main_window_node = load(ALICENZIA_MAIN_WINDOW_SCENE_PATH).instantiate()
	
	EditorInterface.get_editor_main_screen().add_child(alicenzia_main_window_node)
	_make_visible(false)


func _load_rightdock_scene():
	alicenzia_right_dock_node = load(ALICENZIA_RIGHT_DOCK_SCENE_PATH).instantiate()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, alicenzia_right_dock_node)


func _ready() -> void:
	if Engine.is_editor_hint():
		# Signals first before the inits
		alicenzia_main_window_node.addon_refresh.connect(_on_addon_refresh)
		signals_to_connect()
		
		alicenzia_main_window_node._addon_init()
		alicenzia_right_dock_node._addon_init()


func signal_connect_and_log(connect_from : Signal, connect_to : Callable):
	connect_from.connect(connect_to)
	connected_signals[connect_from] = connect_to
	
	
func signals_to_connect(): # after the right dock scene is initiated
	signal_connect_and_log(
		alicenzia_right_dock_node.refresh_license_table,
		alicenzia_main_window_node.on_refresh_license_table
	)
	signal_connect_and_log(
		alicenzia_main_window_node.save_selected_scanned_licenses,
		alicenzia_right_dock_node.on_scan_result_save
	)
	signal_connect_and_log(
		alicenzia_main_window_node.show_export_license_dialog,
		alicenzia_right_dock_node.on_show_export_license_dialog
	)
	### view guide ###
	signal_connect_and_log(
		alicenzia_main_window_node.view_guide_from_main_scene,
		_on_trigger_view_guide
	)
	signal_connect_and_log(
		alicenzia_right_dock_node.view_guide_from_right_dock,
		_on_trigger_view_guide
	)
	###


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		if alicenzia_main_window_node:
			#alicenzia_main_window_node.attempt_save_resource_changes()
			alicenzia_main_window_node.queue_free()
		_attempt_remove_right_dock_scene()


func _has_main_screen():
	return true


func _make_visible(visible):
	if alicenzia_main_window_node:
		alicenzia_main_window_node.visible = visible


func _get_plugin_name():
	return "Alicenzia"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("CanvasLayer", "EditorIcons")


func _disconnect_logged_signals():
	# disconnect all signal from signals_to_connect() manually here
	for sg : Signal in connected_signals:
		sg.disconnect(connected_signals[sg])
	connected_signals.clear()


func _on_addon_refresh():
	var editor_main_screen : Node = EditorInterface.get_editor_main_screen()
	
	if editor_main_screen.is_ancestor_of(alicenzia_main_window_node):
		alicenzia_main_window_node.addon_refresh.disconnect(_on_addon_refresh)
		
		_disconnect_logged_signals()
		
		#scene_saved.disconnect(album_manager_node._on_any_scene_saved)
		alicenzia_main_window_node.queue_free()
		#remove_inspector_plugin(inspector_plugin_inst)
		_load_addon_mainscreen()
		alicenzia_main_window_node.addon_refresh.connect(_on_addon_refresh)
		#scene_saved.connect(album_manager_node._on_any_scene_saved)
		alicenzia_main_window_node.visible = true
		alicenzia_main_window_node._addon_init()
		
	
	_attempt_remove_right_dock_scene()
	_load_rightdock_scene()
	signals_to_connect()
	alicenzia_right_dock_node._addon_init()
	
	print("Alicenzia refreshed")
	print("---")


func _on_trigger_view_guide():
	get_editor_interface().popup_dialog_centered(anz_intro_guide_window)
	
	
func _attempt_remove_right_dock_scene():
	if alicenzia_right_dock_node:
		remove_control_from_docks(alicenzia_right_dock_node)
		alicenzia_right_dock_node._exit_tree() # because somehow it doesn't call _exit_tree()
		alicenzia_right_dock_node.queue_free()
	
#func _save_external_data() -> void:
	#if album_manager_node:
		##@TODO currently it makes saving the resource twice. but might worth because it also saves before closing
		#album_manager_node.attempt_save_resource_changes()
