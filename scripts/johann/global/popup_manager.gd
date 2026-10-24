extends Node

var settings_popup: Resource = preload("res://scenes/prefabs/johann/ui/settings_popup.tscn") 
var loading_popup: Resource = preload("res://scenes/prefabs/johann/ui/loading_popup.tscn") 
var paused_popup: Resource = preload("res://scenes/prefabs/johann/ui/paused_popup.tscn")
var question_popup: Resource = preload("res://scenes/prefabs/johann/ui/question_popup.tscn")

var visible_size: Vector2:
	get:
		return get_viewport().get_visible_rect().size

func open_popup(popup_resource: Resource):
	var new_popup = popup_resource.instantiate() as JPopup
	
	if popup_resource == loading_popup:
		new_popup.process_mode = Node.PROCESS_MODE_ALWAYS
		$Loading.add_child(new_popup)
		
	elif new_popup.pause_game_when_open:
		new_popup.process_mode = Node.PROCESS_MODE_ALWAYS
		$Paused.add_child(new_popup)
		$Paused.move_child(new_popup, -1)
		
	else:
		new_popup.process_mode = Node.PROCESS_MODE_PAUSABLE
		$Unpaused.add_child(new_popup)
		$Unpaused.move_child(new_popup, -1)
	
	new_popup.open()
	
	return new_popup

func open_question_popup(
	question: String,
	answers,
	callbacks
):
	var new_question_popup = question_popup.instantiate() as QuestionPopup
	
	if new_question_popup.pause_game_when_open:
		new_question_popup.process_mode = Node.PROCESS_MODE_ALWAYS
		$Paused.add_child(new_question_popup)
		$Paused.move_child(new_question_popup, -1)
		
	else:
		new_question_popup.process_mode = Node.PROCESS_MODE_PAUSABLE
		$Unpaused.add_child(new_question_popup)
		$Unpaused.move_child(new_question_popup, -1)

	new_question_popup.load_question(question, answers, callbacks)
	new_question_popup.open()
	return new_question_popup

func _on_paused_child_entered_tree(node: Node) -> void:
	get_tree().paused = true

func _on_paused_child_exiting_tree(node: Node) -> void:
	get_tree().paused = $Paused.get_child_count() > 1
	
func close_all_popups():
	for popup in $Unpaused.get_children():
		popup.close()
	for popup in $Paused.get_children():
		popup.close()
		
