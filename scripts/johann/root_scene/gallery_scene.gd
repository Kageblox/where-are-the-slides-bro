class_name CutsceneScene extends RootScene

@export var current_slide_number = 0

var max_slide_number = 10

func _ready() -> void:
	max_slide_number = len($Background/HBox/Slides.get_children())
	print(max_slide_number)

func _on_next_button_pressed(args) -> void:
	$Background/HBox/Previous_Control/PreviousButton.disabled = false
	
	$Background/HBox/Slides.get_child(current_slide_number).visible = false
	current_slide_number += 1
	$Background/HBox/Slides.get_child(current_slide_number).visible = true

	if current_slide_number == max_slide_number - 1:
		print("wat")
		$Background/HBox/Next_Control/NextButton.disabled = true

func _on_previous_button_pressed(args) -> void:
	$Background/HBox/Next_Control/NextButton.disabled = false
	
	$Background/HBox/Slides.get_child(current_slide_number).visible = false
	current_slide_number -= 1
	$Background/HBox/Slides.get_child(current_slide_number).visible = true
	
	if current_slide_number == 0:
		$Background/HBox/Previous_Control/PreviousButton.disabled = true
	
