@tool
class_name SelectTheCorrectImagePopup extends JPopup

signal image_chosen(texture: Texture2D)

const OPTIONS := "PanelContainer/Margins/VBoxContainer/HBoxContainer/"

func _pick(option: String) -> void:
	var button := get_node(OPTIONS + option) as JTextureButton
	image_chosen.emit(button.texture)  
	close()

func _on_option_1_pressed() -> void: 
	_pick("Option1")
	
func _on_option_2_pressed() -> void: 
	_pick("Option2")
	
func _on_option_3_pressed() -> void: 
	_pick("Option3")
