class_name SlideObjective
extends Node

enum Kind { POSITION, SIZE, ROTATION, TYPING, COMPLETION }

@export var kind: Kind = Kind.POSITION
@export var label: String = ""
## Relative importance. Only the ratio between objectives on a slide matters.
@export var weight: float = 1.0
## For POSITION / SIZE / ROTATION.
@export var target: SnapTarget
## For TYPING.
@export var typing_test: TypingTest

var completed: bool = false   # COMPLETION: call mark_complete() from your own logic


func mark_complete(v: bool = true) -> void:
	completed = v


## 0..1
func evaluate() -> float:
	match kind:
		Kind.POSITION:
			return target.score_position() if target else 0.0
		Kind.SIZE:
			return target.score_size() if target else 0.0
		Kind.ROTATION:
			return target.score_rotation() if target else 0.0
		Kind.TYPING:
			if typing_test == null:
				return 0.0
			return ScoreMath.typing_score(typing_test.accuracy, typing_test.wpm,
					typing_test.target_wpm, typing_test.get_progress())
		Kind.COMPLETION:
			return 1.0 if completed else 0.0
	return 0.0


func category() -> String:
	match kind:
		Kind.POSITION:
			return "placement"
		Kind.SIZE:
			return "resize"
		Kind.ROTATION:
			return "rotation"
		Kind.TYPING:
			return "typing"
	return "completion"
