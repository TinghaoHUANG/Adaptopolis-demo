class_name RoundSummaryAnimator
extends Control


signal animation_finished

const POPUP_INTERVAL := 0.5
const POPUP_FADE_IN := 0.2
const POPUP_HOLD := 0.8
const POPUP_FADE_OUT := 0.2
const SUMMARY_FADE := 0.2
const SUMMARY_HOLD := 1.5

@export var popup_font_size: int = 26
@export var summary_font_size: int = 34
@export var popup_color: Color = Color.WHITE
@export var summary_color: Color = Color(0.95, 0.95, 0.95, 1.0)
@export var popup_offset: Vector2 = Vector2.ZERO

var grid_display: GridDisplay = null
var is_playing: bool = false
var _active_tweens: Array[Tween] = []
var _cancelled: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100

func set_grid_display(display: GridDisplay) -> void:
	grid_display = display

func reset() -> void:
	_cancelled = true
	for tween in _active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_active_tweens.clear()
	for child in get_children():
		child.queue_free()
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
	var facility_list: Array = facilities.duplicate()
	for facility in facility_list:
		var cast_facility := facility as Facility
		if cast_facility == null:
			continue
		if _cancelled:
			break
		_spawn_facility_popup(cast_facility, grid_manager)
		await get_tree().create_timer(POPUP_INTERVAL).timeout
		if _cancelled:
			break
	if not _cancelled:
		await _show_round_summary(report)
	is_playing = false
	emit_signal("animation_finished")
	_cancelled = false

func _spawn_facility_popup(facility: Facility, grid_manager: GridManager) -> void:
	var value := facility.resilience
	var center := _resolve_facility_center(facility, grid_manager)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "🛡️ %d" % value
	label.modulate = Color(1, 1, 1, 0)
	label.scale = Vector2(0.6, 0.6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", popup_font_size)
	label.add_theme_color_override("font_color", popup_color)
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

func _show_round_summary(report: Dictionary) -> void:
	var total_resilience := int(report.get("resilience", 0))
	var rainfall := int(report.get("intensity", 0))
	var damage := int(report.get("damage", 0))
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = "🛡️ %d\n🌧️ %d\n💥 %d" % [total_resilience, rainfall, damage]
	label.modulate = Color(1, 1, 1, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", summary_font_size)
	label.add_theme_color_override("font_color", summary_color)
	add_child(label)
	_position_control(label, get_viewport_rect().size * 0.5)
	var tween := create_tween()
	_register_tween(tween, label)
	tween.tween_property(label, "modulate:a", 1.0, SUMMARY_FADE).from(0.0)
	tween.tween_interval(SUMMARY_HOLD)
	tween.tween_property(label, "modulate:a", 0.0, SUMMARY_FADE)
	await tween.finished

func _position_control(control: Control, center: Vector2) -> void:
	var size := control.get_combined_minimum_size()
	control.size = size
	control.pivot_offset = size * 0.5
	control.position = center - control.pivot_offset

func _resolve_facility_center(facility: Facility, grid_manager: GridManager) -> Vector2:
	if grid_display == null:
		return get_viewport_rect().size * 0.5
	var cells: Array[Vector2i] = grid_manager.get_facility_cells(facility)
	if cells.is_empty():
		var origin := grid_manager.get_facility_origin(facility)
		return grid_display.get_cell_center(origin)
	var total := Vector2.ZERO
	for cell in cells:
		total += grid_display.get_cell_center(cell)
	if cells.size() == 0:
		return get_viewport_rect().size * 0.5
	return total / float(cells.size())

func _register_tween(tween: Tween, target: Control) -> void:
	_active_tweens.append(tween)
	tween.connect("finished", Callable(self, "_on_tween_finished").bind(tween, target))

func _on_tween_finished(tween: Tween, target: Control) -> void:
	_active_tweens.erase(tween)
	if is_instance_valid(target):
		target.queue_free()
