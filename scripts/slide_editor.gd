class_name SlideEditor
extends Node2D
## Central input router: picking, selection, palette copies, and forwarding drags to the
## active SlideElement. Add one per Slide. (There is intentionally no score function here:
## scoring goes through SlideObjectives.)

signal selection_changed(element: SlideElement)

## The main slide area: a Control (e.g. a ColorRect) or a Sprite2D.
@export var slide_area: CanvasItem
## Where palette copies are added. Defaults to this node's parent.
@export var elements_root: Node2D
## Dropping an element with its centre outside the slide area deletes it
## (this is also how a palette copy is "put back").
@export var delete_when_dropped_outside: bool = true

var selected: SlideElement
var _active: SlideElement
var _active_is_move: bool = false


func _unhandled_input(event: InputEvent) -> void:
	# _unhandled_input means Control popups on top automatically block editing underneath.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_press()
	elif event is InputEventMouseMotion and _active == null:
		_update_cursor()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		select(null)


# Dragging is polled, not event-driven, so a popup appearing mid-drag cannot strand it.
func _process(_delta: float) -> void:
	if _active == null:
		return
	if not is_instance_valid(_active):
		_active = null
		return
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_release()
		return
	# fake lag trails the cursor; low composure adds a small hand wobble
	var mouse: Vector2 = LagManager.mouse_global() + ComposureManager.hand_offset
	_active.drag_to(mouse, Input.is_key_pressed(KEY_SHIFT))


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
	var p: Vector2 = get_global_mouse_position()

	# 1. Handles of the current selection win (they can sit outside the image).
	if is_instance_valid(selected):
		var h: int = selected.selection_ui.handle_at(selected.to_local(p))
		if h == SelectionUI.Handle.ROTATE:
			selected.begin_rotate(p)
			_activate(selected, false)
			return
		elif h != SelectionUI.Handle.NONE:
			selected.begin_resize(h)
			_activate(selected, false)
			return

	# 2. Topmost placed element, otherwise a palette item (spawns a copy).
	var hit: SlideElement = _pick(p, &"slide_elements")
	if hit == null:
		var tpl: SlideElement = _pick(p, &"palette_items")
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
	var a: SlideElement = _active
	_active = null
	if _active_is_move and delete_when_dropped_outside and _is_outside_slide(a.global_position):
		if selected == a:
			select(null)
		a.queue_free()
		return
	a.end_drag()


func _is_outside_slide(p: Vector2) -> bool:
	if slide_area == null:
		return false
	if slide_area is Control:
		return not (slide_area as Control).get_global_rect().has_point(p)
	if slide_area is Sprite2D:
		var spr: Sprite2D = slide_area as Sprite2D
		return not spr.get_rect().has_point(spr.to_local(p))
	return false


func _spawn_copy(tpl: SlideElement, p: Vector2) -> SlideElement:
	var c: SlideElement = tpl.duplicate() as SlideElement
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
		var e: SlideElement = n as SlideElement
		if e and e.contains_global_point(p) and (best == null or e.z_index >= best.z_index):
			best = e # tree order is draw order, so later elements win ties
	return best


func _update_cursor() -> void:
	if LagManager.busy:
		return # the busy cursor belongs to the fake lag
	var p: Vector2 = get_global_mouse_position()
	var shape: Input.CursorShape = Input.CURSOR_ARROW
	if is_instance_valid(selected):
		var h: int = selected.selection_ui.handle_at(selected.to_local(p))
		if h != SelectionUI.Handle.NONE:
			shape = SelectionUI.cursor_for(h)
	if shape == Input.CURSOR_ARROW:
		if _pick(p, &"slide_elements"):
			shape = Input.CURSOR_MOVE
		elif _pick(p, &"palette_items"):
			shape = Input.CURSOR_POINTING_HAND
	Input.set_default_cursor_shape(shape)
