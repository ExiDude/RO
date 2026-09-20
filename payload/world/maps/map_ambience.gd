extends Node2D

var map_size: Vector2 = Vector2(1280.0, 720.0)
var base_color: Color = Color(0.12, 0.20, 0.12, 1.0)
var ambience_style: String = "field"
var ambience_seed: int = 1

func configure(new_size: Vector2, new_base_color: Color, style_name: String, seed_value: int) -> void:
    map_size = new_size
    base_color = new_base_color
    ambience_style = style_name
    ambience_seed = seed_value
    queue_redraw()

func _draw() -> void:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = ambience_seed

    var patch_count: int = 34 if ambience_style == "town" else 58
    if ambience_style == "ill_field":
        patch_count = 86

    for _index in range(patch_count):
        var pos: Vector2 = Vector2(rng.randf_range(30.0, map_size.x - 30.0), rng.randf_range(55.0, map_size.y - 30.0))
        var radius: float = rng.randf_range(10.0, 34.0)
        var brighten: float = rng.randf_range(-0.045, 0.055)
        var patch_color: Color = Color(
            clampf(base_color.r + brighten, 0.0, 1.0),
            clampf(base_color.g + brighten * 1.25, 0.0, 1.0),
            clampf(base_color.b + brighten * 0.8, 0.0, 1.0),
            rng.randf_range(0.10, 0.22)
        )
        draw_circle(pos, radius, patch_color)

    if ambience_style == "town":
        _draw_town_details(rng)
    elif ambience_style == "ill_field":
        _draw_ill_field_details(rng)
    else:
        _draw_field_details(rng)

    var border_color: Color = Color(0.025, 0.032, 0.026, 0.76)
    draw_rect(Rect2(Vector2(18.0, 18.0), map_size - Vector2(36.0, 36.0)), border_color, false, 2.0)
    draw_rect(Rect2(Vector2(23.0, 23.0), map_size - Vector2(46.0, 46.0)), Color(0.72, 0.54, 0.40, 0.06), false, 1.0)

func _draw_field_details(rng: RandomNumberGenerator) -> void:
    for _index in range(92):
        var pos: Vector2 = Vector2(rng.randf_range(28.0, map_size.x - 28.0), rng.randf_range(68.0, map_size.y - 28.0))
        var blade_height: float = rng.randf_range(4.0, 9.0)
        var grass_color: Color = Color(0.38, 0.56, 0.23, rng.randf_range(0.18, 0.38))
        draw_line(pos, pos + Vector2(-2.0, -blade_height), grass_color, 1.0)
        draw_line(pos, pos + Vector2(2.5, -blade_height * 0.8), grass_color, 1.0)
        if rng.randf() < 0.22:
            draw_circle(pos + Vector2(0.0, -blade_height - 1.0), 1.5, Color(0.92, 0.84, 0.46, 0.42))

    for _index in range(22):
        var stone_pos: Vector2 = Vector2(rng.randf_range(30.0, map_size.x - 30.0), rng.randf_range(75.0, map_size.y - 30.0))
        draw_circle(stone_pos, rng.randf_range(1.5, 3.5), Color(0.44, 0.46, 0.38, 0.32))

func _draw_ill_field_details(rng: RandomNumberGenerator) -> void:
    _draw_ill_path()
    _draw_ill_water()

    for _index in range(170):
        var pos: Vector2 = Vector2(rng.randf_range(30.0, map_size.x - 30.0), rng.randf_range(42.0, map_size.y - 30.0))
        var blade_height: float = rng.randf_range(5.0, 13.0)
        var grass_tone: float = rng.randf_range(0.0, 0.08)
        var grass_color: Color = Color(0.19 + grass_tone, 0.30 + grass_tone, 0.16 + grass_tone * 0.45, rng.randf_range(0.28, 0.56))
        draw_line(pos, pos + Vector2(-2.5, -blade_height), grass_color, 1.0)
        draw_line(pos, pos + Vector2(2.0, -blade_height * 0.86), grass_color, 1.0)
        if rng.randf() < 0.10:
            var flower_color: Color = Color(0.68, 0.11, 0.16, rng.randf_range(0.48, 0.76))
            draw_circle(pos + Vector2(0.0, -blade_height - 1.0), rng.randf_range(1.2, 2.2), flower_color)

    for _index in range(46):
        var stone_pos: Vector2 = Vector2(rng.randf_range(34.0, map_size.x - 34.0), rng.randf_range(72.0, map_size.y - 34.0))
        var stone_radius: float = rng.randf_range(2.0, 6.0)
        draw_circle(stone_pos + Vector2(2.0, 3.0), stone_radius * 1.05, Color(0.01, 0.015, 0.012, 0.28))
        draw_circle(stone_pos, stone_radius, Color(0.27, 0.29, 0.25, rng.randf_range(0.30, 0.48)))

    for _index in range(24):
        var root_pos: Vector2 = Vector2(rng.randf_range(36.0, map_size.x - 36.0), rng.randf_range(90.0, map_size.y - 44.0))
        var root_length: float = rng.randf_range(18.0, 46.0)
        var root_dir: Vector2 = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.4, 0.8)).normalized()
        draw_line(root_pos, root_pos + root_dir * root_length, Color(0.11, 0.075, 0.06, 0.50), rng.randf_range(1.2, 2.6))

    _draw_ill_landmarks()

func _draw_ill_path() -> void:
    var path_points: PackedVector2Array = PackedVector2Array([
        Vector2(map_size.x * 0.50, -20.0),
        Vector2(map_size.x * 0.54, 220.0),
        Vector2(map_size.x * 0.47, 470.0),
        Vector2(map_size.x * 0.53, 760.0),
        Vector2(map_size.x * 0.49, 1040.0),
        Vector2(map_size.x * 0.55, 1320.0),
        Vector2(map_size.x * 0.46, 1600.0),
        Vector2(map_size.x * 0.50, map_size.y + 20.0)
    ])
    draw_polyline(path_points, Color(0.10, 0.075, 0.048, 0.48), 106.0, true)
    draw_polyline(path_points, Color(0.33, 0.28, 0.18, 0.72), 88.0, true)
    draw_polyline(path_points, Color(0.52, 0.42, 0.27, 0.12), 4.0, true)

func _draw_ill_water() -> void:
    var center: Vector2 = Vector2(map_size.x * 0.18, map_size.y * 0.73)
    draw_circle(center + Vector2(4.0, 6.0), 116.0, Color(0.0, 0.0, 0.0, 0.20))
    draw_circle(center, 108.0, Color(0.07, 0.18, 0.20, 0.70))
    draw_circle(center - Vector2(18.0, 10.0), 82.0, Color(0.12, 0.29, 0.30, 0.20))
    for ring_index in range(4):
        var radius: float = 28.0 + float(ring_index) * 17.0
        draw_arc(center, radius, 0.0, TAU, 48, Color(0.50, 0.72, 0.68, 0.11), 1.0, true)

func _draw_ill_landmarks() -> void:
    var shrine: Vector2 = Vector2(150.0, map_size.y * 0.54)
    draw_circle(shrine + Vector2(2.0, 44.0), 52.0, Color(0.0, 0.0, 0.0, 0.24))
    draw_rect(Rect2(shrine + Vector2(-34.0, -34.0), Vector2(68.0, 96.0)), Color(0.24, 0.24, 0.22, 0.76), true)
    draw_rect(Rect2(shrine + Vector2(-27.0, -27.0), Vector2(54.0, 82.0)), Color(0.36, 0.35, 0.31, 0.34), false, 2.0)
    draw_line(shrine + Vector2(-12.0, -5.0), shrine + Vector2(13.0, -5.0), Color(0.47, 0.08, 0.10, 0.74), 3.0)
    draw_line(shrine + Vector2(0.0, -18.0), shrine + Vector2(0.0, 18.0), Color(0.47, 0.08, 0.10, 0.74), 3.0)

    var sign_pos: Vector2 = Vector2(map_size.x * 0.79, map_size.y * 0.47)
    draw_line(sign_pos, sign_pos + Vector2(0.0, 90.0), Color(0.18, 0.11, 0.075, 0.92), 8.0)
    draw_rect(Rect2(sign_pos + Vector2(-60.0, -14.0), Vector2(120.0, 26.0)), Color(0.30, 0.20, 0.12, 0.88), true)
    draw_rect(Rect2(sign_pos + Vector2(-52.0, 18.0), Vector2(104.0, 24.0)), Color(0.26, 0.17, 0.11, 0.88), true)

    var candle_positions: Array[Vector2] = [
        shrine + Vector2(-48.0, 62.0),
        shrine + Vector2(-26.0, 70.0),
        shrine + Vector2(43.0, 66.0),
        Vector2(map_size.x * 0.72, map_size.y * 0.64)
    ]
    for candle_pos: Vector2 in candle_positions:
        draw_rect(Rect2(candle_pos + Vector2(-2.0, -10.0), Vector2(4.0, 14.0)), Color(0.76, 0.68, 0.53, 0.72), true)
        draw_circle(candle_pos + Vector2(0.0, -13.0), 4.0, Color(1.0, 0.58, 0.20, 0.50))
        draw_circle(candle_pos + Vector2(0.0, -13.0), 1.6, Color(1.0, 0.93, 0.62, 0.92))

func _draw_town_details(rng: RandomNumberGenerator) -> void:
    var road_color: Color = Color(0.48, 0.43, 0.30, 0.18)
    draw_rect(Rect2(Vector2(26.0, map_size.y * 0.47), Vector2(map_size.x - 52.0, map_size.y * 0.12)), road_color, true)
    draw_rect(Rect2(Vector2(map_size.x * 0.45, 72.0), Vector2(map_size.x * 0.10, map_size.y - 144.0)), Color(0.45, 0.40, 0.28, 0.12), true)
    for _index in range(46):
        var pos: Vector2 = Vector2(rng.randf_range(28.0, map_size.x - 28.0), rng.randf_range(74.0, map_size.y - 28.0))
        var size: Vector2 = Vector2(rng.randf_range(3.0, 8.0), rng.randf_range(2.0, 5.0))
        draw_rect(Rect2(pos, size), Color(0.82, 0.78, 0.58, rng.randf_range(0.05, 0.12)), true)