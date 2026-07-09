@tool
extends RefCounted
class_name ALZLicenseContext

enum LicenseInheritType {
	INHERIT_NONE, INHERIT_PROJECT_WIDE,
	INHERIT_CLOSEST_PARENT_FOLDER, SELF_ASSIGNED
}

enum LicensePathType {
	UNASSIGNED, FILE, FOLDER
}

var current_fsd_path := "" # selected file on filesystemdock, should be cleansed at this point
var license_name := ""
var path_type : LicensePathType = LicensePathType.UNASSIGNED
var inherit_type : LicenseInheritType = LicenseInheritType.SELF_ASSIGNED
var license_parent_folder_name := "" # if it's INHERIT_CLOSEST_PARENT_FOLDER
var license_parent_folder_path := ""

var folder_name : String: # unused
	get:
		if current_fsd_path.is_empty():
			return ""
		return current_fsd_path.get_slice(	"/",
											current_fsd_path.get_slice_count("/") - 1)
	
