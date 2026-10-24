class_name MainMenu extends Node

func _on_settings_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.settings_popup)
