class_name JPopupElement extends Control

@export var open_tweens: JTweenCollection
@export var close_tweens: JTweenCollection

var popup: JPopup

func _enter_tree() -> void:
	popup = JBasicUtil.get_nearest_parent_of_class(self, JPopup)
	
	popup.on_open_start.connect(func():
		JTween.StartTween(self, open_tweens))
	
	popup.on_close_start.connect(func():
		JTween.StartTween(self, close_tweens))
