@tool
extends Resource
class_name PathLicenseData

#enum AssetType {
	#CODE, MUSIC, ADDON
#}
#
#enum OwnershipType {
	#INTERNALLY_MADE, EXTERNAL
#}
#
#enum Creator {
	#Etherealxx
#}
#
#enum LicenseType {
	#APACHE, MIT, CC_BY, CC0, CC_BY_SSA,
	#CC_BY_NC_ND, GPLV3
#}

# These ones should be the default one i guess
@export_storage var asset_type_hint := "Addon/Plugin/GDExtension,Code,Font,Music,Shader,Sprite,Sprite Sheet,Sound Effect"
@export_storage var ownership_type_hint := "Internally Made,External"
@export_storage var creator_hint := "Etherealxx"
@export_storage var license_type_hint := "0BSD,All Rights Reserved,Apache-2.0,CC0-1.0,CC-BY 3.0,CC-BY-4.0,_Custom,GNU GPL 3.0,MIT,_NotProper,SIL OFL 1.1,_Unknown"

@export var name := ""
@export var type := ""
#@export_custom(PROPERTY_HINT_ENUM, asset_type_list)
@export var ownership_type := ""
@export var creator := ""
@export var license_type := ""
@export_multiline var usage := ""
@export_multiline var modification := ""
@export var webpage_link := ""
@export_file var license_text_path := ""
@export_multiline var full_license_text := ""

var path := ""
var extension := ""
#var full_lisence := ""


func get_enum_hint_name_pair() -> Dictionary[String, String]:
	var pair : Dictionary[String, String] = {
		"type" = "asset_type_hint",
		"ownership_type" = "ownership_type_hint",
		"creator" = "creator_hint",
		"license_type" = "license_type_hint"
	}
	return pair


func get_enum_hint_pair() -> Dictionary[String, String]:
	#var pair : Dictionary[String, String] = {
		#"type" = asset_type_hint,
		#"ownership_type" = ownership_type_hint,
		#"creator" = creator_hint,
		#"license_type" = license_type_hint
	#}
	var pair : Dictionary[String, String]
	var name_pair := get_enum_hint_name_pair()
	for enum_propname : String in name_pair.keys():
		var type_hint_varname : String = name_pair[enum_propname]
		if type_hint_varname in self:
			pair[enum_propname] = self.get(type_hint_varname)
	return pair
