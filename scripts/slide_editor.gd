class_name SlideEditor
extends Node2D
## Central input router: picking, selection, palette copies, and forwarding
## drags to the active SlideElement. Add one per Slide.

signal selection_changed(element: SlideElement)

## Control (e.g. a ColorRect) covering the main slide area.
@export var slide_area: Control
## Where palette copies are added. Defaults to this node's parent.
@export var elements_root: Node2D
## Dropping an element with its centre outside the slide area deletes it
## (this is also how a palette copy is "put back").
@export var delete_when_dropped_outside := true

var selected: SlideElement
var _active: SlideElement
var _active_is_move := false


func _unhandled_input(event: InputEvent) -> void:
	# _unhandled_input means Control popups on top automatically block editing underneath.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_press()
	elif event is InputEventMouseMotion and _active == null:
		_update_cursor()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		select(null)


# Dragging is polled, not event-driven, so a popup appearing mid-drag can't strand it.
func _process(_delta: float) -> void:
	if _active == null:
		return
	if not is_instance_valid(_active):
		_active = null
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_release()
		return
	_active.drag_to(get_global_mouse_position(), Input.is_key_pressed(KEY_SHIFT))


## Total score for the slide. Call this when the round ends.
func score_slide() -> Dictionary:
	var total := 0.0
	var max_total := 0.0
	var details: Array = []
	for n in get_tree().get_nodes_in_group(&"targets"):
		var t := n as SnapTarget
		if t == null:
			continue
		var r := t.score()
		total += r["points"]
		max_total += t.max_points
		details.append({"target": t, "result": r})
	return {"points": total, "max_points": max_total, "details": details}


func select(e: SlideElement) -> void:
	if e == selected:
		return
	if is_instance_valid(selected):
		selected.set_selected(false)
	selected = e
	if e:
		e.set_selected(true)
		e.get_parent().move_child(e, -1) # bring to front
	selection_changed.emit(e)


func _on_press() -> void:
	var p := get_global_mouse_position()

	# 1. Handles of the current selection win (they can sit outside the image).
	if is_instance_valid(selected):
		var h := selected.selection_ui.handle_at(selected.to_local(p))
		if h == SelectionUI.Handle.ROTATE:
			selected.begin_rotate(p)
			_activate(selected, false)
			return
		elif h != SelectionUI.Handle.NONE:
			selected.begin_resize(h)
			_activate(selected, false)
			return

	# 2. Topmost placed element, otherwise a palette item (spawns a copy).
	var hit := _pick(p, &"slide_elements")
	if hit == null:
		var tpl := _pick(p, &"palette_items")
		if tpl:
			hit = _spawn_copy(tpl, p)

	select(hit) # null = empty space = deselect
	if hit:
		hit.begin_move(p)
		_activate(hit, true)


func _activate(e: SlideElement, is_move: bool) -> void:
	_active = e
	_active_is_move = is_move


func _release() -> void:
	var a := _active
	_active = null
	if _active_is_move and delete_when_dropped_outside and _is_outside_slide(a.global_position):
		if selected == a:
			select(null)
		a.queue_free()
		return
	a.end_drag()


func _is_outside_slide(p: Vector2) -> bool:
	return slide_area != null and not slide_area.get_global_rect().has_point(p)


func _spawn_copy(tpl: SlideElement, p: Vector2) -> SlideElement:
	var c := tpl.duplicate() as SlideElement
	c.is_template = false
	var root: Node = elements_root if elements_root else get_parent()
	root.add_child(c) # _ready runs here
	c.global_position = p # centred on the cursor, so the grab offset is zero
	c.global_rotation = 0.0
	var s: Vector2 = tpl.placed_size
	if s == Vector2.ZERO and c.visual.texture:
		s = c.visual.texture.get_size()
	c.size = s.clamp(c.min_size, c.max_size)
	return c


func _pick(p: Vector2, group: StringName) -> SlideElement:
	var best: SlideElement = null
	for n in get_tree().get_nodes_in_group(group):
		var e := n as SlideElement
		if e and e.contains_global_point(p) and (best == null or e.z_index >= best.z_index):
			best = e # tree order is draw order, so later elements win ties
	return best


func _update_cursor() -> void:
	var p := get_global_mouse_position()
	var shape: Input.CursorShape = Input.CURSOR_ARROW
	if is_instance_valid(selected):
		var h := selected.selection_ui.handle_at(selected.to_local(p))
		if h != SelectionUI.Handle.NONE:
			shape = SelectionUI.cursor_for(h)
	if shape == Input.CURSOR_ARROW:
		if _pick(p, &"slide_elements"):
			shape = Input.CURSOR_MOVE
		elif _pick(p, &"palette_items"):
			shape = Input.CURSOR_POINTING_HAND
	Input.set_default_cursor_shape(shape)
