class_name SlideTimer
extends Control

signal warning_started
signal critical_started
signal expired

@export var font: Font
@export var font_size: int = 24
@export var padding: Vector2 = Vector2(16, 9)
@export var calm_color: Color = Color("e6eaf2")
@export var warn_color: Color = Color("ffcf5c")
@export var critical_color: Color = Color("ff4d6d")
@export var panel_color: Color = Color(0.07, 0.08, 0.11, 0.6)

var time_limit: float = 0.0
var time_left: float = 0.0
var running: bool = false

var _state: int = 0   # 0 calm, 1 warning (<30s), 2 critical (<10s)
var _sb: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb.set_corner_radius_all(14)
	_sb.set_border_width_all(1)
	var f: Font = font if font else ThemeDB.fallback_font
	var cell: float = f.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var colon: float = f.get_string_size(":", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	custom_minimum_size = Vector2(cell * 4.0 + colon, f.get_height(font_size)) + padding * 2.0


func start(limit: float) -> void:
	time_limit = limit
	time_left = limit
	running = true
	_state = 0


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if running:
		var cfg: GameConfig = GameConfig.get_cfg()
		time_left = maxf(time_left - delta, 0.0)
		if _state < 1 and time_left <= cfg.warn_seconds and time_limit > cfg.warn_seconds:
			_state = 1
			warning_started.emit()
		if _state < 2 and time_left <= cfg.critical_seconds and time_limit > cfg.critical_seconds:
			_state = 2
			critical_started.emit()
		if time_left <= 0.0:
			running = false
			expired.emit()
	queue_redraw()


func _draw() -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	var f: Font = font if font else ThemeDB.fallback_font
	var t: float = Time.get_ticks_msec() * 0.001
	var col: Color = calm_color
	var glow: float = 0.0
	var bump: float = 1.0
	if _state == 1:
		# subtle: colour drifts toward amber, border breathes slowly
		col = calm_color.lerp(warn_color, clampf(inverse_lerp(cfg.warn_seconds, cfg.warn_seconds * 0.6, time_left), 0.0, 1.0))
		glow = 0.5 + 0.5 * sin(t * 2.5)
	elif _state == 2:
		# urgent: red, solid glow, heartbeat pulse on every second
		col = critical_color
		glow = 1.0
		bump = 1.0 + 0.09 * exp(-8.0 * (1.0 - fposmod(time_left, 1.0)))

	_sb.bg_color = panel_color
	_sb.border_color = Color(col.r, col.g, col.b, 0.2 + 0.55 * glow)
	draw_style_box(_sb, Rect2(Vector2.ZERO, size))

	var secs: int = ceili(time_left)
	var txt: String = "%02d:%02d" % [floori(secs / 60.0), secs % 60]
	var cell: float = f.get_string_size("0", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var colon_w: float = f.get_string_size(":", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x: float = (size.x - (cell * 4.0 + colon_w)) * 0.5
	var base_y: float = padding.y + f.get_ascent(font_size)
	var center: Vector2 = size * 0.5
	draw_set_transform(center, 0.0, Vector2(bump, bump))
	for ch in txt:
		var w: float = colon_w if ch == ":" else cell
		var cw: float = f.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(f, Vector2(x + (w - cw) * 0.5, base_y) - center, ch,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
		x += w
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if time_limit > 0.0:
		var frac: float = time_left / time_limit
		var y: float = size.y - 5.0
		draw_line(Vector2(16.0, y), Vector2(16.0 + (size.x - 32.0) * frac, y),
				Color(col.r, col.g, col.b, 0.55), 2.0, true)
