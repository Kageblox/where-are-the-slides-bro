class_name SlideImage
extends Control
## One picture on the slide.
## Drag the picture = move it. Drag a white corner = resize. Drag the yellow dot = rotate.

const HANDLE_SIZE := 8.0     # size of each white corner square, in pixels
const ROTATE_GAP := 24.0     # how far above the picture the yellow dot floats
const MIN_SIZE := 16.0       # the picture can't be made smaller than this

const BLUE := Color("0c0293")
const YELLOW := Color("e2b714")

var texture: Texture2D       # the picture (SlideArea sets this)
var selected := false        # true = show the outline and handles

# What the mouse is doing right now. Exactly one of these words, or "" for nothing.
var mode := ""               # "" / "move" / "resize" / "rotate"
var grab_offset := Vector2.ZERO   # where inside the picture we grabbed it (used for moving)


func _ready() -> void:
	add_to_group("slide_images")                # so we can find every picture on the slide
	pivot_offset_ratio = Vector2(0.5, 0.5)      # rotate around the centre, not the top-left
	texture_filter = TEXTURE_FILTER_NEAREST     # keeps pixel art sharp


# ------------------------------------------------------------ selecting

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()                              # repaint so the handles appear / disappear


## Select this picture, deselect all the others, and draw this one on top.
func select() -> void:
	for img in get_tree().get_nodes_in_group("slide_images"):
		img.set_selected(false)                 # everyone off...
	set_selected(true)                          # ...then just me on
	move_to_front()


# ------------------------------------------------------------ drawing
# All positions here are measured from the picture's own top-left corner (0, 0).

func _draw() -> void:
	var whole_picture := Rect2(Vector2.ZERO, size)
	if texture:
		draw_texture_rect(texture, whole_picture, false)
	if not selected:
		return                                  # no handles unless selected

	draw_rect(whole_picture, BLUE, false, 2.0)  # blue outline (false = not filled)

	draw_handle_square(top_left())
	draw_handle_square(top_right())
	draw_handle_square(bottom_left())
	draw_handle_square(bottom_right())

	var top_middle := Vector2(size.x / 2, 0)
	draw_line(top_middle, rotate_handle(), BLUE, 2.0)       # the stick
	draw_circle(rotate_handle(), HANDLE_SIZE / 2, YELLOW)   # the yellow dot


func draw_handle_square(centre: Vector2) -> void:
	var top_left_of_square := centre - Vector2(HANDLE_SIZE, HANDLE_SIZE) / 2
	draw_rect(Rect2(top_left_of_square, Vector2(HANDLE_SIZE, HANDLE_SIZE)), Color.WHITE)


func top_left() -> Vector2:
	return Vector2(0, 0)

func top_right() -> Vector2:
	return Vector2(size.x, 0)

func bottom_left() -> Vector2:
	return Vector2(0, size.y)

func bottom_right() -> Vector2:
	return Vector2(size.x, size.y)

func rotate_handle() -> Vector2:
	return Vector2(size.x / 2, -ROTATE_GAP)     # middle of the top edge, then a bit higher


# ------------------------------------------------------------ what was clicked?

func is_on_rotate_handle(point: Vector2) -> bool:
	return point.distance_to(rotate_handle()) <= HANDLE_SIZE


func is_on_corner(point: Vector2) -> bool:
	return (point.distance_to(top_left()) <= HANDLE_SIZE
		or point.distance_to(top_right()) <= HANDLE_SIZE
		or point.distance_to(bottom_left()) <= HANDLE_SIZE
		or point.distance_to(bottom_right()) <= HANDLE_SIZE)


## Godot asks "is this point on me?" before sending a click here. The yellow dot is
## OUTSIDE the rectangle, so we say yes for it too. Otherwise it could never be clicked.
func _has_point(point: Vector2) -> bool:
	if Rect2(Vector2.ZERO, size).has_point(point):
		return true
	return selected and (is_on_rotate_handle(point) or is_on_corner(point))


# ------------------------------------------------------------ mouse

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed(event.position)
		else:
			mode = ""                           # button let go: stop whatever we were doing
		accept_event()                          # "I used this click, don't pass it on"

	elif event is InputEventMouseMotion:
		mouse_moved(event.position)


## event.position is the mouse measured from THIS picture's top-left, as if the picture
## were not rotated at all. That is why the handle checks above work even when rotated.
func mouse_pressed(mouse: Vector2) -> void:
	select()
	if is_on_rotate_handle(mouse):
		mode = "rotate"
	elif is_on_corner(mouse):
		mode = "resize"
	else:
		mode = "move"
		# get_transform() * mouse turns "inside the picture" into "on the slide".
		var mouse_on_slide := get_transform() * mouse
		grab_offset = mouse_on_slide - position  # remember where in the picture we grabbed


func mouse_moved(mouse: Vector2) -> void:
	var mouse_on_slide := get_transform() * mouse
	if mode == "move":
		position = mouse_on_slide - grab_offset
	elif mode == "resize":
		resize(mouse)
	elif mode == "rotate":
		rotate_to(mouse_on_slide)


## Resize around the centre, so the centre stays put (this also keeps rotation correct).
func resize(mouse: Vector2) -> void:
	var centre_on_slide := position + size / 2
	var half_width := size.x / 2
	var half_height := size.y / 2
	# How far the mouse is from the centre, sideways and up/down:
	var mouse_dx := absf(mouse.x - half_width)
	var mouse_dy := absf(mouse.y - half_height)
	# How many times bigger the picture must get to reach the mouse (the larger of the two):
	var scale_by := maxf(mouse_dx / half_width, mouse_dy / half_height)

	var new_width := maxf(size.x * scale_by, MIN_SIZE)
	var new_height := maxf(size.y * scale_by, MIN_SIZE)
	size = Vector2(new_width, new_height)
	position = centre_on_slide - size / 2       # put the centre back where it was


## Turn the picture so its "up" points at the mouse. The dot is above the picture and
## "up" is -90 degrees in Godot, so we add 90 degrees (PI / 2).
func rotate_to(mouse_on_slide: Vector2) -> void:
	var centre_on_slide := position + size / 2
	var direction := mouse_on_slide - centre_on_slide
	rotation = direction.angle() + PI / 2
