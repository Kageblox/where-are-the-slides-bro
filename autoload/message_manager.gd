extends Node

signal message_received(msg: MessageData)
signal message_answered(msg: MessageData, reply: ReplyData, response_time: float)
signal message_ignored(msg: MessageData)

var current: MessageData

var _age: float = 0.0
var _patience: float = 20.0
var _next_in: float = 25.0
var _active: bool = false
var _used: Array[StringName] = []
var _queue: Array[MessageData] = []
var _scheduled: Array[Dictionary] = []   # follow-ups: {"id": StringName, "in": float}


func reset() -> void:
	current = null
	_used.clear()
	_queue.clear()
	_scheduled.clear()
	_active = false


func begin_slide() -> void:
	_active = true
	_next_in = GameConfig.get_cfg().first_message_delay * randf_range(0.8, 1.3)

func end_slide() -> void:
	_active = false


func patience_fraction() -> float:
	if current == null:
		return 0.0
	return clampf(1.0 - _age / _patience, 0.0, 1.0)


func answer(index: int) -> void:
	if current == null or index < 0 or index >= current.replies.size():
		return
	var msg: MessageData = current
	var reply: ReplyData = msg.replies[index]
	current = null
	ComposureManager.apply(reply.composure_delta, &"message_reply")
	if reply.sets_flag != &"":
		GameManager.flags[reply.sets_flag] = true
	if reply.distraction > 0.0:
		FxLayer.add_distraction(reply.distraction)
	if reply.follow_up_id != &"":
		_scheduled.append({"id": reply.follow_up_id, "in": reply.follow_up_delay})
	message_answered.emit(msg, reply, _age)


func lookup(id: StringName) -> MessageData:
	for m in GameConfig.get_cfg().messages:
		if m != null and m.id == id:
			return m
	return null


func _process(delta: float) -> void:
	if not GameManager.running:
		return
	for s in _scheduled.duplicate():
		s["in"] = float(s["in"]) - delta
		if float(s["in"]) <= 0.0:
			_scheduled.erase(s)
			var m: MessageData = lookup(s["id"])
			if m:
				_queue.append(m)
	if current != null:
		_age += delta
		if _age > _patience * 0.5:
			ComposureManager.drip_lose(GameConfig.get_cfg().message_wait_drain * delta)
		if _age >= _patience:
			var ignored: MessageData = current
			current = null
			ComposureManager.lose(GameConfig.get_cfg().loss_message_ignored, &"message_ignored")
			message_ignored.emit(ignored)
		return
	if not _queue.is_empty():
		_deliver(_queue.pop_front())
		return
	if _active:
		_next_in -= delta
		if _next_in <= 0.0:
			_roll_message()


func _roll_message() -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	var progress: float = SlideManager.progress()
	var pool: Array[MessageData] = []
	var total: float = 0.0
	for m in cfg.messages:
		if m == null or m.follow_up_only or progress < m.min_progress:
			continue
		if m.once and _used.has(m.id):
			continue
		if m.requires_flag != &"" and not GameManager.flags.get(m.requires_flag, false):
			continue
		pool.append(m)
		total += m.weight
	_next_in = _gap()
	if pool.is_empty():
		return
	var roll: float = randf() * total
	for m in pool:
		roll -= m.weight
		if roll <= 0.0:
			_deliver(m)
			return
	_deliver(pool[pool.size() - 1])


func _gap() -> float:
	var cfg: GameConfig = GameConfig.get_cfg()
	var base: float = lerpf(cfg.message_gap.x, cfg.message_gap.y, DifficultyDirector.message_rate())
	return base / ComposureManager.notification_multiplier() * randf_range(0.7, 1.3)


func _deliver(m: MessageData) -> void:
	var cfg: GameConfig = GameConfig.get_cfg()
	current = m
	_age = 0.0
	_patience = lerpf(cfg.message_patience.x, cfg.message_patience.y, DifficultyDirector.popup_window_pressure())
	if m.once:
		_used.append(m.id)
	if m.arrival_stress > 0.0:
		ComposureManager.lose(m.arrival_stress, &"stressful_message")
	message_received.emit(m)
