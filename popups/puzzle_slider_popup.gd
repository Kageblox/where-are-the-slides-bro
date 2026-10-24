class_name PuzzleSliderPopup
extends GamePopup

const AREA_W: float = 300.0

class PuzzleArea extends Control:
	var bg: Texture2D
	var gap_x: float = 0.0
	var piece_x: float = 0.0
	var piece: Vector2 = Vector2(52, 52)

	func _draw() -> void:
		var r: Rect2 = Rect2(Vector2.ZERO, size)
		if bg:
			draw_texture_rect(bg, r, false)
		else:
			draw_rect(r, Color("2d3340"))
		var y: float = (size.y - piece.y) * 0.5
		var gap: Rect2 = Rect2(gap_x, y, piece.x, piece.y)
		draw_rect(gap, Color(0, 0, 0, 0.55))
		draw_rect(gap, Color(1, 1, 1, 0.6), false, 2.0)
		var pr: Rect2 = Rect2(piece_x, y, piece.x, piece.y)
		if bg:
			var k: Vector2 = bg.get_size() / size
			draw_texture_rect_region(bg, pr, Rect2(gap.position * k, gap.size * k))
		else:
			draw_rect(pr, Color("e8ecf4"))
		draw_rect(pr, Color("5eead4"), false, 2.0)

var _area: PuzzleArea
var _slider: HSlider
var _target_x: float = 0.0
var _wrong: int = 0


func _build(c: VBoxContainer) -> void:
	var title: Label = Label.new()
	title.text = "Slide the puzzle piece into place"
	c.add_child(title)
	_area = PuzzleArea.new()
	_area.custom_minimum_size = Vector2(AREA_W, 120)
	_area.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not _cfg.captcha_puzzle_backgrounds.is_empty():
		_area.bg = _cfg.captcha_puzzle_backgrounds.pick_random()
	c.add_child(_area)
	_slider = HSlider.new()
	_slider.custom_minimum_size = Vector2(AREA_W, 24)
	_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_slider.max_value = AREA_W - _area.piece.x
	_slider.step = 0.5
	_slider.value_changed.connect(func(v: float) -> void: _target_x = v)
	_slider.drag_ended.connect(_on_drag_ended)
	c.add_child(_slider)
	_new_gap()


func _new_gap() -> void:
	_area.gap_x = randf_range(AREA_W * 0.35, AREA_W - _area.piece.x - 6.0)
	_area.piece_x = 0.0
	_target_x = 0.0
	_slider.value = 0.0
	_area.queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	if _area == null:
		return
	# the piece trails the slider more under lag
	var k: float = lerpf(40.0, 7.0, LagManager.current)
	_area.piece_x = lerpf(_area.piece_x, _target_x, 1.0 - exp(-k * delta))
	_area.queue_redraw()


func _on_drag_ended(_changed: bool) -> void:
	var tolerance: float = lerpf(12.0, 5.0, complexity)
	if absf(_area.gap_x - _slider.value) <= tolerance:
		succeed(clampf(1.0 - 0.3 * _wrong, 0.4, 1.0))
	else:
		_wrong += 1
		penalize(&"wrong")
		_new_gap()
