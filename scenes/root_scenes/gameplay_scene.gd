class_name GameplayScene extends Root_Scene

func _on_spawn_popup_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.select_the_correct_image_popup)
