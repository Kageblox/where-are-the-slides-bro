class_name PowerpointWindow extends WindowPopup

@onready var jialing = $PanelContainer/Margins/HBoxContainer/VBoxContainer3/PanelContainer/SubViewportContainer/SubViewport/JiaLing as AnimatedSprite2D

func _ready() -> void:
	jialing.play("calm")

func _on_open_select_the_correct_image_window_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.select_the_correct_image_window)

func _on_normal_ending_button_pressed() -> void:
	SceneManager.goto_scene(SceneManager.normal_ending_scene_path)


func _on_spawnlist_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	pass # Replace with function body.
