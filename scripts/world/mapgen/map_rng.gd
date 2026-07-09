class_name MapRng
extends RefCounted

## Seeded RNG wrapper for deterministic map generation.


var _rng: RandomNumberGenerator


func _init(seed: int) -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed


func randf() -> float:
	return _rng.randf()


func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)


func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)


func roll(probability: float) -> bool:
	return _rng.randf() < probability


func pick(options: Array) -> Variant:
	if options.is_empty():
		return null
	return options[_rng.randi_range(0, options.size() - 1)]
