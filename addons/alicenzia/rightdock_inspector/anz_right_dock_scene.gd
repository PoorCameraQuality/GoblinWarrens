@tool
extends InspectorSpawner

signal refresh_license_table(vbox : VBoxContainer)
signal view_guide_from_right_dock

enum PathLicenseStatus {
	INHERIT_NONE, INHERIT_PROJECT_WIDE,
	INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
}

const LICENSE_DATABASE_SAVE_PATH := "res://alz_license_database.tres"
const LICENSE_PLD_SAVE_PATH := "res://alz_license_database_paths.json"
const RES_PATH := "res://"
const LICENSE_TEXT_TEMPLATES_PATH := "res://addons/alicenzia/assets/license_text_templates"

const BLUE_LABEL_STYLEBOX = preload("res://addons/alicenzia/custom_types/blue_label_stylebox.tres")
const LIGHTBLUE_LABEL_STYLEBOX = preload("res://addons/alicenzia/custom_types/lightblue_label_stylebox.tres")
const EXPANDABLE_BUTTON_CELL = preload("res://addons/alicenzia/scenes/expandable_button_cell.tscn")
#const TABLE_FIRSTROW_BUTTON = preload("res://addons/alicenzia/scenes/table_firstrow_button.tscn")
#@onready var deselect_area: Control = $DeselectArea

@onready var current_path_textbox: TextEdit = %CurrentPath
@onready var exist_in_lic_db_info: VBoxContainer = %ExistInLicDBInfo
@onready var lic_inherit_info: VBoxContainer = %LicInheritInfo
@onready var unsaved_changes_hbox: HBoxContainer = %UnsavedChangesHbox

@onready var pwl_dialog: ConfirmationDialog = %ProjectWideLicenseDialog
@onready var add_new_string_enum_dialog: ConfirmationDialog = %AddNewStringEnumDialog
@onready var confirm_remove_path_lic_dialog: ConfirmationDialog = %ConfirmRemovePathLicDialog

@onready var save_btn: Button = %SavePathLicenseBtn
@onready var remove_path_license_btn: Button = %RemovePathLicenseBtn
@onready var discard_changes_btn: Button = %DiscardChangesBtn

@onready var export_license_dialog: ConfirmationDialog = %ExportLicenseDialog
@onready var example_template_dialog: AcceptDialog = %ExampleTemplateDialog
@onready var template_text_area: TextEdit = %TemplateTextArea
@onready var save_template_dialog: FileDialog = %SaveTemplateDialog

# bottom tools
@onready var autofill_from_template_btn: Button = %AutofillFromTemplateBtn
@onready var copy_from_license_path_btn: Button = %CopyFromLicensePathBtn

@onready var autofill_license_from_template_dialog: ConfirmationDialog = %AutofillLicenseFromTemplateDialog
@onready var full_license_preview_dialog: AcceptDialog = %FullLicensePreviewDialog
@onready var full_license_preview_text_area: TextEdit = %FullLicensePreviewTextArea


var tracked_signal_callable_pair : Dictionary[Signal, Callable]

var ed_theme : Theme 
var ed_toast : EditorToaster
var ed_fsd : FileSystemDock
var ed_efs : EditorFileSystem
#var mini_inspector_vbox : EditorInspector
var fsd_tree : Tree
#var fsd_last_selected_dir : String
var fsd_last_selected_file : String

var currently_edited_pld : PathLicenseData
var cached_alz_licdb : ALZProjectLicenseDatabase

var inspector_changed_unsaved := false
var empty_pld_ref : PathLicenseData
var res_diraccess : DirAccess

var license_text_with_templates : Array[String]


func _ready() -> void:
	#pwl_dialog.hide()
	pass


func _addon_init() -> void:
	res_diraccess = DirAccess.open(RES_PATH)
	
	ed_theme = EditorInterface.get_editor_theme()
	ed_toast = EditorInterface.get_editor_toaster()
	ed_fsd = EditorInterface.get_file_system_dock()
	ed_efs = EditorInterface.get_resource_filesystem()
	#pwl_dialog.hide()
	inspector_below_here = %InspectorBelowHere
	# mini_inspector_vbox = instantiate_inspector(DATA_TEST)
	instantiate_inspector()
	
	if not _is_version_4point6_upward():
		fsd_tree = _get_tree_from_fsd(ed_fsd)
				
	#fsd_tree.print_tree_pretty()
	
	%NoPWLWarnIcon.texture = get_theme_icon("StatusWarning", "EditorIcons")
	%UnsavedChangesWarningIcon.texture = get_theme_icon("NodeWarning", "EditorIcons")

	%NoProjectLicenseWarn.visible = !is_pwl_exist() # !project_wide_license_dialog.is_pwl_exist()
	#exist_in_lic_db_info._addon_init()
	
	for c: Control in \
	[exist_in_lic_db_info, lic_inherit_info, unsaved_changes_hbox,
	remove_path_license_btn, discard_changes_btn]:
		c.hide()
	
	for n: Node in \
	[lic_inherit_info, pwl_dialog]:
		if n.has_method("_addon_init"):
			n._addon_init()
			
	#fsd_tree.cell_selected.connect(_on_filesystemdock_selectedpath_changed)
	#add_new_string_enum_dialog.attempt_remove_hint_from_param.connect(_on_attempt_remove_hint_from_param)
	
	if _is_version_4point6_upward():
		connect_and_track_signal(
			ed_fsd.selection_changed, _on_filesystemdock_selectedpath_changed)
	else:
		connect_and_track_signal(
			fsd_tree.cell_selected, _on_filesystemdock_selectedpath_changed)
	
	connect_and_track_signal(
		ed_fsd.folder_moved, _on_filesystemdock_folder_moved)
		
	connect_and_track_signal(
		ed_fsd.files_moved, _on_filesystemdock_folder_moved)
		
	save_btn.disabled = true
	
	property_changed.connect(_on_licensedata_property_changed)
	
	_init_license_names_with_templates()
	_list_license_and_refresh_table()
	
	#export_license_dialog.export_license.connect(_on_export_license)
	#deselect_area.deselect.connect(_on_inspector_deselect)


func _on_licensedata_property_changed():
	inspector_changed_unsaved = true
	# TODO check if the currently edited pld is empty/default on the inspector, if yes then disable the button
	discard_changes_btn.show()
	save_btn.disabled = false
	remove_path_license_btn.hide()


func _is_version_4point6_upward() -> bool:
	var ver_info := Engine.get_version_info()
	if ver_info["major"] >= 4 and ver_info["minor"] >= 6:
		return true
		
	return false


func _init_license_names_with_templates():
	license_text_with_templates.clear()
	
	var dir := DirAccess.open(LICENSE_TEXT_TEMPLATES_PATH)
	for file : String in dir.get_files():
		const txt_ext := ".txt"
		if file.ends_with(txt_ext):
			var license_name := file.trim_suffix(txt_ext)
			license_text_with_templates.append(license_name)


func _get_first_node_of_this_class(_class : Node, node_to_search : Node) -> Node:
	var class_to_search := _class.get_class()
	if node_to_search.get_child_count() > 0:
		for child : Node in node_to_search.get_children():
			if child.is_class(class_to_search):
				return child
		return null
	else:
		return null


func _get_tree_from_fsd(fsd : FileSystemDock) -> Tree:
	# in 4.6/4.7 it was located on:
	#┖╴FileSystem
	#	┠╴@VBoxContainer@6789
	#	┃  ┠╴@SplitContainer@5873
	#	┃  ┃  ┠╴@MarginContainer@5874
	#	┃  ┃  ┃  ┖╴@Tree@5888
	if _is_version_4point6_upward(): #INFO no longer used
		var child1 := _get_first_node_of_this_class(VBoxContainer.new(), ed_fsd)
		var child2 := _get_first_node_of_this_class(SplitContainer.new(), child1)
		var child3 := _get_first_node_of_this_class(MarginContainer.new(), child2)
		var child4 := _get_first_node_of_this_class(Tree.new(), child3)
		if child4: return child4
		return null
		
	else: # tested on 4.4 & 4.5
		for child : Node in ed_fsd.get_children():
			if child.get_child_count() > 0:
				var gc = child.get_child(0)
				if gc is Tree:
					return gc
		return null


func _list_license_and_refresh_table():
	var new_license_list_vbox = list_licenses_on_rows()
	refresh_license_table.emit(new_license_list_vbox)


func list_licenses_on_rows(): #WARNING TODO cuma tes aja tpi bisa jadi fix
	
	#for n in license_list_vbox.get_children():
		#n.queue_free()
	var license_list_vbox = VBoxContainer.new()
	license_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		return

	for pld_datas : Dictionary in alz_licdb.get_data_as_dict().values(): # only first to get the titles
		var new_hbox := HBoxContainer.new()
		license_list_vbox.add_child(new_hbox)
		
		for prop_name : String in pld_datas.keys(): 
			if prop_name.ends_with("_hint"):
				continue
			
			var new_label := EXPANDABLE_BUTTON_CELL.instantiate()
			new_label.text = str(prop_name).capitalize()
			
			new_label.remove_theme_stylebox_override("normal")
			new_label.add_theme_stylebox_override("normal", LIGHTBLUE_LABEL_STYLEBOX)
			new_hbox.add_child(new_label)
		
		break # only firstrow
	
	var licdb_dict_data : Dictionary = alz_licdb.get_data_as_dict()
	for pld_path : String in licdb_dict_data.keys():
		var dir := DirAccess.open(RES_PATH)
		
		# file/folder exist on the database but missing in actuality
		if not (dir.file_exists(pld_path) or dir.dir_exists(pld_path)):
			continue # don't show it on the table
		
		var pld_datas : Dictionary = licdb_dict_data[pld_path]
		var new_hbox := HBoxContainer.new()
		license_list_vbox.add_child(new_hbox)
		
		for prop_name : String in pld_datas.keys():
			if prop_name.ends_with("_hint"):
				continue
			
			var prop_value = pld_datas[prop_name]
			
			#var new_label := Label.new()
			var new_table_cell := EXPANDABLE_BUTTON_CELL.instantiate()
			
			if prop_name == "full_license_text":
				new_table_cell.text = "View"
			else:
				new_table_cell.text = str(prop_value)
				
			new_table_cell.pressed.connect(_on_prop_table_cell_pressed.bind(pld_path, prop_name)) # .bind()
			
			#new_label.add_theme_stylebox_override("normal", BLUE_LABEL_STYLEBOX)
			new_hbox.add_child(new_table_cell)
			
	return license_list_vbox


func _on_prop_table_cell_pressed(license_path : String, prop_name : String):
	#self.grab_focus()
	var right_dock_scene_parent := self.get_parent()
	var dock_slot_right : TabContainer
	if right_dock_scene_parent is TabContainer:
		dock_slot_right = right_dock_scene_parent
		var tab_idx := dock_slot_right.get_tab_idx_from_control(self)
		dock_slot_right.current_tab = tab_idx 
	else: # 4.6 upward, with the introduction of EditorDock
		# right_dock_scene_parent is EditorDock
		if right_dock_scene_parent.has_method("make_visible"):
			right_dock_scene_parent.make_visible()
		#dock_slot_right = right_dock_scene_parent.get_parent()


	#for n : Node in dock_slot_right.get_children():
		
	_on_check_parent_folder_license(license_path)
	set_selected_edprop_by_label(prop_name.capitalize()) # currently only works once every refresh



func connect_and_track_signal(obj_and_signal : Signal, callable_to_connect : Callable):
	obj_and_signal.connect(callable_to_connect)
	tracked_signal_callable_pair[obj_and_signal] = callable_to_connect


func _miniinspector_anchor_sizeflag_override(_mini_inspector : ScrollContainer) -> void:
	_mini_inspector.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_mini_inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#mini_inspector.custom_minimum_size.y = self.custom_minimum_size.y + 30.0
	#mini_inspector.size_flags_vertical = SIZE_EXPAND_FILL
	_mini_inspector.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO # unnecessary line
	pass


func _inspectorvbox_anchor_sizeflag_override(_mini_inspector_vbox : VBoxContainer) -> void:
	_mini_inspector_vbox.size_flags_horizontal = SIZE_EXPAND_FILL
	pass

	
func _on_filesystemdock_selectedpath_changed() -> void:
	if inspector_changed_unsaved:
		unsaved_changes_hbox.show()
		return
	# slight delay so that the signal reads the true current file
	await get_tree().create_timer(0.01, true, true, true).timeout
	_refresh_right_scene_dock()


func _on_filesystemdock_folder_moved(old_path: String, new_path: String): # moved or renamed, also works for files i think
	#print("old: %s, new: %s" % [old_path, new_path])
	var db_exist := _check_license_database_exists()
	
	if not db_exist:
		return #@TODO keep in mind to add something here
	
	if not cached_alz_licdb:
		if db_exist:
			cached_alz_licdb = _get_license_database_or_null()
	
	var cleansed_oldpath := _cleanse_dir_path(old_path)
	var cleansed_newpath := _cleanse_dir_path(new_path)
	
	for saved_path : String in cached_alz_licdb.path_license_dict.keys():
		if saved_path.begins_with(cleansed_oldpath):
			var trimmed_rightpart_path := saved_path.trim_prefix(cleansed_oldpath).trim_prefix("/")
			var combined_new_path : String
			if trimmed_rightpart_path.strip_edges().is_empty():
				combined_new_path = cleansed_newpath
			else:
				combined_new_path = cleansed_newpath.path_join(trimmed_rightpart_path)
			#print("combined: %s" % combined_new_path)
			if cached_alz_licdb.path_license_dict.has(saved_path):
				var cached_value = cached_alz_licdb.path_license_dict[saved_path]
				cached_alz_licdb.path_license_dict[combined_new_path] = cached_value
				cached_alz_licdb.path_license_dict.erase(saved_path)
				_save_license_database(cached_alz_licdb)
				print("Alicenzia: Updated the newly renamed path of License data at %s." % combined_new_path)
				if fsd_last_selected_file == saved_path:
					ed_fsd.navigate_to_path(combined_new_path)
					_refresh_right_scene_dock(true)


func _refresh_right_scene_dock(force_refresh := false):
	#var new_current_dir := EditorInterface.get_current_directory()
	var new_current_file := EditorInterface.get_current_path()
	#print("%s | %s" % [new_current_dir, new_current_file])
	
	if new_current_file != fsd_last_selected_file or force_refresh:
		if new_current_file == "Favorites":
			return
		fsd_last_selected_file = new_current_file
		#print("current file: %s" % fsd_last_selected_file)
		current_path_textbox.text = fsd_last_selected_file
		current_path_textbox.animate_current_path_text()
		#construct_license_inspector(fsd_last_selected_file)
		
		empty_pld_ref = PathLicenseData.new() # so far no usage rn
		
		var dir = DirAccess.open(RES_PATH)
		
		var lic_context := ALZLicenseContext.new() # will be used later for checking inherits
		
		if dir.dir_exists(fsd_last_selected_file):
			save_btn.text = "Save Per-Folder License"
			lic_context.path_type = ALZLicenseContext.LicensePathType.FOLDER
		else:
			if dir.file_exists(fsd_last_selected_file):
				save_btn.text = "Save Per-File License"
				lic_context.path_type = ALZLicenseContext.LicensePathType.FILE
			else:
				push_warning("type of path unknown: %s" % fsd_last_selected_file)
		
		var db_cached := false # maybe not useful
		var db_exist := _check_license_database_exists()
		
		if not cached_alz_licdb:
			if db_exist:
				cached_alz_licdb = _get_license_database_or_null()
				db_cached = true
		else:
			db_cached = true
		
		var saved_licdata_found := false
		var lic_dict : Dictionary
		
		var cleansed_path := _cleanse_dir_path(fsd_last_selected_file)
		
		if cached_alz_licdb:
			lic_dict = cached_alz_licdb.path_license_dict
			if lic_dict.has(cleansed_path):
				currently_edited_pld = lic_dict[cleansed_path]
				saved_licdata_found = true
		
		if not saved_licdata_found:
			currently_edited_pld = PathLicenseData.new()
			remove_path_license_btn.hide()
		else:
			remove_path_license_btn.show()
		
		exist_in_lic_db_info.set_text_by_existance(saved_licdata_found)
		
		
		#refill_inspector(temp_pathlicencedata)
		_refill_pathlicensedata_inspector(currently_edited_pld)
		
		# for now, skip if the dir path is res://
		var skip_search := cleansed_path == RES_PATH
		if skip_search:
			return
		
		var next_dir_to_search := cleansed_path.get_base_dir()
		var parent_dir_license := ""
		
		# search for the closest parent per-folder license
		if cached_alz_licdb and not saved_licdata_found:
			var i := 0
			while (next_dir_to_search != RES_PATH):
				#print(next_dir_to_search)
				if lic_dict.has(next_dir_to_search):
					lic_context.license_parent_folder_path = next_dir_to_search
					var parent_dir_pld : PathLicenseData = lic_dict[next_dir_to_search]
					parent_dir_license = parent_dir_pld.license_type
					lic_context.license_parent_folder_name = next_dir_to_search.get_slice(
																"/",
																next_dir_to_search.get_slice_count("/") - 1
															)
					break
				next_dir_to_search = _cleanse_dir_path(next_dir_to_search).get_base_dir()
		
		lic_context.current_fsd_path = cleansed_path
		
		if saved_licdata_found:
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.SELF_ASSIGNED
			lic_context.license_name = currently_edited_pld.license_type
		elif not parent_dir_license.is_empty():
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_CLOSEST_PARENT_FOLDER
			lic_context.license_name = parent_dir_license
		elif is_pwl_exist():
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_PROJECT_WIDE
			lic_context.license_name = _get_license_database_or_null().project_wide_license.license
		else:
			lic_context.inherit_type = ALZLicenseContext.LicenseInheritType.INHERIT_NONE
		
		lic_inherit_info.set_text_by_license_context(lic_context)
		
		#list_licenses_on_rows()
		_list_license_and_refresh_table()  #TODO mungkin baiknya kalo force update aja
		_check_for_bottom_tools()

#func construct_license_inspector(fsd_last_selected_file): # wtf what does this one do?
	#pass


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		
		for cd: ConfirmationDialog in \
		[pwl_dialog, add_new_string_enum_dialog, confirm_remove_path_lic_dialog]:
			if cd:
				cd.hide()
		
		if mini_inspector:
			var inspector_parent := mini_inspector.get_parent()
			if inspector_parent:
				mini_inspector.get_parent().remove_child(mini_inspector)
			mini_inspector.queue_free()
		if fsd_tree:
			if fsd_tree.cell_selected.is_connected(_on_filesystemdock_selectedpath_changed):
				fsd_tree.cell_selected.disconnect(_on_filesystemdock_selectedpath_changed)
		
		for np : NodePath in ["%UnsavedChangesWarningIcon", "%NoPWLWarnIcon"]:
			var n : TextureRect = get_node_or_null(np)
			if n != null:
				n.texture = null

		pwl_dialog.hide()
		
		#print(tracked_signal_callable_pair)
		for s : Signal in tracked_signal_callable_pair.keys():
			var callable : Callable = tracked_signal_callable_pair[s]
			if s.is_connected(callable):
				s.disconnect(callable)
		
		tracked_signal_callable_pair.clear()


func _on_init_pwl_btn_pressed() -> void:
	if not pwl_dialog.visible:
		pwl_dialog.show()


func _on_project_wide_license_dialog_new_pwl_saved() -> void:
	%NoProjectLicenseWarn.hide()


func _check_license_database_exists() -> bool:
	var dir = DirAccess.open(RES_PATH)
	return dir.file_exists(LICENSE_DATABASE_SAVE_PATH)


func _get_license_database_or_null() -> ALZProjectLicenseDatabase:
	var alz_licdb : ALZProjectLicenseDatabase
	 
	if _check_license_database_exists():
		#print("licensedb does exist")
		alz_licdb = ResourceLoader.load(
										LICENSE_DATABASE_SAVE_PATH,
										"",
										ResourceLoader.CACHE_MODE_REPLACE)
										
		alz_licdb.set_plds_from_json(_get_pld_json())
			
		return alz_licdb
	else:
		#alz_licdb = ALZProjectLicenseDatabase.new()
		return null


func _get_pld_json() -> String:
	if not FileAccess.file_exists(LICENSE_PLD_SAVE_PATH):
		return ""
	var json_file = FileAccess.open(LICENSE_PLD_SAVE_PATH, FileAccess.READ)
	var json_text = json_file.get_as_text()
	return json_text
	

func _save_license_database(alz_licdb : ALZProjectLicenseDatabase) -> int:
	var err := ResourceSaver.save(alz_licdb, LICENSE_DATABASE_SAVE_PATH)
	var file = FileAccess.open(LICENSE_PLD_SAVE_PATH, FileAccess.WRITE)
	file.store_string(alz_licdb.get_data_as_string_json())
	#print("db updated")
	cached_alz_licdb = alz_licdb # also refresh cache
	return err
	

func _cleanse_dir_path(dir_path : String) -> String:
	if dir_path == RES_PATH:
		return dir_path
	return dir_path.strip_edges().trim_suffix("/")
	

#@TODO add editor toast
func _on_save_path_license_btn_pressed() -> void:
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	# fill the path license dict with the path as key and the license data as the value
	alz_licdb.path_license_dict.set(
		_cleanse_dir_path(fsd_last_selected_file), currently_edited_pld)
	
	_save_license_database(alz_licdb)
	exist_in_lic_db_info.set_text_by_existance(true)
	
	#lic_inherit_info.set_text_by_license_status(
		#PathLicenseStatus.SELF_ASSIGNED, temp_pathlicencedata.license_type
	#)
	inspector_changed_unsaved = false
	discard_changes_btn.hide()
	save_btn.disabled = true
	unsaved_changes_hbox.hide()
	_refresh_right_scene_dock(true)


func on_scan_result_save(scanned_licenses : Array[Dictionary]): # called from main scene via signal
	#TODO update the table on main scene
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	for scanned_license_dict in scanned_licenses:
		var pld_path : String = scanned_license_dict["license_parentdir_path"] # addon directory
		if alz_licdb.path_license_dict.has(pld_path):
			push_warning("Alicenzia: License data for %s already found on the database. For data integrity reason it won't be added by the license scanner." % pld_path)
		else:
			var new_pld := PathLicenseData.new()
			new_pld.name = scanned_license_dict["name"]
			new_pld.type = scanned_license_dict["type"]
			new_pld.license_type = scanned_license_dict["license"]
			new_pld.creator = scanned_license_dict["copyright_owner"]
			if scanned_license_dict["full_license_text"]:
				new_pld.full_license_text = scanned_license_dict["full_license_text"]
			
			alz_licdb.path_license_dict.set(pld_path, new_pld)
			print("License data of %s at %s added to the database via the scan tool." % [new_pld.name, pld_path])
	
	_save_license_database(alz_licdb)
	_refresh_right_scene_dock(true)


func is_pwl_exist() -> bool :
	var alz_licdb = _get_license_database_or_null()
	if alz_licdb:
		if alz_licdb.project_wide_license:
			return true
	return false


func _on_project_wide_license_dialog_confirmed() -> void:
	var new_pwl = ALZProjectWideLicense.new(
		pwl_dialog.get_owner_text(),
		pwl_dialog.get_license_text()
	)
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	alz_licdb.project_name = ProjectSettings.get("application/config/name")
	alz_licdb.project_wide_license = new_pwl
	_save_license_database(alz_licdb)
	%NoProjectLicenseWarn.visible = false
	_refresh_right_scene_dock(true)


func _on_stringenumdropdown_addmore_btn_pressed(button_ref : Button, res_ref : Resource, prop_name_ref : String) -> void: # override
	%AddNewStringEnumDialog.show_and_setup(res_ref, prop_name_ref)


func _on_add_new_string_enum_dialog_confirmed() -> void:
	var updated_licdb : ALZProjectLicenseDatabase = %AddNewStringEnumDialog.assign_new_prop_option_to_res(
		_get_license_database_or_null()
	)
	if updated_licdb:
		_save_license_database(updated_licdb)
	#%AddNewStringEnumDialog.update_resdefault_changes()
	var updated_res : Resource = %AddNewStringEnumDialog.get_cached_edited_res()
	_refill_pathlicensedata_inspector(updated_res)


func _on_attempt_remove_hint_from_param(hint_to_remove : String) -> void:
	var updated_licdb : ALZProjectLicenseDatabase = %AddNewStringEnumDialog.remove_selected_hint_on_cached_res(
		hint_to_remove, _get_license_database_or_null()
	)
	if updated_licdb:
		_save_license_database(updated_licdb)
	
	await %AddNewStringEnumDialog.refresh_after_remove_hint()
	
	var updated_res : Resource = %AddNewStringEnumDialog.get_cached_edited_res()
	_refill_pathlicensedata_inspector(updated_res)


func _refill_pathlicensedata_inspector(pld_res : PathLicenseData) -> void:
	# check and update the type hints first
	var alz_licdb := _get_license_database_or_null()
	if alz_licdb:
		var sdc := alz_licdb.get_saved_default_changes_or_null("PathLicenseData")
		if sdc:
			for propname : String in sdc.propname_savedvalue_pairs.keys():
				var new_value = sdc.propname_savedvalue_pairs[propname]
				pld_res.set(propname, new_value)
				
	refill_inspector(pld_res)


func _on_discard_changes_btn_pressed() -> void:
	inspector_changed_unsaved = false
	unsaved_changes_hbox.hide()
	discard_changes_btn.hide()
	save_btn.disabled = true
	_refresh_right_scene_dock(true)


func _on_remove_path_license_btn_pressed() -> void:
	confirm_remove_path_lic_dialog.show_and_fill_path_info(
		_cleanse_dir_path(fsd_last_selected_file)
	)


func _on_confirm_remove_path_lic_dialog_confirmed() -> void:
	
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		return
	
	var cleansed_path := _cleanse_dir_path(fsd_last_selected_file)
	var _erase_successful := alz_licdb.path_license_dict.erase(cleansed_path)
	
	_save_license_database(alz_licdb)
	discard_changes_btn.hide()
	
	ed_toast.push_toast("Alicenzia: License data at %s successfully removed." % fsd_last_selected_file, EditorToaster.SEVERITY_INFO)
	_refresh_right_scene_dock(true)


func _on_check_parent_folder_license(res_path: String) -> void:
	var dir = DirAccess.open(RES_PATH)
	if not (dir.file_exists(res_path) or dir.dir_exists(res_path)):
		return
	ed_fsd.navigate_to_path(res_path)
	_refresh_right_scene_dock(true)


func on_show_export_license_dialog(): # called from main scene
	export_license_dialog.show()


func _find_pld_with_this_name(lic_name : String, alz_licdb : ALZProjectLicenseDatabase) -> PathLicenseData:
	for license_path : String in alz_licdb.path_license_dict:
		var pld : PathLicenseData = alz_licdb.path_license_dict[license_path]
		if lic_name == pld.name:
			return pld
	
	return PathLicenseData.new()


func generate_license_template(format: String, template: String) -> String:
	var final_text := ""
	
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	match(template):
		"Chrome-like": # name, website link, full license
			var i := 0
			for pld : PathLicenseData in alz_licdb.path_license_dict.values():
			
				if i >= 1:
					final_text += "\n———\n\n" # line to separate
					
				final_text += pld.name + "\n"
				if pld.webpage_link:
					final_text += pld.webpage_link + "\n"
				if pld.full_license_text:
					final_text += "\n%s\n" % pld.full_license_text
				else:
					if pld.creator:
						final_text += "by %s\n" % pld.creator

				i += 1
		"hdoc-like":
			# needs to be sorted first
			var license_name_path_dict : Dictionary[String, String]
			for license_path : String in alz_licdb.path_license_dict:
				var pld : PathLicenseData = alz_licdb.path_license_dict[license_path]
				license_name_path_dict[pld.name] = license_path
				
			var license_names_sorted := license_name_path_dict.keys()
			license_names_sorted.sort()
			
			final_text = "%s relies on several open source software projects. We thank all of the contributors to these projects for their work. These are listed below in alphabetical order:\n\n" % alz_licdb.project_name
			
			for lic_name : String in license_names_sorted:
				final_text += "- %s" % lic_name
				var pld := _find_pld_with_this_name(lic_name, alz_licdb)
				if pld.full_license_text.is_empty() and pld.webpage_link.is_empty() and pld.creator:
					final_text += " (by %s)" % pld.creator
				if pld.webpage_link:
					final_text += " (%s)" % pld.webpage_link
				final_text += "\n"
			
			final_text += "\nTheir licenses are reproduced below.\n\n"
			
			for lic_name : String in license_names_sorted:
				var pld := _find_pld_with_this_name(lic_name, alz_licdb)
				if pld.full_license_text:
					final_text += "———\n%s license\n\n" % lic_name
					final_text += "%s\n\n" % pld.full_license_text
			#var pl_dict_sorted : Dictionary[String, PathLicenseData]
			#
			#for license_name : String in license_names_sorted:
				#for license_path : String in alz_licdb.path_license_dict:
					#var pld : PathLicenseData = alz_licdb.path_license_dict[license_path]
					#if license_name == pld.name:
						#pass
			
	return final_text


func _on_export_license_dialog_make_example_template(format: String, template: String) -> void:
	var template_text := generate_license_template(format, template)
	template_text_area.text = template_text
	example_template_dialog.title = "Attribution text with %s template" % template
	example_template_dialog.show()


func _on_export_license_dialog_export_license(format: String, template: String) -> void:
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
		
	save_template_dialog.current_file = "%s_LICENSE.txt" % alz_licdb.project_name
	save_template_dialog.show()


func _on_save_template_dialog_file_selected(path: String) -> void:
	var alz_licdb := _get_license_database_or_null()
	if not alz_licdb:
		alz_licdb = ALZProjectLicenseDatabase.new()
	
	var ft : Array[String]= export_license_dialog.get_format_and_template()
	var template_text := generate_license_template(ft[0], ft[1])
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(template_text)
	file.close()
	#save_template_dialog.hide()
	export_license_dialog.hide()
	ed_toast.push_toast("Alicenzia: License data successfully exported at %s." % path, EditorToaster.SEVERITY_INFO)
	ed_efs.scan()


func _prop_changed_override(prop : String, value : Variant) -> void:
	#prints(prop,value)
	if currently_edited_pld.full_license_text.is_empty():
		match prop:
			"license_type":
				autofill_from_template_btn.hide()
				if value in license_text_with_templates:
					autofill_from_template_btn.show()
			"license_text_path":
				copy_from_license_path_btn.hide()
				if value != "":
					#copy_from_license_path_btn.show() #TODO not implemented, not important for now
					pass


func _hide_all_bottom_tools():
	copy_from_license_path_btn.hide()
	autofill_from_template_btn.hide()


func _check_for_bottom_tools():
	_hide_all_bottom_tools()
	if currently_edited_pld.full_license_text.is_empty():
		if currently_edited_pld.license_type in license_text_with_templates:
			autofill_from_template_btn.show()
		if not currently_edited_pld.license_text_path.is_empty():
			#copy_from_license_path_btn.show() #TODO ditto
			pass


func _on_autofill_from_template_btn_pressed() -> void:
	autofill_license_from_template_dialog.show()
	autofill_license_from_template_dialog.fill_data(currently_edited_pld.license_type, currently_edited_pld.creator)


#region this was written very uglily. i'm tired
func _on_autofill_license_preview_btn_pressed() -> void:
	var preview_license_text = _fill_preview_license()
	
	full_license_preview_text_area.text = preview_license_text
	full_license_preview_dialog.title = "%s Full License Text of %s" % \
										[autofill_license_from_template_dialog.chosen_license_type,
										currently_edited_pld.name]
	full_license_preview_dialog.show()


func _fill_preview_license() -> String:
	autofill_license_from_template_dialog.set_typed_data()
	
	var preview_license_text := ""
	
	var license_template_filename : String = autofill_license_from_template_dialog.chosen_license_type + ".txt"
	var license_template_path := LICENSE_TEXT_TEMPLATES_PATH.path_join(license_template_filename)
	
	if FileAccess.file_exists(license_template_path):
		preview_license_text = FileAccess.get_file_as_string(license_template_path)
	
	preview_license_text = preview_license_text.replacen("<year>", str(autofill_license_from_template_dialog.chosen_year))
	preview_license_text = preview_license_text.replacen("<COPYRIGHT HOLDER>", autofill_license_from_template_dialog.chosen_owner)

	autofill_license_from_template_dialog.preview_license_text = preview_license_text
	
	return preview_license_text


func _on_autofill_license_from_template_dialog_confirmed() -> void:
	autofill_license_from_template_dialog.hide()
	var preview_license_text = _fill_preview_license()
	currently_edited_pld.full_license_text = preview_license_text
	_refill_pathlicensedata_inspector(currently_edited_pld)
	_on_licensedata_property_changed()
	_check_for_bottom_tools()

#endregion


func _on_view_guide_btn_pressed() -> void:
	view_guide_from_right_dock.emit()
