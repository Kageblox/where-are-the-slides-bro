class_name PowerpointWindow extends WindowPopup

const PENALITY = 30

var slide_elements: Array[Resource] = [
	preload("res://images/powerpoint_elements/Pop up png 3.png"),
	preload("res://images/powerpoint_elements/Pop up png 6.png"),
	preload("res://images/powerpoint_elements/Pop up png 7.png"),
	preload("res://images/powerpoint_elements/Volume.png"),
	preload("res://images/powerpoint_elements/Window home.png")
]

@onready var jialing = $PanelContainer/Margins/HBox/VBoxContainer3/Viewport/SubViewportContainer/SubViewport/JiaLing as AnimatedSprite2D

func _ready() -> void:
	jialing.play("calm")
	TimeManager.start_game()
	

func reduce_time(value: float):
	TimeManager.reduce_time(value)


func _on_open_select_the_correct_image_window_button_pressed(args) -> void:
	PopupManager.open_popup(PopupManager.select_the_correct_image_window)


func _on_normal_ending_button_pressed(args) -> void:
	SceneManager.goto_scene(SceneManager.normal_ending_scene_path)


func _process(delta: float) -> void:
	$PanelContainer/Margins/HBox/VBoxContainer3/Counter/Margins/Counter_Text.text = TimeManager.time_left_string

func _on_slide_element_pressed(args: Variant) -> void:
	$PanelContainer/Margins/HBox/Margins/SlideArea.insert_image(slide_elements[args] as Texture2D)


func _on_reduce_time_button_pressed(args: Variant) -> void:
	reduce_time(10)

func _on_submit_slide_button_pressed(args: Variant) -> void:
	
	var avg_score = $PanelContainer/Margins/HBox/Margins/SlideArea.score_all()
	print(avg_score)
	if avg_score <= 0.5:
		avg_score *= 2
		
		reduce_time(PENALITY - PENALITY * avg_score)
	
