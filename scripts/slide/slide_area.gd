class_name SlideArea
extends Control

const IMAGE_SIZE := Vector2(128, 128)   


func _ready() -> void:
	clip_contents = true   # anything poking outside the white slide is hidden


## The popup calls this (see gameplay_scene.gd) with the picture the player chose.
func insert_image(texture: Texture2D) -> void:
	var img := SlideImage.new()                  # make a new picture
	img.texture = texture                        # give it the chosen texture
	img.size = IMAGE_SIZE                        # starting size
	img.position = (size - IMAGE_SIZE) / 2       # top-left that puts it in the middle of the slide
	add_child(img)                               # put it on the slide (this runs its _ready)
	img.select()                                 # show its handles straight away


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for img in get_tree().get_nodes_in_group("slide_images"):
			img.set_selected(false)
