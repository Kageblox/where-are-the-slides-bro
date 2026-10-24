extends Node

signal run_started
signal run_ended(summary: Dictionary)

enum Ending { ACADEMIC_FAILURE, COMPUTER_DEATH, COMPLETED }

var running: bool = false
var flags: Dictionary = {}


func _ready() -> void:
	VirusManager.computer_crashed.connect(func() -> void: _finish(Ending.COMPUTER_DEATH))
	SlideManager.run_finished.connect(_on_run_finished)


func start_run(host: Node) -> void:
	flags.clear()
	ComposureManager.reset()
	VirusManager.reset()
	ScoreManager.reset()
	DifficultyDirector.reset()
	LagManager.reset()
	PopupDirector.reset()
	MessageManager.reset()
	running = true
	run_started.emit()
	SlideManager.start_run(host)


func _on_run_finished() -> void:
	var low: bool = ScoreManager.grade_score() < GameConfig.get_cfg().academic_failure_below
	_finish(Ending.ACADEMIC_FAILURE if low else Ending.COMPLETED)


func _finish(ending: Ending) -> void:
	if not running:
		return
	running = false
	if is_instance_valid(SlideManager.current):
		SlideManager.current.stop()
	var score: float = ScoreManager.grade_score()
	var grade: String = ScoreManager.letter(score)
	var composure: float = ComposureManager.value
	var virus: float = VirusManager.value
	run_ended.emit({
		"ending": ending,
		"ending_name": Ending.keys()[ending],
		"final_score": score,
		"grade": grade,
		"composure": composure,
		"composure_label": ComposureManager.label(),
		"virus": virus,
		"virus_label": VirusManager.label(),
		"records": ScoreManager.records.duplicate(true),
		"epilogue": _epilogue(ending, grade, composure, virus),
	})


func _epilogue(ending: Ending, grade: String, composure: float, virus: float) -> String:
	if ending == Ending.COMPUTER_DEATH:
		return "The screen froze mid-sentence. The slides were never saved."
	if ending == Ending.ACADEMIC_FAILURE:
		return "You handed it in. The teacher stared at it for a very long time."
	var wreck: bool = composure < 15.0
	var calm: bool = composure >= 60.0
	var barely: bool = virus >= 70.0
	var good: bool = ScoreManager.grade_score() >= 80.0
	if good and wreck and barely:
		return "Grade %s. You remember none of it, and the computer is held together by hope." % grade
	if good and wreck:
		return "Grade %s. You presented it like a ghost." % grade
	if good and calm:
		return "Grade %s. Nobody believes how smooth that was." % grade
	if barely:
		return "Grade %s. The computer did not deserve this." % grade
	return "Grade %s. It's done. Close the laptop." % grade
