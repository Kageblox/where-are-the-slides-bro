class_name GameplayScene extends Root_Scene

func _ready() -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)

func _on_powerpoint_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.powerpoint_window)
