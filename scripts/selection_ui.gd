class_name SelectionUI
extends Node2D
## Draws the selection box, 8 resize handles and a rotation handle in the element's local space,
## and hit-tests them. Handles stay a constant screen size.

enum Handle { NONE, TL, TR, BR, BL, T, R, B, L, ROTATE }

# Corners first so they win hit-tests on tiny elements.
const DIRS: Dictionary = {
	Handle.TL: Vector2(-1, -1), Handle.TR: Vector2(1, -1),
	Handle.BR: Vector2(1, 1), Handle.BL: Vector2(-1, 1),
	Handle.T: Vector2(0, -1), Handle.R: Vector2(1, 0),
	Handle.B: Vector2(0, 1), Handle.L: Vector2(-1, 0),
}

@export var accent: Color = Color("4f8cff")
@export var handle_px: float = 10.0
@export var rotate_distance_px: float = 28.0
@export var line_px: float = 1.5
@export var hit_padding_px: float = 6.0

@onready var _el: SlideElement = get_parent() as SlideElement


static func dir_of(h: int) -> Vector2:
	var d: Vector2 = DIRS.get(h, Vector2.ZERO)
	return d


static func cursor_for(h: int) -> Input.CursorShape:
	match h:
		Handle.TL, Handle.BR:
			return Input.CURSOR_FDIAGSIZE
		Handle.TR, Handle.BL:
			return Input.CURSOR_BDIAGSIZE
		Handle.T, Handle.B:
			return Input.CURSOR_VSIZE
		Handle.L, Handle.R:
			return Input.CURSOR_HSIZE
		Handle.ROTATE:
			return Input.CURSOR_POINTING_HAND
	return Input.CURSOR_ARROW


## One screen pixel in local units (assumes uniform scale, no camera zoom).
func px() -> float:
	return 1.0 / maxf(get_global_transform().get_scale().x, 0.001)


## `local` is in the element's local space: element.to_local(mouse).
func handle_at(local: Vector2) -> int:
	if not visible or _el == null:
		return Handle.NONE
	var u: float = px()
	var r: float = (handle_px * 0.5 + hit_padding_px) * u
	var half: Vector2 = _el.size * 0.5
	if local.distance_to(Vector2(0, -half.y - rotate_distance_px * u)) <= r:
		return Handle.ROTATE
	for h in DIRS:
		var dir: Vector2 = DIRS[h]
		if local.distance_to(dir * half) <= r:
			return h
	return Handle.NONE


func _draw() -> void:
	if _el == null:
		return
	var u: float = px()
	var half: Vector2 = _el.size * 0.5
	draw_rect(Rect2(-half, _el.size), accent, false, line_px * u)

	# rotation stem + handle
	var rp: Vector2 = Vector2(0, -half.y - rotate_distance_px * u)
	draw_line(Vector2(0, -half.y), rp, accent, line_px * u)
	draw_circle(rp, handle_px * 0.6 * u, Color.WHITE)
	draw_arc(rp, handle_px * 0.6 * u, 0.0, TAU, 24, accent, line_px * u)

	# resize handles
	var hs: Vector2 = Vector2.ONE * handle_px * u
	for h in DIRS:
		var dir: Vector2 = DIRS[h]
		var r: Rect2 = Rect2(dir * half - hs * 0.5, hs)
		draw_rect(r, Color.WHITE)
		draw_rect(r, accent, false, line_px * u)
