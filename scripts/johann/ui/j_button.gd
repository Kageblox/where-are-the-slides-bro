@tool
class_name JButton extends Control

signal pressed(args)

@export var disabled: bool = false:
	get:
		return disabled
	set(value):
		if value:
			JTween.StartTween($GFX, disabled_tweens)
		else:
			if is_node_ready():
				JTween.StartTween($GFX, default_tweens)
		disabled = value

@export var pressed_args: Variant

@export_category("GFX")
@export var default_tweens: JTweenCollection
@export var hover_tweens: JTweenCollection
@export var disabled_tweens: JTweenCollection
@export var pressed_tweens: JTweenCollection

var popup: JPopup

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		self.mouse_entered.connect(func():
			if not disabled:
				JTween.StartTween($GFX, hover_tweens))
				
		self.mouse_exited.connect(func():
			if not disabled:
				JTween.StartTween($GFX, default_tweens))
		
		self.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton:
				if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not disabled:
					JTween.StartTween($GFX, pressed_tweens)
					pressed.emit(pressed_args)
					accept_event())
		
		popup = JBasicUtil.get_nearest_parent_of_class(self, JPopup)
		if popup:
			popup.on_close_start.connect(func():
				disabled = true)
