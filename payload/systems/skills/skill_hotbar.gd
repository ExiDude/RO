extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

const WINDOW_METAL: String = "res://assets/ui/ill_mobile/window_parchment.svg"
const BUTTON_NORMAL: String = "res://assets/ui/ill_mobile/button_normal.svg"
const BUTTON_HOVER: String = "res://assets/ui/ill_mobile/button_hover.svg"
const BUTTON_PRESSED: String = "res://assets/ui/ill_mobile/button_pressed.svg"
const HOTKEYS: Array[int] = [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9]

var _skill_system: Node = null
var _buttons: Array[Button] = []
var _message: Label = null
var _message_tween: Tween = null
var _frame: Panel = null
var _mobile_mode: bool = false

func _ready() -> void:
    add_to_group("skill_hotbar")
    _mobile_mode = MOBILE_MODE.is_mobile_mode()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build_hotbar()
    call_deferred("_bind_skill_system")
    if _mobile_mode:
        call_deferred("_apply_mobile_layout")


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and _mobile_mode:
        _apply_mobile_layout()

func _apply_mobile_layout() -> void:
    if _frame == null:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return
    var safe: Vector4 = MOBILE_MODE.get_safe_margins(viewport_size)
    _frame.position = Vector2(-268.0, -safe.w - 132.0)
    _message.position = Vector2(-280.0, -safe.w - 168.0)

func _unhandled_input(event: InputEvent) -> void:
    var key_event: InputEventKey = event as InputEventKey
    if key_event == null or not key_event.pressed or key_event.echo:
        return
    for slot_index in range(HOTKEYS.size()):
        if key_event.physical_keycode == HOTKEYS[slot_index]:
            _activate_slot(slot_index)
            get_viewport().set_input_as_handled()
            return

func _build_hotbar() -> void:
    _frame = Panel.new()
    _frame.name = "Frame"
    _frame.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
    _frame.position = Vector2(-268.0, -134.0) if _mobile_mode else Vector2(-247.0, -124.0)
    _frame.size = Vector2(536.0, 60.0) if _mobile_mode else Vector2(494.0, 56.0)
    _frame.mouse_filter = Control.MOUSE_FILTER_STOP
    _frame.add_theme_stylebox_override("panel", _make_texture_style(WINDOW_METAL, 9.0))
    add_child(_frame)

    var row: HBoxContainer = HBoxContainer.new()
    row.position = Vector2(7.0, 6.0)
    row.size = Vector2(522.0, 48.0) if _mobile_mode else Vector2(480.0, 44.0)
    row.add_theme_constant_override("separation", 3)
    _frame.add_child(row)

    for slot_index in range(9):
        var button: Button = Button.new()
        button.custom_minimum_size = Vector2(54.0, 48.0) if _mobile_mode else Vector2(50.0, 44.0)
        button.text = "%d\n—" % (slot_index + 1) if _mobile_mode else "F%d\n—" % (slot_index + 1)
        button.focus_mode = Control.FOCUS_NONE
        button.add_theme_font_size_override("font_size", 10 if _mobile_mode else 9)
        button.add_theme_color_override("font_color", Color(0.05, 0.08, 0.15, 1.0))
        button.add_theme_color_override("font_hover_color", Color(0.02, 0.06, 0.16, 1.0))
        button.add_theme_color_override("font_pressed_color", Color(0.96, 0.98, 1.0, 1.0))
        button.add_theme_stylebox_override("normal", _make_texture_style(BUTTON_NORMAL, 7.0))
        button.add_theme_stylebox_override("hover", _make_texture_style(BUTTON_HOVER, 7.0))
        button.add_theme_stylebox_override("pressed", _make_texture_style(BUTTON_PRESSED, 7.0))
        button.add_theme_stylebox_override("focus", _make_texture_style(BUTTON_HOVER, 7.0))
        button.pressed.connect(Callable(self, "_activate_slot").bind(slot_index))
        row.add_child(button)
        _buttons.append(button)

    _message = Label.new()
    _message.position = Vector2(-280.0, -159.0) if _mobile_mode else Vector2(-260.0, -159.0)
    _message.size = Vector2(560.0, 28.0) if _mobile_mode else Vector2(520.0, 28.0)
    _message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _message.add_theme_font_size_override("font_size", 12)
    _message.add_theme_color_override("font_color", Color(1.0, 0.92, 0.54, 1.0))
    _message.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.95))
    _message.add_theme_constant_override("shadow_offset_x", 1)
    _message.add_theme_constant_override("shadow_offset_y", 1)
    _message.visible = false
    _message.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_message)

func _bind_skill_system() -> void:
    _skill_system = get_tree().get_first_node_in_group("skill_controller")
    if _skill_system == null:
        return
    if _skill_system.has_signal("hotbar_changed"):
        var hotbar_callable: Callable = Callable(self, "_refresh")
        if not _skill_system.is_connected("hotbar_changed", hotbar_callable):
            _skill_system.connect("hotbar_changed", hotbar_callable)
    if _skill_system.has_signal("skill_changed"):
        var skill_callable: Callable = Callable(self, "_on_skill_changed")
        if not _skill_system.is_connected("skill_changed", skill_callable):
            _skill_system.connect("skill_changed", skill_callable)
    if _skill_system.has_signal("skill_failed"):
        var failed_callable: Callable = Callable(self, "_on_skill_failed")
        if not _skill_system.is_connected("skill_failed", failed_callable):
            _skill_system.connect("skill_failed", failed_callable)
    if _skill_system.has_signal("skill_used"):
        var used_callable: Callable = Callable(self, "_on_skill_used")
        if not _skill_system.is_connected("skill_used", used_callable):
            _skill_system.connect("skill_used", used_callable)
    _refresh()

func _on_skill_changed(_skill_id: String) -> void:
    _refresh()

func _refresh() -> void:
    if _skill_system == null or not is_instance_valid(_skill_system):
        _skill_system = get_tree().get_first_node_in_group("skill_controller")
    if _skill_system == null:
        return
    for slot_index in range(_buttons.size()):
        var button: Button = _buttons[slot_index]
        var skill_id: String = str(_skill_system.call("get_hotbar_skill", slot_index))
        if skill_id.is_empty():
            button.text = "%d\n—" % (slot_index + 1) if _mobile_mode else "F%d\n—" % (slot_index + 1)
            button.tooltip_text = "Empty slot"
            continue
        var name: String = str(_skill_system.call("get_skill_name", skill_id))
        var short_name: String = name
        if name == "First Aid":
            short_name = "Aid"
        elif name == "Play Dead":
            short_name = "Dead"
        button.text = "%d\n%s" % [slot_index + 1, short_name] if _mobile_mode else "F%d\n%s" % [slot_index + 1, short_name]
        var definition_variant: Variant = _skill_system.call("get_definition", skill_id)
        var definition: Dictionary = definition_variant as Dictionary
        var sp_cost: int = int(definition.get("sp_cost", 0))
        button.tooltip_text = "%s\nSP %d" % [name, sp_cost]

func _activate_slot(slot_index: int) -> void:
    if _skill_system == null or not is_instance_valid(_skill_system):
        _skill_system = get_tree().get_first_node_in_group("skill_controller")
    if _skill_system == null:
        return
    _skill_system.call("use_hotbar_slot", slot_index)

func _on_skill_failed(skill_id: String, reason: String) -> void:
    var name: String = skill_id
    if _skill_system != null and _skill_system.has_method("get_skill_name"):
        name = str(_skill_system.call("get_skill_name", skill_id))
    _show_message("%s: %s" % [name, reason], Color(1.0, 0.55, 0.46, 1.0))

func _on_skill_used(skill_id: String) -> void:
    if _skill_system == null:
        return
    var name: String = str(_skill_system.call("get_skill_name", skill_id))
    _show_message(name, Color(0.72, 0.92, 1.0, 1.0))

func _show_message(text_value: String, color: Color) -> void:
    if _message == null:
        return
    if _message_tween != null and _message_tween.is_valid():
        _message_tween.kill()
    _message.text = text_value
    _message.add_theme_color_override("font_color", color)
    _message.visible = true
    _message.modulate = Color.WHITE
    _message_tween = create_tween()
    _message_tween.tween_interval(0.75)
    _message_tween.tween_property(_message, "modulate:a", 0.0, 0.28)
    _message_tween.tween_callback(Callable(self, "_hide_message"))

func _hide_message() -> void:
    if _message != null:
        _message.visible = false

func _make_texture_style(texture_path: String, margin: float) -> StyleBoxTexture:
    var texture: Texture2D = load(texture_path) as Texture2D
    var style: StyleBoxTexture = StyleBoxTexture.new()
    style.texture = texture
    style.texture_margin_left = margin
    style.texture_margin_top = margin
    style.texture_margin_right = margin
    style.texture_margin_bottom = margin
    return style