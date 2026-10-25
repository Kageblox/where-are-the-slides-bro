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
