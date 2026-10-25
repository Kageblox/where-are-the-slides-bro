class_name SlideImage
extends Control


const HANDLE_SIZE := 8.0     
const ROTATE_GAP := 24.0     
const MIN_SIZE := 16.0       

const BLUE := Color("0c0293")
const YELLOW := Color("e2b714")

var texture: Texture2D       
var selected := false        

var mode := ""               # "" / "move" / "resize" / "rotate"
var grab_offset := Vector2.ZERO   


func _ready() -> void:
	add_to_group("slide_images")               
	pivot_offset_ratio = Vector2(0.5, 0.5)      
	texture_filter = TEXTURE_FILTER_NEAREST     



func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()                              


func select() -> void:
	for img in get_tree().get_nodes_in_group("slide_images"):
		img.set_selected(false)                 
	set_selected(true)                         
	move_to_front()



func _draw() -> void:
	var whole_picture := Rect2(Vector2.ZERO, size)
	if texture:
		draw_texture_rect(texture, whole_picture, false)
	if not selected:
		return                                  

	draw_rect(whole_picture, BLUE, false, 2.0)  

	draw_handle_square(top_left())
	draw_handle_square(top_right())
	draw_handle_square(bottom_left())
	draw_handle_square(bottom_right())

	var top_middle := Vector2(size.x / 2, 0)
	draw_line(top_middle, rotate_handle(), BLUE, 2.0)       
	draw_circle(rotate_handle(), HANDLE_SIZE / 2, YELLOW)   


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



func is_on_rotate_handle(point: Vector2) -> bool:
	return point.distance_to(rotate_handle()) <= HANDLE_SIZE


func is_on_corner(point: Vector2) -> bool:
	return (point.distance_to(top_left()) <= HANDLE_SIZE
		or point.distance_to(top_right()) <= HANDLE_SIZE
		or point.distance_to(bottom_left()) <= HANDLE_SIZE
		or point.distance_to(bottom_right()) <= HANDLE_SIZE)



func _has_point(point: Vector2) -> bool:
	if Rect2(Vector2.ZERO, size).has_point(point):
		return true
	return selected and (is_on_rotate_handle(point) or is_on_corner(point))



func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			mouse_pressed(event.position)
		else:
			mode = ""                           
		accept_event()                          

	elif event is InputEventMouseMotion:
		mouse_moved(event.position)



func mouse_pressed(mouse: Vector2) -> void:
	select()
	if is_on_rotate_handle(mouse):
		mode = "rotate"
	elif is_on_corner(mouse):
		mode = "resize"
	else:
		mode = "move"
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
	position = centre_on_slide - size / 2       


func rotate_to(mouse_on_slide: Vector2) -> void:
	var centre_on_slide := position + size / 2
	var direction := mouse_on_slide - centre_on_slide
	rotation = direction.angle() + PI / 2
