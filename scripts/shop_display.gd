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
@export var skip_button_path: NodePath
@export var refresh_button_path: NodePath

var offers: Array = []
var buttons: Array[Button] = []
var button_group: ButtonGroup = ButtonGroup.new()
var selected_index: int = -1
var offers_container: VBoxContainer = null
var detail_label: Label = null
var skip_button: Button = null
var refresh_button: Button = null

func _ready() -> void:
	button_group.allow_unpress = true
	offers_container = get_node_or_null(offers_container_path) as VBoxContainer
	detail_label = get_node_or_null(detail_label_path) as Label
	skip_button = get_node_or_null(skip_button_path) as Button
	refresh_button = get_node_or_null(refresh_button_path) as Button
	if skip_button:
		skip_button.text = tr("SKIP_TURN")
		skip_button.connect("pressed", Callable(self, "_on_skip_pressed"))
	if refresh_button:
		refresh_button.text = "Refresh"
		refresh_button.connect("pressed", Callable(self, "_on_refresh_pressed"))
	_update_status_hint()

func set_offers(new_offers: Array) -> void:
	offers = new_offers.duplicate()
	selected_index = -1
	_rebuild_offer_list()
	_update_status_hint()

func set_status(text: String) -> void:
	if detail_label:
		detail_label.text = text

func clear_selection() -> void:
	selected_index = -1
	for button in buttons:
		button.button_pressed = false
	_update_status_hint()
	if offers_container and offers.is_empty():
		set_status("No offers available.")

func _rebuild_offer_list() -> void:
	if offers_container == null:
		return
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
	button.custom_minimum_size = Vector2(0, 72)
	button.text = _format_offer_summary(facility)
	button.connect("toggled", Callable(self, "_on_offer_toggled").bind(index))
	return button

func _format_offer_summary(facility: Facility) -> String:
	var icon: String = "GREEN" if facility.type == "green" else "GREY"
	if facility.id == "green_roof":
		icon = "ROOF"
	var lines: Array[String] = []
	lines.append("%s %s (Lv %d)" % [icon, facility.name, facility.level])
	lines.append("COST %d    RESILIENCE %d" % [facility.cost, facility.resilience])
	if facility.special_rule != "":
		lines.append("NOTE: %s" % facility.special_rule)
	if facility.description != "":
		lines.append(facility.description)
	return "\n".join(lines)

func _build_detail_text(facility: Facility) -> String:
	var parts: Array[String] = []
	parts.append("%s (Lv %d)" % [facility.name, facility.level])
	parts.append("Cost: %d" % facility.cost)
	parts.append("Resilience: %d" % facility.resilience)
	if facility.special_rule != "":
		parts.append("Special: %s" % facility.special_rule)
	if facility.description != "":
		parts.append("")
		parts.append(facility.description)
	return "\n".join(parts)

func _on_offer_toggled(pressed: bool, index: int) -> void:
	if not pressed:
		if selected_index == index:
			selected_index = -1
			emit_signal("offer_selected", -1)
			_update_status_hint()
		return
	selected_index = index
	emit_signal("offer_selected", index)
	var facility: Facility = offers[index]
	set_status(_build_detail_text(facility))
	if skip_button:
		skip_button.disabled = false

func _on_skip_pressed() -> void:
	if selected_index < 0:
		return
	emit_signal("skip_selected", selected_index)

func _on_refresh_pressed() -> void:
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
