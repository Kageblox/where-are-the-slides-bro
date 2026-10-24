extends Node

var old_scene: Root_Scene = null
var current_scene: Root_Scene = null

var loading_screen_opening = false
var loading_screen_closing = false

var loading_path = null
var progress: Array[float] = []

var loading_popup: JPopup = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 ) as Root_Scene
	$PauseButton/PauseButton.visible = current_scene.pausable
	
func goto_scene(path):
	PopupManager.close_all_popups()
	
	ResourceLoader.load_threaded_request(path)
	
	loading_path = path
	
	loading_popup = PopupManager.open_popup(PopupManager.loading_popup)
	loading_screen_opening = true
	
	loading_popup.on_open_end.connect(func():
		loading_screen_opening = false)

func _process(delta: float) -> void:
	if loading_path != null:
		var status = ResourceLoader.load_threaded_get_status(loading_path, progress)
		
		match status:
			ResourceLoader.THREAD_LOAD_FAILED:
				push_error("Unable to load scene: " + loading_path)
			ResourceLoader.THREAD_LOAD_LOADED:
				var new_scene = ResourceLoader.load_threaded_get(loading_path)
				loading_path = null
				old_scene = current_scene 
				current_scene = new_scene.instantiate() as Root_Scene
				
	if loading_popup and loading_path == null and not loading_screen_opening:
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		old_scene.queue_free()
		loading_popup.close()
		loading_popup = null
		$PauseButton/PauseButton.visible = current_scene.pausable

func _on_pause_button_pressed() -> void:
	PopupManager.open_popup(PopupManager.paused_popup)
