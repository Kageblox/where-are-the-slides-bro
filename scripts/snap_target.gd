@tool
class_name SnapTarget
extends Node2D

@export var expected_id: StringName = &""
@export var texture: Texture2D:
	set(v):
		texture = v
		queue_redraw()
@export var target_size := Vector2(200, 200):
	set(v):
		target_size = v
		queue_redraw()

@export_group("Ghost look")
@export var ghost_color := Color(1, 1, 1, 0.35):
	set(v):
		ghost_color = v
		queue_redraw()
@export var outline_color := Color("4f8cff"):
	set(v):
		outline_color = v
		queue_redraw()
@export var show_outline := false:
	set(v):
		show_outline = v
		queue_redraw()

@export_group("Snapping")
@export var snap_distance := 20.0

@export_group("Scoring")
@export var max_points := 100.0
@export_range(0.0, 1.0) var position_weight := 0.5
@export_range(0.0, 1.0) var rotation_weight := 0.25
@export_range(0.0, 1.0) var size_weight := 0.25
@export_subgroup("Position (px)")
@export var position_full := 8.0
@export var position_zero := 150.0
@export_subgroup("Rotation (degrees)")
@export var rotation_full := 4.0
@export var rotation_zero := 45.0
@export_subgroup("Size (relative error, 0.1 = 10%)")
@export_range(0.0, 1.0) var size_full := 0.05
@export_range(0.0, 2.0) var size_zero := 0.5


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"targets")


func _draw() -> void:
	var r := Rect2(-target_size * 0.5, target_size)
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


func evaluate(e: SlideElement) -> Dictionary:
	var pos_dev := e.global_position.distance_to(global_position)
	var rot_dev := rad_to_deg(absf(angle_difference(e.global_rotation, global_rotation)))
	var es: Vector2 = e.size * e.global_scale.abs()
	var ts := (target_size * global_scale.abs()).max(Vector2.ONE)
	var size_dev := maxf(absf(es.x / ts.x - 1.0), absf(es.y / ts.y - 1.0))

	var p := _falloff(pos_dev, position_full, position_zero)
	var r := _falloff(rot_dev, rotation_full, rotation_zero)
	var s := _falloff(size_dev, size_full, size_zero)
	var wsum := maxf(position_weight + rotation_weight + size_weight, 0.0001)
	var total := (p * position_weight + r * rotation_weight + s * size_weight) / wsum
	return {
		"position": p, "rotation": r, "size": s,
		"position_error_px": pos_dev, "rotation_error_deg": rot_dev, "size_error": size_dev,
		"total": total, "points": total * max_points,
	}


func best_match() -> SlideElement:
	var best: SlideElement = null
	var best_s := -1.0
	for n in get_tree().get_nodes_in_group(&"slide_elements"):
		var e := n as SlideElement
		if e == null or not matches(e):
			continue
		var s: float = evaluate(e)["total"]
		if s > best_s:
			best_s = s
			best = e
	return best


func score() -> Dictionary:
	var e := best_match()
	if e == null:
		return {"total": 0.0, "points": 0.0, "element": null}
	var r := evaluate(e)
	r["element"] = e
	return r


static func _falloff(dev: float, full: float, zero: float) -> float:
	if dev <= full:
		return 1.0
	return 1.0 - clampf(inverse_lerp(full, maxf(zero, full + 0.0001), dev), 0.0, 1.0)
