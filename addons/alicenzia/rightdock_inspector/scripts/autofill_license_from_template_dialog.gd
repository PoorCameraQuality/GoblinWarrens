@tool
extends ConfirmationDialog

@onready var license_type_label: Label = %LicenseTypeLabel
@onready var owner_pn_d: HBoxContainer = %OwnerPnD
@onready var copyright_year_pn_d: HBoxContainer = %CopyrightYearPnD

var preview_full_license_text : String = ""
var chosen_license_type : String = ""
var chosen_owner := ""
var chosen_year := 2026
var preview_license_text := ""


#TODO protection for empty fillings
func fill_data(license_type : String, creator : String):
	chosen_license_type = license_type
	license_type_label.text = "Chosen License : %s" % license_type
	owner_pn_d.set_value(creator)
	copyright_year_pn_d.set_value(str(Time.get_date_dict_from_system()["year"]))


func set_typed_data():
	chosen_owner = owner_pn_d.get_value()
	chosen_year = int(copyright_year_pn_d.get_value()) #TODO need protection


func _on_preview_license_btn_pressed() -> void:
	pass # Replace with function body.


func _create_license_from_type():
	pass
