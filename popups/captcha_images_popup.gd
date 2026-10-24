class_name CaptchaImagesPopup
extends GamePopup

var _grid: GridContainer
var _tiles: Array[Dictionary] = []
var _wrong: int = 0


func _build(c: VBoxContainer) -> void:
	var title: Label = Label.new()
	title.text = "Select all images containing slides"
	c.add_child(title)
	_grid = GridContainer.new()
	_grid.columns = 3 if complexity < 0.6 else 4
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	c.add_child(_grid)
	var verify: Button = Button.new()
	verify.text = "VERIFY"
	verify.pressed.connect(_on_verify)
	c.add_child(verify)
	_new_round()


func _new_round() -> void:
	for ch in _grid.get_children():
		ch.queue_free()
	_tiles.clear()
	var count: int = _grid.columns * 3
	var slide_count: int = randi_range(3, mini(5, count - 3))
	var flags: Array[bool] = []
	for i in count:
		flags.append(i < slide_count)
	flags.shuffle()
	for is_slide in flags:
		var b: Button = Button.new()
		b.toggle_mode = true
		b.expand_icon = true
		b.custom_minimum_size = Vector2(76, 76)
		var pool: Array[Texture2D] = _cfg.captcha_slide_textures if is_slide else _cfg.captcha_other_textures
		if pool.is_empty():
			b.text = "SLIDE" if is_slide else "photo"
		else:
			b.icon = pool.pick_random()
		_grid.add_child(b)
		_tiles.append({"btn": b, "slide": is_slide})


func _on_verify() -> void:
	for t in _tiles:
		var b: Button = t["btn"]
		if b.button_pressed != t["slide"]:
			_wrong += 1
			penalize(&"wrong")
			_new_round()     # wrong answer: lose composure and get a fresh grid
			return
	succeed(clampf(1.0 - 0.3 * _wrong, 0.4, 1.0))
