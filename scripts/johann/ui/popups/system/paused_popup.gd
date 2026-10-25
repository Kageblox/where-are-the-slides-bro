class_name PausedPopup extends JPopup

func _on_background_pressed() -> void:
	close()

func _on_resume_game_button_pressed() -> void:
	close()

func _on_return_to_main_menu_pressed() -> void:
	PopupManager.open_popup(
		PopupManager.system_question_popup,
		[
			"Return to Main Menu?",
			[
				"Yes",
				"No"
			],
			[
				func(): SceneManager.goto_scene(SceneManager.main_menu_scene_path), 
				func(): pass
			]
		])

func _on_settings_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.settings_popup)
