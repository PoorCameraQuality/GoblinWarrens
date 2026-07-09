@tool
extends ConfirmationDialog

signal export_license(format : String, template : String)
signal make_example_template(format : String, template : String)

@onready var export_format_pn_o: HBoxContainer = %ExportFormatPnO
@onready var export_template_pn_o: HBoxContainer = %ExportTemplatePnO
@onready var view_example_btn: Button = %ViewExampleBtn


func _on_confirmed() -> void:
	var ft := get_format_and_template()
	export_license.emit(ft[0], ft[1])


func get_format_and_template() -> Array[String]:
	var format_and_template : Array[String]
	
	var _format : String = export_format_pn_o.get_value()
	format_and_template.append(_format)
	var _template : String = export_template_pn_o.get_value()
	format_and_template.append(_template)
	
	return format_and_template


func _on_view_example_btn_pressed() -> void:
	var ft := get_format_and_template()
	make_example_template.emit(ft[0], ft[1])


func _update_view_example_text():
	if export_format_pn_o: # prevent triggering on startup
		view_example_btn.text = "View Example of %s" % export_template_pn_o.get_value()
	
func _on_export_template_pn_o_selected_item_changed(item_name: String) -> void:
	_update_view_example_text()


func _on_visibility_changed() -> void:
	_update_view_example_text()
