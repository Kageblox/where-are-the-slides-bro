class_name SystemQuestionPopup extends JPopup

func open(
	args = null
	) -> void:
	super()
	var question = args[0]
	var answers = args[1]
	var callbacks = args[2]
	
	$Panel/VBoxContainer/Margins/Question.text = question
	
	var answer0 = $Panel/VBoxContainer/VBoxContainer/OptionButton as JLabelButton
	var answer_buttons = [answer0]
	
	for i in range(len(answers)):
		if i == 0:
			var newAnswer = answer0
			newAnswer.text = answers[i]
		else:
			var newAnswer = answer0.duplicate()
			newAnswer.text = answers[i]
			$Panel/VBoxContainer/VBoxContainer.add_child(newAnswer)
			answer_buttons.append(newAnswer)
	
	for i in range(len(callbacks)):
		var current_answer = answer_buttons[i]
		current_answer.pressed.connect(callbacks[i])
		current_answer.pressed.connect(func():
			close())

func _on_background_pressed() -> void:
	close()
