class_name HudBars
extends Control
## Presentation / Composure / Virus bars. Presentation shows the CURRENT slide's live score.

@export var bar_size: Vector2 = Vector2(200, 10)
@export var row_gap: float = 30.0
@export var font_size: int = 12
@export var score_color: Color = Color("5eead4")
@export var composure_color: Color = Color("60a5fa")
@export var virus_color: Color = Color("ff4d6d")
@export var track_color: Color = Color(1, 1, 1, 0.1)

var _target: Dictionary = {"score": 0.0, "composure": 100.0, "virus": 0.0}
var _shown: Dictionary = {"score": 0.0, "composure": 100.0, "virus": 0.0}
var _track: StyleBoxFlat = StyleBoxFlat.new()
var _fill: StyleBoxFlat = StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(bar_size.x, row_gap * 3.0)
	_track.set_corner_radius_all(int(bar_size.y * 0.5))
	_fill.set_corner_radius_all(int(bar_size.y * 0.5))
	_track.bg_color = track_color
	ScoreManager.score_changed.connect(func(live: float, _g: float) -> void: _target["score"] = live)
	ComposureManager.composure_changed.connect(func(v: float, _d: float, _r: StringName) -> void: _target["composure"] = v)
	VirusManager.virus_changed.connect(func(v: float, _d: float, _r: StringName) -> void: _target["virus"] = v)


func _process(delta: float) -> void:
	for k in _shown:
		_shown[k] = lerpf(_shown[k], _target[k], 1.0 - exp(-8.0 * delta))
	queue_redraw()


func _draw() -> void:
	var f: Font = ThemeDB.fallback_font
	var rows: Array = [
		["PRESENTATION", "score", score_color],
		["COMPOSURE", "composure", composure_color],
		["VIRUS", "virus", virus_color],
	]
	for i in rows.size():
		var y: float = i * row_gap
		var key: String = rows[i][1]
		var col: Color = rows[i][2]
		draw_string(f, Vector2(0, y + font_size), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.65))
		var r: Rect2 = Rect2(0, y + font_size + 5.0, bar_size.x, bar_size.y)
		draw_style_box(_track, r)
		var frac: float = clampf(float(_shown[key]) / 100.0, 0.0, 1.0)
		if frac > 0.01:
			_fill.bg_color = col
			draw_style_box(_fill, Rect2(r.position, Vector2(maxf(bar_size.y, bar_size.x * frac), bar_size.y)))
