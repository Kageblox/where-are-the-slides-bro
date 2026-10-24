class_name JTween extends Resource

@export var property: String
@export var initial_val: Variant
@export var final_val: Variant
@export var ignore_time_scale: bool
@export var transition: Tween.TransitionType
@export var ease: Tween.EaseType
@export var duration: float = 1
@export var delay: float = 0

static func StartTween(
	object: Node,
	_tween
	):
	if _tween is JTween:
		if _tween.initial_val:
			object.set(_tween.property, _tween.initial_val)
			
		var tween = object.create_tween()
		tween.set_ignore_time_scale(_tween.ignore_time_scale)
		tween.tween_property(
			object, 
			_tween.property, 
			_tween.final_val, 
			_tween.duration
			)\
		.set_trans(_tween.transition)\
		.set_ease(_tween.ease)\
		.set_delay(_tween.delay)
	elif _tween is Array[JTween]:
		for _individualTween in _tween:
			StartTween(object, _individualTween)
