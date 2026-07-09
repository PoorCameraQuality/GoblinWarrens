extends SceneTree
func _init() -> void:
    call_deferred("_run")
func _run() -> void:
    var c = load("res://scenes/colony.tscn").instantiate()
    root.add_child(c)
    print("added colony")
    await create_timer(10.0).timeout
    print("wood=", c.get_stockpile().get_amount(Defs.ResourceKind.WOOD))
    quit(0)
