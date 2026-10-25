@tool
class_name TargetSlot
extends Control


const FAINT := Color(1, 1, 1, 0.3)         
const OUTLINE := Color(0.05, 0.0, 0.58, 0.6)

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _ready() -> void:
	pivot_offset_ratio = Vector2(0.5, 0.5)       
	texture_filter = TEXTURE_FILTER_NEAREST      
	mouse_filter = Control.MOUSE_FILTER_IGNORE   


func _draw() -> void:
	var whole_rect := Rect2(Vector2.ZERO, size)
	if texture:
		draw_texture_rect(texture, whole_rect, false, FAINT)   
	draw_rect(whole_rect, OUTLINE, false, 2.0)  


func score() -> float:
	var ghost_centre := position + size / 2
	var best := 0.0

	for node in get_tree().get_nodes_in_group("slide_images"):
		var img := node as SlideImage
		var img_centre := img.position + img.size / 2

		var distance := ghost_centre.distance_to(img_centre)
		var distance_score := clampf(1.0 - distance / 300, 0.0, 1.0)

		var angle_off := absf(angle_difference(rotation, img.rotation))
		var rotation_score := 1.0 - angle_off / PI

		best = maxf(best, distance_score * rotation_score)

	return best
