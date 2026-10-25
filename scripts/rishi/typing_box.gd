class_name TypingBox
extends RichTextLabel


signal typing_done(wpm: float, accuracy: float)   

@export var target_text := "where are the slides bro" 
@export var right_color := Color("1e6f50")
@export var wrong_color := Color("c0263a")
@export var todo_color := Color("8b93a8")

var typed := ""          
var keys_pressed := 0    
var keys_right := 0      
var start_time := -1.0   
var done := false


func _ready() -> void:
	bbcode_enabled = true            
	focus_mode = Control.FOCUS_ALL   
	focus_entered.connect(show_text) 
	focus_exited.connect(show_text)  
	grab_focus()
	show_text()


func _gui_input(event: InputEvent) -> void:
	if done or not (event is InputEventKey) or not event.pressed:
		return

	if event.keycode == KEY_BACKSPACE:
		typed = typed.left(typed.length() - 1)    
	elif event.unicode >= 32:                     
		type_letter(char(event.unicode))
	else:
		return                                    

	accept_event()
	show_text()


func type_letter(letter: String) -> void:
	if typed.length() >= target_text.length():
		return                                    

	if start_time < 0.0:
		start_time = Time.get_ticks_msec() / 1000.0   

	var letter_we_wanted := target_text[typed.length()]
	keys_pressed += 1
	if letter == letter_we_wanted:
		keys_right += 1
	typed += letter

	if typed == target_text:
		done = true
		typing_done.emit(wpm(), accuracy())


func show_text() -> void:
	var result := ""
	for i in target_text.length():
		var letter := target_text[i]
		var color := todo_color                   

		if i < typed.length():                    
			if typed[i] == letter:
				color = right_color
			else:
				color = wrong_color
				if letter == " ":
					letter = "_"                  

		var piece := "[color=#%s]%s[/color]" % [color.to_html(false), letter]

		var is_next_letter := (i == typed.length())
		if is_next_letter and has_focus():
			piece = "[u]" + piece + "[/u]"        

		result += piece
	text = result


func accuracy() -> float:
	if keys_pressed == 0:
		return 0.0
	return (100.0 * keys_right / keys_pressed)* typed.length()/target_text.length()


func wpm() -> float:
	if start_time < 0.0:
		return 0.0
	var seconds := Time.get_ticks_msec() / 1000.0 - start_time
	var minutes := maxf(seconds / 60.0, 0.001)    # maxf stops us dividing by zero

	var right_letters := 0
	for i in typed.length():
		if typed[i] == target_text[i]:
			right_letters += 1
	return (right_letters / 5.0) / minutes
	

func score() -> float:
	var best = 0.0
	var accuracy = clampf(accuracy()/100,0.0,1.0)
	best = maxf(best, accuracy)
	return best
