extends Camera2D

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

@export var follow_offset: Vector2 = Vector2(0.0, -72.0)
@export var smoothing_speed: float = 7.5

var _player: Node2D = null
var _map_controller: Node = null
var _refresh_left: float = 0.0

func _ready() -> void:
    enabled = MOBILE_MODE.is_mobile_mode()
    if not enabled:
        set_process(false)
        return

    position_smoothing_enabled = true
    position_smoothing_speed = smoothing_speed
    limit_smoothed = true
    call_deferred("_bind_sources")

func _process(delta: float) -> void:
    if not enabled:
        return

    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player") as Node2D
    if _player != null:
        global_position = _player.global_position + follow_offset

    _refresh_left -= delta
    if _refresh_left <= 0.0:
        _refresh_left = 0.35
        _refresh_limits()

func _bind_sources() -> void:
    _player = get_tree().get_first_node_in_group("player") as Node2D
    _map_controller = get_tree().get_first_node_in_group("map_controller")
    if _map_controller != null and _map_controller.has_signal("map_changed"):
        var changed_callable: Callable = Callable(self, "_on_map_changed")
        if not _map_controller.is_connected("map_changed", changed_callable):
            _map_controller.connect("map_changed", changed_callable)
    _refresh_limits()
    if _player != null:
        global_position = _player.global_position + follow_offset
    reset_smoothing()

func _on_map_changed(_scene_path: String, _spawn_name: StringName) -> void:
    call_deferred("_refresh_limits")
    call_deferred("reset_smoothing")

func _refresh_limits() -> void:
    if _map_controller == null or not is_instance_valid(_map_controller):
        _map_controller = get_tree().get_first_node_in_group("map_controller")
    if _map_controller == null or not _map_controller.has_method("get_current_playable_rect"):
        return

    var rect_variant: Variant = _map_controller.call("get_current_playable_rect")
    if typeof(rect_variant) != TYPE_RECT2:
        return
    var rect: Rect2 = rect_variant as Rect2
    if rect.size.x <= 1.0 or rect.size.y <= 1.0:
        return

    limit_left = floori(rect.position.x)
    limit_top = floori(rect.position.y)
    limit_right = ceili(rect.end.x)
    limit_bottom = ceili(rect.end.y)

    var viewport_size: Vector2 = get_viewport_rect().size
    var zoom_for_width: float = viewport_size.x / rect.size.x
    var zoom_for_height: float = viewport_size.y / rect.size.y
    var minimum_zoom: float = maxf(1.0, maxf(zoom_for_width, zoom_for_height))
    zoom = Vector2(minimum_zoom, minimum_zoom)