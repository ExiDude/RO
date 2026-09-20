extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

@onready var target_panel: Panel = $TargetPanel
@onready var title_bar: Panel = $TargetPanel/TitleBar
@onready var target_name: Label = $TargetPanel/Name
@onready var hp_bar: ProgressBar = $TargetPanel/HPBar
@onready var hp_text: Label = $TargetPanel/HPBar/HPText
@onready var meta_text: Label = $TargetPanel/Meta
@onready var distance_text: Label = $TargetPanel/Distance

var _mobile_mode: bool = false

func _ready() -> void:
    _mobile_mode = MOBILE_MODE.is_mobile_mode()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    target_panel.visible = false
    _apply_pre_renewal_skin()
    if _mobile_mode:
        _apply_mobile_layout()


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and _mobile_mode:
        _apply_mobile_layout()

func _apply_mobile_layout() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return
    var safe: Vector4 = MOBILE_MODE.get_safe_margins(viewport_size)
    target_panel.position = Vector2(viewport_size.x - safe.z - 220.0, safe.y + 182.0)
    target_panel.size = Vector2(208.0, 118.0)
    title_bar.size = Vector2(200.0, 24.0)
    target_name.size = Vector2(184.0, target_name.size.y)
    hp_bar.size = Vector2(184.0, hp_bar.size.y)
    meta_text.size = Vector2(184.0, meta_text.size.y)
    distance_text.size = Vector2(184.0, distance_text.size.y)

func _make_panel_style(background: Color, border: Color, width: int = 2) -> StyleBoxFlat:
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
    target_panel.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/window_parchment.svg", 10.0))
    title_bar.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/title_blood.svg", 7.0))
    $TargetPanel/TitleBar/Caption.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
    $TargetPanel/TitleBar/Caption.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.06, 0.92))
    $TargetPanel/TitleBar/Caption.add_theme_constant_override("shadow_offset_x", 1)
    $TargetPanel/TitleBar/Caption.add_theme_constant_override("shadow_offset_y", 1)
    target_name.add_theme_color_override("font_color", Color(0.05, 0.075, 0.13, 1.0))
    target_name.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.72))
    target_name.add_theme_constant_override("shadow_offset_x", 1)
    target_name.add_theme_constant_override("shadow_offset_y", 1)
    meta_text.add_theme_color_override("font_color", Color(0.14, 0.17, 0.24, 1.0))
    distance_text.add_theme_color_override("font_color", Color(0.18, 0.21, 0.29, 1.0))

    var bg: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_bg.svg", 4.0)
    var fill: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_hp.svg", 4.0)
    hp_bar.add_theme_stylebox_override("background", bg)
    hp_bar.add_theme_stylebox_override("fill", fill)
    hp_text.add_theme_color_override("font_color", Color.WHITE)
    hp_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
    hp_text.add_theme_constant_override("shadow_offset_x", 1)
    hp_text.add_theme_constant_override("shadow_offset_y", 1)

func _process(_delta: float) -> void:
    var player: Node = get_tree().get_first_node_in_group("player")
    if player == null or not player.has_method("get_combat_target"):
        target_panel.visible = false
        return

    var target: Node2D = player.call("get_combat_target") as Node2D
    if target == null or not is_instance_valid(target):
        target_panel.visible = false
        return

    if target.has_method("is_alive") and not bool(target.call("is_alive")):
        target_panel.visible = false
        return

    target_panel.visible = true

    var name_value: String = str(target.name)
    if target.has_method("get_display_name"):
        name_value = str(target.call("get_display_name"))
    target_name.text = name_value

    var current_hp: int = 0
    var max_hp: int = 1
    if target.has_method("get_current_hp"):
        current_hp = int(target.call("get_current_hp"))
    if target.has_method("get_max_hp"):
        max_hp = maxi(1, int(target.call("get_max_hp")))

    hp_bar.max_value = float(max_hp)
    hp_bar.value = float(current_hp)
    hp_text.text = "%d / %d HP" % [current_hp, max_hp]

    var level_value: int = int(target.call("get_level")) if target.has_method("get_level") else 1
    var meta_value: String = "Lv. %d" % level_value
    if target.has_method("get_rathena_data"):
        var data_variant: Variant = target.call("get_rathena_data")
        if typeof(data_variant) == TYPE_DICTIONARY:
            var data: Dictionary = data_variant as Dictionary
            var element_name: String = str(data.get("element", ""))
            var element_level: int = int(data.get("element_level", 0))
            var race_name: String = str(data.get("race", ""))
            if not element_name.is_empty():
                meta_value += "   %s %d" % [element_name, element_level]
            if not race_name.is_empty():
                meta_value += "   %s" % race_name
    meta_text.text = meta_value

    var player_2d: Node2D = player as Node2D
    if player_2d != null:
        distance_text.text = "Distance  %d" % roundi(player_2d.global_position.distance_to(target.global_position))