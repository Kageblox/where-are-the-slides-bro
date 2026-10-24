class_name GameConfig
extends Resource
## Every tunable number lives here. Create res://data/game_config.tres (New Resource -> GameConfig).
## Without that file the defaults below are used, but then Slides is empty!

const PATH: String = "res://data/game_config.tres"
static var _cached: GameConfig

static func get_cfg() -> GameConfig:
	if _cached == null:
		if ResourceLoader.exists(PATH):
			_cached = load(PATH) as GameConfig
		if _cached == null:
			_cached = GameConfig.new()
	return _cached

@export_group("Content")
@export var slides: Array[PackedScene] = []
@export var messages: Array[MessageData] = []
@export var captcha_slide_textures: Array[Texture2D] = []
@export var captcha_other_textures: Array[Texture2D] = []
@export var captcha_puzzle_backgrounds: Array[Texture2D] = []

@export_group("Objective curves (x = error, y = score 0..1)")
## x = pixels from the target centre
@export var position_curve: PackedVector2Array = PackedVector2Array([Vector2(0, 1), Vector2(10, 1), Vector2(40, 0.85), Vector2(110, 0.5), Vector2(260, 0)])
## x = degrees
@export var rotation_curve: PackedVector2Array = PackedVector2Array([Vector2(0, 1), Vector2(4, 1), Vector2(15, 0.85), Vector2(40, 0.5), Vector2(90, 0)])
## x = relative size error (0.1 = 10%)
@export var size_curve: PackedVector2Array = PackedVector2Array([Vector2(0, 1), Vector2(0.05, 1), Vector2(0.15, 0.85), Vector2(0.4, 0.5), Vector2(0.9, 0)])

@export_group("Typing")
## x = accuracy %
@export var typing_accuracy_curve: PackedVector2Array = PackedVector2Array([Vector2(60, 0), Vector2(80, 0.35), Vector2(90, 0.65), Vector2(95, 0.85), Vector2(98, 1), Vector2(100, 1)])
## x = wpm / the test's target_wpm. Never below 0.45, so slow typists are not crushed.
@export var typing_speed_curve: PackedVector2Array = PackedVector2Array([Vector2(0, 0.45), Vector2(0.5, 0.8), Vector2(1.0, 1.0)])
## Geometric blend: accuracy dominates, and fast+sloppy cannot score well.
@export var typing_accuracy_exponent: float = 0.7
@export var typing_speed_exponent: float = 0.3

@export_group("Timer and time modifiers")
@export var warn_seconds: float = 30.0
@export var critical_seconds: float = 10.0
## Adaptive deadline bounds (multiplier on a slide's expected_time).
@export var min_time_scale: float = 0.75
@export var max_time_scale: float = 1.25
## Points added when finishing at or before early_fraction of the limit, tapering to 0 at the limit.
@export var time_bonus_max: float = 5.0
@export_range(0.1, 0.95) var early_fraction: float = 0.6
@export var timeout_penalty: float = 6.0

@export_group("Grading")
## Final presentation score below this = Academic Failure ending.
@export var academic_failure_below: float = 40.0
@export var grade_letters: PackedStringArray = PackedStringArray(["A+", "A", "A-", "B+", "B", "B-", "C+", "C", "C-", "D+", "D", "D-"])
@export var grade_cutoffs: PackedFloat32Array = PackedFloat32Array([97.0, 93.0, 90.0, 87.0, 83.0, 80.0, 77.0, 73.0, 70.0, 67.0, 63.0, 60.0])

@export_group("Composure")
@export var composure_start: float = 100.0
@export var composure_regen_per_sec: float = 0.6
## Seconds without any new stressor before regen starts.
@export var calm_delay: float = 4.0
@export var loss_popup_missed: float = 8.0
@export var loss_captcha_wrong: float = 6.0
@export var loss_message_ignored: float = 8.0
@export var loss_timeout: float = 15.0
@export var message_wait_drain: float = 0.25
@export var gain_popup_success: float = 2.0
@export var gain_slide_good: float = 6.0

@export_group("Composure effects")
@export var typo_chance_max: float = 0.12
@export var typo_start_below: float = 35.0
## At least this many characters between two injected typos.
@export var typo_min_gap: int = 6
@export var cursor_error_max_px: float = 7.0
@export var cursor_error_start_below: float = 60.0
@export var shake_max_px: float = 2.5
@export var shake_start_below: float = 75.0
@export var stutter_below: float = 25.0
@export var stutter_chance_per_sec: float = 0.08
@export var stutter_seconds: Vector2 = Vector2(0.15, 0.4)

@export_group("Virus")
@export var virus_download_yes: float = 18.0
@export var virus_bad_choice: float = 8.0
@export var virus_popup_ignored: float = 5.0
@export var virus_drip_per_sec: float = 0.35
@export var virus_fail_challenge: float = 4.0
@export var virus_relief_on_success: float = 1.0
@export var virus_crash_at: float = 100.0

@export_group("Fake lag")
@export var lag_episodes_per_min_max: float = 6.0
@export var lag_episode_seconds: Vector2 = Vector2(0.7, 2.0)
@export var lag_cooldown: float = 5.0
@export var mouse_delay_max: float = 0.32
@export var text_delay_max: float = 0.25
@export var ui_slowdown_max: float = 0.55
@export var open_delay_max: float = 1.4
@export var button_hesitation_max: float = 0.45

@export_group("Popups (Vector2 = easy end, hard end)")
@export var popup_gap: Vector2 = Vector2(35.0, 18.0)
@export var popup_window: Vector2 = Vector2(25.0, 9.0)
@export var max_simultaneous: Vector2 = Vector2(1.0, 4.0)
@export var first_popup_delay: float = 20.0
@export_range(0.0, 1.0) var burst_chance: float = 0.35
@export var calm_seconds: Vector2 = Vector2(12.0, 28.0)
@export var build_seconds: Vector2 = Vector2(10.0, 20.0)
@export var burst_seconds: Vector2 = Vector2(8.0, 16.0)

@export_group("Messages (Vector2 = easy end, hard end)")
@export var message_gap: Vector2 = Vector2(60.0, 22.0)
@export var message_patience: Vector2 = Vector2(30.0, 14.0)
@export var first_message_delay: float = 25.0

@export_group("Difficulty weights (order: progress, skill, pace, stress, virus, popup_fail)")
@export var w_general: PackedFloat32Array = PackedFloat32Array([0.40, 0.20, 0.05, 0.10, 0.15, 0.10])
@export var w_popup_rate: PackedFloat32Array = PackedFloat32Array([0.45, 0.20, 0.05, 0.10, 0.15, 0.05])
@export var w_popup_complexity: PackedFloat32Array = PackedFloat32Array([0.60, 0.30, 0.0, 0.0, 0.10, 0.0])
@export var w_popup_window: PackedFloat32Array = PackedFloat32Array([0.50, 0.25, 0.0, 0.15, 0.0, 0.10])
@export var w_message_rate: PackedFloat32Array = PackedFloat32Array([0.50, 0.15, 0.0, 0.25, 0.0, 0.10])
@export var w_lag: PackedFloat32Array = PackedFloat32Array([0.10, 0.0, 0.0, 0.30, 0.60, 0.0])
@export var w_time: PackedFloat32Array = PackedFloat32Array([0.30, 0.40, 0.20, -0.15, 0.0, 0.0])
@export var progress_exponent: float = 1.2
@export var final_slide_bump: float = 0.15
@export var mercy_below: float = 20.0
@export_range(0.0, 0.6) var mercy_strength: float = 0.3
