@tool
extends ConfirmationDialog

#signal new_pwl_saved
#
#const NEW_PWL_SAVE_PATH := "res://project_wide_lisence.tres"

@onready var owner_pn_d: HBoxContainer = %OwnerPnD
@onready var license_pn_o: HBoxContainer = %LicensePnO

var ok_btn : Button


func _addon_init() -> void:
	var pld_ref := PathLicenseData.new() 
	var license_options : PackedStringArray = pld_ref.license_type_hint.split(",", false) # maybe turn it into static var next time
	#print(license_options)
	license_pn_o.refill_options(license_options)
	license_pn_o.set_selected_option("All Rights Reserved")


func _ready() -> void:
	ok_btn = get_ok_button()
	ok_btn.disabled = true
	#%LicensePnO.options = Array(license_options)


func _on_param_and_data_text_changed(new_text : String) -> void:
	ok_btn.disabled = new_text.is_empty()


func get_owner_text() -> String:
	return owner_pn_d.get_value()
	
	
func get_license_text() -> String:
	return license_pn_o.get_value()
