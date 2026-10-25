@tool
class_name JPopup extends Control

enum PopupType { GAME, SYSTEM, LOADING }

signal on_open_start()
signal on_open_end()

signal on_close_start()
signal on_close_end()

@export var open_duration: float = 0.5
@export var close_duration: float = 0.5
@export var popup_type: PopupType = PopupType.GAME

var popup_timer: Timer
var closing: bool = false
var interactable: bool = true

func _enter_tree() -> void:
	popup_timer = Timer.new()
	add_child(popup_timer)
	popup_timer.timeout.connect(func():
		if not closing:
			on_open_end.emit()
			interactable = true
		else:
			on_close_end.emit()
			queue_free())

func open(
	args = null
) -> void:
	interactable = false
	on_open_start.emit()
	popup_timer.start(open_duration)

func close():
	interactable = false
	on_close_start.emit()
	closing = true
	popup_timer.start(close_duration)
