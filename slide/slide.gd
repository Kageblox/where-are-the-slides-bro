class_name Slide
extends Node2D

@export var slide_title: String = "Slide"
## Designed completion time. The real deadline is adapted around it within bounds.
@export var expected_time: float = 120.0
## Weight of this slide in the final presentation score.
@export var slide_weight: float = 1.0
@export var timer: SlideTimer
@export var objectives: SlideObjectives
@export var editor: SlideEditor
@export var popup_layer: Control
## Optional; hidden while the slide is minimised.
@export var submit_button: BaseButton

var time_limit: float = 0.0
var elapsed: float = 0.0
var _active: bool = false
var minimized: bool = false
var _live_t: float = 0.0


func begin() -> void:
	time_limit = DifficultyDirector.time_limit_for(expected_time)
	elapsed = 0.0
	_active = true
	for t in get_tree().get_nodes_in_group(&"typing_tests"):
		(t as TypingTest).reset()
	timer.start(time_limit)
	timer.expired.connect(func() -> void: submit(true), CONNECT_ONE_SHOT)
	PopupDirector.begin_slide(popup_layer)
	MessageManager.begin_slide()
	if editor:
		editor.set_process_unhandled_input(not minimized)


func _process(delta: float) -> void:
	if not _active:
		return
	elapsed += delta
	_live_t += delta
	if _live_t >= 0.25:
		_live_t = 0.0
		ScoreManager.set_live(objectives.evaluate()["percent"])


## Wire the "Submit" button to this.
func submit(timed_out: bool = false) -> void:
	if not _active:
		return
	stop()
	SlideManager.complete_slide(self, timed_out)


## The slide "window" can be minimised (Open/Close buttons in the main scene). The clock keeps
## running; editing and submitting are disabled while it is hidden.
func set_minimized(m: bool) -> void:
	minimized = m
	visible = not m
	if editor:
		editor.set_process_unhandled_input(_active and not m)
	if submit_button:
		submit_button.visible = not m


func stop() -> void:
	_active = false
	timer.stop()
	if editor:
		editor.set_process_unhandled_input(false)
	PopupDirector.end_slide()
	MessageManager.end_slide()
