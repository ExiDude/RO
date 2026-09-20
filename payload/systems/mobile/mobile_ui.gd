extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")
const WINDOW_DARK: String = "res://assets/ui/ill_mobile/window_dark.svg"
const TITLE_BLOOD: String = "res://assets/ui/ill_mobile/title_blood.svg"
const ATTACK_NORMAL: String = "res://assets/ui/ill_mobile/attack_normal.svg"
const ATTACK_PRESSED: String = "res://assets/ui/ill_mobile/attack_pressed.svg"
const TARGET_ROUND: String = "res://assets/ui/ill_mobile/target_round.svg"
const CANCEL_ROUND: String = "res://assets/ui/ill_mobile/cancel_round.svg"

@onready var minimap_frame: Panel = $MiniMapFrame
@onready var minimap_title: Label = $MiniMapFrame/Title

var _player: Node = null
var _skill_system: Node = null
var _inventory: Node = null
var _map_controller: Node = null
var _action_root: Control = null
var _event_log_frame: Panel = null
var _event_log: Label = null
var _command_frame: Panel = null
var _command_badge: Label = null
var _touch_hint: Label = null
var _hint_tween: Tween = null
var _log_lines: Array[String] = []
var _last_command_text: String = ""
var _safe_margins: Vector4 = Vector4.ZERO

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    if not MOBILE_MODE.is_mobile_mode():
        visible = false
        return

    add_to_group("mobile_ui")
    Input.emulate_mouse_from_touch = false
    _apply_minimap_skin()
    _build_action_cluster()
    _build_event_log()
    _build_command_badge()
    _build_touch_hint()
    call_deferred("_bind_sources")
    call_deferred("_apply_responsive_layout")
    queue_redraw()

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and visible:
        _apply_responsive_layout()
        queue_redraw()

func _draw() -> void:
    if not visible:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return

    var brass: Color = Color(0.39, 0.29, 0.20, 0.72)
    var blood: Color = Color(0.46, 0.045, 0.06, 0.34)
    var shade: Color = Color(0.015, 0.012, 0.011, 0.44)
    draw_rect(Rect2(Vector2.ZERO, Vector2(viewport_size.x, 5.0)), shade, true)
    draw_rect(Rect2(Vector2(0.0, viewport_size.y - 6.0), Vector2(viewport_size.x, 6.0)), shade, true)
    draw_rect(Rect2(Vector2.ZERO, Vector2(5.0, viewport_size.y)), shade, true)
    draw_rect(Rect2(Vector2(viewport_size.x - 5.0, 0.0), Vector2(5.0, viewport_size.y)), shade, true)
    draw_line(Vector2(12.0, 12.0), Vector2(86.0, 12.0), brass, 2.0)
    draw_line(Vector2(12.0, 12.0), Vector2(12.0, 86.0), brass, 2.0)
    draw_line(Vector2(viewport_size.x - 12.0, 12.0), Vector2(viewport_size.x - 86.0, 12.0), brass, 2.0)
    draw_line(Vector2(viewport_size.x - 12.0, 12.0), Vector2(viewport_size.x - 12.0, 86.0), brass, 2.0)
    draw_circle(Vector2(viewport_size.x * 0.5, viewport_size.y - 8.0), 4.0, blood)

func _process(_delta: float) -> void:
    if not visible:
        return
    var player_node: Node = _get_player()
    if player_node == null or _command_badge == null:
        return

    var command_text: String = "BEREIT"
    if player_node.has_method("get_current_command_name"):
        command_text = str(player_node.call("get_current_command_name"))

    var target: Node2D = null
    if player_node.has_method("get_combat_target"):
        target = player_node.call("get_combat_target") as Node2D
    if target != null and is_instance_valid(target):
        var target_name: String = str(target.name)
        if target.has_method("get_display_name"):
            target_name = str(target.call("get_display_name"))
        var player_2d: Node2D = player_node as Node2D
        if player_2d != null:
            var distance: int = roundi(player_2d.global_position.distance_to(target.global_position))
            command_text += "   •   %s   •   %d px" % [target_name, distance]

    if command_text != _last_command_text:
        _last_command_text = command_text
        _command_badge.text = command_text

func _apply_minimap_skin() -> void:
    minimap_frame.add_theme_stylebox_override("panel", _make_texture_style(WINDOW_DARK, 9.0))
    minimap_title.add_theme_color_override("font_color", Color(0.92, 0.80, 0.60, 1.0))
    minimap_title.add_theme_color_override("font_shadow_color", Color(0.02, 0.01, 0.01, 0.98))
    minimap_title.add_theme_constant_override("shadow_offset_x", 1)
    minimap_title.add_theme_constant_override("shadow_offset_y", 1)

func _build_action_cluster() -> void:
    _action_root = Control.new()
    _action_root.name = "CombatTouchCluster"
    _action_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    _action_root.size = Vector2(216.0, 206.0)
    _action_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_action_root)

    var target_button: TextureButton = _make_round_button(TARGET_ROUND, TARGET_ROUND, Vector2(0.0, 4.0), Vector2(82.0, 82.0), "ZIEL")
    target_button.tooltip_text = "Nächstes Ziel"
    target_button.pressed.connect(Callable(self, "_on_target_pressed"))
    _action_root.add_child(target_button)

    var cancel_button: TextureButton = _make_round_button(CANCEL_ROUND, CANCEL_ROUND, Vector2(90.0, 4.0), Vector2(82.0, 82.0), "ABBR.")
    cancel_button.tooltip_text = "Bewegung / Ziel abbrechen"
    cancel_button.pressed.connect(Callable(self, "_on_cancel_pressed"))
    _action_root.add_child(cancel_button)

    var attack_button: TextureButton = _make_round_button(ATTACK_NORMAL, ATTACK_PRESSED, Vector2(80.0, 88.0), Vector2(126.0, 126.0), "ANGRIFF")
    attack_button.tooltip_text = "Auto-Approach + Auto-Attack"
    attack_button.pressed.connect(Callable(self, "_on_attack_pressed"))
    _action_root.add_child(attack_button)

func _make_round_button(normal_path: String, pressed_path: String, position_value: Vector2, size_value: Vector2, caption: String) -> TextureButton:
    var button: TextureButton = TextureButton.new()
    button.position = position_value
    button.size = size_value
    button.texture_normal = load(normal_path) as Texture2D
    button.texture_pressed = load(pressed_path) as Texture2D
    button.texture_hover = button.texture_normal
    button.ignore_texture_size = true
    button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP

    var label: Label = Label.new()
    label.set_anchors_preset(Control.PRESET_FULL_RECT)
    label.offset_top = size_value.y * 0.58
    label.text = caption
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 11 if size_value.x < 100.0 else 13)
    label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72, 1.0))
    label.add_theme_color_override("font_shadow_color", Color(0.03, 0.01, 0.01, 0.96))
    label.add_theme_constant_override("shadow_offset_x", 1)
    label.add_theme_constant_override("shadow_offset_y", 1)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    button.add_child(label)
    return button

func _build_event_log() -> void:
    _event_log_frame = Panel.new()
    _event_log_frame.name = "MobileCombatLog"
    _event_log_frame.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    _event_log_frame.size = Vector2(332.0, 96.0)
    _event_log_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _event_log_frame.add_theme_stylebox_override("panel", _make_texture_style(WINDOW_DARK, 10.0))
    add_child(_event_log_frame)

    var title: Label = Label.new()
    title.position = Vector2(10.0, 6.0)
    title.size = Vector2(312.0, 18.0)
    title.text = "ALLE   SYSTEM   KAMPF"
    title.add_theme_font_size_override("font_size", 10)
    title.add_theme_color_override("font_color", Color(0.86, 0.70, 0.48, 1.0))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _event_log_frame.add_child(title)

    _event_log = Label.new()
    _event_log.position = Vector2(10.0, 25.0)
    _event_log.size = Vector2(312.0, 64.0)
    _event_log.text = "[System] Touch-Steuerung bereit."
    _event_log.add_theme_font_size_override("font_size", 10)
    _event_log.add_theme_color_override("font_color", Color(0.91, 0.88, 0.78, 1.0))
    _event_log.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    _event_log.add_theme_constant_override("shadow_offset_x", 1)
    _event_log.add_theme_constant_override("shadow_offset_y", 1)
    _event_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _event_log_frame.add_child(_event_log)
    _log_lines.append("[System] Touch-Steuerung bereit.")

func _build_command_badge() -> void:
    _command_frame = Panel.new()
    _command_frame.name = "CommandBadgeFrame"
    _command_frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    _command_frame.size = Vector2(360.0, 30.0)
    _command_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _command_frame.add_theme_stylebox_override("panel", _make_texture_style(TITLE_BLOOD, 7.0))
    add_child(_command_frame)

    _command_badge = Label.new()
    _command_badge.set_anchors_preset(Control.PRESET_FULL_RECT)
    _command_badge.offset_left = 10.0
    _command_badge.offset_right = -10.0
    _command_badge.text = "BEREIT"
    _command_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _command_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _command_badge.add_theme_font_size_override("font_size", 11)
    _command_badge.add_theme_color_override("font_color", Color(0.96, 0.88, 0.72, 1.0))
    _command_badge.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    _command_badge.add_theme_constant_override("shadow_offset_x", 1)
    _command_badge.add_theme_constant_override("shadow_offset_y", 1)
    _command_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _command_frame.add_child(_command_badge)

func _build_touch_hint() -> void:
    _touch_hint = Label.new()
    _touch_hint.name = "TouchHint"
    _touch_hint.set_anchors_preset(Control.PRESET_CENTER)
    _touch_hint.size = Vector2(520.0, 32.0)
    _touch_hint.text = "TIPPE BODEN = LAUFEN   •   TIPPE GEGNER = AUTO-ANGRIFF"
    _touch_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _touch_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _touch_hint.add_theme_font_size_override("font_size", 11)
    _touch_hint.add_theme_color_override("font_color", Color(1.0, 0.90, 0.68, 1.0))
    _touch_hint.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.98))
    _touch_hint.add_theme_constant_override("shadow_offset_x", 2)
    _touch_hint.add_theme_constant_override("shadow_offset_y", 2)
    _touch_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_touch_hint)

    _hint_tween = create_tween()
    _hint_tween.tween_interval(3.8)
    _hint_tween.tween_property(_touch_hint, "modulate:a", 0.0, 0.45)
    _hint_tween.tween_callback(Callable(self, "_hide_touch_hint"))

func _bind_sources() -> void:
    _player = get_tree().get_first_node_in_group("player")
    _skill_system = get_tree().get_first_node_in_group("skill_controller")
    _inventory = get_tree().get_first_node_in_group("inventory_controller")
    _map_controller = get_tree().get_first_node_in_group("map_controller")

    if _player != null and _player.has_signal("combat_feedback"):
        var feedback_callable: Callable = Callable(self, "_on_combat_feedback")
        if not _player.is_connected("combat_feedback", feedback_callable):
            _player.connect("combat_feedback", feedback_callable)

    if _skill_system != null:
        if _skill_system.has_signal("skill_used"):
            var used_callable: Callable = Callable(self, "_on_skill_used")
            if not _skill_system.is_connected("skill_used", used_callable):
                _skill_system.connect("skill_used", used_callable)
        if _skill_system.has_signal("skill_failed"):
            var failed_callable: Callable = Callable(self, "_on_skill_failed")
            if not _skill_system.is_connected("skill_failed", failed_callable):
                _skill_system.connect("skill_failed", failed_callable)

    if _inventory != null and _inventory.has_signal("item_added"):
        var item_callable: Callable = Callable(self, "_on_item_added")
        if not _inventory.is_connected("item_added", item_callable):
            _inventory.connect("item_added", item_callable)

    if _map_controller != null and _map_controller.has_signal("map_changed"):
        var map_callable: Callable = Callable(self, "_on_map_changed")
        if not _map_controller.is_connected("map_changed", map_callable):
            _map_controller.connect("map_changed", map_callable)
        _refresh_map_title()

func _get_player() -> Node:
    if _player == null or not is_instance_valid(_player):
        _player = get_tree().get_first_node_in_group("player")
    return _player

func _on_target_pressed() -> void:
    var player_node: Node = _get_player()
    if player_node != null and player_node.has_method("select_nearest_target"):
        player_node.call("select_nearest_target")
        _pulse(18)

func _on_attack_pressed() -> void:
    var player_node: Node = _get_player()
    if player_node != null and player_node.has_method("attack_selected_target_with_approach"):
        player_node.call("attack_selected_target_with_approach")
        _pulse(28)
    elif player_node != null and player_node.has_method("attack_current_target"):
        player_node.call("attack_current_target")
        _pulse(28)

func _on_cancel_pressed() -> void:
    var player_node: Node = _get_player()
    if player_node != null and player_node.has_method("cancel_current_command"):
        player_node.call("cancel_current_command", true)
        _pulse(14)

func _on_combat_feedback(message: String, category: String) -> void:
    if category == "move":
        return
    var prefix: String = "[Kampf]"
    if category == "target" or category == "system":
        prefix = "[System]"
    elif category == "damage" or category == "critical_damage":
        prefix = "[Treffer]"
    _append_log("%s %s" % [prefix, message])
    if category == "critical" or category == "critical_damage":
        _pulse(42)
    elif category == "hit" or category == "damage":
        _pulse(20)

func _on_skill_used(skill_id: String) -> void:
    var skill_name: String = skill_id
    if _skill_system != null and _skill_system.has_method("get_skill_name"):
        skill_name = str(_skill_system.call("get_skill_name", skill_id))
    _append_log("[Skill] %s" % skill_name)
    _pulse(18)

func _on_skill_failed(skill_id: String, reason: String) -> void:
    var skill_name: String = skill_id
    if _skill_system != null and _skill_system.has_method("get_skill_name"):
        skill_name = str(_skill_system.call("get_skill_name", skill_id))
    _append_log("[Skill] %s: %s" % [skill_name, reason])

func _on_item_added(item_id: String, amount: int) -> void:
    var item_name: String = item_id
    if _inventory != null and _inventory.has_method("get_display_name"):
        item_name = str(_inventory.call("get_display_name", item_id))
    _append_log("[Loot] %d × %s" % [amount, item_name])
    _pulse(12)

func _on_map_changed(_scene_path: String, _spawn_name: StringName) -> void:
    _refresh_map_title()

func _refresh_map_title() -> void:
    if _map_controller == null or not is_instance_valid(_map_controller):
        _map_controller = get_tree().get_first_node_in_group("map_controller")
    if _map_controller != null and _map_controller.has_method("get_current_map_name"):
        minimap_title.text = str(_map_controller.call("get_current_map_name")).to_upper()

func _append_log(line: String) -> void:
    _log_lines.append(line)
    while _log_lines.size() > 4:
        _log_lines.remove_at(0)
    if _event_log != null:
        var output: String = ""
        for index in range(_log_lines.size()):
            if index > 0:
                output += "\n"
            output += _log_lines[index]
        _event_log.text = output

func _pulse(duration_msec: int) -> void:
    if MOBILE_MODE.is_real_mobile():
        Input.vibrate_handheld(duration_msec)

func _hide_touch_hint() -> void:
    if _touch_hint != null:
        _touch_hint.visible = false

func _apply_responsive_layout() -> void:
    if _action_root == null or _event_log_frame == null or _command_frame == null:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return
    _safe_margins = MOBILE_MODE.get_safe_margins(viewport_size)
    var safe_left: float = _safe_margins.x
    var safe_top: float = _safe_margins.y
    var safe_right: float = _safe_margins.z
    var safe_bottom: float = _safe_margins.w
    var portrait: bool = viewport_size.y > viewport_size.x

    if portrait:
        minimap_frame.position = Vector2(viewport_size.x - safe_right - 184.0, safe_top + 12.0)
        minimap_frame.size = Vector2(172.0, 156.0)
        _action_root.position = Vector2(-safe_right - 220.0, -safe_bottom - 430.0)
        _action_root.scale = Vector2(0.92, 0.92)
        _event_log_frame.position = Vector2(safe_left + 12.0, -safe_bottom - 316.0)
        _command_frame.position = Vector2(-180.0, -safe_bottom - 194.0)
        _touch_hint.position = Vector2(-260.0, 132.0)
    else:
        minimap_frame.position = Vector2(viewport_size.x - safe_right - 184.0, safe_top + 12.0)
        minimap_frame.size = Vector2(172.0, 156.0)
        _action_root.position = Vector2(-safe_right - 228.0, -safe_bottom - 346.0)
        _action_root.scale = Vector2.ONE
        _event_log_frame.position = Vector2(safe_left + 14.0, -safe_bottom - 270.0)
        _command_frame.position = Vector2(-180.0, -safe_bottom - 164.0)
        _touch_hint.position = Vector2(-260.0, 158.0)

func _make_texture_style(texture_path: String, margin: float) -> StyleBoxTexture:
    var texture: Texture2D = load(texture_path) as Texture2D
    var style: StyleBoxTexture = StyleBoxTexture.new()
    style.texture = texture
    style.texture_margin_left = margin
    style.texture_margin_top = margin
    style.texture_margin_right = margin
    style.texture_margin_bottom = margin
    return style