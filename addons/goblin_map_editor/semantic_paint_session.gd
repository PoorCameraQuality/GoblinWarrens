class_name SemanticPaintSession
extends RefCounted

## In-memory edit session for one semantic source layer (editor-only workflow).

const PAINTABLE_LAYERS := [
	"biome_id",
	"buildability",
	"start_zone",
	"no_scatter",
	"raid_entry",
	"enemy_camp_zone",
]

const _Importer := preload("res://scripts/world/map/map_semantic_importer.gd")

var map_root: String = ""
var manifest: Dictionary = {}
var active_layer_key: String = ""
var source_image: Image
var dirty: bool = false


func open_map(root: String) -> bool:
	map_root = root
	var manifest_path := map_root.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		push_error("SemanticPaintSession: missing manifest")
		return false
	manifest = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	return not manifest.is_empty()


func load_layer(layer_key: String) -> bool:
	if manifest.is_empty():
		return false
	if layer_key not in PAINTABLE_LAYERS:
		push_error("SemanticPaintSession: layer not paintable: %s" % layer_key)
		return false
	var files: Dictionary = manifest.get("files", {})
	var file_name := str(files.get(layer_key, ""))
	if file_name.is_empty():
		return false
	var source_path := ProjectSettings.globalize_path(map_root.path_join("source").path_join(file_name))
	if not FileAccess.file_exists(source_path):
		push_error("SemanticPaintSession: missing source layer %s" % source_path)
		return false
	var image := Image.load_from_file(source_path)
	if image == null or image.is_empty():
		return false
	image.convert(Image.FORMAT_RGBA8)
	source_image = image
	active_layer_key = layer_key
	dirty = false
	return true


func preview_texture() -> ImageTexture:
	if source_image == null:
		return null
	var preview := source_image.duplicate()
	var max_side := 512
	if preview.get_width() > max_side or preview.get_height() > max_side:
		var scale := float(max_side) / float(maxi(preview.get_width(), preview.get_height()))
		var target := Vector2i(
			maxi(1, int(round(float(preview.get_width()) * scale))),
			maxi(1, int(round(float(preview.get_height()) * scale))),
		)
		preview.resize(target.x, target.y, Image.INTERPOLATE_NEAREST)
	var tex := ImageTexture.create_from_image(preview)
	return tex


func paint_at_source_pixel(cell: Vector2i, paint_value: Color, brush_radius: int = 0) -> void:
	if source_image == null:
		return
	for dy in range(-brush_radius, brush_radius + 1):
		for dx in range(-brush_radius, brush_radius + 1):
			if Vector2(dx, dy).length() > float(brush_radius) + 0.5:
				continue
			var px := cell + Vector2i(dx, dy)
			if px.x < 0 or px.y < 0 or px.x >= source_image.get_width() or px.y >= source_image.get_height():
				continue
			source_image.set_pixel(px.x, px.y, paint_value)
	dirty = true


func map_preview_uv_to_source(preview_size: Vector2, uv: Vector2) -> Vector2i:
	if source_image == null or preview_size.x <= 0.0 or preview_size.y <= 0.0:
		return Vector2i(-1, -1)
	var sx := clampi(int(floor(uv.x * float(source_image.get_width()))), 0, source_image.get_width() - 1)
	var sy := clampi(int(floor(uv.y * float(source_image.get_height()))), 0, source_image.get_height() - 1)
	return Vector2i(sx, sy)


func save_source_layer() -> bool:
	if source_image == null or active_layer_key.is_empty():
		return false
	var files: Dictionary = manifest.get("files", {})
	var file_name := str(files.get(active_layer_key, ""))
	if file_name.is_empty():
		return false
	var source_path := ProjectSettings.globalize_path(map_root.path_join("source").path_join(file_name))
	var err := source_image.save_png(source_path)
	if err != OK:
		push_error("SemanticPaintSession: save failed err=%s" % error_string(err))
		return false
	dirty = false
	return true


func rebake_layers(target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) -> Dictionary:
	return _Importer.import_map(map_root, target_size)


func paint_value_for_layer(layer_key: String, option_index: int) -> Color:
	match layer_key:
		"biome_id":
			var palette: Dictionary = manifest.get("biome_palette", {})
			var keys := palette.keys()
			keys.sort()
			if option_index < 0 or option_index >= keys.size():
				return Color.BLACK
			return Color.from_string(str(keys[option_index]), Color.MAGENTA)
		"buildability":
			return Color(1, 1, 1, 1) if option_index > 0 else Color(0, 0, 0, 1)
		"start_zone":
			match option_index:
				0:
					return Color(0.5, 0.5, 0.5, 1) ## neutral
				1:
					return Color(0, 1, 0, 1) ## allowed
				_:
					return Color(1, 0, 0, 1) ## forbidden
		"no_scatter":
			return Color(1, 1, 1, 1) if option_index > 0 else Color(0, 0, 0, 1)
		"raid_entry":
			return Color(1, 1, 1, 1) if option_index > 0 else Color(0, 0, 0, 1)
		"enemy_camp_zone":
			match option_index:
				0:
					return Color(0, 0, 0, 1)
				_:
					return Color(0.85, 0.1, 0.85, 1)
	return Color.MAGENTA
