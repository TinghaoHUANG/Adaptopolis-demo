# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name CardBar
extends PanelContainer


signal card_hovered(card_info: Dictionary, card_widget: Control)
signal card_hover_exited(card_info: Dictionary, card_widget: Control)

@export var cards_container_path: NodePath
@export var empty_label_path: NodePath

const CARD_SIZE := Vector2(105, 140)
const CARD_CONTENT_WIDTH := 93
const TITLE_HEIGHT := 48
const ART_HEIGHT := 54
const EFFECT_ROW_HEIGHT := 24

var cards_container: HBoxContainer = null
var empty_label: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_container = get_node_or_null(cards_container_path) as HBoxContainer
	empty_label = get_node_or_null(empty_label_path) as Label
	if cards_container:
		cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
		cards_container.add_theme_constant_override("separation", 12)
	show_cards([])

func show_cards(cards: Array) -> void:
	if cards_container == null:
		return
	for child in cards_container.get_children():
		child.queue_free()
	var has_cards := not cards.is_empty()
	if empty_label:
		empty_label.visible = not has_cards
	if not has_cards:
		return
	for card in cards:
		var widget := _create_card_widget(card)
		cards_container.add_child(widget)

func _create_card_widget(card: Dictionary) -> Control:
	var card_frame := PanelContainer.new()
	card_frame.custom_minimum_size = CARD_SIZE
	card_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	card_frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var raw_name := String(card.get("name", "Card"))
	var wrapped_name := _wrap_card_name(raw_name)
	var description := String(card.get("description", ""))
	var effect_summary := String(card.get("effect_summary", ""))
	var effect_icons := String(card.get("effect_icons", ""))
	var trimmed_description := description.strip_edges()
	card_frame.tooltip_text = _build_card_tooltip(raw_name, effect_summary, trimmed_description)

	var is_active := bool(card.get("active", true))
	card_frame.set_meta("card_info", card)
	_apply_card_style(card_frame, is_active)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	margin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	card_frame.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content.alignment = BoxContainer.ALIGNMENT_BEGIN
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)

	var title_wrapper := Control.new()
	title_wrapper.custom_minimum_size = Vector2(CARD_CONTENT_WIDTH, TITLE_HEIGHT)
	title_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_wrapper)

	var title_label := Label.new()
	title_label.text = wrapped_name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_label.max_lines_visible = 2
	title_label.add_theme_font_size_override("font_size", 12)
	title_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if is_active else Color(0.72, 0.76, 0.82))
	title_label.custom_minimum_size = Vector2(CARD_CONTENT_WIDTH, TITLE_HEIGHT)
	title_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_wrapper.add_child(title_label)

	var art_panel := Panel.new()
	art_panel.custom_minimum_size = Vector2(CARD_CONTENT_WIDTH, ART_HEIGHT)
	art_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_panel.add_theme_stylebox_override("panel", _create_art_style(is_active))
	content.add_child(art_panel)

	var effects_label := Label.new()
	effects_label.text = effect_icons
	effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effects_label.custom_minimum_size = Vector2(CARD_CONTENT_WIDTH, EFFECT_ROW_HEIGHT)
	effects_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	effects_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	effects_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	effects_label.clip_text = true
	effects_label.add_theme_font_size_override("font_size", 16)
	effects_label.modulate = Color(1.0, 1.0, 1.0) if is_active else Color(0.68, 0.72, 0.78)
	effects_label.visible = not effect_icons.is_empty()
	content.add_child(effects_label)

	card_frame.connect("mouse_entered", Callable(self, "_on_card_mouse_entered").bind(card_frame))
	card_frame.connect("mouse_exited", Callable(self, "_on_card_mouse_exited").bind(card_frame))
	return card_frame

func _apply_card_style(card_frame: PanelContainer, is_active: bool) -> void:
	var base_color := Color(0.32, 0.36, 0.50) if is_active else Color(0.20, 0.22, 0.28)
	var border_color := Color(0.60, 0.80, 0.96) if is_active else Color(0.38, 0.44, 0.54)
	var normal := StyleBoxFlat.new()
	normal.bg_color = base_color
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(2)
	normal.border_color = border_color
	normal.shadow_color = Color(border_color.r, border_color.g, border_color.b, 0.25)
	normal.shadow_offset = Vector2.ZERO
	normal.shadow_size = 8
	card_frame.add_theme_stylebox_override("panel", normal)

func _create_art_style(is_active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.38, 0.42, 0.58) if is_active else Color(0.24, 0.26, 0.34)
	style.set_corner_radius_all(6)
	style.set_border_width_all(0)
	return style

func _wrap_card_name(raw_name: String) -> String:
	var trimmed_name := raw_name.strip_edges()
	if trimmed_name.is_empty():
		return trimmed_name
	var words := trimmed_name.split(" ", false)
	if words.size() <= 1:
		return trimmed_name
	return _join_with_newlines(words)

func _build_card_tooltip(card_name: String, effect_summary: String, description: String) -> String:
	var parts: Array[String] = []
	if not card_name.strip_edges().is_empty():
		parts.append(card_name.strip_edges())
	if not effect_summary.strip_edges().is_empty():
		parts.append(effect_summary.strip_edges())
	elif not description.is_empty():
		parts.append(description)
	return _join_with_newlines(parts)

func _join_with_newlines(items: Array) -> String:
	if items.is_empty():
		return ""
	var builder := String()
	for index in range(items.size()):
		if index > 0:
			builder += "\n"
		builder += String(items[index])
	return builder

func _on_card_mouse_entered(source: Control) -> void:
	var info: Variant = source.get_meta("card_info")
	if typeof(info) == TYPE_DICTIONARY:
		emit_signal("card_hovered", info, source)

func _on_card_mouse_exited(source: Control) -> void:
	var info: Variant = source.get_meta("card_info")
	if typeof(info) == TYPE_DICTIONARY:
		emit_signal("card_hover_exited", info, source)
