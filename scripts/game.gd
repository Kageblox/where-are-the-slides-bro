extends Node
## Main scene. Starts the run and wires the result/ending screens.
## Also keeps the Open/Close buttons: the slide "app" can be minimised, but its timer keeps running.

@onready var host: Node = $SlideHost
@onready var screens: Screens = $UI/Screens
@onready var open_button: Button = $OpenButton
@onready var close_button: Button = $CloseButton

## Whether the slide app starts open. The original prototype started closed.
@export var start_open: bool = false

var _open: bool = false


func _ready() -> void:
	_open = start_open
	open_button.pressed.connect(func() -> void: _set_open(true))
	close_button.pressed.connect(func() -> void: _set_open(false))
	SlideManager.slide_started.connect(func(_i: int, _s: Slide) -> void: _set_open(_open))
	GameManager.run_ended.connect(screens.show_ending)
	SlideManager.slide_completed.connect(screens.show_slide_result)
	screens.next_slide_pressed.connect(SlideManager.advance)
	screens.restart_pressed.connect(func() -> void: get_tree().reload_current_scene())
	GameManager.start_run(host)


func _set_open(v: bool) -> void:
	_open = v
	open_button.visible = not v
	close_button.visible = v
	if is_instance_valid(SlideManager.current):
		SlideManager.current.set_minimized(not v)
