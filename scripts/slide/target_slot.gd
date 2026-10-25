@tool
class_name TargetSlot
extends Control
## The faint "ghost" showing where a picture should end up.
## Place, resize and rotate this node in the editor to set the target.
## (@tool makes the script also run in the editor, so you can SEE the ghost while placing it.)

const FAINT := Color(1, 1, 1, 0.3)         # white at 30% opacity = see-through
const OUTLINE := Color(0.05, 0.0, 0.58, 0.6)

# Whenever the Texture is changed in the Inspector, repaint the ghost.
@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _ready() -> void:
	pivot_offset_ratio = Vector2(0.5, 0.5)       # rotate around the centre
	texture_filter = TEXTURE_FILTER_NEAREST      # keep pixel art sharp
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # never block clicks meant for pictures


func _draw() -> void:
	var whole_rect := Rect2(Vector2.ZERO, size)
	if texture:
		draw_texture_rect(texture, whole_rect, false, FAINT)   # the see-through picture
	draw_rect(whole_rect, OUTLINE, false, 2.0)                  # thin blue outline
