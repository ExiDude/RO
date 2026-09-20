extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

@onready var info_strip: Panel = $InfoStrip
@onready var menu_panel: Panel = $MenuPanel
@onready var hint_toast: Label = $HintToast
@onready var buttons: HBoxContainer = $MenuPanel/Buttons

var _toast_tween: Tween = null
var _mobile_mode: bool = false

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _mobile_mode = MOBILE_MODE.is_mobile_mode()
    hint_toast.visible = false
    _apply_pre_renewal_skin()
    _apply_mobile_layout()
    $MenuPanel/Buttons/Status.pressed.connect(Callable(self, "_on_status_pressed"))
    $MenuPanel/Buttons/Item.pressed.connect(Callable(self, "_on_item_pressed"))
    $MenuPanel/Buttons/Skill.pressed.connect(Callable(self, "_on_skill_pressed"))
    $MenuPanel/Buttons/Quest.pressed.connect(Callable(self, "_on_quest_pressed"))
    $MenuPanel/Buttons/Map.pressed.connect(Callable(self, "_on_map_pressed"))
    $MenuPanel/Buttons/Option.pressed.connect(Callable(self, "_on_option_pressed"))

func _apply_mobile_layout() -> void:
    if not _mobile_mode:
        return
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return
    var safe: Vector4 = MOBILE_MODE.get_safe_margins(viewport_size)
    info_strip.visible = false
    menu_panel.anchor_left = 0.0
    menu_panel.anchor_top = 1.0
    menu_panel.anchor_right = 1.0
    menu_panel.anchor_bottom = 1.0
    menu_panel.offset_left = safe.x + 10.0
    menu_panel.offset_top = -safe.w - 62.0
    menu_panel.offset_right = -safe.z - 10.0
    menu_panel.offset_bottom = -safe.w - 10.0
    for child: Node in buttons.get_children():
        var button: Button = child as Button
        if button == null:
            continue
        button.custom_minimum_size = Vector2(0.0, 42.0)
        button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        button.add_theme_font_size_override("font_size", 10)
    hint_toast.position = Vector2(safe.x + 18.0, viewport_size.y - safe.w - 104.0)
    hint_toast.size = Vector2(viewport_size.x - safe.x - safe.z - 36.0, 28.0)
    hint_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and _mobile_mode:
        _apply_mobile_layout()

func _make_panel_style(background: Color, border: Color, width: int = 1) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.border_width_left = width
    style.border_width_top = width
    style.border_width_right = width
    style.border_width_bottom = width
    style.corner_radius_top_left = 2
    style.corner_radius_top_right = 2
    style.corner_radius_bottom_left = 2
    style.corner_radius_bottom_right = 2
    return style


func _make_texture_style(texture_path: String, margin: float = 6.0) -> StyleBoxTexture:
    var texture: Texture2D = load(texture_path) as Texture2D
    var style: StyleBoxTexture = StyleBoxTexture.new()
    style.texture = texture
    style.texture_margin_left = margin
    style.texture_margin_top = margin
    style.texture_margin_right = margin
    style.texture_margin_bottom = margin
    return style

func _apply_pre_renewal_skin() -> void:
    info_strip.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/strip_ornate.svg", 8.0))
    menu_panel.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/window_parchment.svg", 10.0))
    $InfoStrip/Channel.add_theme_color_override("font_color", Color(0.04, 0.14, 0.39, 1.0))
    $InfoStrip/Channel.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.75))
    $InfoStrip/Channel.add_theme_constant_override("shadow_offset_x", 1)
    $InfoStrip/Channel.add_theme_constant_override("shadow_offset_y", 1)
    $InfoStrip/Text.add_theme_color_override("font_color", Color(0.08, 0.10, 0.16, 1.0))

    var normal: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/button_normal.svg", 7.0)
    var hover: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/button_hover.svg", 7.0)
    var pressed: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/button_pressed.svg", 7.0)

    for child in buttons.get_children():
        var button: Button = child as Button
        if button == null:
            continue
        button.add_theme_stylebox_override("normal", normal)
        button.add_theme_stylebox_override("hover", hover)
        button.add_theme_stylebox_override("pressed", pressed)
        button.add_theme_stylebox_override("focus", hover)
        button.add_theme_color_override("font_color", Color(0.055, 0.075, 0.13, 1.0))
        button.add_theme_color_override("font_hover_color", Color(0.03, 0.06, 0.13, 1.0))
        button.add_theme_color_override("font_pressed_color", Color(0.96, 0.98, 1.0, 1.0))
        button.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.60))
        button.add_theme_constant_override("shadow_offset_x", 1)
        button.add_theme_constant_override("shadow_offset_y", 1)
        button.add_theme_font_size_override("font_size", 10)

func _get_ro_windows() -> Node:
    return get_tree().get_first_node_in_group("ro_windows")

func _open_ro_window(window_key: String) -> void:
    var windows: Node = _get_ro_windows()
    if windows != null and windows.has_method("toggle_window"):
        windows.call("toggle_window", window_key)
    else:
        _show_hint("RO window system is not available.")

func _on_status_pressed() -> void:
    _open_ro_window("status")

func _on_item_pressed() -> void:
    var inventory_ui: Node = get_tree().get_first_node_in_group("inventory_ui")
    if inventory_ui != null and inventory_ui.has_method("toggle_inventory"):
        inventory_ui.call("toggle_inventory")
    else:
        _show_hint("Inventory UI is not available.")

func _on_skill_pressed() -> void:
    _open_ro_window("skill")

func _on_quest_pressed() -> void:
    _open_ro_window("quest")

func _on_map_pressed() -> void:
    _open_ro_window("map")

func _on_option_pressed() -> void:
    _open_ro_window("option")

func _show_hint(message: String) -> void:
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    hint_toast.text = message
    hint_toast.visible = true
    hint_toast.modulate = Color.WHITE
    hint_toast.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0, 1.0))
    hint_toast.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
    hint_toast.add_theme_constant_override("shadow_offset_x", 1)
    hint_toast.add_theme_constant_override("shadow_offset_y", 1)
    _toast_tween = create_tween()
    _toast_tween.tween_interval(1.1)
    _toast_tween.tween_property(hint_toast, "modulate:a", 0.0, 0.28)
    _toast_tween.tween_callback(Callable(self, "_hide_hint"))

func _hide_hint() -> void:
    hint_toast.visible = false