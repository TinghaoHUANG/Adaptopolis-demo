# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name ShopDisplay
extends PanelContainer

signal offer_selected(index: int)
signal skip_selected(index: int)
signal refresh_requested()

@export var offers_container_path: NodePath
@export var detail_label_path: NodePath
@export var warning_label_path: NodePath
@export var skip_button_path: NodePath
@export var refresh_button_path: NodePath

var offers: Array = []
var buttons: Array[Button] = []
var button_group: ButtonGroup = ButtonGroup.new()
var selected_index: int = -1
var offers_container: VBoxContainer = null
var detail_label: Label = null
var warning_label: Label = null
var skip_button: Button = null
var refresh_button: Button = null

const LEVEL2_HIGHLIGHT: Color = Color(0.64, 0.45, 0.93, 1.0)
const LEVEL3_HIGHLIGHT: Color = Color(0.96, 0.80, 0.30, 1.0)
const LEVEL_BORDER_WIDTH: int = 3
const NO_HIGHLIGHT: Color = Color(0, 0, 0, 0)
const BASE_BUTTON_COLOR: Color = Color(0.24, 0.27, 0.33)
const OFFER_TITLE_FONT: FontFile = preload("res://fonts/pixel_font.tres")
const OFFER_TITLE_FONT_SIZE: int = 16
const OFFER_STATS_FONT: FontFile = preload("res://fonts/pixel_font.tres")
const OFFER_STATS_FONT_SIZE: int = 16
const DETAIL_FONT: FontFile = preload("res://fonts/details_font_desc.tres")
const DETAIL_FONT_SIZE: int = 28
const SHAPE_PREVIEW_CLASS := preload("res://scripts/shop_shape_preview.gd")

func _ready() -> void:
	button_group.allow_unpress = true
	offers_container = get_node_or_null(offers_container_path) as VBoxContainer
	detail_label = get_node_or_null(detail_label_path) as Label
	warning_label = get_node_or_null(warning_label_path) as Label
	skip_button = get_node_or_null(skip_button_path) as Button
	refresh_button = get_node_or_null(refresh_button_path) as Button
	if skip_button:
		skip_button.text = tr("SKIP_TURN")
		skip_button.connect("pressed", Callable(self, "_on_skip_pressed"))
	if refresh_button:
		refresh_button.text = "Refresh"
		refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
	if detail_label and DETAIL_FONT:
		detail_label.add_theme_font_override("font", DETAIL_FONT)
		detail_label.add_theme_font_size_override("font_size", DETAIL_FONT_SIZE)
	if warning_label:
		warning_label.visible = false
		warning_label.text = ""
		warning_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.34))
	_update_status_hint()

func set_offers(new_offers: Array) -> void:
	offers = new_offers.duplicate()
	selected_index = -1
	_rebuild_offer_list()
	_update_status_hint()

func set_status(text: String) -> void:
	if detail_label:
		detail_label.text = text

func set_warning(text: String) -> void:
	if warning_label == null:
		return
	warning_label.text = text
	warning_label.visible = not text.is_empty()

func clear_warning() -> void:
	set_warning("")

func clear_selection() -> void:
	selected_index = -1
	for button in buttons:
		button.button_pressed = false
	_update_status_hint()
	clear_warning()
	if offers_container and offers.is_empty():
		set_status("No offers available.")

func _rebuild_offer_list() -> void:
	if offers_container == null:
		return
	clear_warning()
	for button in buttons:
		button.queue_free()
	buttons.clear()
	for index in range(offers.size()):
		var facility: Facility = offers[index]
		var button := _create_offer_button(index, facility)
		offers_container.add_child(button)
		buttons.append(button)

func _create_offer_button(index: int, facility: Facility) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false
	button.custom_minimum_size = Vector2(0, 110)
	button.text = ""
	var content := HBoxContainer.new()
	content.name = "Summary"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 12)
	button.add_child(content)

	var text_column := VBoxContainer.new()
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_column.alignment = BoxContainer.ALIGNMENT_BEGIN
	text_column.add_theme_constant_override("separation", 6)
	content.add_child(text_column)

	var title_label := Label.new()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.text = _format_offer_title(facility)
	if OFFER_TITLE_FONT:
		title_label.add_theme_font_override("font", OFFER_TITLE_FONT)
		title_label.add_theme_font_size_override("font_size", OFFER_TITLE_FONT_SIZE)
	text_column.add_child(title_label)

	var stats_row := HBoxContainer.new()
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	stats_row.add_theme_constant_override("separation", 8)
	text_column.add_child(stats_row)

	var stats_label := Label.new()
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stats_label.text = _format_offer_stats(facility)
	if OFFER_STATS_FONT:
		stats_label.add_theme_font_override("font", OFFER_STATS_FONT)
		stats_label.add_theme_font_size_override("font_size", OFFER_STATS_FONT_SIZE)
	stats_row.add_child(stats_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spacer.custom_minimum_size = Vector2(28, 0)
	stats_row.add_child(spacer)

	var preview := SHAPE_PREVIEW_CLASS.new()
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.set_facility(facility)
	stats_row.add_child(preview)

	_apply_offer_style(button, facility)
	button.connect("toggled", Callable(self, "_on_offer_toggled").bind(index))
	return button

func _apply_offer_style(button: Button, facility: Facility) -> void:
	var highlight := _get_level_highlight(facility.level)
	var base_color := BASE_BUTTON_COLOR
	if highlight != NO_HIGHLIGHT:
		base_color = BASE_BUTTON_COLOR.lerp(highlight, 0.25)
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(8)
	if highlight == NO_HIGHLIGHT:
		normal.set_border_width_all(1)
		normal.border_color = BASE_BUTTON_COLOR.darkened(0.35)
	else:
		normal.set_border_width_all(LEVEL_BORDER_WIDTH)
		normal.border_color = highlight
		normal.shadow_color = Color(highlight.r, highlight.g, highlight.b, 0.35)
		normal.shadow_offset = Vector2.ZERO
		normal.shadow_size = LEVEL_BORDER_WIDTH * 6
	var hover := normal.duplicate()
	var pressed := normal.duplicate()
	var hover_color := base_color.lightened(0.10)
	var pressed_color := base_color.darkened(0.12)
	hover.bg_color = hover_color
	pressed.bg_color = pressed_color
	if highlight != NO_HIGHLIGHT:
		hover.shadow_color = Color(highlight.r, highlight.g, highlight.b, 0.45)
		pressed.shadow_color = Color(highlight.r, highlight.g, highlight.b, 0.25)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color.WHITE)

func _get_level_highlight(level: int) -> Color:
	if level <= 1:
		return NO_HIGHLIGHT
	if level == 2:
		return LEVEL2_HIGHLIGHT
	return LEVEL3_HIGHLIGHT

func _format_offer_title(facility: Facility) -> String:
	var dots := facility.get_type_dots()
	var prefix := "%s " % dots if not dots.is_empty() else ""
	return "%s%s (Lv %d)" % [prefix, facility.name, facility.level]

func _format_offer_stats(facility: Facility) -> String:
	return "💰 %d    🛡️ %d" % [facility.cost, facility.resilience]

func _build_detail_text(facility: Facility) -> String:
	var description := facility.description.strip_edges()
	if description.is_empty():
		return "No description available yet."
	return description

func _on_offer_toggled(pressed: bool, index: int) -> void:
	if not pressed:
		if selected_index == index:
			selected_index = -1
			emit_signal("offer_selected", -1)
			_update_status_hint()
		return
	selected_index = index
	clear_warning()
	emit_signal("offer_selected", index)
	var facility: Facility = offers[index]
	set_status(_build_detail_text(facility))
	if skip_button:
		skip_button.disabled = false

func _on_skip_pressed() -> void:
	if selected_index < 0:
		return
	clear_warning()
	emit_signal("skip_selected", selected_index)

func _on_refresh_pressed() -> void:
	clear_warning()
	emit_signal("refresh_requested")

func _update_status_hint() -> void:
	if detail_label == null:
		return
	if skip_button:
		skip_button.disabled = selected_index < 0
	if selected_index >= 0 and selected_index < offers.size():
		var facility: Facility = offers[selected_index]
		set_status(_build_detail_text(facility))
	else:
		set_status("Select a facility, then click the grid to place it.")
