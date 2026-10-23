class_name JButton extends Control

signal pressed()

@export var disabled: bool = false:
	get:
		return disabled
	set(value):
		if value:
			JTween.TweenWithDetails(button_texture, texture_disabled_tween_details)
		else:
			JTween.TweenWithDetails(button_texture, texture_default_tween_details)
		disabled = value

@export var button_texture: TextureRect
@export var texture_default_tween_details: Array[JTweenDetails]
@export var texture_hover_tween_details: Array[JTweenDetails]
@export var texture_disabled_tween_details: Array[JTweenDetails]
@export var texture_pressed_tween_details: Array[JTweenDetails]

func _enter_tree() -> void:
	self.mouse_entered.connect(func():
		if not disabled:
			JTween.TweenWithDetails(button_texture, texture_hover_tween_details))
			
	self.mouse_exited.connect(func():
		if not disabled:
			JTween.TweenWithDetails(button_texture, texture_default_tween_details))
	
	self.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not disabled:
				JTween.TweenWithDetails(button_texture, texture_pressed_tween_details)
				pressed.emit()
				accept_event())
	pass
