class_name GameplayScene extends Root_Scene

func _on_spawn_popup_button_pressed() -> void:
	var popup := PopupManager.open_popup(PopupManager.select_the_correct_image_popup) as SelectTheCorrectImagePopup
	popup.image_chosen.connect($SlideArea.insert_image)
