class_name JTween extends Object

static func TweenWithDetails(
	object: Node,
	tween_details
	):
	if tween_details is JTweenDetails:
		var tween = object.create_tween()
		tween.tween_property(
			object, 
			tween_details.property, 
			tween_details.final_val, 
			tween_details.duration
			)\
		.set_trans(tween_details.transition)\
		.set_ease(tween_details.ease)\
		.set_delay(tween_details.delay)
	elif tween_details is Array[JTweenDetails]:
		for tween_detail in tween_details:
			TweenWithDetails(object, tween_detail)
