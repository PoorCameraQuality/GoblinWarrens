extends SceneTree
func _init():
    var t = Time.get_ticks_msec()
    var plan = MapGenerator.build(MapConfig.default_for_demo())
    print("done ms=", Time.get_ticks_msec() - t, " props=", plan.prop_placements.size())
    quit(0)
