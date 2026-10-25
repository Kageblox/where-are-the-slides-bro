class_name IntroductionScene extends CutsceneScene

func _ready() -> void:
	super()
	AudioManager.play_audio(1)

func _on_start_game_button_pressed(args: Variant) -> void:
	SceneManager.goto_scene(SceneManager.gameplay_scene_path)
