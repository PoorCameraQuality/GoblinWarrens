@tool
extends Resource
class_name ALZProjectLicenseDatabase

@export var project_name : String
@export var project_wide_license : ALZProjectWideLicense

@export var path_license_dict : Dictionary[String, PathLicenseData]

@export var saved_default_changes : Array[ALZResDefaultsChanges]


func get_saved_default_changes_or_null(res_global_name : String) -> ALZResDefaultsChanges:
	for refdefchange : ALZResDefaultsChanges in saved_default_changes:
		if refdefchange.res_script_globalname == res_global_name:
			return refdefchange
	return null


func get_data_as_dict() -> Dictionary:
	var data_dict := Dictionary()
	for path : String in path_license_dict.keys():
		var pld : PathLicenseData = path_license_dict[path]
		var pld_proplist := pld.get_property_list()
		#var pld_filteredprop := Array()
		var pld_filtered_propname_value_dict := Dictionary()
		for pld_propdict : Dictionary in pld_proplist:
			if pld_propdict["usage"] in [4098, 4102]: #INFO explain this later, okay?
				#print(pld_propdict["usage"])
				#pld_filteredprop.append(pld_propdict)
				var propname : String = pld_propdict["name"]
				pld_filtered_propname_value_dict[propname] = pld.get(propname)
		data_dict[path] = pld_filtered_propname_value_dict # pld_filteredprop
	
	#print(data_dict)
	return data_dict


func get_data_as_string_json() -> String:
	var string_json = JSON.stringify(get_data_as_dict(), "\t")
	return string_json


func set_plds_from_json(json : String):
	if not json:
		return
		
	var plds_from_json = JSON.parse_string(json) # this one should be dict[string, dict[string, variant]]
	if plds_from_json is not Dictionary:
		push_warning("Loaded database is not a dictionary") #@WARNING rewrite this later
		return
	# for now, clear the old data
	path_license_dict = {}
	
	for path : String in plds_from_json.keys():
		var new_pld := PathLicenseData.new()
		var propname_value_dict : Dictionary = plds_from_json[path] # maybe need another check if it was truly a dictionary
		for propname : String in propname_value_dict.keys():
			if propname in new_pld:
				new_pld.set(propname, propname_value_dict[propname])
				
		path_license_dict[path] = new_pld
		
	#print(path_license_dict) # uncomment to test


func restore_data_from_dict() -> void:
	pass
