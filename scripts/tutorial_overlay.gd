class_name TutorialOverlay
extends Control

signal tutorial_started
signal tutorial_finished

var dim_top: ColorRect
var dim_bottom: ColorRect
var dim_left: ColorRect
var dim_right: ColorRect
var highlight: Panel
var message_panel: PanelContainer
var message_label: Label
var next_button: Button

var _steps: Array[Dictionary] = []
var _current_step: int = -1
var _current_target: Control = null
var _current_padding: float = 16.0
var _active: bool = false

func _ready() -> void:
	dim_top = $DimTop
	dim_bottom = $DimBottom
	dim_left = $DimLeft
	dim_right = $DimRight
	highlight = $Highlight
	message_panel = $MessagePanel
	message_label = $MessagePanel/Margin/VBox/MessageLabel
	next_button = $MessagePanel/Margin/VBox/NextButton
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	next_button.connect("pressed", Callable(self, "_on_next_pressed"))
	_setup_highlight_style()
	var root_window: Window = get_tree().root
	if root_window and not root_window.is_connected("size_changed", Callable(self, "_on_viewport_size_changed")):
		root_window.connect("size_changed", Callable(self, "_on_viewport_size_changed"))

func start(steps: Array) -> void:
	var sanitized: Array[Dictionary] = []
	for entry in steps:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var target: Variant = entry.get("target", null)
		if target == null or not target is Control:
			continue
		sanitized.append(entry.duplicate(true))
	if sanitized.is_empty():
		return
	_steps = sanitized
	_current_step = -1
	_active = true
	visible = true
	move_to_front()
	mouse_filter = Control.MOUSE_FILTER_STOP
	emit_signal("tutorial_started")
	_advance()

func is_active() -> bool:
	return _active

func _advance() -> void:
	_current_step += 1
	if _current_step >= _steps.size():
		_finish()
		return
	var step: Dictionary = _steps[_current_step]
	_current_target = step.get("target", null)
	_current_padding = float(step.get("padding", 16.0))
	var message: String = String(step.get("message", ""))
	message_label.text = message
	if _current_step == _steps.size() - 1:
		next_button.text = tr("Start")
	else:
		next_button.text = tr("Next")
	call_deferred("_update_layout_for_current_step")

func _finish() -> void:
	_active = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_current_target = null
	_steps.clear()
	emit_signal("tutorial_finished")

func _on_next_pressed() -> void:
	if not _active:
		return
	_advance()

func _on_viewport_size_changed() -> void:
	call_deferred("_update_layout_for_current_step")

func _update_layout_for_current_step() -> void:
	if not _active or _current_step < 0 or _current_step >= _steps.size():
		return
	var viewport_rect: Rect2 = get_viewport_rect()
	var screen_size: Vector2 = viewport_rect.size
	var highlight_rect: Rect2 = Rect2(Vector2.ZERO, Vector2.ZERO)
	if _current_target != null:
		var target_rect: Rect2 = _current_target.get_global_rect()
		highlight_rect.position = target_rect.position - Vector2(_current_padding, _current_padding)
		highlight_rect.size = target_rect.size + Vector2(_current_padding * 2.0, _current_padding * 2.0)
	highlight_rect = _clamp_rect_to_screen(highlight_rect, screen_size)
	highlight.position = highlight_rect.position
	highlight.size = highlight_rect.size
	_update_dim_regions(highlight_rect, screen_size)
	_position_message_panel(highlight_rect, screen_size)

func _update_dim_regions(highlight_rect: Rect2, screen_size: Vector2) -> void:
	var left_edge: float = clamp(highlight_rect.position.x, 0.0, screen_size.x)
	var top_edge: float = clamp(highlight_rect.position.y, 0.0, screen_size.y)
	var right_edge: float = clamp(highlight_rect.position.x + highlight_rect.size.x, 0.0, screen_size.x)
	var bottom_edge: float = clamp(highlight_rect.position.y + highlight_rect.size.y, 0.0, screen_size.y)

	dim_top.position = Vector2.ZERO
	dim_top.size = Vector2(screen_size.x, top_edge)

	dim_bottom.position = Vector2(0.0, bottom_edge)
	dim_bottom.size = Vector2(screen_size.x, max(0.0, screen_size.y - bottom_edge))

	dim_left.position = Vector2(0.0, top_edge)
	dim_left.size = Vector2(left_edge, max(0.0, bottom_edge - top_edge))

	dim_right.position = Vector2(right_edge, top_edge)
	dim_right.size = Vector2(max(0.0, screen_size.x - right_edge), max(0.0, bottom_edge - top_edge))

	for dim in [dim_top, dim_bottom, dim_left, dim_right]:
		dim.visible = dim.size.x > 0.0 and dim.size.y > 0.0

func _position_message_panel(highlight_rect: Rect2, screen_size: Vector2) -> void:
	message_panel.reset_size()
	var preferred_size: Vector2 = message_panel.get_combined_minimum_size()
	var position: Vector2 = highlight_rect.position + Vector2(highlight_rect.size.x + 24.0, 0.0)
	if position.x + preferred_size.x > screen_size.x:
		position.x = max(24.0, highlight_rect.position.x - preferred_size.x - 24.0)
	position.x = clamp(position.x, 24.0, screen_size.x - preferred_size.x - 24.0)

	if position.y + preferred_size.y > screen_size.y:
		position.y = max(24.0, screen_size.y - preferred_size.y - 24.0)
	else:
		position.y = max(24.0, min(position.y, screen_size.y - preferred_size.y - 24.0))

	message_panel.position = position

func _clamp_rect_to_screen(rect: Rect2, screen_size: Vector2) -> Rect2:
	var clamped := rect
	if clamped.size.x <= 0 or clamped.size.y <= 0:
		clamped = Rect2(Vector2(screen_size.x * 0.3, screen_size.y * 0.3), Vector2(200, 120))
	clamped.position.x = clamp(clamped.position.x, 0.0, max(0.0, screen_size.x - clamped.size.x))
	clamped.position.y = clamp(clamped.position.y, 0.0, max(0.0, screen_size.y - clamped.size.y))
	clamped.size.x = clamp(clamped.size.x, 80.0, screen_size.x)
	clamped.size.y = clamp(clamped.size.y, 80.0, screen_size.y)
	return clamped

func _setup_highlight_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.draw_center = false
	style.set_border_width_all(4)
	style.border_color = Color(1.0, 0.85, 0.35, 1.0)
	style.shadow_color = Color(1.0, 0.85, 0.35, 0.4)
	style.shadow_offset = Vector2.ZERO
	style.shadow_size = 12
	highlight.add_theme_stylebox_override("panel", style)
