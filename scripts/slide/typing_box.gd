class_name TypingBox
extends RichTextLabel
## A typing test. After every key press we rebuild the text, colouring each letter:
## green = typed right, red = typed wrong, grey = not typed yet, underline = the next letter.

signal typing_done(wpm: float, accuracy: float)   # fired once, when the sentence is finished

@export var target_text := "where are the slides bro"   # the sentence to type
@export var right_color := Color("1e6f50")
@export var wrong_color := Color("c0263a")
@export var todo_color := Color("8b93a8")

var typed := ""          # everything typed so far, mistakes included
var keys_pressed := 0    # total letter keys pressed
var keys_right := 0      # how many of those were correct
var start_time := -1.0   # seconds when the first key was pressed (-1 = not started)
var done := false


func _ready() -> void:
	bbcode_enabled = true            # lets us colour text with [color=...] tags
	focus_mode = Control.FOCUS_ALL   # allows this box to receive the keyboard
	focus_entered.connect(show_text) # redraw (for the underline) when we gain focus...
	focus_exited.connect(show_text)  # ...and when we lose it
	grab_focus()
	show_text()


func _gui_input(event: InputEvent) -> void:
	if done or not (event is InputEventKey) or not event.pressed:
		return

	if event.keycode == KEY_BACKSPACE:
		typed = typed.left(typed.length() - 1)    # cut the last letter off
	elif event.unicode >= 32:                     # 32 and up = letters, digits, space...
		type_letter(char(event.unicode))
	else:
		return                                    # some other key: ignore it

	accept_event()
	show_text()


func type_letter(letter: String) -> void:
	if typed.length() >= target_text.length():
		return                                    # already typed the whole sentence

	if start_time < 0.0:
		start_time = Time.get_ticks_msec() / 1000.0   # the first key starts the clock

	var letter_we_wanted := target_text[typed.length()]
	keys_pressed += 1
	if letter == letter_we_wanted:
		keys_right += 1
	typed += letter

	if typed == target_text:
		done = true
		typing_done.emit(wpm(), accuracy())


## Build the coloured text, one letter at a time.
func show_text() -> void:
	var result := ""
	for i in target_text.length():
		var letter := target_text[i]
		var color := todo_color                   # grey unless we find out otherwise

		if i < typed.length():                    # this letter has been typed
			if typed[i] == letter:
				color = right_color
			else:
				color = wrong_color
				if letter == " ":
					letter = "_"                  # a wrong space is invisible, so show "_"

		var piece := "[color=#%s]%s[/color]" % [color.to_html(false), letter]

		var is_next_letter := (i == typed.length())
		if is_next_letter and has_focus():
			piece = "[u]" + piece + "[/u]"        # underline the next letter

		result += piece
	text = result


## Accuracy = % of key presses that were right. Fixing a mistake doesn't erase it.
func accuracy() -> float:
	if keys_pressed == 0:
		return 100.0
	return 100.0 * keys_right / keys_pressed


## Words per minute. Every 5 correct letters count as 1 word.
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
