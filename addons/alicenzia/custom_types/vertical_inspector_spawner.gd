@tool
class_name VerticalInspectorSpawner extends Control

signal property_changed

const INTERNAL_RESOURCE_PROP_NAMES := \
	["resource_local_to_scene", "resource_name", "metadata/_custom_type_script"]

const TITLE_IDENTIFIER_CONSTNAME := "title_identifier"
const COVER_IDENTIFIER_CONSTNAME := "cover_identifier"

#@onready var song_title_label: Label = %SongTitleLabel
var inspector_below_here: Node

var propname_edprop_map : Dictionary[String, EditorProperty]
var mini_inspector : EditorInspector
var mini_inspector_hbox : HBoxContainer
var prop_title_varname : String
var prop_cover_varname : String

var res_to_edit_ref : Resource
var res_array_ref : Array

func _miniinspector_anchor_sizeflag_override(_mini_inspector : ScrollContainer) -> void:
	#set_anchors_and_offsets_preset, size_flags_horizontal, custom_minimum_size
	pass

func _inspectorvbox_anchor_sizeflag_override(_mini_inspector_vbox : HBoxContainer) -> void:
	# size_flags_horizontal, custom_minimum_size
	pass

func _skip_if_true_override(res_to_edit : Resource, prop_dict : Dictionary) -> bool:
	#if
		#return true
		
	return false

func _propname_matchcase_override(res_to_edit : Resource, prop_name : String) -> void:
	match prop_name:
		_:
			pass

func _after_init_override() -> void:
	#mini_inspector.hide()
	pass

func _prop_changed_override(prop : String, value : Variant) -> void:
	pass

func instantiate_inspector(res_to_edit : Resource = null, res_array := Array()) -> void:
	if Engine.is_editor_hint():
		res_array_ref = res_array
		#res_to_edit_ref = res_to_edit
		
		mini_inspector = EditorInspector.new()
		_miniinspector_anchor_sizeflag_override(mini_inspector)
		#mini_inspector.size_flags_vertical = SIZE_EXPAND_FILL
		
		mini_inspector.draw_focus_border = false
		mini_inspector.focus_exited.connect(_on_mini_inspector_focus_exited)
		
		assert(inspector_below_here, "make sure to override inspector_below_here on ready")
		inspector_below_here.add_sibling(mini_inspector)
		
		mini_inspector_hbox = HBoxContainer.new()
		mini_inspector_hbox.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		mini_inspector_hbox.size_flags_vertical = SIZE_EXPAND_FILL
		_inspectorvbox_anchor_sizeflag_override(mini_inspector_hbox)
		mini_inspector.add_child(mini_inspector_hbox)
		
		if res_to_edit != null:
			refill_inspector(res_to_edit)
		
		_after_init_override()
		#return mini_inspector # mini_inspector_vbox


func refill_inspector(res_to_edit : Resource) -> void:
	if Engine.is_editor_hint():
		if mini_inspector_hbox.get_child_count() > 0:
			for child : Node in mini_inspector_hbox.get_children():
				child.queue_free()
		
		res_to_edit_ref = res_to_edit
		
		var data_dict_list : Array[Dictionary]
		for prop_dict : Dictionary in res_to_edit.get_property_list():
			# custom exported variables
			#print("name : %s | usage : %s" % [prop_dict["name"], prop_dict["usage"]])
			if prop_dict["usage"] in [6, 4102, 65536 + 6] and (prop_dict["name"] not in INTERNAL_RESOURCE_PROP_NAMES):
				#print(prop_dict)
				if _skip_if_true_override(res_to_edit, prop_dict):
					continue
				data_dict_list.append(prop_dict)
			elif prop_dict["name"] == 'script' and prop_dict["class_name"] == 'Script':
				var res_script : Script = res_to_edit.get(prop_dict["name"])
				var res_class_name = res_script.get_global_name()
				var script_const_map := res_script.get_script_constant_map()
				if TITLE_IDENTIFIER_CONSTNAME in script_const_map:
					# the variable name that's responsible to the song name
					prop_title_varname = res_script[TITLE_IDENTIFIER_CONSTNAME]
				if COVER_IDENTIFIER_CONSTNAME in script_const_map:
					prop_cover_varname = res_script[COVER_IDENTIFIER_CONSTNAME]
		
		var var_hint_pair : Dictionary[String,String]
		if res_to_edit.has_method("get_enum_hint_pair"):
			var_hint_pair = res_to_edit.get_enum_hint_pair()
		
		for data_prop_dict : Dictionary in data_dict_list:
			#print(data_prop_dict)
			var prop_name : String = data_prop_dict["name"]
			
			_propname_matchcase_override(res_to_edit, prop_name)
			
			var prop_editor : EditorProperty
			
			if var_hint_pair and (prop_name in var_hint_pair.keys()):
				prop_editor  = EditorInspector.instantiate_property_editor(
					res_to_edit,
					data_prop_dict["type"],
					prop_name,
					PROPERTY_HINT_ENUM,
					var_hint_pair[prop_name],
					data_prop_dict["usage"]
				)
				#@INFO new things on this vertical stuff
				prop_editor.name_split_ratio = 1.0
				
				var new_hbox = HBoxContainer.new()
				var new_btn = Button.new()
				new_btn.pressed.connect(_on_stringenumdropdown_addmore_btn_pressed.bind(new_btn, res_to_edit, prop_name))
				new_hbox.add_child(prop_editor)
				new_hbox.add_child(new_btn)
				new_btn.text = "+"
				prop_editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				mini_inspector_hbox.add_child(new_hbox)
				
			else:
				prop_editor  = EditorInspector.instantiate_property_editor(
					res_to_edit,
					data_prop_dict["type"],
					prop_name,
					data_prop_dict["hint"],
					data_prop_dict["hint_string"],
					data_prop_dict["usage"]
				)
				#@INFO new things on this vertical stuff
				prop_editor.name_split_ratio = 1.0
		
				mini_inspector_hbox.add_child(prop_editor)
			
			prop_editor.set_object_and_property(res_to_edit, prop_name)
			prop_editor.label = prop_name.capitalize()
			prop_editor.name_split_ratio = 0.4
			prop_editor.property_changed.connect(_prop_changed)
			prop_editor.selected.connect(_prop_selected)
			prop_editor.update_property()
			propname_edprop_map[prop_name] = prop_editor


func _on_mini_inspector_focus_exited() -> void:
	for edprop in mini_inspector_hbox.get_children():
		if edprop is EditorProperty:
			edprop.deselect()

func _prop_changed(p_property: String, p_value, p_field: StringName, p_changing: bool) -> void:
	_prop_changed_override(p_property, p_value)
	res_to_edit_ref.set(p_property, p_value)
	if typeof(p_value) >= TYPE_ARRAY:
		propname_edprop_map[p_property].update_property()
	property_changed.emit()

func _prop_selected(p_path:String, p_focusable: int) -> void:
	for _edprop in mini_inspector_hbox.get_children():
		var edprop = _edprop
		if edprop is HBoxContainer:
			if edprop.get_child(0) is EditorProperty:
				edprop = _edprop.get_child(0)
		if edprop is EditorProperty:
			if edprop == propname_edprop_map[p_path]:
				continue
			if edprop.is_selected():
				edprop.deselect()

func _on_stringenumdropdown_addmore_btn_pressed(button_ref : Button, res_ref : Resource, prop_name_ref : String) -> void:
	pass
