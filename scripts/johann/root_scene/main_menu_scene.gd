class_name MainMenuScene extends Root_Scene

func _on_settings_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.settings_popup)
	
func _on_start_game_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/root_scenes/gameplay_scene.tscn")
