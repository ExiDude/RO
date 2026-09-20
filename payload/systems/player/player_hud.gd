extends Control

const MOBILE_MODE: Script = preload("res://systems/mobile/mobile_mode.gd")

@onready var basic_info: Panel = $BasicInfo
@onready var title_bar: Panel = $BasicInfo/TitleBar
@onready var portrait_frame: Panel = $BasicInfo/PortraitFrame
@onready var identity_label: Label = $BasicInfo/Identity
@onready var level_label: Label = $BasicInfo/Levels
@onready var hp_bar: ProgressBar = $BasicInfo/HP
@onready var hp_text: Label = $BasicInfo/HP/Text
@onready var sp_bar: ProgressBar = $BasicInfo/SP
@onready var sp_text: Label = $BasicInfo/SP/Text
@onready var base_bar: ProgressBar = $BasicInfo/BaseEXP
@onready var job_bar: ProgressBar = $BasicInfo/JobEXP
@onready var map_banner: Panel = $MapBanner
@onready var map_name: Label = $MapBanner/Name
@onready var event_toast: Label = $EventToast
@onready var bottom_info: Panel = $BottomInfo
@onready var base_bar_long: ProgressBar = $BottomInfo/BaseEXPLong
@onready var exp_percent: Label = $BottomInfo/Percent
@onready var fade: ColorRect = $Fade

var _player: Node = null
var _map_controller: Node = null
var _banner_tween: Tween = null
var _toast_tween: Tween = null
var _toast_fade_tween: Tween = null
var _fade_tween: Tween = null
var _mobile_mode: bool = false

func _ready() -> void:
    _mobile_mode = MOBILE_MODE.is_mobile_mode()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    map_banner.visible = false
    event_toast.visible = false
    fade.visible = false
    _apply_pre_renewal_skin()
    if _mobile_mode:
        _apply_mobile_layout()
    call_deferred("_bind_sources")


func _notification(what: int) -> void:
    if what == NOTIFICATION_RESIZED and _mobile_mode:
        _apply_mobile_layout()

func _apply_mobile_layout() -> void:
    var viewport_size: Vector2 = get_viewport_rect().size
    if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
        return
    var safe: Vector4 = MOBILE_MODE.get_safe_margins(viewport_size)
    basic_info.position = Vector2(safe.x + 12.0, safe.y + 12.0)
    basic_info.size = Vector2(360.0, 130.0)
    bottom_info.visible = false
    map_banner.position = Vector2(viewport_size.x * 0.5 - 130.0, safe.y + 146.0)
    map_banner.size = Vector2(260.0, 34.0)
    event_toast.position = Vector2(viewport_size.x * 0.5 - 250.0, safe.y + 318.0)
    event_toast.size = Vector2(500.0, 32.0)

func _make_panel_style(background: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.border_width_left = border_width
    style.border_width_top = border_width
    style.border_width_right = border_width
    style.border_width_bottom = border_width
    style.corner_radius_top_left = 2
    style.corner_radius_top_right = 2
    style.corner_radius_bottom_left = 2
    style.corner_radius_bottom_right = 2
    return style

func _make_bar_style(background: Color, border: Color) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = background
    style.border_color = border
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.corner_radius_top_left = 1
    style.corner_radius_top_right = 1
    style.corner_radius_bottom_left = 1
    style.corner_radius_bottom_right = 1
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
    # 3D-rendered Pre-Renewal skin: baked metallic bevels and glossy bars.
    basic_info.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/window_parchment.svg", 10.0))
    title_bar.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/title_blood.svg", 7.0))
    portrait_frame.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/window_dark.svg", 8.0))
    map_banner.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/window_parchment.svg", 10.0))
    bottom_info.add_theme_stylebox_override("panel", _make_texture_style("res://assets/ui/ill_mobile/strip_ornate.svg", 8.0))

    $BasicInfo/TitleBar/Title.add_theme_color_override("font_color", Color(0.98, 0.99, 1.0, 1.0))
    $BasicInfo/TitleBar/Title.add_theme_color_override("font_shadow_color", Color(0.0, 0.02, 0.06, 0.92))
    $BasicInfo/TitleBar/Title.add_theme_constant_override("shadow_offset_x", 1)
    $BasicInfo/TitleBar/Title.add_theme_constant_override("shadow_offset_y", 1)
    identity_label.add_theme_color_override("font_color", Color(0.055, 0.075, 0.12, 1.0))
    identity_label.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.70))
    identity_label.add_theme_constant_override("shadow_offset_x", 1)
    identity_label.add_theme_constant_override("shadow_offset_y", 1)
    level_label.add_theme_color_override("font_color", Color(0.13, 0.16, 0.23, 1.0))
    $BasicInfo/HPLabel.add_theme_color_override("font_color", Color(0.34, 0.06, 0.07, 1.0))
    $BasicInfo/SPLabel.add_theme_color_override("font_color", Color(0.04, 0.12, 0.34, 1.0))
    map_name.add_theme_color_override("font_color", Color(0.08, 0.11, 0.18, 1.0))
    map_name.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.78))
    map_name.add_theme_constant_override("shadow_offset_x", 1)
    map_name.add_theme_constant_override("shadow_offset_y", 1)

    var bar_background: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_bg.svg", 4.0)
    var hp_fill: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_hp.svg", 4.0)
    var sp_fill: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_sp.svg", 4.0)
    var base_fill: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_base.svg", 4.0)
    var job_fill: StyleBoxTexture = _make_texture_style("res://assets/ui/ill_mobile/bar_job.svg", 4.0)

    hp_bar.add_theme_stylebox_override("background", bar_background)
    hp_bar.add_theme_stylebox_override("fill", hp_fill)
    sp_bar.add_theme_stylebox_override("background", bar_background)
    sp_bar.add_theme_stylebox_override("fill", sp_fill)
    base_bar.add_theme_stylebox_override("background", bar_background)
    base_bar.add_theme_stylebox_override("fill", base_fill)
    job_bar.add_theme_stylebox_override("background", bar_background)
    job_bar.add_theme_stylebox_override("fill", job_fill)
    base_bar_long.add_theme_stylebox_override("background", bar_background)
    base_bar_long.add_theme_stylebox_override("fill", base_fill)

    hp_text.add_theme_color_override("font_color", Color.WHITE)
    hp_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
    hp_text.add_theme_constant_override("shadow_offset_x", 1)
    hp_text.add_theme_constant_override("shadow_offset_y", 1)
    sp_text.add_theme_color_override("font_color", Color.WHITE)
    sp_text.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
    sp_text.add_theme_constant_override("shadow_offset_x", 1)
    sp_text.add_theme_constant_override("shadow_offset_y", 1)

func _process(_delta: float) -> void:
    if _player == null or not is_instance_valid(_player):
        return
    _refresh_player_panel()

func _bind_sources() -> void:
    _player = get_tree().get_first_node_in_group("player")
    _map_controller = get_tree().get_first_node_in_group("map_controller")

    if _player != null:
        if _player.has_signal("experience_gained"):
            var exp_callable: Callable = Callable(self, "_on_experience_gained")
            if not _player.is_connected("experience_gained", exp_callable):
                _player.connect("experience_gained", exp_callable)
        if _player.has_signal("level_up"):
            var level_callable: Callable = Callable(self, "_on_level_up")
            if not _player.is_connected("level_up", level_callable):
                _player.connect("level_up", level_callable)

    if _map_controller != null and _map_controller.has_signal("map_changed"):
        var map_callable: Callable = Callable(self, "_on_map_changed")
        if not _map_controller.is_connected("map_changed", map_callable):
            _map_controller.connect("map_changed", map_callable)
        _show_map_banner()

    _refresh_player_panel()

func _refresh_player_panel() -> void:
    if _player == null:
        return

    var character_name_value: String = "Player"
    if _player.has_method("get_character_name"):
        character_name_value = str(_player.call("get_character_name"))
    var job_name_value: String = "Novice"
    if _player.has_method("get_job_name"):
        job_name_value = str(_player.call("get_job_name"))

    var base_level: int = int(_player.call("get_base_level")) if _player.has_method("get_base_level") else 1
    var job_level: int = int(_player.call("get_job_level")) if _player.has_method("get_job_level") else 1
    var current_base: int = int(_player.call("get_base_exp")) if _player.has_method("get_base_exp") else 0
    var required_base: int = int(_player.call("get_base_exp_required")) if _player.has_method("get_base_exp_required") else 0
    var current_job: int = int(_player.call("get_job_exp")) if _player.has_method("get_job_exp") else 0
    var required_job: int = int(_player.call("get_job_exp_required")) if _player.has_method("get_job_exp_required") else 0
    var current_hp: int = int(_player.call("get_current_hp")) if _player.has_method("get_current_hp") else 100
    var max_hp: int = maxi(1, int(_player.call("get_max_hp"))) if _player.has_method("get_max_hp") else 100
    var current_sp: int = int(_player.call("get_current_sp")) if _player.has_method("get_current_sp") else 50
    var max_sp: int = maxi(1, int(_player.call("get_max_sp"))) if _player.has_method("get_max_sp") else 50
    var zeny_value: int = int(_player.call("get_zeny")) if _player.has_method("get_zeny") else 0

    identity_label.text = "%s / %s" % [character_name_value, job_name_value]
    level_label.text = "Base Lv. %d   Job Lv. %d   Zeny %s" % [base_level, job_level, _format_number(zeny_value)]

    hp_bar.max_value = float(max_hp)
    hp_bar.value = float(clampi(current_hp, 0, max_hp))
    hp_text.text = "%d / %d" % [current_hp, max_hp]

    sp_bar.max_value = float(max_sp)
    sp_bar.value = float(clampi(current_sp, 0, max_sp))
    sp_text.text = "%d / %d" % [current_sp, max_sp]

    base_bar.max_value = maxf(1.0, float(required_base))
    base_bar.value = float(current_base)
    job_bar.max_value = maxf(1.0, float(required_job))
    job_bar.value = float(current_job)
    base_bar_long.max_value = maxf(1.0, float(required_base))
    base_bar_long.value = float(current_base)

    var base_percent: float = 100.0 if required_base <= 0 else clampf(float(current_base) / float(required_base) * 100.0, 0.0, 100.0)
    var job_percent: float = 100.0 if required_job <= 0 else clampf(float(current_job) / float(required_job) * 100.0, 0.0, 100.0)
    exp_percent.text = "Base %.2f%%   Job %.2f%%" % [base_percent, job_percent]
    base_bar.tooltip_text = "Base EXP: %d / %d" % [current_base, required_base] if required_base > 0 else "Base EXP: MAX"
    job_bar.tooltip_text = "Job EXP: %d / %d" % [current_job, required_job] if required_job > 0 else "Job EXP: MAX"

func _format_number(value: int) -> String:
    var raw: String = str(maxi(0, value))
    var output: String = ""
    var count: int = 0
    for index in range(raw.length() - 1, -1, -1):
        if count > 0 and count % 3 == 0:
            output = "." + output
        output = raw.substr(index, 1) + output
        count += 1
    return output

func _on_experience_gained(base_amount: int, job_amount: int) -> void:
    _show_toast("+%d Base EXP     +%d Job EXP" % [base_amount, job_amount], false)

func _on_level_up(kind: String, level: int) -> void:
    _show_toast("%s LEVEL UP  →  %d" % [kind.to_upper(), level], true)

func _on_map_changed(_scene_path: String, _spawn_name: StringName) -> void:
    _show_map_banner()
    _play_fade()

func _show_map_banner() -> void:
    if _map_controller == null:
        return
    var display_name: String = "REGION"
    if _map_controller.has_method("get_current_map_name"):
        display_name = str(_map_controller.call("get_current_map_name"))
    map_name.text = display_name
    map_banner.visible = true
    map_banner.modulate = Color.WHITE

    if _banner_tween != null and _banner_tween.is_valid():
        _banner_tween.kill()
    _banner_tween = create_tween()
    _banner_tween.tween_interval(1.15)
    _banner_tween.tween_property(map_banner, "modulate:a", 0.0, 0.42)
    _banner_tween.tween_callback(Callable(self, "_hide_banner"))

func _hide_banner() -> void:
    map_banner.visible = false

func _play_fade() -> void:
    if _fade_tween != null and _fade_tween.is_valid():
        _fade_tween.kill()
    fade.visible = true
    fade.modulate.a = 0.44
    _fade_tween = create_tween()
    _fade_tween.tween_property(fade, "modulate:a", 0.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _fade_tween.tween_callback(Callable(self, "_hide_fade"))

func _hide_fade() -> void:
    fade.visible = false

func _show_toast(message: String, important: bool) -> void:
    if _toast_tween != null and _toast_tween.is_valid():
        _toast_tween.kill()
    if _toast_fade_tween != null and _toast_fade_tween.is_valid():
        _toast_fade_tween.kill()

    event_toast.text = message
    event_toast.visible = true
    event_toast.modulate = Color.WHITE
    event_toast.scale = Vector2(1.08, 1.08) if important else Vector2.ONE
    event_toast.add_theme_color_override("font_color", Color(1.0, 0.82, 0.22, 1.0) if important else Color(0.96, 0.97, 1.0, 1.0))
    event_toast.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.92))
    event_toast.add_theme_constant_override("shadow_offset_x", 1)
    event_toast.add_theme_constant_override("shadow_offset_y", 1)

    _toast_tween = create_tween()
    _toast_tween.set_parallel(true)
    var toast_target_y: float = event_toast.position.y if _mobile_mode else 58.0\n    var toast_start_y: float = toast_target_y + 12.0\n    _toast_tween.tween_property(event_toast, "position:y", toast_target_y, 0.18).from(toast_start_y).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _toast_tween.tween_property(event_toast, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    _toast_fade_tween = create_tween()
    _toast_fade_tween.tween_interval(1.1 if important else 0.78)
    _toast_fade_tween.tween_property(event_toast, "modulate:a", 0.0, 0.34)
    _toast_fade_tween.tween_callback(Callable(self, "_hide_toast"))

func _hide_toast() -> void:
    event_toast.visible = false