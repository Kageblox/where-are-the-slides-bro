class_name ReplyData
extends Resource

@export var text: String = ""
## Negative hurts, positive restores.
@export var composure_delta: float = 0.0
## Seconds of visual noise (FxLayer).
@export var distraction: float = 0.0
## Stored in GameManager.flags, so later messages can require it (consequences).
@export var sets_flag: StringName = &""
## id of a MessageData to send later.
@export var follow_up_id: StringName = &""
@export var follow_up_delay: float = 12.0
