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

func start_game():
	start(default_time_left)
	$MinigameTimer.start()
	
func end_game():
	stop()
	$MinigameTimer.stop()
	SceneManager.goto_scene(SceneManager.normal_ending_scene_path)

func reduce_time(value:float):
	if time_left - value < 0:
		stop()
		$MinigameTimer.stop()
	else:
		start(time_left - value)

func _on_timeout() -> void:
	end_game()
	
func _on_minigame_timer_timeout() -> void:
	PopupManager.open_popup(PopupManager.select_the_correct_image_window)
