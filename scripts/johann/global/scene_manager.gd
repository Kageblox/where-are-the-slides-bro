extends Node

## Scenes
var main_menu_scene_path = "res://scenes/root_scenes/main_menu_scene.tscn"
var gameplay_scene_path = "res://scenes/root_scenes/gameplay_scene.tscn"
var normal_ending_scene_path = "res://scenes/root_scenes/normal_ending_scene.tscn" 
var gallery_scene_path = "res://scenes/root_scenes/gallery_scene.tscn" 
var introduction_scene_path = "res://scenes/root_scenes/introduction_scene.tscn" 


var old_scene: RootScene = null
var current_scene: RootScene = null

var loading_screen_opening = false
var loading_screen_closing = false

var loading_path = null
var progress: Array[float] = []

var loading_popup: JPopup = null

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 ) as RootScene
	$Pause/PauseButton.visible = current_scene.pausable
	
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
				current_scene = new_scene.instantiate() as RootScene
				
	if loading_popup and loading_path == null and not loading_screen_opening:
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		old_scene.queue_free()
		loading_popup.close()
		loading_popup = null
		$Pause/PauseButton.visible = current_scene.pausable

func _on_pause_button_pressed(args) -> void:
	PopupManager.open_popup(PopupManager.paused_popup)
