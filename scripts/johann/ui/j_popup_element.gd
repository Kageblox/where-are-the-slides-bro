class_name JPopupElement extends Control

@export var open_tweens: Array[JTween]
@export var close_tweens: Array[JTween]

var popup: JPopup

func _enter_tree() -> void:
	popup = JBasicUtil.get_nearest_parent_of_class(self, JPopup)
	
	popup.on_open_start.connect(func():
		JTween.StartTween(self, open_tweens))
	
	popup.on_close_start.connect(func():
		JTween.StartTween(self, close_tweens))
