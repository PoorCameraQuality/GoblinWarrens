@tool
extends VBoxContainer

signal addon_refresh # addon
signal save_selected_scanned_licenses(selected_licenses : Array[Dictionary])
signal show_export_license_dialog
signal view_guide_from_main_scene
#signal data_button_expand_request(idx : int, expand_yes : bool)

#const ASSET_DATA_ROW : PackedScene = preload("uid://dagdcisuqdljk")

const RES_PATH := "res://"

@export var prepare_data_rows_on_start := true

@onready var file_digger: Node = $RecursiveFileDigger
@onready var assets_table: VBoxContainer = %AssetsTable
@onready var expanded_box: VBoxContainer = %ExpandedBox
@onready var scan_license_dialog: ConfirmationDialog = %ScanLicenseDialog
@onready var scan_result_dialog: ConfirmationDialog = %ScanResultDialog
@onready var full_license_text_area: TextEdit = %FullLicenseTextArea
@onready var full_license_dialog: AcceptDialog = %FullLicenseDialog


func _ready() -> void:
	if not Engine.is_editor_hint():
		_addon_init()
		expanded_box._ready()


func _addon_init():
	pass
	#data_button_expand_request.connect(_on_data_button_expand_request)
	
	#assets_table.clear_row()
	#if prepare_data_rows_on_start:
		#var path_data : PackedStringArray = file_digger.start_walk_dir("res://")
		##print(path_data)
		#for path : String in path_data:
			#assets_table.add_data_row(path)
			
			#	func(idx, expand_yes): data_button_expand_request.emit(idx, expand_yes))
	#export_license_dialog.export_license.connect(_on_export_license)


func _on_refresh_addon_btn_pressed() -> void:
	print("---")
	addon_refresh.emit()


func _on_refresh_table_btn_pressed() -> void:
	#%AssetsTable.refresh()
	pass


func on_refresh_license_table(vbox : VBoxContainer): # called from main script
	#print(vbox.is_inside_tree())
	if assets_table:
		var table_parent := assets_table.get_parent()
		assets_table.queue_free()
		#vbox.get_parent().remove_child(vbox)
		table_parent.add_child(vbox)
		assets_table = vbox


func _on_scan_license_btn_pressed() -> void:
	scan_license_dialog.show_and_update()


func _on_scan_license_dialog_confirmed() -> void:
	#print("begin scan!")
	scan_license_dialog.show_scan_progress()
	await get_tree().create_timer(0.1).timeout # artificial timer to show the progess UI
	var time_before_scan := Time.get_ticks_usec()
	var path_license_data_array : Array = scan_license_dialog.begin_scan()
	var time_after_scan := Time.get_ticks_usec()
	var scan_duration_in_seconds := float(time_after_scan - time_before_scan) / 1000000.0
	print("Alicenzia: Scan duration took %f seconds." % scan_duration_in_seconds)
	scan_license_dialog.hide()
	
	var license_rows : Array[Control] = scan_result_dialog.build_rows(path_license_data_array)
	for row in license_rows:
		row.show_license.connect(_on_scanned_license_row_full_lic_pressed)
	
	scan_result_dialog.show_and_adjust()


func _on_scanned_license_row_full_lic_pressed(thisrow_license_data):
	#var data : Dictionary = scan_result_row.thisrow_license_data
	var license_respath = thisrow_license_data["license_path"]
	print(license_respath) # why, idk forgot
	full_license_text_area.text = ""
	full_license_dialog.title = ""
	if thisrow_license_data["full_license_text"]:
		full_license_text_area.text = thisrow_license_data["full_license_text"]
		full_license_dialog.title = "Full license text of %s" % thisrow_license_data["name"]
		full_license_dialog.show()


func _on_scan_result_dialog_confirmed() -> void:
	var confirmed_licenses : Array[Dictionary] = scan_result_dialog.get_confirmed_licenses()
	#print(str(confirmed_licenses))
	save_selected_scanned_licenses.emit(confirmed_licenses)


func _on_export_license_pressed() -> void:
	show_export_license_dialog.emit()


func _on_view_guide_btn_pressed() -> void:
	view_guide_from_main_scene.emit()
