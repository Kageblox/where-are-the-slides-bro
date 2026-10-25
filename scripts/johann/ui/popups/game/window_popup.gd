@tool
class_name WindowPopup extends JPopup

@export var window_frame_focus: JTweenCollection
@export var window_frame_unfocus: JTweenCollection

@export var is_focus: bool = true:
	get:
		return is_focus
	set(value):
		if value:
			JTween.StartTween($PanelContainer/WindowFrame, window_frame_focus)
		else:
			if is_node_ready():
				JTween.StartTween($PanelContainer/WindowFrame, window_frame_unfocus)
		is_focus = value

func close():
	super()
	PopupManager._on_game_window_closed(self)
