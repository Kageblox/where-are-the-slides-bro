class_name SlideArea
extends Control

const IMAGE_SIZE := Vector2(128, 128)   

@export var current_slide_num: int = 0
@export var current_slide: Control

func _ready() -> void:
	clip_contents = true
	
	current_slide = $Slide0 


func insert_image(texture: Texture2D) -> void:
	var img := SlideImage.new()       
	img.texture = texture                        
	img.size = IMAGE_SIZE                        
	img.position = (size - IMAGE_SIZE) / 2       
	current_slide.add_child(img)                              
	img.select()                                 

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for img in get_tree().get_nodes_in_group("slide_images"):
			img.set_selected(false)


func _on_delete_button_pressed(args: Variant) -> void:
	for img in get_tree().get_nodes_in_group("slide_images"):
		if img.selected:
			img.queue_free()           


func score_all():
	var all_scores = []
	
	for child in current_slide.get_children():
		if child.has_method("score"):
			all_scores.append(child.score())
	
	var total_score = 0
	for score in all_scores:
		total_score += score
	
	print(all_scores)
	
	current_slide_num += 1
	
	if has_node("Slide" + str(current_slide_num)):
		var old_slide = current_slide
		current_slide = get_node("Slide" + str(current_slide_num))
		current_slide.visible = true
		old_slide.queue_free()
	else:
		TimeManager.end_game()
	
	return total_score/len(all_scores)
	
	
	
	
	   
