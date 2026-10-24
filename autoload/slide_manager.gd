extends Node

signal slide_started(index: int, slide: Slide)
signal slide_completed(record: Dictionary)
signal run_finished

var index: int = -1
var current: Slide
var _host: Node


func start_run(host: Node) -> void:
	_host = host
	index = -1
	advance()


## Call after the player has seen the result card.
func advance() -> void:
	if is_instance_valid(current):
		current.queue_free()
		current = null
	index += 1
	var scenes: Array[PackedScene] = GameConfig.get_cfg().slides
	if index >= scenes.size():
		run_finished.emit()
		return
	current = scenes[index].instantiate() as Slide
	_host.add_child(current)
	current.begin()
	slide_started.emit(index, current)


func complete_slide(slide: Slide, timed_out: bool) -> void:
	slide_completed.emit(ScoreManager.finalize_slide(slide, timed_out))


## 0..1 position in the run (0 on the first slide, 1 on the last).
func progress() -> float:
	var n: int = GameConfig.get_cfg().slides.size()
	return clampf(float(maxi(index, 0)) / maxf(float(n - 1), 1.0), 0.0, 1.0)


func is_final_slide() -> bool:
	return index >= GameConfig.get_cfg().slides.size() - 1
