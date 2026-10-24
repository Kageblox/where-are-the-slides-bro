class_name Screens
extends Control

signal next_slide_pressed
signal restart_pressed

var _dim: ColorRect = ColorRect.new()
var _box: VBoxContainer = VBoxContainer.new()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_dim) # also blocks clicks on the game while a screen is showing
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("1b1f2a")
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	_box.custom_minimum_size.x = 380
	_box.add_theme_constant_override("separation", 10)
	panel.add_child(_box)


func show_slide_result(rec: Dictionary) -> void:
	_clear()
	_dim.color = Color(0, 0, 0, 0.55)
	var score: float = rec["score"]
	_label("SLIDE %d" % int(rec["slide_number"]), 14, Color(1, 1, 1, 0.6))
	_label(ScoreManager.letter(score), 64, Color("5eead4"))
	_label("%d / 100" % roundi(score), 22)
	if rec["timed_out"]:
		_label("Out of time", 15, Color("ff4d6d"))
	else:
		_label("Finished in %ds of %ds" % [roundi(rec["time_taken"]), roundi(rec["time_limit"])], 15, Color(1, 1, 1, 0.7))
	var cats: Array = [["Typing", "typing_score"], ["Placement", "placement_score"],
			["Size", "resize_score"], ["Rotation", "rotation_score"]]
	for pair in cats:
		var v: float = rec[pair[1]]
		if v >= 0.0:   # -1 = this slide had no such objective
			_label("%s: %d%%" % [pair[0], roundi(v)], 15, Color(1, 1, 1, 0.8))
	_label("Popups handled: %d%%" % roundi(float(rec["popup_success_rate"]) * 100.0), 15, Color(1, 1, 1, 0.8))
	var btn: Button = Button.new()
	btn.text = "Submit presentation" if SlideManager.is_final_slide() else "Next slide"
	btn.pressed.connect(func() -> void:
		visible = false
		next_slide_pressed.emit())
	_box.add_child(btn)
	visible = true


func show_ending(s: Dictionary) -> void:
	_clear()
	var ending: int = s["ending"]
	var crashed: bool = ending == GameManager.Ending.COMPUTER_DEATH
	_dim.color = Color("0b57d0") if crashed else Color(0, 0, 0, 0.8)
	if crashed:
		_label(":(", 72)
		_label("Your PC ran into a problem and needs to restart.", 20)
	elif ending == GameManager.Ending.ACADEMIC_FAILURE:
		_label("F", 96, Color("ff4d6d"))
		_label("You failed the presentation.", 22)
	else:
		_label(String(s["grade"]), 96, Color("5eead4"))
		_label("Presentation complete", 22)
	_label("Final score: %d" % roundi(s["final_score"]), 16)
	_label("Composure: %s (%d%%)" % [s["composure_label"], roundi(s["composure"])], 15, Color(1, 1, 1, 0.8))
	_label("Computer: %s (%d%% infected)" % [s["virus_label"], roundi(s["virus"])], 15, Color(1, 1, 1, 0.8))
	_label(String(s["epilogue"]), 16, Color(1, 1, 1, 0.9))
	var btn: Button = Button.new()
	btn.text = "Play again"
	btn.pressed.connect(func() -> void: restart_pressed.emit())
	_box.add_child(btn)
	visible = true


func _clear() -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()


func _label(text: String, font_size: int = 16, color: Color = Color.WHITE) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(l)
	return l
