@tool
extends VBoxContainer

signal check_parent_folder_license(path : String)

#enum PathLicenseStatus {
	#INHERIT_NONE, INHERIT_PROJECT_WIDE,
	#INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
#}

#@export var panels_to_theme : Array[PanelContainer]

@onready var info_icon: TextureRect = %InfoIcon
@onready var inherit_info: RichTextLabel = %InheritInfo
@onready var folder_info_panel: PanelContainer = %FolderInfoPanel
@onready var folder_info: RichTextLabel = %FolderInfo

var panel_themer: Node
var cached_license_parent_folder_path := ""


func _addon_init() -> void:
	panel_themer = $PanelThemer
	_cleanse_theme()
	panel_themer.replace_panel_themes()


# func set_text_by_license_status(licstatus : PathLicenseStatus, lic_name : String):
func set_text_by_license_context(lic_context : ALZLicenseContext):
	show()
	cached_license_parent_folder_path = ""
	info_icon.texture = get_theme_icon("NodeInfo", "EditorIcons")
	folder_info_panel.hide()
	match (lic_context.inherit_type):
		ALZLicenseContext.LicenseInheritType.INHERIT_NONE:
			hide()
		ALZLicenseContext.LicenseInheritType.INHERIT_PROJECT_WIDE:
			inherit_info.text = "Without a path-specific license, this file [b]inherits[/b] the [b]project-wide[/b] %s." % lic_context.license_name
		ALZLicenseContext.LicenseInheritType.INHERIT_CLOSEST_PARENT_FOLDER:
			inherit_info.text = "Without a path-specific license, this file [b]inherits[/b] the [b]parent folder's[/b] %s." % lic_context.license_name #
			folder_info.text = "License inherited from the [b]%s[/b] folder" % lic_context.license_parent_folder_name
			cached_license_parent_folder_path = lic_context.license_parent_folder_path
			folder_info_panel.show()
		ALZLicenseContext.LicenseInheritType.SELF_ASSIGNED:
			hide()
	#if licdata_exists:
		#label.text = "License data for this path found on the database and loaded."
		#
	#else:
		#label.text = 	"This path has no license data saved in the database. " + \
						#"Create new one by filling the fields below and save."


func _on_check_license_btn_pressed() -> void:
	check_parent_folder_license.emit(cached_license_parent_folder_path)
	

func _cleanse_theme():
	panel_themer.cleanse_panel_themes()
	info_icon.texture = null


func _exit_tree() -> void:
	info_icon.texture = null
