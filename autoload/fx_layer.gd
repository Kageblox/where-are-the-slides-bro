extends CanvasLayer
## Screen shake (composure), glitch shader (virus), busy spinner (lag), distraction veil (messages).

const GLITCH: String = """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float intensity = 0.0;
uniform float t = 0.0;
float rnd(float x) { return fract(sin(x * 12.9898) * 43758.5453); }
void fragment() {
	vec2 uv = SCREEN_UV;
	float row = floor(uv.y * 40.0) + floor(t * 8.0);
	float band = step(0.985 - 0.06 * intensity, rnd(row));
	float shift = (rnd(row + 7.0) - 0.5) * 0.06 * intensity * band;
	vec2 o = vec2(shift + 0.002 * intensity, 0.0);
	COLOR = vec4(texture(screen_tex, uv + o).r, texture(screen_tex, uv).g, texture(screen_tex, uv - o).b, 1.0);
}
"""

class _Spinner extends Control:
	func _draw() -> void:
		var t: float = Time.get_ticks_msec() * 0.006
		draw_arc(Vector2(16, 16), 11.0, t, t + PI * 1.3, 24, Color(1, 1, 1, 0.85), 3.0, true)

var _mat: ShaderMaterial = ShaderMaterial.new()
var _glitch: ColorRect = ColorRect.new()
var _veil: ColorRect = ColorRect.new()
var _spinner: _Spinner = _Spinner.new()
var _distract: float = 0.0
var _shaking: bool = false
var _cam: Camera2D
var _cam_base: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = 100
	var sh: Shader = Shader.new()
	sh.code = GLITCH
	_mat.shader = sh
	_glitch.material = _mat
	_veil.color = Color(1.0, 0.3, 0.4, 0.0)
	for c in [_glitch, _veil]:
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(c)
	_spinner.size = Vector2(32, 32)
	_spinner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_spinner)


func add_distraction(seconds: float) -> void:
	_distract = maxf(_distract, seconds)


func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.001
	# virus: screen glitches
	var g: float = VirusManager.glitch_level()
	_glitch.visible = g > 0.02 and GameManager.running
	_mat.set_shader_parameter("intensity", g)
	_mat.set_shader_parameter("t", t)
	# composure: shake. With a Camera2D the camera's offset is shaken (the camera owns the
	# canvas transform, so overwriting it would break the zoom); otherwise the canvas itself.
	var shake: float = ComposureManager.shake_px() if GameManager.running else 0.0
	var cam: Camera2D = get_viewport().get_camera_2d()
	var jolt: Vector2 = Vector2(sin(t * 37.0), cos(t * 29.0)) * shake
	if cam != _cam:
		_cam = cam
		_cam_base = cam.offset if cam else Vector2.ZERO
	if shake > 0.01:
		_shaking = true
		if cam:
			cam.offset = _cam_base + jolt
		else:
			get_viewport().canvas_transform = Transform2D(0.0, jolt)
	elif _shaking:
		_shaking = false
		if cam:
			cam.offset = _cam_base
		else:
			get_viewport().canvas_transform = Transform2D.IDENTITY
	# composure: occasional harmless visual distraction at mild stress
	var ramp: float = ComposureManager.ramp(GameConfig.get_cfg().shake_start_below)
	if GameManager.running and randf() < 0.15 * ramp * delta:
		add_distraction(0.6)
	_distract = maxf(_distract - delta, 0.0)
	_veil.color.a = 0.07 * clampf(_distract, 0.0, 1.0) * (0.5 + 0.5 * sin(t * 14.0))
	# lag: spinner
	_spinner.visible = LagManager.spinner_visible
	_spinner.position = get_viewport().get_visible_rect().size - Vector2(48, 48)
	if _spinner.visible:
		_spinner.queue_redraw()
