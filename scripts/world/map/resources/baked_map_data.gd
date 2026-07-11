class_name BakedMapData
extends Resource

## Runtime-oriented compile output for an authored map definition.

@export var definition: Resource
@export var compiled_grid_fingerprint: String = ""


const _Compiler := preload("res://scripts/world/map/grid_compiler.gd")


func compile_grid() -> Variant:
	if definition == null or definition.map_root.is_empty():
		return null
	var grid: Variant = _Compiler.compile_map(definition.map_root, definition.grid_size())
	return grid


func compile_resources() -> Variant:
	if definition == null or definition.map_root.is_empty():
		return null
	var ResourceCompiler = load("res://scripts/world/map/resource_scatter_compiler.gd")
	return ResourceCompiler.compile(definition.map_root, definition.grid_size())


func compile_strategic() -> Variant:
	if definition == null or definition.map_root.is_empty():
		return null
	var StrategicCompiler = load("res://scripts/world/map/strategic_map_compiler.gd")
	return StrategicCompiler.compile(definition.map_root, definition.grid_size())


func is_ready() -> bool:
	return definition != null and not definition.baked_dir.is_empty()
