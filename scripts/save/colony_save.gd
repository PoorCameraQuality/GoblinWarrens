class_name ColonySave
extends RefCounted

## Versioned snapshot save/load for the colony vertical slice.


static func save(colony: Node, path: String = Constants.SAVE_PATH) -> Error:
	if colony == null or not colony.has_method("capture_save_data"):
		Log.error("ColonySave.save: invalid colony node", "save")
		return ERR_INVALID_PARAMETER
	var data: ColonySaveData = colony.capture_save_data()
	return ResourceSaver.save(data, path)


static func load(colony: Node, path: String = Constants.SAVE_PATH) -> Error:
	if not ResourceLoader.exists(path):
		return ERR_FILE_NOT_FOUND
	if colony == null or not colony.has_method("apply_save_data"):
		Log.error("ColonySave.load: invalid colony node", "save")
		return ERR_INVALID_PARAMETER
	var data := ResourceLoader.load(path) as ColonySaveData
	if data == null:
		Log.error("ColonySave.load: failed to load %s" % path, "save")
		return ERR_CANT_OPEN
	return colony.apply_save_data(data)
