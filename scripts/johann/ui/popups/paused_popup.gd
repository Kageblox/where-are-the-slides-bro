class_name PausedPopup extends JPopup

func _on_background_pressed() -> void:
	close()

func _on_resume_game_button_pressed() -> void:
	close()

func _on_return_to_main_menu_pressed() -> void:
	PopupManager.open_question_popup(
		"Return to Main Menu?",
		["Yes", "No"],
		[
			func(): SceneManager.goto_scene("res://scenes/root_scenes/main_menu_scene.tscn"), 
			func(): pass
		]
		)

func _on_settings_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.settings_popup)
