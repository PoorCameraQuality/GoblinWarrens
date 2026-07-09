@tool
extends ConfirmationDialog

signal attempt_remove_hint_from_param(singular_hint: String)
#signal update_db_after_remove_hint_done

@onready var main_vbox: VBoxContainer = $MainVbox
@onready var list_label: Label = %ListLabel
@onready var enum_hint_list: ItemList = %EnumHintList
@onready var new_item_pn_d: HBoxContainer = %NewItemPnD

@onready var remove_selected_opt_btn: Button = %RemoveSelectedOptBtn
@onready var remove_confirm_label: Label = %RemoveConfirmLabel
@onready var remove_confirm_vbox: VBoxContainer = %RemoveConfirmVbox

var ok_btn : Button
var new_item_lineedit : LineEdit

# this cache system is flawed if used incorrectly :(
var edited_res_cache : Resource
var edited_param_cache : String
var param_options_cache : PackedStringArray
var typehint_varname_cache : String
var new_typehint_cache : String
var currently_selected_paramhint_on_list := ""

#INFO during development, there are changes on how i refere param options, hints, etc


func _ready() -> void:
	_hide_remconfirmvbox_and_update_window_height()
	ok_btn = get_ok_button()
	ok_btn.disabled = true
	new_item_lineedit = new_item_pn_d.get_lineedit_node()
	
	new_item_lineedit.text_changed.connect(func(new_item_text : String):
		if (new_item_text.is_empty() or (new_item_text in param_options_cache) or ("," in new_item_text)):
			ok_btn.disabled = true
		else:
			ok_btn.disabled = false
	)


func show_and_setup(res_to_edit : Resource, param_to_addnewoption : String) -> void:
	#_setup_panel_theme()
	$PanelThemer.replace_panel_themes()
	
	new_item_lineedit.text = ""
	enum_hint_list.clear()
	
	# in theory the resource in question should always be PathLicenseData?
	if not res_to_edit.has_method("get_enum_hint_pair"):
		push_warning("resource don't have enum hint pair")
		return
	
	edited_res_cache = res_to_edit
	edited_param_cache = param_to_addnewoption
	
	var var_hint_pair : Dictionary[String, String] = res_to_edit.get_enum_hint_pair()
	if param_to_addnewoption in var_hint_pair.keys():
		var param_options_str := var_hint_pair[param_to_addnewoption]
		param_options_cache = param_options_str.split(",", false) # maybe turn it into static var next time
		#print(param_options_cache)
		for opt : String in param_options_cache:
			enum_hint_list.add_item(opt)
	
	var cap_paramname := param_to_addnewoption.capitalize()
	title = 'Edit "%s" Option List' % cap_paramname
	list_label.text = "List of current options for %s:" % cap_paramname
	new_item_pn_d.param_name = "New %s" % cap_paramname
	self.show()
	new_item_lineedit.grab_focus()


func assign_new_prop_option_to_res(alz_licdb : ALZProjectLicenseDatabase = null) -> ALZProjectLicenseDatabase:
	var new_propoption := new_item_lineedit.text
	
	if edited_res_cache.has_method("get_enum_hint_pair"):
		var res_enum_name_pair : Dictionary[String,String] = edited_res_cache.get_enum_hint_name_pair()
		if edited_param_cache in res_enum_name_pair.keys():
			var type_hint_varname : String = res_enum_name_pair[edited_param_cache]
			#var old_type_hint := edited_res_cache.get(type_hint_varname)
			var new_propoption_list := param_options_cache.duplicate() # duplicate packedstringarray
			new_propoption_list.append(new_propoption)
			new_propoption_list.sort()
			var new_type_hint := ",".join(new_propoption_list)
			#print(new_type_hint)
			edited_res_cache.set(type_hint_varname, new_type_hint)
			
			if alz_licdb:
				var existing_refdefchange := _get_existing_refdefchange_from_db(alz_licdb)
				existing_refdefchange.propname_savedvalue_pairs[type_hint_varname] = new_type_hint
		
	edited_res_cache.set(edited_param_cache, new_propoption)
	#return edited_res_cache
	return alz_licdb


func remove_selected_hint_on_cached_res(
hint_to_remove := "",
alz_licdb : ALZProjectLicenseDatabase = null
) -> ALZProjectLicenseDatabase:
	
	if edited_res_cache.has_method("get_enum_hint_pair"):
		var res_enum_name_pair : Dictionary[String,String] = edited_res_cache.get_enum_hint_name_pair()
		if edited_param_cache in res_enum_name_pair.keys():
			var type_hint_varname : String = res_enum_name_pair[edited_param_cache]
			var new_propoption_list : Array = Array(param_options_cache.duplicate()) # duplicate packedstringarray
			new_propoption_list.erase(hint_to_remove)
			var new_type_hint := ",".join(new_propoption_list)
			edited_res_cache.set(type_hint_varname, new_type_hint)
			
			if alz_licdb:
				var existing_refdefchange := _get_existing_refdefchange_from_db(alz_licdb)
				existing_refdefchange.propname_savedvalue_pairs[type_hint_varname] = new_type_hint

	return alz_licdb


func _get_existing_refdefchange_from_db(alz_licdb : ALZProjectLicenseDatabase) -> ALZResDefaultsChanges:
	var existing_refdefchange : ALZResDefaultsChanges
	var edited_res_script_globalname : String = edited_res_cache.get_script().get_global_name()
	for refdefchange : ALZResDefaultsChanges in alz_licdb.saved_default_changes:
		if refdefchange.res_script_globalname == edited_res_script_globalname:
			existing_refdefchange = refdefchange
			break
	
	if not existing_refdefchange:
		existing_refdefchange = ALZResDefaultsChanges.new()
		existing_refdefchange.res_script_globalname = edited_res_script_globalname
		alz_licdb.saved_default_changes.append(existing_refdefchange)
	
	return existing_refdefchange


func refresh_after_remove_hint() -> bool:
	show_and_setup(edited_res_cache, edited_param_cache)
	return true


# Currently does not have a check if this the old or the one with the new typehint added
func get_cached_edited_res() -> Resource:
	return edited_res_cache


func _on_enum_hint_list_item_selected(index: int) -> void:
	if not remove_confirm_vbox.visible:
		remove_selected_opt_btn.disabled = false
	
	currently_selected_paramhint_on_list = enum_hint_list.get_item_text(index)
	remove_confirm_label.text = "Are you sure you want to remove %s from %s options?" % [
		currently_selected_paramhint_on_list, edited_param_cache.capitalize()
	]


func _on_remove_selected_custom_opt_btn_pressed() -> void:
	remove_selected_opt_btn.disabled = true
	remove_confirm_vbox.show()


func _on_remove_opt_cancel_btn_pressed() -> void:
	remove_selected_opt_btn.disabled = true
	_hide_remconfirmvbox_and_update_window_height()


func _on_remove_opt_confirm_btn_pressed() -> void:
	attempt_remove_hint_from_param.emit(currently_selected_paramhint_on_list)
	currently_selected_paramhint_on_list = ""
	remove_selected_opt_btn.disabled = true
	_hide_remconfirmvbox_and_update_window_height()


func _hide_remconfirmvbox_and_update_window_height():
	remove_confirm_vbox.hide()
	self.size.y = roundi(main_vbox.get_combined_minimum_size().y)
