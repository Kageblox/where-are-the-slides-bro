@tool
class_name JLabelButton extends JButton

var _text: String
var _font_size: int
var _margins: int

@export var text: String = "Button":
	get:
		if is_node_ready():
			return $GFX/Margins/Label.text
		else:
			return _text
	set(value):
		if is_node_ready():
			$GFX/Margins/Label.text = value
		_text = value

@export var font_size: int:
	get:
		if is_node_ready():
			return $GFX/Margins/Label.get_theme_font_size("font_size")
		else:
			return _font_size
	set(value):
		if is_node_ready():
			$GFX/Margins/Label.add_theme_font_size_override("font_size", value)
		_font_size = value
		
@export var margins: int:
	get:
		if is_node_ready():
			return $GFX/Margins.get_theme_constant("margin_left")
		else:
			return _margins
	set(value):
		if is_node_ready():
			$GFX/Margins.add_theme_constant_override("margin_top", value)
			$GFX/Margins.add_theme_constant_override("margin_bottom", value)
			$GFX/Margins.add_theme_constant_override("margin_left", value)
			$GFX/Margins.add_theme_constant_override("margin_right", value)
		_margins = value

func _ready() -> void:
	$GFX/Margins/Label.text = _text
	$GFX/Margins/Label.add_theme_font_size_override("font_size", _font_size)
	$GFX/Margins.add_theme_constant_override("margin_top", _margins)
	$GFX/Margins.add_theme_constant_override("margin_bottom", _margins)
	$GFX/Margins.add_theme_constant_override("margin_left", _margins)
	$GFX/Margins.add_theme_constant_override("margin_right", _margins)
