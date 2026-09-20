extends RefCounted

static func is_mobile_mode() -> bool:
    if OS.has_feature("mobile"):
        return true
    for raw_arg: String in OS.get_cmdline_user_args():
        if raw_arg == "--mobile-demo":
            return true
    return false

static func is_real_mobile() -> bool:
    return OS.has_feature("mobile")

static func get_safe_margins(viewport_size: Vector2) -> Vector4:
    if not is_real_mobile():
        return Vector4.ZERO

    var screen_size: Vector2i = DisplayServer.screen_get_size()
    var safe_area: Rect2i = DisplayServer.get_display_safe_area()
    if screen_size.x <= 0 or screen_size.y <= 0 or safe_area.size.x <= 0 or safe_area.size.y <= 0:
        return Vector4.ZERO

    var scale_x: float = viewport_size.x / float(screen_size.x)
    var scale_y: float = viewport_size.y / float(screen_size.y)
    var left: float = maxf(0.0, float(safe_area.position.x) * scale_x)
    var top: float = maxf(0.0, float(safe_area.position.y) * scale_y)
    var right_px: int = maxi(0, screen_size.x - safe_area.end.x)
    var bottom_px: int = maxi(0, screen_size.y - safe_area.end.y)
    var right: float = float(right_px) * scale_x
    var bottom: float = float(bottom_px) * scale_y
    return Vector4(left, top, right, bottom)