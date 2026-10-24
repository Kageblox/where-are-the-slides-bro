extends Node

@onready var slide: Node2D = $Slide
@onready var open_button: Button = $OpenButton
@onready var close_button: Button = $CloseButton


func _ready() -> void:
	print("READY WORKS")

	open_button.pressed.connect(open_slide)
	close_button.pressed.connect(close_slide)

	slide.hide()
	open_button.show()
	close_button.hide()


func open_slide() -> void:
	slide.show()
	open_button.hide()
	close_button.show()


func close_slide() -> void:
	slide.hide()
	open_button.show()
	close_button.hide()
