class_name DownloadPopup
extends GamePopup

const BAITS: Array[String] = ["free_slides_pack.exe", "ULTIMATE_templates.zip", "totally_safe_update.msi", "font_pack_(2).dmg.exe"]

func _init() -> void:
	malicious = true


func _build(c: VBoxContainer) -> void:
	var title: Label = Label.new()
	title.text = "Do you want to download this?"
	c.add_child(title)
	var file: Label = Label.new()
	file.text = BAITS.pick_random()
	file.add_theme_color_override("font_color", Color("ffcf5c"))
	c.add_child(file)

	var yes: Button = Button.new()
	var no: Button = Button.new()
	if complexity < 0.5:
		yes.text = "YES"
		no.text = "NO"
	else:   # later: dark-pattern wording
		yes.text = "Download (recommended)"
		no.text = "Not now"
	yes.custom_minimum_size = Vector2(150, 40)
	yes.pressed.connect(func() -> void: fail(&"wrong", _cfg.virus_download_yes))
	connect_dismiss(no, func() -> void: succeed())

	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	var order: Array[Button] = [yes, no]
	if randf() < 0.5:     # swap sides so muscle memory does not solve it
		order.reverse()
	for b in order:
		row.add_child(b)
	c.add_child(row)
