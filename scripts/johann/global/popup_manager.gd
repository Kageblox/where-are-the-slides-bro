extends Node

var settings_popup: Resource = preload("res://scenes/prefabs/johann/ui/settings_popup.tscn") 

var visible_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

func open_popup(popup_resource: Resource):
	var new_popup = popup_resource.instantiate() as JPopup
	
	if get_tree().paused:
		new_popup.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		$"When Paused".add_child(new_popup)
		$"When Paused".move_child(new_popup, -1)
	else:
		new_popup.process_mode = Node.PROCESS_MODE_PAUSABLE
		$"Pausable".add_child(new_popup)
		$"Pausable".move_child(new_popup, -1)
