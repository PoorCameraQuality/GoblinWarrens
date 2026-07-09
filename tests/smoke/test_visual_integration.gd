extends SceneTree

func _init() -> void:
	print("all_macro=", TerrainPalette.all_macro_textures_present(), " uv=", TerrainPalette.preferred_uv_scale())
	print(VisualScaleAudit.run())
	quit(0)
