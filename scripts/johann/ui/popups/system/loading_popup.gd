class_name LoadingPopup extends JPopup

@export var loading_screens: Array[Control]

func _ready() -> void:
	var random_index = randi() % len(loading_screens)
	
	for i in range(len(loading_screens)):
		loading_screens[i].visible = i == random_index
