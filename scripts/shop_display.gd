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
signal offer_lock_toggled(index: int, locked: bool)

@export var title_label_path: NodePath
@export var offers_container_path: NodePath
@export var detail_label_path: NodePath
@export var warning_label_path: NodePath
@export var skip_button_path: NodePath
@export var refresh_button_path: NodePath
@export var filter_container_path: NodePath

var offers: Array = []
var offer_locks: Array[bool] = []
var buttons: Array[Button] = []
var lock_buttons: Array[Button] = []
var button_group: ButtonGroup = ButtonGroup.new()
var selected_index: int = -1
var offers_container: VBoxContainer = null
var title_label: Label = null
var detail_label: RichTextLabel = null
var warning_label: Label = null
var skip_button: Button = null
var refresh_button: Button = null
var filter_container: HBoxContainer = null
var faction_filter_buttons: Dictionary = {}
var faction_filter: String = "all"

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
const FUNDS_LABEL_TEXT: String = "🪙 Funds"
const REFRESH_FREE_TEXT := "Free"
const FACTION_STYLES := {
	"all": {
		"label": "All",
		"short": "ALL",
		"color": Color(0.62, 0.66, 0.78)
	},
	"green": {
		"label": "Green",
		"short": "GRN",
		"color": Color(0.32, 0.62, 0.38)
	},
	"grey": {
		"label": "Grey",
		"short": "GRY",
		"color": Color(0.55, 0.58, 0.66)
	},
	"hybrid": {
		"label": "Hybrid",
		"short": "HYB",
		"color": Color(0.74, 0.54, 0.33)
	},
	"blue": {
		"label": "Blue",
		"short": "BLU",
		"color": Color(0.33, 0.55, 0.82)
	},
	"default": {
		"label": "Unassigned",
		"short": "NA",
		"color": Color(0.46, 0.46, 0.46)
	}
}

var _base_title_text: String = ""
var _current_funds_value: Variant = null
var _current_refresh_cost: int = 0

func _ready() -> void:
	button_group.allow_unpress = true
	title_label = get_node_or_null(title_label_path) as Label
	offers_container = get_node_or_null(offers_container_path) as VBoxContainer
	detail_label = get_node_or_null(detail_label_path) as RichTextLabel
	warning_label = get_node_or_null(warning_label_path) as Label
	skip_button = get_node_or_null(skip_button_path) as Button
	refresh_button = get_node_or_null(refresh_button_path) as Button
	filter_container = get_node_or_null(filter_container_path) as HBoxContainer
	if skip_button:
		skip_button.text = tr("SKIP_TURN")
		skip_button.connect("pressed", Callable(self, "_on_skip_pressed"))
	if refresh_button:
		refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
		_update_refresh_button_label()
	if detail_label and DETAIL_FONT:
		detail_label.add_theme_font_override("font", DETAIL_FONT)
		detail_label.add_theme_font_size_override("font_size", DETAIL_FONT_SIZE)
	if warning_label:
		warning_label.visible = false
		warning_label.text = ""
		warning_label.add_theme_color_override("font_color", Color(1.0, 0.34, 0.34))
	if detail_label:
		detail_label.bbcode_enabled = true
	if title_label:
		_base_title_text = title_label.text
		_refresh_title()
	_build_faction_filters()
	_update_status_hint()

func set_offers(new_offers: Array, locked_states: Array = []) -> void:
	offers = new_offers.duplicate()
	offer_locks.clear()
	for i in range(offers.size()):
		var locked := false
		if i < locked_states.size():
			locked = bool(locked_states[i])
		offer_locks.append(locked)
	selected_index = -1
	_rebuild_offer_list()
	_update_status_hint()

func set_status(text: String) -> void:
	_set_detail_text(text, false)

func set_warning(text: String) -> void:
	if warning_label == null:
		return
	warning_label.text = text
	warning_label.visible = not text.is_empty()

func clear_warning() -> void:
	set_warning("")

func set_funds(value) -> void:
	_current_funds_value = value
	_refresh_title()

func set_refresh_cost(cost: int) -> void:
	_current_refresh_cost = max(0, cost)
	_update_refresh_button_label()

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
	for button in lock_buttons:
		if is_instance_valid(button):
			button.queue_free()
	lock_buttons.clear()
	for index in range(offers.size()):
		var facility: Facility = offers[index]
		var button := _create_offer_button(index, facility)
		offers_container.add_child(button)
		buttons.append(button)
	_sync_lock_buttons()
	_apply_filter_to_buttons()

func _create_offer_button(index: int, facility: Facility) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.focus_mode = Control.FOCUS_NONE
	button.flat = false
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_minimum_size = Vector2(440, 110)
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

	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_row.add_theme_constant_override("separation", 8)
	text_column.add_child(header_row)

	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.text = _format_offer_title(facility)
	if OFFER_TITLE_FONT:
		name_label.add_theme_font_override("font", OFFER_TITLE_FONT)
		name_label.add_theme_font_size_override("font_size", OFFER_TITLE_FONT_SIZE)
	header_row.add_child(name_label)

	var badge := _create_faction_badge(facility.faction)
	header_row.add_child(badge)

	var stats_row := HBoxContainer.new()
	stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	stats_row.add_theme_constant_override("separation", 8)
	stats_row.custom_minimum_size = Vector2(button.custom_minimum_size.x + 40, 0)
	text_column.add_child(stats_row)

	var stats_group := HBoxContainer.new()
	stats_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_group.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_group.alignment = BoxContainer.ALIGNMENT_BEGIN
	stats_group.add_theme_constant_override("separation", 12)
	stats_row.add_child(stats_group)

	var stats_label := Label.new()
	stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	stats_label.text = _format_offer_stats(facility)
	if OFFER_STATS_FONT:
		stats_label.add_theme_font_override("font", OFFER_STATS_FONT)
		stats_label.add_theme_font_size_override("font_size", OFFER_STATS_FONT_SIZE)
	stats_group.add_child(stats_label)

	var preview := SHAPE_PREVIEW_CLASS.new()
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview.set_facility(facility)
	stats_group.add_child(preview)
	var lock_spacer := Control.new()
	lock_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lock_spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	stats_row.add_child(lock_spacer)

	var lock_button := Button.new()
	lock_button.toggle_mode = true
	lock_button.focus_mode = Control.FOCUS_NONE
	lock_button.mouse_filter = Control.MOUSE_FILTER_STOP
	lock_button.text = "🔓"
	lock_button.tooltip_text = "Lock this offer to keep it on refresh."
	lock_button.custom_minimum_size = Vector2(32, 32)
	lock_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	lock_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lock_button.connect("toggled", Callable(self, "_on_lock_toggled").bind(index))
	stats_row.add_child(lock_button)
	lock_buttons.append(lock_button)

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

func _refresh_title() -> void:
	if title_label == null:
		return
	if _base_title_text.is_empty():
		_base_title_text = title_label.text if not title_label.text.is_empty() else "🛒 Shop"
	if _current_funds_value == null:
		title_label.text = _base_title_text
		return
	var formatted := _format_money(_current_funds_value)
	title_label.text = "%s    %s %s" % [_base_title_text, FUNDS_LABEL_TEXT, formatted]

func _update_refresh_button_label() -> void:
	if refresh_button == null:
		return
	var base_label := "Refresh"
	if _current_refresh_cost <= 0:
		refresh_button.text = "%s (%s)" % [base_label, tr(REFRESH_FREE_TEXT)]
	else:
		refresh_button.text = "%s (-%d)" % [base_label, _current_refresh_cost]

func _format_offer_title(facility: Facility) -> String:
	var dots := facility.get_type_dots()
	var prefix := "%s " % dots if not dots.is_empty() else ""
	return "%s%s (Lv %d)" % [prefix, facility.name, facility.level]

func _format_offer_stats(facility: Facility) -> String:
	return "💰 %d    🛡️ %d" % [facility.cost, facility.resilience]

func _build_detail_text(facility: Facility) -> String:
	var style := _get_faction_style(facility.faction)
	var capex := _format_money(facility.capex if facility.capex != 0 else facility.cost)
	var opex := _format_money(facility.opex_per_year)
	var maintenance := _format_money(facility.maint_required)
	var lifetime := facility.lifetime_years
	var build_time := facility.build_time_weeks
	var land_use := facility.land_use
	var benefits := _format_co_benefits(facility)
	var description := facility.description.strip_edges()
	if description.is_empty():
		description = "No description available yet."
	var lines: Array[String] = []
	lines.append("[b]%s[/b]" % _escape_bbcode(facility.name))
	lines.append("[color=%s]%s[/color]" % [style.color.to_html(false), style.label])
	lines.append("CapEx %s    OpEx/yr %s    Lifetime %dy" % [capex, opex, lifetime])
	lines.append("Maintenance %s / yr    Build %dw    Land %s tiles" % [maintenance, build_time, _format_land(land_use)])
	if not benefits.is_empty():
		lines.append("Co-benefits %s" % benefits)
	lines.append("")
	lines.append(_escape_bbcode(description))
	return "\n".join(lines)

func _format_money(value) -> String:
	var numeric := float(value)
	var rounded: float = round(numeric * 100.0) / 100.0
	if is_equal_approx(rounded, round(rounded)):
		return str(int(round(rounded)))
	return "%0.1f" % rounded

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
	_set_detail_text(_build_detail_text(facility), true)
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
		_set_detail_text(_build_detail_text(facility), true)
	else:
		set_status("Select a facility, then click the grid to place it.")

func _on_lock_toggled(pressed: bool, index: int) -> void:
	if index < 0 or index >= offers.size():
		return
	if index >= offer_locks.size():
		var previous_size := offer_locks.size()
		offer_locks.resize(offers.size())
		for i in range(previous_size, offer_locks.size()):
			offer_locks[i] = false
	offer_locks[index] = pressed
	_update_lock_button_visual(index)
	emit_signal("offer_lock_toggled", index, pressed)

func _update_lock_button_visual(index: int) -> void:
	if index < 0 or index >= lock_buttons.size():
		return
	var button := lock_buttons[index]
	if not is_instance_valid(button):
		return
	var locked := index < offer_locks.size() and offer_locks[index]
	button.set_block_signals(true)
	button.button_pressed = locked
	button.text = "🔒" if locked else "🔓"
	button.tooltip_text = "Unlock this offer to refresh it." if locked else "Lock this offer to keep it on refresh."
	button.set_block_signals(false)

func _sync_lock_buttons() -> void:
	for i in range(lock_buttons.size()):
		_update_lock_button_visual(i)

func _build_faction_filters() -> void:
	if filter_container == null:
		return
	for child in filter_container.get_children():
		child.queue_free()
	faction_filter_buttons.clear()
	var order := ["all", "green", "grey", "hybrid"]
	for faction in order:
		var style := _get_faction_style(faction)
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.text = style.short
		button.tooltip_text = "Show %s facilities." % style.label
		button.button_pressed = faction == faction_filter
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var theme := StyleBoxFlat.new()
		theme.bg_color = style.color.darkened(0.2)
		theme.set_corner_radius_all(6)
		button.add_theme_stylebox_override("normal", theme)
		var hover := theme.duplicate()
		hover.bg_color = style.color
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", hover)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.connect("pressed", Callable(self, "_on_faction_filter_pressed").bind(faction))
		filter_container.add_child(button)
		faction_filter_buttons[faction] = button

func _on_faction_filter_pressed(faction: String) -> void:
	if faction_filter == faction:
		return
	faction_filter = faction
	for key in faction_filter_buttons.keys():
		var btn: Button = faction_filter_buttons[key]
		if is_instance_valid(btn):
			btn.set_block_signals(true)
			btn.button_pressed = key == faction_filter
			btn.set_block_signals(false)
	_apply_filter_to_buttons()

func _apply_filter_to_buttons() -> void:
	var selection_cleared := false
	for i in range(buttons.size()):
		if i >= offers.size():
			continue
		var facility: Facility = offers[i]
		var visible := _passes_faction_filter(facility)
		var button := buttons[i]
		if not is_instance_valid(button):
			continue
		button.visible = visible
		button.disabled = not visible
		if not visible and button.button_pressed:
			button.button_pressed = false
			if selected_index == i:
				selected_index = -1
				selection_cleared = true
	if selection_cleared:
		emit_signal("offer_selected", -1)
		_update_status_hint()

func _passes_faction_filter(facility: Facility) -> bool:
	if facility == null:
		return true
	if faction_filter == "all":
		return true
	return facility.faction.strip_edges().to_lower() == faction_filter

func _create_faction_badge(faction: String) -> Control:
	var style := _get_faction_style(faction)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(64, 24)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var box := StyleBoxFlat.new()
	box.bg_color = style.color
	box.set_corner_radius_all(6)
	box.border_color = style.color.darkened(0.25)
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.text = style.short
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel

func _get_faction_style(faction: String) -> Dictionary:
	var normalized := faction.strip_edges().to_lower()
	if normalized.is_empty():
		return FACTION_STYLES["default"]
	return FACTION_STYLES.get(normalized, FACTION_STYLES["default"])

func _format_co_benefits(facility: Facility) -> String:
	if facility.co_benefits.is_empty():
		return ""
	var heat := float(facility.co_benefits.get("heat_delta", 0.0))
	var ecology := float(facility.co_benefits.get("ecology_delta", 0.0))
	var water := float(facility.co_benefits.get("water_quality_delta", 0.0))
	return "☀ %s    🌿 %s    💧 %s" % [_format_signed(heat), _format_signed(ecology), _format_signed(water)]

func _format_land(value: float) -> String:
	if is_equal_approx(value, floor(value)):
		return str(int(value))
	return "%0.1f" % value

func _format_signed(value: float) -> String:
	if abs(value) < 0.05:
		return "0"
	return "%+0.1f" % value

func _set_detail_text(text: String, rich: bool) -> void:
	if detail_label == null:
		return
	if rich:
		detail_label.bbcode_text = text
	else:
		detail_label.bbcode_text = _escape_bbcode(text)

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]").replace("]", "[rb]")
