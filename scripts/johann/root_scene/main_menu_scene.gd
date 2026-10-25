class_name MainMenuScene extends RootScene

func _ready() -> void:
	AudioManager.play_audio(0)

func _on_settings_button_pressed(args) -> void:
	PopupManager.open_popup(PopupManager.settings_popup)
	
func _on_start_game_button_pressed(args) -> void:
	SceneManager.goto_scene(SceneManager.introduction_scene_path)


func _on_gallery_button_pressed(args: Variant) -> void:
	SceneManager.goto_scene(SceneManager.gallery_scene_path)
