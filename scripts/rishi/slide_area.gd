class_name SlideArea
extends Control

const IMAGE_SIZE := Vector2(128, 128)   


func _ready() -> void:
	clip_contents = true   


func insert_image(texture: Texture2D) -> void:
	var img := SlideImage.new()                 
	img.texture = texture                        
	img.size = IMAGE_SIZE                        
	img.position = (size - IMAGE_SIZE) / 2       
	add_child(img)                              
	img.select()                                 

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for img in get_tree().get_nodes_in_group("slide_images"):
			img.set_selected(false)


func _on_delete_button_pressed(args: Variant) -> void:
	for img in get_tree().get_nodes_in_group("slide_images"):
		if img.selected:
			img.queue_free()              
