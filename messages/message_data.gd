class_name MessageData
extends Resource

@export var id: StringName = &""
@export var sender: String = "Friend"
@export_multiline var text: String = ""
@export var replies: Array[ReplyData] = []
@export var weight: float = 1.0
## 0..1 run progress before this can appear.
@export_range(0.0, 1.0) var min_progress: float = 0.0
## Only appears if GameManager.flags[requires_flag] is true.
@export var requires_flag: StringName = &""
@export var once: bool = true
## Composure lost the moment it arrives (stressful messages).
@export var arrival_stress: float = 0.0
## Only reachable via a reply's follow_up_id.
@export var follow_up_only: bool = false
