class_name PowerpointWindow extends WindowPopup

@onready var jialing = $PanelContainer/Margins/HBoxContainer/VBoxContainer3/PanelContainer/SubViewportContainer/SubViewport/JiaLing as AnimatedSprite2D

func _ready() -> void:
	jialing.play("calm")

func _on_open_select_the_correct_image_window_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.select_the_correct_image_window)
