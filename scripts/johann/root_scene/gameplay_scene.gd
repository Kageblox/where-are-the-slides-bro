class_name GameplayScene extends RootScene

func _ready() -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)
	AudioManager.play_audio(2)

	
func _on_powerpoint_button_pressed(args) -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)
