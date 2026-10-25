class_name GameplayScene extends RootScene

func _ready() -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)

func _on_powerpoint_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)
