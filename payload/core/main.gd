extends Node

signal map_changed(scene_path: String, spawn_name: StringName)

const START_MAP: String = "map://dev_town"
const DATA_MAP_SCENE: PackedScene = preload("res://world/maps/data_map.tscn")
const START_SPAWN: StringName = &"default"
const PLAYER_SCENE: PackedScene = preload("res://actors/player/player.tscn")
const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")
const MOBILE_START_MAP: String = "map://south_field"
const MOBILE_VIRTUAL_SIZE: Vector2i = Vector2i(720, 1280)
const MOBILE_DESKTOP_PREVIEW_SIZE: Vector2i = Vector2i(540, 960)

@onready var world: Node2D = $World
@onready var map_root: Node2D = $World/MapRoot
@onready var actor_root: Node2D = $World/ActorRoot

var current_map: Node2D = null
var current_map_path: String = ""
var player: CharacterBody2D = null
var _transition_pending: bool = false
var _impact_shake_left: float = 0.0
var _impact_shake_duration: float = 0.11
var _impact_shake_strength: float = 0.0
var _impact_shake_direction: Vector2 = Vector2.RIGHT
var _impact_shake_phase: float = 0.0
var _combat_shake_enabled: bool = true

func _ready() -> void:
    add_to_group("map_controller")
    _configure_mobile_display()
    _ensure_default_input()
    _spawn_player()
    _change_map(_resolve_start_map(), START_SPAWN)


func _configure_mobile_display() -> void:
    if not MOBILE_MODE.is_mobile_mode():
        return

    var root_window: Window = get_window()
    root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
    root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
    root_window.content_scale_size = MOBILE_VIRTUAL_SIZE

    if not MOBILE_MODE.is_real_mobile():
        root_window.size = MOBILE_DESKTOP_PREVIEW_SIZE

func _process(delta: float) -> void:
    if _impact_shake_left <= 0.0:
        if world.position != Vector2.ZERO:
            world.position = Vector2.ZERO
        return

    _impact_shake_left = maxf(0.0, _impact_shake_left - delta)
    _impact_shake_phase += delta * 92.0
    var intensity: float = clampf(_impact_shake_left / maxf(_impact_shake_duration, 0.001), 0.0, 1.0)
    var perpendicular: Vector2 = Vector2(-_impact_shake_direction.y, _impact_shake_direction.x)
    var primary: float = sin(_impact_shake_phase)
    var secondary: float = cos(_impact_shake_phase * 1.73)
    world.position = (
        _impact_shake_direction * primary * 0.72
        + perpendicular * secondary * 0.48
    ) * _impact_shake_strength * intensity

    if _impact_shake_left <= 0.0:
        world.position = Vector2.ZERO
        _impact_shake_strength = 0.0

func play_combat_impact(direction: Vector2, strength: float = 4.5) -> void:
    if not _combat_shake_enabled:
        return
    var safe_direction: Vector2 = direction
    if safe_direction.length_squared() <= 0.001:
        safe_direction = Vector2.RIGHT
    else:
        safe_direction = safe_direction.normalized()

    _impact_shake_direction = safe_direction
    _impact_shake_strength = maxf(_impact_shake_strength, maxf(strength, 0.0))
    _impact_shake_left = _impact_shake_duration
    _impact_shake_phase = 0.0


func set_combat_shake_enabled(enabled: bool) -> void:
    _combat_shake_enabled = enabled
    if not enabled:
        _impact_shake_left = 0.0
        _impact_shake_strength = 0.0
        world.position = Vector2.ZERO

func is_combat_shake_enabled() -> bool:
    return _combat_shake_enabled

func _ensure_default_input() -> void:
    _ensure_key_action("move_up", [KEY_W, KEY_UP])
    _ensure_key_action("move_down", [KEY_S, KEY_DOWN])
    _ensure_key_action("move_left", [KEY_A, KEY_LEFT])
    _ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
    _ensure_key_action("interact", [KEY_E, KEY_ENTER])
    _ensure_key_action("target_next", [KEY_TAB])
    _ensure_key_action("attack_primary", [KEY_SPACE])
    _ensure_key_action("inventory_toggle", [KEY_I])
    _ensure_key_action("save_game", [KEY_F11])
    _ensure_key_action("load_game", [KEY_F12])

func _ensure_key_action(action_name: StringName, keys: Array[int]) -> void:
    if not InputMap.has_action(action_name):
        InputMap.add_action(action_name)

    if not InputMap.action_get_events(action_name).is_empty():
        return

    for keycode: int in keys:
        var event: InputEventKey = InputEventKey.new()
        event.physical_keycode = keycode
        InputMap.action_add_event(action_name, event)

func _spawn_player() -> void:
    if player != null:
        return

    player = PLAYER_SCENE.instantiate() as CharacterBody2D
    if player == null:
        push_error("Player scene could not be instantiated as CharacterBody2D.")
        return

    actor_root.add_child(player)

func request_map_change(scene_path: String, spawn_name: StringName = &"default") -> void:
    if _transition_pending:
        return

    if scene_path.is_empty():
        push_error("Portal requested an empty map path.")
        return

    _transition_pending = true
    call_deferred("_change_map", scene_path, spawn_name)

func _change_map(scene_path: String, spawn_name: StringName = &"default") -> void:
    get_tree().call_group("dialogue_controller", "force_close")

    var next_map: Node2D = null
    if scene_path.begins_with("map://"):
        var map_id: String = scene_path.trim_prefix("map://").strip_edges()
        if map_id.is_empty():
            push_error("Data map id is empty: %s" % scene_path)
            _transition_pending = false
            return
        var map_data_path: String = "res://data/maps/%s.json" % map_id
        if not FileAccess.file_exists(map_data_path):
            push_error("Map data not found: %s" % map_data_path)
            _transition_pending = false
            return
        next_map = DATA_MAP_SCENE.instantiate() as Node2D
        if next_map != null and next_map.has_method("configure"):
            next_map.call("configure", map_id)
    else:
        if not ResourceLoader.exists(scene_path):
            push_error("Map scene not found: %s" % scene_path)
            _transition_pending = false
            return
        var packed_scene: PackedScene = load(scene_path) as PackedScene
        if packed_scene == null:
            push_error("Could not load map scene: %s" % scene_path)
            _transition_pending = false
            return
        next_map = packed_scene.instantiate() as Node2D

    if next_map == null:
        push_error("Could not instantiate map: %s" % scene_path)
        _transition_pending = false
        return

    if player != null and player.has_method("set_play_dead"):
        player.call("set_play_dead", false)
    if player != null and player.has_method("cancel_current_command"):
        player.call("cancel_current_command", true)
    elif player != null and player.has_method("clear_combat_target"):
        player.call("clear_combat_target")

    if current_map != null:
        map_root.remove_child(current_map)
        current_map.queue_free()

    current_map = next_map
    current_map_path = scene_path
    map_root.add_child(current_map)
    _apply_player_movement_bounds()
    _place_player_at_spawn(spawn_name)
    _transition_pending = false
    map_changed.emit(current_map_path, spawn_name)

func _apply_player_movement_bounds() -> void:
    if player == null or current_map == null:
        return

    if current_map.has_method("get_playable_rect"):
        var bounds: Rect2 = current_map.call("get_playable_rect")
        player.call("set_movement_bounds", bounds)
    else:
        player.call("clear_movement_bounds")

func _place_player_at_spawn(spawn_name: StringName) -> void:
    if player == null or current_map == null:
        push_error("Cannot place player: player or map is missing.")
        return

    var spawn_points: Node = current_map.get_node_or_null("SpawnPoints")
    if spawn_points == null:
        push_error("Map has no SpawnPoints node: %s" % current_map.scene_file_path)
        return

    var spawn: Marker2D = spawn_points.get_node_or_null(NodePath(str(spawn_name))) as Marker2D
    if spawn == null and spawn_name != &"default":
        push_warning("Spawn '%s' missing; falling back to 'default'." % spawn_name)
        spawn = spawn_points.get_node_or_null(NodePath("default")) as Marker2D

    if spawn == null:
        push_error("No usable spawn point found in map: %s" % current_map.scene_file_path)
        return

    player.global_position = spawn.global_position
    player.velocity = Vector2.ZERO


func respawn_player() -> void:
    if player == null or current_map == null:
        return
    _apply_player_movement_bounds()
    _place_player_at_spawn(START_SPAWN)
    if player.has_method("cancel_current_command"):
        player.call("cancel_current_command", true)

func _resolve_start_map() -> String:
    var user_args: PackedStringArray = OS.get_cmdline_user_args()
    for arg_value in user_args:
        var arg: String = str(arg_value)
        if arg.begins_with("--play-map="):
            var requested_id: String = arg.trim_prefix("--play-map=").strip_edges()
            var requested_ref: String = "map://%s" % requested_id
            if _map_reference_exists(requested_ref):
                return requested_ref
            push_warning("Requested playtest map does not exist: %s" % requested_id)
    if MOBILE_MODE.is_mobile_mode() and _map_reference_exists(MOBILE_START_MAP):
        return MOBILE_START_MAP
    return START_MAP

func _normalize_map_reference(map_reference: String) -> String:
    if map_reference == "res://world/maps/dev_map.tscn":
        return "map://dev_town"
    if map_reference == "res://world/maps/south_field.tscn":
        return "map://south_field"
    return map_reference

func _map_reference_exists(map_reference: String) -> bool:
    if map_reference.begins_with("map://"):
        var map_id: String = map_reference.trim_prefix("map://").strip_edges()
        if map_id.is_empty():
            return false
        return FileAccess.file_exists("res://data/maps/%s.json" % map_id)
    return ResourceLoader.exists(map_reference)


func get_world_save_state() -> Dictionary:
    var player_position: Array[float] = [0.0, 0.0]
    if player != null:
        player_position = [player.global_position.x, player.global_position.y]

    return {
        "map_path": current_map_path,
        "player_position": player_position
    }

func apply_world_save_state(state: Dictionary) -> bool:
    var saved_map_path: String = _normalize_map_reference(str(state.get("map_path", START_MAP)))
    if saved_map_path.is_empty() or not _map_reference_exists(saved_map_path):
        push_warning("Saved map is missing; using start map instead: %s" % saved_map_path)
        saved_map_path = START_MAP

    _change_map(saved_map_path, START_SPAWN)

    if player == null:
        return false

    var position_variant: Variant = state.get("player_position", [])
    if typeof(position_variant) == TYPE_ARRAY:
        var position_array: Array = position_variant as Array
        if position_array.size() >= 2:
            var saved_position: Vector2 = Vector2(float(position_array[0]), float(position_array[1]))
            if player.has_method("restore_saved_position"):
                player.call("restore_saved_position", saved_position)
            else:
                player.global_position = saved_position

    player.velocity = Vector2.ZERO
    return true

func get_current_playable_rect() -> Rect2:
    if current_map != null and current_map.has_method("get_playable_rect"):
        var rect_variant: Variant = current_map.call("get_playable_rect")
        if typeof(rect_variant) == TYPE_RECT2:
            return rect_variant as Rect2
    return Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))

func get_current_map_name() -> String:
    if current_map != null and current_map.has_method("get_display_name"):
        return str(current_map.call("get_display_name"))
    return current_map_path