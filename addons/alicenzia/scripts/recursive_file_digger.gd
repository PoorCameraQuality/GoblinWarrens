@tool
extends Node
# currently unused

const FILE_NAME_IGNORE_LIST : Array[String] = [
	".DS_Store"
]

const FILE_EXTENSION_IGNORE_LIST : Array[String] = [ # Lowercase, No need for the dot
	"import", "uid", "gitignore", "gitattributes",
	"gitkeep"
]

const DIRECTORY_IGNORE_LIST : Array[String] = [ # No need for extra slash
	"res://addons", "res://.godot"
]

var path_output := PackedStringArray()

func start_walk_dir(dir_to_walk : String) -> PackedStringArray:
	path_output.clear()
	walk_dir(dir_to_walk)
	return path_output

func walk_dir(dir_to_walk : String):
	var dir = DirAccess.open(dir_to_walk)
	var current_dir = dir.get_current_dir()
	#print(str(dir.get_open_error()))
	
	var unfiltered_file_list : PackedStringArray = dir.get_files()
	var file_list := PackedStringArray()
	if unfiltered_file_list.size() > 0:
		for file_name in unfiltered_file_list:
			var file_extension := file_name.get_slice(".", file_name.get_slice_count(".") - 1).to_lower()
			if file_name in FILE_NAME_IGNORE_LIST \
			or file_extension in FILE_EXTENSION_IGNORE_LIST:
				continue
			file_list.append(file_name)
		
		for file_name : String in file_list:
			var full_file_path = current_dir.path_join(file_name)
			#print(full_file_path)
			path_output.append(full_file_path)
			
	else: # unfiltered_file_list is 0
		#print("No file found at: " + current_dir)
		pass

	for folder in dir.get_directories():
		var next_dir := current_dir.path_join(folder)
		if next_dir not in DIRECTORY_IGNORE_LIST:
			walk_dir(next_dir)
