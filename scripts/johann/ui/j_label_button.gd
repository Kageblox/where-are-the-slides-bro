@tool
class_name JLabelButton extends JButton

@export var text: String = "Button":
	get:
		return get_node("GFX/Margins/Label").text
	set(value):
		get_node("GFX/Margins/Label").text = value
