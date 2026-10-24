class_name MainMenu extends Node

@export var settings_button: JButton

func _ready() -> void:
	settings_button.pressed.connect(func():
		PopupManager.open_popup(PopupManager.settings_popup))
