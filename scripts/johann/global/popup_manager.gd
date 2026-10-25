extends Node

## Loading Popups
var loading_popup: Resource = preload("res://scenes/prefabs/johann/ui/popups/loading/loading_popup.tscn") 

## System Popups
var settings_popup: Resource = preload("res://scenes/prefabs/johann/ui/popups/system/settings_popup.tscn") 
var paused_popup: Resource = preload("res://scenes/prefabs/johann/ui/popups/system/paused_popup.tscn")
var system_question_popup: Resource = preload("res://scenes/prefabs/johann/ui/popups/system/system_question_popup.tscn")

## Game Popups
var powerpoint_window: Resource = preload("res://scenes/prefabs/johann/ui/popups/game/powerpoint_window.tscn")
var select_the_correct_image_window: Resource = preload("res://scenes/prefabs/johann/ui/popups/game/minigames/select_the_correct_image_window.tscn")


func open_popup(
	popup_resource: Resource,
	args = null
	):
	var new_popup = popup_resource.instantiate() as JPopup
	
	match(new_popup.popup_type):
		JPopup.PopupType.LOADING:
			$Loading.add_child(new_popup)
			$Loading.move_child(new_popup, -1)
		JPopup.PopupType.SYSTEM:
			$System.add_child(new_popup)
			$System.move_child(new_popup, -1)
		JPopup.PopupType.GAME:
			$Game.add_child(new_popup)
			$Game.move_child(new_popup, -1)
	
	new_popup.open(args)
	return new_popup


func _on_game_child_entered_tree(node: Node) -> void:
	var game_popups = $Game.get_children()
	for i in range($Game.get_child_count()):
		game_popups[i].is_focus = i == $Game.get_child_count()-1


func _on_game_window_closed(node: Node) -> void:
	var game_popups = $Game.get_children()
	for i in range($Game.get_child_count()):
		game_popups[i].is_focus = i == $Game.get_child_count()-2


func _on_system_child_entered_tree(node: Node) -> void:
	get_tree().paused = true


func _on_system_child_exiting_tree(node: Node) -> void:
	get_tree().paused = $System.get_child_count() > 1



func close_all_popups():
	for popup in $Game.get_children():
		popup.close()
	for popup in $System.get_children():
		popup.close()
