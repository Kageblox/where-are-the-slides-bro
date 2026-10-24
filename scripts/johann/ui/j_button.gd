@tool
class_name JButton extends Control

signal pressed()

@export var disabled: bool = false:
	get:
		return disabled
	set(value):
		if value:
			JTween.StartTween($ButtonTexture, texture_disabled_tweens)
		else:
			if is_node_ready():
				JTween.StartTween($ButtonTexture, texture_default_tweens)
		disabled = value

@export_category("Texture")
@export var texture: Texture2D:
	get:
		return texture
	set(value):
		if is_node_ready():
			$ButtonTexture.texture = value
			texture = value

@export var texture_default_tweens: Array[JTween]
@export var texture_hover_tweens: Array[JTween]
@export var texture_disabled_tweens: Array[JTween]
@export var texture_pressed_tweens: Array[JTween]

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		self.mouse_entered.connect(func():
			if not disabled:
				JTween.StartTween($ButtonTexture, texture_hover_tweens))
				
		self.mouse_exited.connect(func():
			if not disabled:
				JTween.StartTween($ButtonTexture, texture_default_tweens))
		
		self.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not disabled:
					JTween.StartTween($ButtonTexture, texture_pressed_tweens)
					pressed.emit()
					accept_event())
		pass
