@tool
extends ConfirmationDialog

const WINDOW_MIN_Y := 143
const RES_PATH := "res://"
const USER_PATH := "user://"

const TOOL_INFO_TEMPLATE_TEXT := "%s tool haven't been installed on this system yet. Click the button below to install it."
const DOWNLOAD_BTN_TEMPLATE_TEXT := "Download %s tool (<10MB)"

const ASKALONO_OPTION := "askalono"
const ASKALONO_WINDOWS_LINK := "https://github.com/jpeddicord/askalono/releases/download/0.5.0/askalono-Windows.zip"
#const ASKALONO_WINDOWS_ZIPNAME := "askalono.zip"
const ASKALONO_WINDOWS_EXENAME := "askalono.exe" # this must strictly follow what's actually inside the zip

const GOLICENSE_OPTION := "go-license-detector"
const GOLICENSE_WINDOWS_LINK := "https://github.com/go-enry/go-license-detector/releases/download/v4.3.0/license-detector-v4.3.0-windows-amd64.zip"
const GOLICENSE_WINDOWS_EXENAME := "license-detector.exe"

const TOOL_DOWNLOAD_FOLDER_PATH := "user://alicenzia_scan_tools"

const YEAR_OWNER_SEARCH_PATTERN := r"Copyright\s+(?:\([cC]\)\s+|©\s+)?(\d{4}(?:-\d{4})?)\s+(.*)" # Gemini 3.1 Pro provided this
const PLUGIN_FILE_NAME := "plugin.cfg"
const TARGET_SCAN_PATH_ADDON := "res://addons"

@onready var non_windows_notice: VBoxContainer = %NonWindowsNotice

@onready var scan_tool_pn_o: HBoxContainer = %ScanToolPnO
@onready var tool_info: Label = %ToolInfo

@onready var download_tool_btn: Button = %DownloadToolBtn
@onready var tool_info_panel: PanelContainer = %ToolInfoPanel

@onready var scan_progress_panel: PanelContainer = %ScanProgressPanel

# relative path
@onready var askalono_exe_path := TOOL_DOWNLOAD_FOLDER_PATH + ("/%s" % ASKALONO_WINDOWS_EXENAME) #ASKALONO_WINDOWS_ZIPNAME)
@onready var golicense_exe_path := TOOL_DOWNLOAD_FOLDER_PATH + ("/%s" % GOLICENSE_WINDOWS_EXENAME)

var chosen_tool_to_download : String
var chosen_download_link : String
var chosen_exe_path : String
var chosen_exe_name : String

var is_device_supported := true


func _ready() -> void:
	self.size.y = WINDOW_MIN_Y
	if not Engine.is_editor_hint():
		scan_progress_panel.hide()
		_check_if_tool_available()
		_change_tool_texts()


func show_and_update():
	scan_progress_panel.hide()
	non_windows_notice.hide()
	self.show()
	_check_if_tool_available()
	_change_tool_texts()
	_check_supported_device()


func _check_supported_device():
	if OS.get_name() != "Windows":
		var okbtn := get_ok_button()
		tool_info_panel.visible = false
		okbtn.disabled = true
		is_device_supported = false
		non_windows_notice.show()


func _check_if_tool_available():
	if not is_device_supported:
		return
		
	var chosen_tool : String = scan_tool_pn_o.get_value()
	var dir = DirAccess.open(USER_PATH)
	var okbtn := get_ok_button()
	match (chosen_tool):
		ASKALONO_OPTION:
			if dir.file_exists(askalono_exe_path):
				_show_tool_download_info(false)
			else:
				_show_tool_download_info(true)
		GOLICENSE_OPTION:
			if dir.file_exists(golicense_exe_path):
				_show_tool_download_info(false)
			else:
				_show_tool_download_info(true)


func _show_tool_download_info(do_show : bool):
	var okbtn := get_ok_button()
	tool_info_panel.visible = do_show
	#tool_info.visible = do_show
	#download_tool_btn.visible = do_show
	okbtn.disabled = do_show
	if not do_show:
		self.size.y = WINDOW_MIN_Y


func _change_tool_texts():
	var chosen_tool : String = scan_tool_pn_o.get_value()
	tool_info.text = TOOL_INFO_TEMPLATE_TEXT % chosen_tool
	download_tool_btn.text = DOWNLOAD_BTN_TEMPLATE_TEXT % chosen_tool


func _on_scan_tool_pn_o_selected_item_changed(item_name: String) -> void:
	_check_if_tool_available()
	_change_tool_texts()


func _on_download_tool_btn_pressed() -> void:
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_tool_download_completed)
	
	download_tool_btn.disabled = true
	scan_tool_pn_o.disable_option_btn(true)

	var chosen_tool : String = scan_tool_pn_o.get_value()
	chosen_tool_to_download = chosen_tool
	#print("chosen: %s" % chosen_tool)
	
	match (chosen_tool_to_download):
		ASKALONO_OPTION:
			chosen_download_link = ASKALONO_WINDOWS_LINK
			chosen_exe_name = ASKALONO_WINDOWS_EXENAME
			chosen_exe_path = askalono_exe_path
		GOLICENSE_OPTION:
			chosen_download_link = GOLICENSE_WINDOWS_LINK
			chosen_exe_name = GOLICENSE_WINDOWS_EXENAME
			chosen_exe_path = golicense_exe_path
			
	print("Downloading file...")
	var error = http_request.request(chosen_download_link)
	if error != OK:
		push_error("An error occurred in the HTTP request.")


func _tool_download_completed(result, response_code, headers, body):
	download_tool_btn.disabled = false
	scan_tool_pn_o.disable_option_btn(false)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Tool couldn't be downloaded. Retry, check your internet connection, or report this as a bug.")
	else:
		## save the downloaded zip
		var dir = DirAccess.open(USER_PATH)
		dir.make_dir_recursive(TOOL_DOWNLOAD_FOLDER_PATH)
		
		var chosen
		var zip_name := chosen_download_link.get_slice("/", chosen_download_link.split("/").size() - 1) # get zip name from link
		var zip_download_path := TOOL_DOWNLOAD_FOLDER_PATH + ("/%s" % zip_name) #ASKALONO_WINDOWS_ZIPNAME)
		#print(zip_download_path)
		var zip_file = FileAccess.open(zip_download_path, FileAccess.WRITE)
		zip_file.store_buffer(body) # write downloaded file byte to physical file on local storage
		zip_file.close()
		
		## extract the executable from zip and save it
		var reader = ZIPReader.new()
		var err = reader.open(zip_download_path)
		if err != OK:
			print("this errors out: %d" % err)
			return PackedByteArray()
		var chosen_tool := reader.read_file(chosen_exe_name)
		var exe_file = FileAccess.open(chosen_exe_path, FileAccess.WRITE)
		exe_file.store_buffer(chosen_tool)
		reader.close()
		exe_file.close()
		
		print("File downloaded!")
		
		_show_tool_download_info(false)

func show_scan_progress():
	scan_progress_panel.show()

func begin_scan() -> Array[Dictionary]:
	var scanned_license_dict_array : Array[Dictionary]
	var chosen_tool : String = scan_tool_pn_o.get_value()
	
	show_scan_progress()
	#OS.delay_msec(500)
	if chosen_tool == ASKALONO_OPTION:
		scanned_license_dict_array = _scan_with_askalono()
	elif chosen_tool == GOLICENSE_OPTION:
		scanned_license_dict_array = _scan_with_golicense()
	
	var manual_scan_license_dict_array = _manual_addon_scan(scanned_license_dict_array)
	scanned_license_dict_array.append_array(manual_scan_license_dict_array)
	
	return scanned_license_dict_array
	

func _manual_addon_scan(prev_scan_lic_dict_array : Array[Dictionary]):
	### skip previously scanned addons
	var prev_scanned_addon_name : Array[String]
	
	for prev_scan_lic_dict : Dictionary in prev_scan_lic_dict_array:
		prev_scanned_addon_name.append(prev_scan_lic_dict["name"])
	
	var scanned_license_dict_array : Array[Dictionary]
	
	var addon_dir := DirAccess.open(TARGET_SCAN_PATH_ADDON)
	#var globalpath_directories : Array
	for folder in addon_dir.get_directories():
		if folder.capitalize() in prev_scanned_addon_name:
			continue
		
		var addon_respath := TARGET_SCAN_PATH_ADDON.path_join(folder)
		var plugin_path := addon_respath.path_join(PLUGIN_FILE_NAME)
		var copyright_owner := _get_author_from_plugin_file(plugin_path)
		if not copyright_owner.is_empty():
			var scanned_license_dict := Dictionary()
			scanned_license_dict["name"] = folder.capitalize()
			scanned_license_dict["type"] = "Addon" # for now
			scanned_license_dict["license"] = ""
			scanned_license_dict["license_parentdir_path"] = addon_respath
			scanned_license_dict["copyright_owner"] = copyright_owner
			scanned_license_dict["copyright_year"] = int()
			scanned_license_dict["full_license_text"] = ""
			
			scanned_license_dict_array.append(scanned_license_dict)
			
	return scanned_license_dict_array


func _scan_with_askalono():
	var askalono_exe_globalpath := ProjectSettings.globalize_path(askalono_exe_path)
	var addon_folder_globalpath := ProjectSettings.globalize_path(TARGET_SCAN_PATH_ADDON)
	#var addon_folder_gpath_split_size := addon_folder_globalpath.split("/", false).size()
	var output = []
	var exit_code = OS.execute(askalono_exe_globalpath, ["--format", "json", "crawl", addon_folder_globalpath], output)
	if not output[0]:
		push_error("No output found")
		return Array()
	
	var scanned_license_dict_array : Array[Dictionary]
	
	for spotted_license_json in output[0].split("\n", false):
		var spotted_license_dict = JSON.parse_string(spotted_license_json)
		var license_path : String = spotted_license_dict["path"]
		var license_path_relative := license_path.trim_prefix(addon_folder_globalpath)
		if license_path_relative.split("\\", false).size() > 2:
			continue # skip license file found deep inside an addon, for now
			
		if spotted_license_dict.has("error"):
			continue
			
		var result_dict : Dictionary = spotted_license_dict["result"]
		var license_dict : Dictionary = result_dict["license"]
		var license_name : String = license_dict["name"]
		var copyright_year : int
		var copyright_owner : String
		
		if license_name in ["MIT", "Apache-2.0"]: # supported license type to search with regex
			var full_license_text := FileAccess.get_file_as_string(license_path)
			var regex = RegEx.new()
			regex.compile(YEAR_OWNER_SEARCH_PATTERN) 
			var result = regex.search(full_license_text)
			if result:
				copyright_year = int(result.get_string(1))
				copyright_owner = result.get_string(2)
		
		var addon_folder_name := license_path_relative.get_slice("\\", 1) #TODO janky
		var plugin_file_location := TARGET_SCAN_PATH_ADDON.path_join(addon_folder_name)
		
		var dir = DirAccess.open(plugin_file_location)
		if copyright_owner.is_empty() and dir.file_exists(PLUGIN_FILE_NAME):
			var plugin_path := plugin_file_location.path_join(PLUGIN_FILE_NAME)
			copyright_owner = _get_author_from_plugin_file(plugin_path)

		var addon_name := license_path_relative.get_slice("\\", 1)
		var license_respath := TARGET_SCAN_PATH_ADDON.path_join(license_path_relative.replace("\\", "/").trim_prefix("/"))
		var license_dir_respath := TARGET_SCAN_PATH_ADDON.path_join(addon_name).replace("\\", "/").trim_prefix("/")
		var scanned_license_dict := Dictionary()
		scanned_license_dict["name"] = addon_name.capitalize() # for example, \alicenzia\LICENSE got Alicenzia
		scanned_license_dict["type"] = "Addon" # for now
		scanned_license_dict["license"] = license_name
		scanned_license_dict["license_parentdir_path"] = license_dir_respath
		scanned_license_dict["license_path"] = license_respath
		scanned_license_dict["copyright_year"] = copyright_year
		scanned_license_dict["copyright_owner"] = copyright_owner
		scanned_license_dict["full_license_text"] = ""
		
		dir = DirAccess.open(RES_PATH)
		if dir.file_exists(license_respath):
			var license_text := FileAccess.get_file_as_string(license_respath)
			if !license_text.is_empty():
				scanned_license_dict["full_license_text"] = license_text
		
		scanned_license_dict_array.append(scanned_license_dict)
		#print(	"path: %s | license : %s | year : %d | owner : %s"
				#% [scanned_license_dict["license_path"], license_name, copyright_year, copyright_owner])
	
	#print("Scan done!")
	return scanned_license_dict_array


func _fix_license_name(lic_name : String):
	match (lic_name):
		"deprecated_GPL-3.0":
			return "GPL-3.0-only"
		"deprecated_GPL-3.0+":
			return "GPL-3.0-or-later"
	return lic_name
	

func _get_author_from_plugin_file(plugin_file_path : String) -> String: # absolute path, i think
	if FileAccess.file_exists(plugin_file_path):
		var file := FileAccess.open(plugin_file_path, FileAccess.READ)
		while file.get_position() < file.get_length():
			var line := file.get_line()
			if line.begins_with("author="):
				var author = line.trim_prefix('author="').trim_suffix('"')
				file.close()
				return author
		file.close()
	return ""


func _scan_with_golicense():
	var golicense_exe_globalpath := ProjectSettings.globalize_path(golicense_exe_path)
	var addon_folder_globalpath := ProjectSettings.globalize_path(TARGET_SCAN_PATH_ADDON)
	
	var addon_dir := DirAccess.open(TARGET_SCAN_PATH_ADDON)
	var current_dir := addon_dir.get_current_dir() # absolute path
	var output = []
	
	var globalpath_directories : Array
	for folder in addon_dir.get_directories():
		globalpath_directories.append(addon_folder_globalpath.path_join(folder))
		
	var golicense_command := globalpath_directories
	golicense_command.append_array(["--format", "json"])
	
	var exit_code = OS.execute(golicense_exe_globalpath, golicense_command, output)
		
	if not output[0]:
		push_error("No output found")
		return Array()
	#else:
		#print(output[0])
	
	var scanned_license_dict_array : Array[Dictionary]
	
	var spotted_license_array = JSON.parse_string(output[0])
	for spotted_license_dict : Dictionary in spotted_license_array:
		if spotted_license_dict.has("error"):
			continue
		elif spotted_license_dict.has("matches"):
			var license_parent_dir : String = spotted_license_dict["project"]
			var license_match_dict : Dictionary = spotted_license_dict["matches"][0] # has license, confidence, and file (pick the most confident
			
			var license_filename : String = license_match_dict["file"]
			var license_globalpath : String = license_parent_dir.path_join(license_filename)
			var license_name : String = license_match_dict["license"]
			license_name = _fix_license_name(license_name)
			var license_path_relative := license_globalpath.trim_prefix(addon_folder_globalpath)
			
			var copyright_year : int
			var copyright_owner : String
			
			if license_name in ["MIT", "Apache-2.0"]: # supported license type to search with regex
				var full_license_text := FileAccess.get_file_as_string(license_globalpath)
				var regex = RegEx.new()
				regex.compile(YEAR_OWNER_SEARCH_PATTERN) 
				var result = regex.search(full_license_text)
				if result:
					copyright_year = int(result.get_string(1))
					copyright_owner = result.get_string(2)
					
			var plugin_file_location := license_parent_dir
			
			var dir = DirAccess.open(plugin_file_location)
			if copyright_owner.is_empty() and dir.file_exists(PLUGIN_FILE_NAME):
				var plugin_path := plugin_file_location.path_join(PLUGIN_FILE_NAME)
				copyright_owner = _get_author_from_plugin_file(plugin_path)
			
			var addon_name := license_parent_dir.trim_prefix(addon_folder_globalpath)
			var license_respath := TARGET_SCAN_PATH_ADDON.path_join(license_path_relative.replace("\\", "/").trim_prefix("/"))
			var license_dir_respath := TARGET_SCAN_PATH_ADDON.path_join(addon_name.replace("\\", "/").trim_prefix("/"))
			var scanned_license_dict := Dictionary()
			scanned_license_dict["name"] = license_path_relative.get_slice("/", 1).capitalize() # for example, \alicenzia\LICENSE got Alicenzia
			scanned_license_dict["type"] = "Addon" # for now
			scanned_license_dict["license"] = license_name
			scanned_license_dict["license_parentdir_path"] = license_dir_respath
			scanned_license_dict["license_path"] = license_respath
			scanned_license_dict["copyright_year"] = copyright_year
			scanned_license_dict["copyright_owner"] = copyright_owner
			scanned_license_dict["full_license_text"] = ""
			
			dir = DirAccess.open(RES_PATH)
			if dir.file_exists(license_respath):
				var license_text := FileAccess.get_file_as_string(license_respath)
				if !license_text.is_empty():
					scanned_license_dict["full_license_text"] = license_text
			
			scanned_license_dict_array.append(scanned_license_dict)
			
	#print("Scan done!")
	return scanned_license_dict_array
