class_name JPopupPressable extends JPopupElement

@export var pressed_args = null

signal pressed(args)

func _ready() -> void:
	if not Engine.is_editor_hint():
		self.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and popup.interactable:
					pressed.emit(pressed_args))
