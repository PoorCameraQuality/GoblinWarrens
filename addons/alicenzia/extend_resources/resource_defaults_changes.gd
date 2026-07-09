@tool
extends Resource
class_name ALZResDefaultsChanges

#var res_ref : Resource
#var res_script_path : String
@export_storage var res_script_globalname : String

#var res_propname : Array[String]
#var propname_savedvalue : Array

@export_storage var propname_savedvalue_pairs : Dictionary[String, Variant]
