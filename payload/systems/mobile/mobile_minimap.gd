extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

var _player: Node2D = null
var _map_controller: Node = null
var _refresh_left: float = 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    visible = MOBILE_MODE.is_mobile_mode()
    if not visible:
        set_process(false)
        return
    call_deferred("_bind_sources")

func _process(delta: float) -> void:
    _refresh_left -= delta
    if _refresh_left <= 0.0:
        _refresh_left = 0.20
        if _player == null or not is_instance_valid(_player):
            _player = get_tree().get_first_node_in_group("player") as Node2D
        if _map_controller == null or not is_instance_valid(_map_controller):
            _map_controller = get_tree().get_first_node_in_group("map_controller")
        queue_redraw()

func _bind_sources() -> void:
    _player = get_tree().get_first_node_in_group("player") as Node2D
    _map_controller = get_tree().get_first_node_in_group("map_controller")
    if _map_controller != null and _map_controller.has_signal("map_changed"):
        var map_callable: Callable = Callable(self, "_on_map_changed")
        if not _map_controller.is_connected("map_changed", map_callable):
            _map_controller.connect("map_changed", map_callable)
    queue_redraw()

func _on_map_changed(_scene_path: String, _spawn_name: StringName) -> void:
    queue_redraw()

func _draw() -> void:
    if not visible:
        return

    var map_rect: Rect2 = Rect2(Vector2.ZERO, Vector2(1440.0, 1920.0))
    if _map_controller != null and _map_controller.has_method("get_current_playable_rect"):
        var rect_variant: Variant = _map_controller.call("get_current_playable_rect")
        if typeof(rect_variant) == TYPE_RECT2:
            map_rect = rect_variant as Rect2

    if map_rect.size.x <= 1.0 or map_rect.size.y <= 1.0:
        return

    var inner: Rect2 = Rect2(Vector2(5.0, 5.0), size - Vector2(10.0, 10.0))
    if inner.size.x <= 1.0 or inner.size.y <= 1.0:
        return

    draw_rect(inner, Color(0.075, 0.12, 0.075, 0.94), true)
    draw_rect(inner, Color(0.45, 0.34, 0.23, 0.72), false, 1.2)

    var path_points: PackedVector2Array = PackedVector2Array([
        Vector2(0.50, 0.00), Vector2(0.54, 0.15), Vector2(0.47, 0.28),
        Vector2(0.53, 0.42), Vector2(0.49, 0.56), Vector2(0.55, 0.70),
        Vector2(0.46, 0.84), Vector2(0.50, 1.00)
    ])
    var mapped_path: PackedVector2Array = PackedVector2Array()
    for normalized_point: Vector2 in path_points:
        mapped_path.append(inner.position + normalized_point * inner.size)
    draw_polyline(mapped_path, Color(0.55, 0.43, 0.27, 0.66), 8.0, true)

    var water_center: Vector2 = inner.position + Vector2(inner.size.x * 0.18, inner.size.y * 0.73)
    draw_circle(water_center, minf(inner.size.x, inner.size.y) * 0.075, Color(0.11, 0.31, 0.33, 0.72))

    for monster_node: Node in get_tree().get_nodes_in_group("monster"):
        var monster: Node2D = monster_node as Node2D
        if monster == null or not is_instance_valid(monster):
            continue
        if monster.has_method("is_alive") and not bool(monster.call("is_alive")):
            continue
        var marker: Vector2 = _map_world_point(monster.global_position, map_rect, inner)
        draw_circle(marker, 2.6, Color(0.90, 0.26, 0.36, 0.95))

    for loot_node: Node in get_tree().get_nodes_in_group("loot"):
        var loot: Node2D = loot_node as Node2D
        if loot == null or not is_instance_valid(loot):
            continue
        var loot_marker: Vector2 = _map_world_point(loot.global_position, map_rect, inner)
        draw_circle(loot_marker, 1.8, Color(0.82, 0.72, 0.28, 0.88))

    if _player != null and is_instance_valid(_player):
        var player_marker: Vector2 = _map_world_point(_player.global_position, map_rect, inner)
        draw_circle(player_marker, 4.0, Color(1.0, 0.93, 0.60, 1.0))
        draw_arc(player_marker, 6.0, 0.0, TAU, 18, Color(0.25, 0.05, 0.06, 0.95), 1.4, true)

func _map_world_point(world_position: Vector2, map_rect: Rect2, inner: Rect2) -> Vector2:
    var normalized_x: float = clampf((world_position.x - map_rect.position.x) / map_rect.size.x, 0.0, 1.0)
    var normalized_y: float = clampf((world_position.y - map_rect.position.y) / map_rect.size.y, 0.0, 1.0)
    return inner.position + Vector2(normalized_x * inner.size.x, normalized_y * inner.size.y)