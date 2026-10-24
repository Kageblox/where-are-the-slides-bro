class_name FakeDialogPopup
extends GamePopup

const DIALOGS: Array[Dictionary] = [
	{"title": "Windows Defender", "body": "3 threats were found on your PC.", "good": "Dismiss", "bad": ["Fix now", "Remove all"]},
	{"title": "System Update", "body": "Your computer has not been updated in 94 days.", "good": "Remind me later", "bad": ["Update now", "Install (recommended)"]},
	{"title": "Storage almost full", "body": "Free up space to keep working.", "good": "Not now", "bad": ["Clean up", "Optimize"]},
	{"title": "Browser warning", "body": "Your session has expired.", "good": "Close", "bad": ["Sign in again", "Verify"]},
]

func _init() -> void:
	malicious = true


func _build(c: VBoxContainer) -> void:
	var d: Dictionary = DIALOGS.pick_random()
	var title: Label = Label.new()
	title.text = d["title"]
	title.add_theme_color_override("font_color", Color("ffcf5c"))
	c.add_child(title)
	var body: Label = Label.new()
	body.text = d["body"]
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size.x = 280
	c.add_child(body)

	var buttons: Array[Button] = []
	var good: Button = Button.new()
	good.text = d["good"]
	connect_dismiss(good, func() -> void: succeed())
	buttons.append(good)
	var bads: Array = d["bad"].duplicate()
	bads.shuffle()
	for i in (1 if complexity < 0.5 else 2):    # more traps later
		var b: Button = Button.new()
		b.text = bads[i]
		b.pressed.connect(func() -> void: fail(&"wrong"))
		buttons.append(b)
	buttons.shuffle()
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for b in buttons:
		row.add_child(b)
	c.add_child(row)
