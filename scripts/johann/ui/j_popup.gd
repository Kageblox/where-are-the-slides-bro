@tool
class_name JPopup extends Control

signal on_open_start()
signal on_open_end()

signal on_close_start()
signal on_close_end()

@export var open_duration: float = 0.5
@export var close_duration: float = 0.5

var popup_timer: Timer
var closing: bool = false

func _enter_tree() -> void:
	popup_timer = Timer.new()
	add_child(popup_timer)

func _ready() -> void:
	on_open_start.emit()
	popup_timer.start(open_duration)

func close():
	on_close_start.emit()
	closing = true
	popup_timer.start(close_duration)

func _timeout():
	if not closing:
		on_open_end.emit()
	else:
		on_close_end.emit()
		queue_free()
