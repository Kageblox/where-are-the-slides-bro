class_name SlideElement
extends Area2D
## A selectable, movable, resizable, rotatable slide element.
## Origin == visual centre. Never resized via node scale; use `size`.
## With is_template = true it is a palette thumbnail instead (see SlideEditor).

signal selection_changed(is_selected: bool)
## Fires once the element has settled (after any snap tween).
signal edited(kind: StringName) # &"move" / &"resize" / &"rotate"

@export var size: Vector2 = Vector2(200, 200):
	set(v):
		size = v
		if is_node_ready():
			_sync()
@export var fit_texture_on_ready: bool = true

@export_group("Game")
## Matches a SnapTarget's Expected Id. Palette copies inherit it.
@export var element_id: StringName = &""

@export_group("Palette")
## A palette item is a source thumbnail: pressing it spawns a copy to drag onto the slide.
@export var is_template: bool = false
## Size of the copy on the slide. (0,0) = the texture's native size.
@export var placed_size: Vector2 = Vector2.ZERO

@export_group("Drag")
@export var drag_threshold: float = 4.0
@export var snap_enabled: bool = true
@export var snap_time: float = 0.1

@export_group("Resize")
@export var min_size: Vector2 = Vector2(32, 32)
@export var max_size: Vector2 = Vector2(1600, 1600)
## Corner handles keep aspect ratio; holding Shift inverts this.
@export var keep_aspect_on_corners: bool = true

@export_group("Rotate")
## Applied while holding Shift.
@export var rotation_snap_degrees: float = 15.0
## Soft snap to 0/90/180/270 without Shift. Set 0 to disable.
@export var magnet_degrees: float = 3.0

enum Op { NONE, MOVE, RESIZE, ROTATE }

@onready var visual: Sprite2D = $Visual
@onready var shape_node: CollisionShape2D = $CollisionShape2D
@onready var selection_ui: SelectionUI = $SelectionUI

var is_selected: bool = false
var snapped_to: SnapTarget = null # target the element is locked onto (null if none)

var _op: Op = Op.NONE
var _tween: Tween
# move
var _grab_offset: Vector2 = Vector2.ZERO
var _press_pos: Vector2 = Vector2.ZERO
var _moved: bool = false
# resize
var _handle: int = 0
var _start_xform: Transform2D = Transform2D.IDENTITY
var _start_size: Vector2 = Vector2.ONE
# rotate
var _rot_offset: float = 0.0


func _ready() -> void:
	input_pickable = false # SlideEditor does picking
	# duplicate() copies groups, so set membership explicitly for both cases.
	if is_template:
		add_to_group(&"palette_items")
		remove_from_group(&"slide_elements")
	else:
		add_to_group(&"slide_elements")
		remove_from_group(&"palette_items")
	shape_node.shape = RectangleShape2D.new() # unique per instance; shared shapes would resize together
	shape_node.position = Vector2.ZERO
	visual.centered = true
	visual.offset = Vector2.ZERO
	visual.position = Vector2.ZERO
	selection_ui.visible = false
	if fit_texture_on_ready and not is_template and visual.texture:
		size = visual.texture.get_size()
	_sync()


# ====================== public API ======================

## Call after add_child() when spawning from code.
func set_texture(tex: Texture2D, fit: bool = true) -> void:
	visual.texture = tex
	if fit and tex:
		size = tex.get_size().clamp(min_size, max_size)
	_sync()


func set_selected(v: bool) -> void:
	if is_selected == v:
		return
	is_selected = v
	selection_ui.visible = v
	selection_changed.emit(v)


## Exact for any parent transform, scale, or rotation.
func contains_global_point(p: Vector2) -> bool:
	var l: Vector2 = to_local(p)
	var h: Vector2 = size * 0.5
	return absf(l.x) <= h.x and absf(l.y) <= h.y


## The only place that maps `size` onto the visual and collision shape.
## For text elements, swap Visual for a Label and resize it here.
func _sync() -> void:
	var tex: Texture2D = visual.texture
	if tex and tex.get_size().x > 0.0 and tex.get_size().y > 0.0:
		visual.scale = size / tex.get_size()
	(shape_node.shape as RectangleShape2D).size = size
	selection_ui.queue_redraw()


# ====================== drag API (called by SlideEditor) ======================

func begin_move(mouse: Vector2) -> void:
	_begin(Op.MOVE)
	snapped_to = null
	_press_pos = mouse
	_grab_offset = global_position - mouse # both global, so parent transforms do not matter
	_moved = false


func begin_resize(handle: int) -> void:
	_begin(Op.RESIZE)
	_handle = handle
	_start_xform = global_transform
	_start_size = size


func begin_rotate(mouse: Vector2) -> void:
	_begin(Op.ROTATE)
	_rot_offset = global_rotation - (mouse - global_position).angle()


func drag_to(mouse: Vector2, shift: bool = false) -> void:
	match _op:
		Op.MOVE:
			if not _moved:
				if mouse.distance_to(_press_pos) < drag_threshold:
					return # a plain click should not nudge the element
				_moved = true
			global_position = mouse + _grab_offset
		Op.RESIZE:
			_update_resize(mouse, shift)
		Op.ROTATE:
			_update_rotate(mouse, shift)


func end_drag() -> void:
	match _op:
		Op.MOVE:
			if _moved:
				_settle(&"move")
		Op.RESIZE:
			_settle(&"resize") # a resize shifts the centre, so re-check the snap
		Op.ROTATE:
			edited.emit(&"rotate")
	_op = Op.NONE


func _begin(op: Op) -> void:
	if _tween:
		_tween.kill()
	_op = op


# ====================== resize ======================

func _update_resize(mouse: Vector2, shift: bool) -> void:
	var dir: Vector2 = SelectionUI.dir_of(_handle)
	var anchor: Vector2 = -dir * _start_size * 0.5         # fixed point, start-local space
	var m: Vector2 = _start_xform.affine_inverse() * mouse # mouse in start-local space

	var new_size: Vector2 = _start_size
	if dir.x != 0.0:
		new_size.x = (m.x - anchor.x) * dir.x
	if dir.y != 0.0:
		new_size.y = (m.y - anchor.y) * dir.y

	var is_corner: bool = dir.x != 0.0 and dir.y != 0.0
	if is_corner and (keep_aspect_on_corners != shift):
		var s: float = maxf(new_size.x / _start_size.x, new_size.y / _start_size.y)
		var s_min: float = maxf(min_size.x / _start_size.x, min_size.y / _start_size.y)
		var s_max: float = minf(max_size.x / _start_size.x, max_size.y / _start_size.y)
		new_size = _start_size * clampf(s, s_min, maxf(s_min, s_max))
	else:
		new_size = new_size.clamp(min_size, max_size)

	size = new_size
	# Opposite side stays pinned: the centre shifts by dir * delta / 2.
	global_position = _start_xform * (dir * (new_size - _start_size) * 0.5)


# ====================== rotate ======================

func _update_rotate(mouse: Vector2, shift: bool) -> void:
	var a: float = (mouse - global_position).angle() + _rot_offset
	if shift:
		a = snappedf(a, deg_to_rad(rotation_snap_degrees))
	elif magnet_degrees > 0.0:
		var near: float = snappedf(a, PI * 0.5)
		if absf(angle_difference(a, near)) < deg_to_rad(magnet_degrees):
			a = near
	global_rotation = a


# ====================== snapping (position only, very close range) ======================

## Nearest matching target whose anchor is within its snap_distance.
func find_snap_target() -> SnapTarget:
	var best: SnapTarget = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group(&"targets"):
		var t: SnapTarget = n as SnapTarget
		if t == null or not t.matches(self):
			continue
		var d: float = global_position.distance_to(t.get_anchor())
		if d <= t.snap_distance and d < best_d:
			best = t
			best_d = d
	return best


func _settle(kind: StringName) -> void:
	var t: SnapTarget = find_snap_target() if snap_enabled else null
	snapped_to = t
	if t and not global_position.is_equal_approx(t.get_anchor()):
		_tween = create_tween()
		_tween.tween_property(self, "global_position", t.get_anchor(), snap_time) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_callback(edited.emit.bind(kind))
	else:
		edited.emit(kind)
