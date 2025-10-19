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

var cards_container: HBoxContainer = null
var empty_label: Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cards_container = get_node_or_null(cards_container_path) as HBoxContainer
	empty_label = get_node_or_null(empty_label_path) as Label
	if cards_container:
		cards_container.alignment = BoxContainer.ALIGNMENT_CENTER
	show_cards([])

func show_cards(cards: Array) -> void:
	if not cards_container:
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
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = false
	button.flat = true
	button.text = card.get("name", "Card")
	button.custom_minimum_size = Vector2(120, 48)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.add_theme_font_size_override("font_size", 18)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("card_info", card)
	button.connect("mouse_entered", Callable(self, "_on_card_mouse_entered").bind(button))
	button.connect("mouse_exited", Callable(self, "_on_card_mouse_exited").bind(button))
	return button

func _on_card_mouse_entered(source: Control) -> void:
	var info: Variant = source.get_meta("card_info")
	if typeof(info) == TYPE_DICTIONARY:
		emit_signal("card_hovered", info, source)

func _on_card_mouse_exited(source: Control) -> void:
	var info: Variant = source.get_meta("card_info")
	if typeof(info) == TYPE_DICTIONARY:
		emit_signal("card_hover_exited", info, source)
