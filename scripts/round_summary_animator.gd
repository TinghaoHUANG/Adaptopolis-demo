class_name RoundSummaryAnimator
extends Control


signal animation_finished

const POPUP_FADE_IN := 0.2
const POPUP_HOLD := 0.8
const POPUP_FADE_OUT := 0.2
const SUMMARY_FADE := 0.2
const SUMMARY_HOLD := 1.5
const MONEY_COLOR := Color(0.96, 0.84, 0.25, 1.0)
const MONEY_FAIL_COLOR := Color(0.85, 0.35, 0.35, 1.0)
const POPUP_CHAIN_DELAY := 0.2

@export var popup_font_size: int = 26
@export var summary_font_size: int = 34
@export var popup_color: Color = Color.WHITE
@export var summary_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var popup_offset: Vector2 = Vector2.ZERO

var grid_display: GridDisplay = null
var is_playing: bool = false
var _active_tweens: Array[Tween] = []
var _cancelled: bool = false
var rain_overlay: RainOverlay = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_ensure_rain_overlay()

func set_grid_display(display: GridDisplay) -> void:
	grid_display = display

func reset() -> void:
	_cancelled = true
	for tween in _active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_active_tweens.clear()
	for child in get_children():
		if rain_overlay != null and child == rain_overlay:
			continue
		child.queue_free()
	if rain_overlay:
		rain_overlay.reset()
	is_playing = false

func play_round_report(facilities: Array, grid_manager: GridManager, display: GridDisplay, report: Dictionary) -> void:
	if display != null:
		grid_display = display
	if grid_manager == null:
		return
	if is_playing:
		await animation_finished
	_cancelled = false
	is_playing = true
	_ensure_rain_overlay()
	var facility_list: Array = facilities.duplicate()
	var pump_events_map: Dictionary = {}
	for event_data in report.get("pump_events", []):
		var event: Dictionary = event_data
		var facility: Facility = event.get("facility", null)
		if facility:
			pump_events_map[facility] = event
	for raw_facility in facility_list:
		var cast_facility := raw_facility as Facility
		if cast_facility == null:
			continue
		if _cancelled:
			break
		var center := _resolve_facility_center(cast_facility, grid_manager)
		if pump_events_map.has(cast_facility):
			var event: Dictionary = pump_events_map[cast_facility]
			if event.get("active", false):
				_spawn_value_popup(center, "💰 -0.5", MONEY_COLOR)
				await _wait_between_popups()
				if _cancelled:
					break
				_spawn_facility_popup(cast_facility, center)
				await _wait_between_popups()
			else:
				_spawn_value_popup(center, "💰 0", MONEY_FAIL_COLOR)
				await _wait_between_popups()
			if _cancelled:
				break
		else:
			_spawn_facility_popup(cast_facility, center)
			await _wait_between_popups()
		if _cancelled:
			break
	if not _cancelled:
		await _play_rain_animation(report)
	if not _cancelled:
		await _show_round_summary(report)
	is_playing = false
	emit_signal("animation_finished")
	_cancelled = false

func _spawn_facility_popup(facility: Facility, center: Vector2) -> Tween:
	var value := facility.resilience
	return _spawn_value_popup(center, "🛡️ %d" % value, popup_color)

func _wait_between_popups() -> void:
	await get_tree().create_timer(POPUP_CHAIN_DELAY).timeout

func _spawn_value_popup(center: Vector2, text: String, color: Color) -> Tween:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.6, 0.6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", popup_font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	_position_control(label, center + popup_offset)
	var tween := create_tween()
	_register_tween(tween, label)
	tween.tween_property(label, "modulate:a", 1.0, POPUP_FADE_IN).from(0.0)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, POPUP_FADE_IN).from(Vector2(0.6, 0.6))
	if POPUP_HOLD > 0.0:
		tween.tween_interval(POPUP_HOLD)
	tween.tween_property(label, "modulate:a", 0.0, POPUP_FADE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), POPUP_FADE_OUT)
	return tween

func _show_round_summary(report: Dictionary) -> void:
	var total_resilience := int(report.get("resilience", 0))
	var rainfall := int(report.get("intensity", 0))
	var damage := int(report.get("damage", 0))
	var card_bonus := int(report.get("card_bonus", 0))
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var summary_lines: Array[String] = [
		"🛡️ %d" % total_resilience,
		"🌧️ %d" % rainfall,
		"💥 %d" % damage
	]
	if card_bonus > 0:
		summary_lines.append("🎴 +%d" % card_bonus)
	var damage_delta := int(report.get("card_damage_delta", 0))
	if damage_delta != 0:
		if damage_delta > 0:
			summary_lines.append("🎯 +%d" % damage_delta)
		else:
			summary_lines.append("⚠️ %d" % damage_delta)
	var health_gain := int(report.get("card_health_restore", 0))
	if health_gain > 0:
		summary_lines.append("❤️ +%d" % health_gain)
	label.text = "\n".join(summary_lines)
	label.modulate = Color(1, 1, 1, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", summary_font_size)
	label.add_theme_color_override("font_color", summary_color)
	add_child(label)
	var viewport_rect := get_viewport().get_visible_rect()
	var viewport_center := viewport_rect.size / 2.0
	_position_control(label, viewport_center)
	var tween := create_tween()
	_register_tween(tween, label)
	tween.tween_property(label, "modulate:a", 1.0, SUMMARY_FADE).from(0.0)
	tween.tween_interval(SUMMARY_HOLD)
	tween.tween_property(label, "modulate:a", 0.0, SUMMARY_FADE)
	await tween.finished

func _position_control(control: Control, center: Vector2) -> void:
	var control_size := control.get_combined_minimum_size()
	control.size = control_size
	control.pivot_offset = control_size * 0.5
	control.position = center - control.pivot_offset

func _resolve_facility_center(facility: Facility, grid_manager: GridManager) -> Vector2:
	var viewport_rect := get_viewport().get_visible_rect()
	if grid_display == null:
		return viewport_rect.size / 2.0
	var cells: Array[Vector2i] = grid_manager.get_facility_cells(facility)
	if cells.is_empty():
		var origin := grid_manager.get_facility_origin(facility)
		return grid_display.get_cell_center(origin)
	var total := Vector2.ZERO
	for cell in cells:
		total += grid_display.get_cell_center(cell)
	if cells.size() == 0:
		return viewport_rect.size / 2.0
	return total / float(cells.size())

func _register_tween(tween: Tween, target: Control) -> void:
	_active_tweens.append(tween)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(tween, target))

func _on_tween_finished(tween: Tween, target: Control) -> void:
	_active_tweens.erase(tween)
	if is_instance_valid(target):
		target.queue_free()

func _ensure_rain_overlay() -> void:
	if rain_overlay != null:
		return
	rain_overlay = RainOverlay.new()
	rain_overlay.name = "RainOverlay"
	add_child(rain_overlay)

func _play_rain_animation(report: Dictionary) -> void:
	if rain_overlay == null or grid_display == null:
		return
	var rain_duration := float(report.get("rain_animation_duration", rain_overlay.fall_duration))
	if rain_duration <= 0.0:
		rain_duration = rain_overlay.fall_duration
	var grid_rect := grid_display.get_global_rect()
	var to_local_transform: Transform2D = get_global_transform_with_canvas().affine_inverse()
	var top_left: Vector2 = to_local_transform * grid_rect.position
	var bottom_right: Vector2 = to_local_transform * (grid_rect.position + grid_rect.size)
	var local_pos := Vector2(min(top_left.x, bottom_right.x), min(top_left.y, bottom_right.y))
	var local_size := Vector2(abs(bottom_right.x - top_left.x), abs(bottom_right.y - top_left.y))
	var local_rect := Rect2(local_pos, local_size)
	await rain_overlay.play(local_rect, rain_duration)
