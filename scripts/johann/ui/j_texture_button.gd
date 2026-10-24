@tool
class_name JTextureButton extends JButton

var _texture: Texture2D
@export var texture: Texture2D:
	get:
		if is_node_ready():
			return $GFX/Texture.texture
		else:
			return _texture
	set(value):
		if is_node_ready():
			$GFX/Texture.texture = value
		_texture = value
			
func _ready() -> void:
	$GFX/Texture.texture = _texture
	
