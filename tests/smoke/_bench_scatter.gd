extends SceneTree
func _init():
    var config = MapConfig.default_for_demo()
    var plan = MapPlan.new()
    plan.width = 32
    plan.height = 32
    plan.warren_cell = Vector2i(15, 15)
    var hd = HeightmapGenerator.generate(config, plan.warren_cell)
    plan.heights = hd.heights
    plan.height_point_width = hd.point_width
    plan.height_point_height = hd.point_height
    plan.tile_classes = TerrainClassifier.classify_grid(plan.heights, plan.height_point_width, plan.height_point_height, config, plan.warren_cell)
    var rng = MapRng.new(99)
    var count = 0
    for y in range(32):
        for x in range(32):
            count += 1
    print("cells", count)
    var t = Time.get_ticks_msec()
    var placements = []
    var blockers = {}
    PropScatterer._scatter_scenery(plan, config, rng, placements, blockers)
    print("scenery ms", Time.get_ticks_msec() - t, " n=", placements.size())
    quit(0)
