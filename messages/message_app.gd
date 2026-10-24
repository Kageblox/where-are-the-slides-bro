class_name MessageApp
extends PanelContainer

var _head: Button
var _body: VBoxContainer
var _text: Label
var _bar: ProgressBar
var _replies: VBoxContainer
var _open: bool = false
var _unread: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(300, 0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("1f2430")
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(12)
	add_theme_stylebox_override("panel", sb)
	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	add_child(root)
	_head = Button.new()
	_head.text = "Messages"
	_head.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_head.pressed.connect(_toggle)
	root.add_child(_head)
	_body = VBoxContainer.new()
	_body.visible = false
	_body.add_theme_constant_override("separation", 8)
	root.add_child(_body)
	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 270
	_body.add_child(_text)
	_bar = ProgressBar.new()
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.custom_minimum_size.y = 5
	_body.add_child(_bar)
	_replies = VBoxContainer.new()
	_replies.add_theme_constant_override("separation", 6)
	_body.add_child(_replies)

	MessageManager.message_received.connect(_on_received)
	MessageManager.message_answered.connect(func(_m, _r, _t) -> void: _close())
	MessageManager.message_ignored.connect(func(_m) -> void: _close())


func _on_received(msg: MessageData) -> void:
	_unread = true
	_head.text = "%s  -  new message" % msg.sender
	_text.text = msg.text
	for ch in _replies.get_children():
		ch.queue_free()
	for i in msg.replies.size():
		var b: Button = Button.new()
		b.text = msg.replies[i].text
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func() -> void: MessageManager.answer(i))
		_replies.add_child(b)


func _toggle() -> void:
	if MessageManager.current == null:
		return
	if _open:
		_open = false
		_body.visible = false
		return
	_open = true
	_unread = false
	var d: float = LagManager.open_delay()
	if d > 0.1:
		_head.text = "Loading..."
		await get_tree().create_timer(d).timeout
	if MessageManager.current != null:
		_head.text = MessageManager.current.sender
		_body.visible = _open


func _close() -> void:
	_open = false
	_unread = false
	_body.visible = false
	_head.text = "Messages"
	_head.modulate.a = 1.0


func _process(_delta: float) -> void:
	if _unread and not _open:
		var rate: float = 5.0 * ComposureManager.notification_multiplier()
		_head.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.001 * rate)
	if _open:
		_bar.value = MessageManager.patience_fraction()
