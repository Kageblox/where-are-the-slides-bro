extends Control

@export var rotation_speed: float = 2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation += delta * rotation_speed
