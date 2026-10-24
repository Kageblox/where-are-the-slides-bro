@tool
class_name SnapTarget
extends Node2D
## A placement slot. It always draws a ghost of the expected result.
##   origin        = where the CENTRE of the image should end up
##   node rotation = expected rotation (set it in the Inspector)
##   target_size   = expected size

@export var expected_id: StringName = &""
@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
@export var target_size: Vector2 = Vector2(200, 200):
	set(v):
		target_size = v
		queue_redraw()

@export_group("Ghost look")
@export var ghost_color: Color = Color(1, 1, 1, 0.35):
	set(v):
		ghost_color = v
		queue_redraw()
@export var outline_color: Color = Color("4f8cff"):
	set(v):
		outline_color = v
		queue_redraw()
@export var show_outline: bool = true:
	set(v):
		show_outline = v
		queue_redraw()

@export_group("Snap and scoring")
## Position-only snap, and only when the element centre is this close (global px).
@export var snap_distance: float = 20.0
## >1 = more forgiving slot, <1 = stricter slot (scales all three error measures).
@export var tolerance_scale: float = 1.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"targets")


func _draw() -> void:
	var r: Rect2 = Rect2(-target_size * 0.5, target_size)
	if texture:
		draw_texture_rect(texture, r, false, ghost_color)
	else:
		draw_rect(r, ghost_color)
	if show_outline:
		draw_rect(r, outline_color, false, 2.0)


func get_anchor() -> Vector2:
	return global_position


func matches(e: SlideElement) -> bool:
	return expected_id == &"" or e.element_id == expected_id


## Nearest placed element that matches this slot's id.
func best_match() -> SlideElement:
	var best: SlideElement = null
	var best_d: float = INF
	for n in get_tree().get_nodes_in_group(&"slide_elements"):
		var e: SlideElement = n as SlideElement
		if e == null or not matches(e):
			continue
		var d: float = e.global_position.distance_to(global_position)
		if d < best_d:
			best = e
			best_d = d
	return best


func score_position() -> float:
	var e: SlideElement = best_match()
	if e == null:
		return 0.0
	var err: float = e.global_position.distance_to(global_position) / maxf(tolerance_scale, 0.01)
	return ScoreMath.piecewise(err, GameConfig.get_cfg().position_curve)


func score_rotation() -> float:
	var e: SlideElement = best_match()
	if e == null:
		return 0.0
	var deg: float = rad_to_deg(absf(angle_difference(e.global_rotation, global_rotation)))
	return ScoreMath.piecewise(deg / maxf(tolerance_scale, 0.01), GameConfig.get_cfg().rotation_curve)


func score_size() -> float:
	var e: SlideElement = best_match()
	if e == null:
		return 0.0
	var es: Vector2 = e.size * e.global_scale.abs()
	var ts: Vector2 = (target_size * global_scale.abs()).max(Vector2.ONE)
	var dev: float = maxf(absf(es.x / ts.x - 1.0), absf(es.y / ts.y - 1.0))
	return ScoreMath.piecewise(dev / maxf(tolerance_scale, 0.01), GameConfig.get_cfg().size_curve)
