extends Timer

@export var default_time_left: float = 150.0

var time_left_string: String:
	get:
		return get_time_left_string()

func get_time_left_string():
	var minutes = int(floor(time_left/60))
	var seconds = int(fmod(time_left, 60))
	
	var minutes_string = str(minutes)
	var seconds_string = str(seconds)
	
	if minutes < 10:
		minutes_string = "0" + str(minutes)
	
	if seconds < 10:
		seconds_string = "0" + str(seconds)
		
	return minutes_string + ":" + seconds_string

func reduce_time(value:float):
	if time_left - value <= 0:
		stop()
		SceneManager.goto_scene(SceneManager.normal_ending_scene_path)
	else:
		start(time_left - value)

func _on_timeout() -> void:
	stop()
	SceneManager.goto_scene(SceneManager.normal_ending_scene_path)

func _process(delta: float) -> void:
	print(time_left_string)
