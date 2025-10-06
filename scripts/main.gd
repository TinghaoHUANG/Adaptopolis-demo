# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name Main
extends Node


@export var grid_manager_path: NodePath
@export var city_state_path: NodePath
@export var rain_system_path: NodePath
@export var shop_manager_path: NodePath
@export var localization_path: NodePath
@export var ui_manager_path: NodePath
@export var save_manager_path: NodePath
@export var facility_library_path: NodePath
@export var next_round_button_path: NodePath
@export var grid_display_path: NodePath
@export var shop_display_path: NodePath
@export var status_label_path: NodePath
@export var start_menu_path: NodePath
@export var start_button_path: NodePath
@export var hud_container_path: NodePath
@export var shop_panel_path: NodePath
@export var restart_button_path: NodePath
@export var victory_menu_path: NodePath
@export var victory_label_path: NodePath
@export var victory_restart_button_path: NodePath
@export var victory_endless_button_path: NodePath

@export var facility_data_path: String = "res://data/facility_data.json"
@export var locale_files: Dictionary = {
	"en": "res://locales/en.csv",
	"zh": "res://locales/zh.csv"
}

var city_state: CityState
var grid_manager: GridManager
var facility_library: FacilityLibrary
var rain_system: RainSystem
var shop_manager: ShopManager
var localization: LocalizationManager
var ui_manager: UIManager
var save_manager: SaveManager
var grid_display: GridDisplay = null
var shop_display: ShopDisplay = null
var status_label: Label = null
var next_round_button: Button = null
var selected_offer_index: int = -1
var selected_preview_facility: Facility = null
var dragged_facility: Facility = null
var dragged_original_origin: Vector2i = Vector2i.ZERO
var start_menu: Control = null
var start_button: Button = null
var hud_container: Control = null
var shop_panel: Control = null
var restart_button: Button = null
var victory_menu: Control = null
var victory_label: Label = null
var victory_restart_button: Button = null
var victory_endless_button: Button = null
var game_active: bool = false
var endless_mode: bool = false
const VICTORY_ROUND_TARGET := 20

func _ready() -> void:
	city_state = _ensure_node(city_state_path, CityState) as CityState
	grid_manager = _ensure_node(grid_manager_path, GridManager) as GridManager
	facility_library = _ensure_node(facility_library_path, FacilityLibrary) as FacilityLibrary
	rain_system = _ensure_node(rain_system_path, RainSystem) as RainSystem
	shop_manager = _ensure_node(shop_manager_path, ShopManager) as ShopManager
	localization = _ensure_node(localization_path, LocalizationManager) as LocalizationManager
	ui_manager = _ensure_node(ui_manager_path, UIManager) as UIManager
	save_manager = _ensure_node(save_manager_path, SaveManager) as SaveManager

	status_label = get_node_or_null(status_label_path) as Label
	start_menu = get_node_or_null(start_menu_path) as Control
	start_button = get_node_or_null(start_button_path) as Button
	hud_container = get_node_or_null(hud_container_path) as Control
	shop_panel = get_node_or_null(shop_panel_path) as Control
	restart_button = get_node_or_null(restart_button_path) as Button
	victory_menu = get_node_or_null(victory_menu_path) as Control
	victory_label = get_node_or_null(victory_label_path) as Label
	victory_restart_button = get_node_or_null(victory_restart_button_path) as Button
	victory_endless_button = get_node_or_null(victory_endless_button_path) as Button
	_bind_controls()

	grid_display = get_node_or_null(grid_display_path) as GridDisplay
	if grid_display:
		_grid_display_call("set_grid_manager", [grid_manager])
		grid_display.connect("cell_clicked", Callable(self, "_on_grid_cell_clicked"))

	shop_display = get_node_or_null(shop_display_path) as ShopDisplay
	if shop_display:
		shop_display.connect("offer_selected", Callable(self, "_on_shop_offer_selected"))
		shop_display.connect("skip_selected", Callable(self, "_on_shop_skip_selected"))
		shop_display.connect("refresh_requested", Callable(self, "_on_shop_refresh_requested"))

	grid_manager.set_city_state(city_state)
	facility_library.load_from_json(facility_data_path)
	shop_manager.set_library(facility_library)
	shop_manager.set_city_state(city_state)
	localization.ensure_loaded(locale_files)
	ui_manager.set_city_state(city_state)

	if city_state and not city_state.is_connected("stats_changed", Callable(self, "_on_city_stats_changed")):
		city_state.connect("stats_changed", Callable(self, "_on_city_stats_changed"))

	grid_manager.connect("facility_placed", Callable(self, "_on_facility_placed"))
	shop_manager.connect("facility_purchased", Callable(self, "_on_facility_purchased"))
	shop_manager.connect("offers_changed", Callable(self, "_on_offers_changed"))
	shop_manager.connect("purchase_failed", Callable(self, "_on_purchase_failed"))

	_show_start_menu()

func start_new_game() -> void:
	_cancel_dragged_facility(false)
	_clear_selection_preview()
	selected_offer_index = -1
	endless_mode = false
	game_active = true
	_hide_start_menu()
	_hide_victory_menu()
	city_state.reset()
	grid_manager.clear()
	if grid_display:
		grid_display.visible = true
		_grid_display_call("refresh_all")
	if shop_panel:
		shop_panel.visible = true
	if hud_container:
		hud_container.visible = true
	if shop_display:
		_shop_display_call("clear_selection")
	var offers: Array = _shop_refresh_offers()
	_on_offers_changed(offers)
	var forecast := _update_forecast()
	if ui_manager:
		ui_manager.show_rain_report({})
	_show_status("A new city rises. Incoming rain intensity: %d. Select a facility to begin building." % forecast)
	_update_button_state()

func simulate_round() -> Dictionary:
	var report: Dictionary = rain_system.simulate_round(city_state)
	ui_manager.show_rain_report(report)
	city_state.add_income()
	city_state.advance_round()
	return report

func attempt_purchase(index: int, origin: Vector2i) -> bool:
	if _is_dragging():
		_show_status("Finish relocating the current facility before placing new builds.")
		return false
	if not shop_manager:
		return false
	return _shop_purchase_offer(index, grid_manager, origin, selected_preview_facility)

func save_game() -> bool:
	if _is_dragging():
		_show_status("Place the facility you're moving before saving.")
		return false
	if not save_manager:
		return false
	var success := save_manager.save_game(city_state, grid_manager)
	if success:
		_show_status("Game saved.")
	return success

func load_game() -> bool:
	_cancel_dragged_facility(true)
	_clear_selection_preview()
	if not save_manager:
		return false
	var loaded := save_manager.load_game(city_state, grid_manager, facility_library)
	if loaded:
		if grid_display:
			_grid_display_call("refresh_all")
		var forecast := _update_forecast()
		if ui_manager:
			ui_manager.show_rain_report({})
		_show_status("Save loaded. Upcoming rain intensity: %d. Continue defending the city." % forecast)
	return loaded

func _on_facility_placed(_facility, _origin: Vector2i) -> void:
	if grid_display:
		_grid_display_call("refresh_all")

func _on_facility_purchased(facility) -> void:
	selected_offer_index = -1
	_clear_selection_preview()
	if grid_display:
		_grid_display_call("refresh_all")
	if shop_display:
		_shop_display_call("clear_selection")
	_show_status("Placed %s (Lv %d)." % [facility.name, facility.level])
	_update_button_state()
	_shop_refresh_offers()

func _on_offers_changed(offers: Array) -> void:
	if shop_display:
		_shop_display_call("set_offers", [offers])
	if selected_offer_index >= 0 and offers.size() > selected_offer_index:
		_set_selected_preview_from_offer(offers[selected_offer_index])
	else:
		if selected_offer_index >= 0:
			selected_offer_index = -1
		_clear_selection_preview()

func _on_purchase_failed(reason: String) -> void:
	var message := "Cannot complete purchase."
	match reason:
		"Invalid offer index":
			message = "That offer is no longer available."
		"City state unavailable":
			message = "City state is not ready yet."
		"Insufficient funds":
			message = "Not enough funds for that facility."
		"Invalid placement":
			message = "That placement is blocked. Try a different tile."
		"Placement failed":
			message = "Placement failed unexpectedly." 
	_show_status(message)

func _on_shop_offer_selected(index: int) -> void:
	if _is_dragging():
		_show_status("Finish relocating the current facility before buying a new one.")
		if shop_display:
			_shop_display_call("clear_selection")
		selected_offer_index = -1
		_clear_selection_preview()
		return
	selected_offer_index = index
	if index < 0:
		_clear_selection_preview()
		_show_status("Select a facility to prepare for placement.")
		return
	var offers := _shop_get_offers()
	if index >= offers.size():
		selected_offer_index = -1
		_clear_selection_preview()
		return
	_set_selected_preview_from_offer(offers[index])

func _on_shop_skip_selected(index: int) -> void:
	if _is_dragging():
		_show_status("Finish relocating the current facility before adjusting shop offers.")
		return
	if not shop_manager:
		return
	if _shop_skip_offer(index):
		selected_offer_index = -1
		_clear_selection_preview()
		if shop_display:
			_shop_display_call("clear_selection")
		_show_status("Skipped offer. Pick another facility when ready.")

func _on_shop_refresh_requested() -> void:
	if _is_dragging():
		_show_status("Finish relocating the current facility before refreshing the shop.")
		return
	_shop_refresh_offers()
	selected_offer_index = -1
	_clear_selection_preview()
	if shop_display:
		_shop_display_call("clear_selection")
	_show_status("Shop refreshed with new options.")

func _on_grid_cell_clicked(position: Vector2i) -> void:
	if not game_active:
		return
	if _is_dragging():
		_attempt_drag_drop(position)
		return
	if selected_offer_index >= 0:
		if attempt_purchase(selected_offer_index, position):
			selected_offer_index = -1
			_clear_selection_preview()
			if shop_display:
				_shop_display_call("clear_selection")
		return
	var existing := grid_manager.get_facility_at(position) if grid_manager else null
	if existing:
		_begin_facility_drag(existing)
		return
	_show_status("Select a facility to place or click an existing one to move it.")

func _input(event: InputEvent) -> void:
	if not game_active:
		return
	var mouse_event := event as InputEventMouseButton
	if mouse_event == null:
		return
	if not mouse_event.pressed or mouse_event.double_click:
		return
	if mouse_event.button_index != MOUSE_BUTTON_RIGHT:
		return
	if _is_dragging():
		return
	if selected_offer_index < 0 or selected_preview_facility == null:
		return
	if grid_display:
		var rect := grid_display.get_global_rect()
		if not rect.has_point(mouse_event.position):
			return
	var clockwise := not mouse_event.shift_pressed
	_rotate_preview(clockwise)
	get_viewport().set_input_as_handled()

func _bind_controls() -> void:
	if not next_round_button_path.is_empty():
		next_round_button = get_node_or_null(next_round_button_path) as Button
	if next_round_button:
		var pressed_callable := Callable(self, "_on_next_round_pressed")
		if next_round_button.is_connected("pressed", pressed_callable):
			next_round_button.disconnect("pressed", pressed_callable)
		next_round_button.connect("pressed", pressed_callable)

	_connect_button(start_button, "_on_start_pressed")
	_connect_button(restart_button, "_on_restart_pressed")
	_connect_button(victory_restart_button, "_on_restart_pressed")
	_connect_button(victory_endless_button, "_on_victory_endless_pressed")

func _on_next_round_pressed() -> void:
	if not game_active:
		return
	if _is_dragging():
		_show_status("Finish relocating the current facility before advancing to the next round.")
		return
	if city_state and city_state.is_game_over():
		return
	var report := simulate_round()
	if grid_display:
		_grid_display_call("refresh_all")
	if not endless_mode and city_state.round_number > VICTORY_ROUND_TARGET:
		_handle_victory(report)
		return
	var forecast := _update_forecast()
	var intensity := int(report.get("intensity", 0))
	var defense := int(report.get("defense", 0))
	var damage := int(report.get("damage", 0))
	_show_status("Rain %d vs Defense %d -> Damage %d. Next rain intensity: %d." % [intensity, defense, damage, forecast])
func _on_city_stats_changed() -> void:
	_update_button_state()

func _update_button_state() -> void:
	if next_round_button == null:
		return
	var disabled := not game_active
	if city_state and city_state.is_game_over():
		disabled = true
	if _is_dragging():
		disabled = true
	next_round_button.disabled = disabled

func _update_forecast() -> int:
	if rain_system == null or city_state == null:
		return 0
	var forecast := rain_system.prepare_forecast(city_state.round_number)
	if ui_manager:
		ui_manager.show_rain_forecast(forecast)
	return forecast

func _ensure_node(path: NodePath, script_type) -> Node:
	if not path.is_empty():
		var existing: Node = get_node_or_null(path)
		if existing:
			return existing
	var node: Node = script_type.new()
	add_child(node)
	return node

func _show_start_menu() -> void:
	_cancel_dragged_facility(true)
	_clear_selection_preview()
	game_active = false
	endless_mode = false
	if start_menu:
		start_menu.visible = true
	if hud_container:
		hud_container.visible = false
	if shop_panel:
		shop_panel.visible = false
	if grid_display:
		grid_display.visible = false
	selected_offer_index = -1
	_shop_display_call("clear_selection")
	_update_button_state()
	_show_status("Welcome to Adaptopolis! Press Start to begin.")

func _hide_start_menu() -> void:
	if start_menu:
		start_menu.visible = false
	if hud_container:
		hud_container.visible = true
	if shop_panel:
		shop_panel.visible = true
	if grid_display:
		grid_display.visible = true
	_update_button_state()

func _show_victory_menu(summary: String) -> void:
	_cancel_dragged_facility(true)
	_clear_selection_preview()
	game_active = false
	if victory_label:
		victory_label.text = summary
	if victory_menu:
		victory_menu.visible = true
		var summary_label := victory_menu.get_node_or_null("Menu/Panel/VBox/SummaryLabel") as Label
		if summary_label:
			summary_label.text = "Continue in endless mode or restart the campaign."
	if shop_panel:
		shop_panel.visible = false
	_update_button_state()

func _hide_victory_menu() -> void:
	if victory_menu:
		victory_menu.visible = false
	if shop_panel:
		shop_panel.visible = true
	_update_button_state()

func _handle_victory(_report: Dictionary) -> void:
	game_active = false
	endless_mode = false
	selected_offer_index = -1
	_clear_selection_preview()
	_shop_display_call("clear_selection")
	var completed_rounds: int = 0
	if city_state:
		completed_rounds = max(city_state.round_number - 1, 0)
	var summary := "City secured! Completed %d rounds." % completed_rounds
	_show_status("%s Choose an option to proceed." % summary)
	_show_victory_menu(summary)

func _on_start_pressed() -> void:
	start_new_game()

func _on_restart_pressed() -> void:
	start_new_game()

func _on_victory_endless_pressed() -> void:
	endless_mode = true
	game_active = true
	_hide_victory_menu()
	var forecast := _update_forecast()
	_show_status("Endless mode engaged. Next rain intensity: %d." % forecast)
	_update_button_state()

func _connect_button(button: Button, method_name: String) -> void:
	if button == null:
		return
	var callable := Callable(self, method_name)
	if button.is_connected("pressed", callable):
		button.disconnect("pressed", callable)
	button.connect("pressed", callable)

func _is_dragging() -> bool:
	return dragged_facility != null

func _rotation_hint() -> String:
	return "Right-click to rotate clockwise (顺时针), Shift + Right-click to rotate counter-clockwise (逆时针)."

func _maybe_append_rotation_hint(message: String) -> String:
	if not game_active:
		return message
	if selected_preview_facility == null:
		return message
	if _is_dragging():
		return message
	if message.find("Right-click") != -1:
		return message
	return "%s %s" % [message, _rotation_hint()]

func _build_selection_message(facility: Facility) -> String:
	if facility == null:
		return "Select a facility before placing it on the grid."
	return "Selected %s for %d funds. Right-click to rotate (Shift + Right-click for counter-clockwise). Click a grid tile to place." % [facility.name, facility.cost]

func _clear_selection_preview() -> void:
	selected_preview_facility = null
	_grid_display_call("set_preview_facility", [null])
	_grid_display_call("clear_preview")

func _set_selected_preview_from_offer(facility: Facility) -> void:
	if facility == null:
		_clear_selection_preview()
		return
	selected_preview_facility = facility.clone()
	_grid_display_call("set_preview_facility", [selected_preview_facility])
	_show_status(_build_selection_message(selected_preview_facility))

func _rotate_preview(clockwise: bool) -> void:
	if selected_preview_facility == null:
		return
	var shape: Array = selected_preview_facility.shape
	if shape.is_empty():
		return
	if clockwise:
		selected_preview_facility.shape = _rotate_shape_clockwise(shape)
	else:
		selected_preview_facility.shape = _rotate_shape_counterclockwise(shape)
	_grid_display_call("set_preview_facility", [selected_preview_facility])
	_show_status(_build_selection_message(selected_preview_facility))

func _rotate_shape_clockwise(shape: Array) -> Array:
	if shape.is_empty():
		return []
	var height := shape.size()
	var width := (shape[0] as Array).size()
	var rotated: Array = []
	for x in range(width):
		var row: Array = []
		for y in range(height - 1, -1, -1):
			row.append(shape[y][x])
		rotated.append(row)
	return rotated

func _rotate_shape_counterclockwise(shape: Array) -> Array:
	if shape.is_empty():
		return []
	var height := shape.size()
	var width := (shape[0] as Array).size()
	var rotated: Array = []
	for x in range(width - 1, -1, -1):
		var row: Array = []
		for y in range(height):
			row.append(shape[y][x])
		rotated.append(row)
	return rotated

func _begin_facility_drag(facility: Facility) -> void:
	if facility == null:
		return
	if grid_manager == null:
		return
	dragged_facility = facility
	dragged_original_origin = grid_manager.get_facility_origin(facility)
	grid_manager.remove_facility(facility)
	if grid_display:
		_grid_display_call("set_preview_facility", [facility])
	_show_status("Repositioning %s. Choose a new tile for its top-left corner." % facility.name)
	_update_button_state()

func _attempt_drag_drop(position: Vector2i) -> void:
	if not _is_dragging():
		return
	if grid_manager == null:
		return
	var facility := dragged_facility
	if not grid_manager.can_place_facility(facility, position):
		_show_status("That location is blocked. Choose another tile or click the original spot to cancel.")
		if grid_display:
			_grid_display_call("set_preview_facility", [facility])
		return
	var placed := grid_manager.place_facility(facility, position)
	if not placed:
		_show_status("Unable to move %s there. Try a different tile." % facility.name)
		if grid_display:
			_grid_display_call("set_preview_facility", [facility])
		return
	dragged_facility = null
	dragged_original_origin = Vector2i.ZERO
	if grid_display:
		_grid_display_call("set_preview_facility", [null])
		_grid_display_call("clear_preview")
	_show_status("Moved %s to a new position." % facility.name)
	_update_button_state()

func _cancel_dragged_facility(restore: bool = true, message: String = "") -> void:
	if not _is_dragging():
		return
	var facility := dragged_facility
	var origin := dragged_original_origin
	dragged_facility = null
	dragged_original_origin = Vector2i.ZERO
	if restore and grid_manager and facility:
		var restored := grid_manager.can_place_facility(facility, origin) and grid_manager.place_facility(facility, origin)
		if not restored:
			push_warning("Failed to restore facility %s to origin %s" % [facility.name, origin])
	if grid_display:
		_grid_display_call("set_preview_facility", [null])
		_grid_display_call("clear_preview")
	if not message.is_empty():
		_show_status(message)
	_update_button_state()

func _shop_refresh_offers() -> Array:
	if shop_manager and shop_manager.has_method("refresh_offers"):
		var result = shop_manager.call("refresh_offers")
		return result if typeof(result) == TYPE_ARRAY else []
	return []

func _shop_get_offers() -> Array:
	if shop_manager and shop_manager.has_method("get_offers"):
		var result = shop_manager.call("get_offers")
		return result if typeof(result) == TYPE_ARRAY else []
	return []

func _shop_skip_offer(index: int) -> bool:
	if shop_manager and shop_manager.has_method("skip_offer"):
		return bool(shop_manager.call("skip_offer", index))
	return false

func _shop_purchase_offer(index: int, manager: Node, origin: Vector2i, template: Facility = null) -> bool:
	if shop_manager and shop_manager.has_method("purchase_offer"):
		return bool(shop_manager.call("purchase_offer", index, manager, origin, template))
	return false

func _grid_display_call(method: StringName, args: Array = []) -> void:
	if grid_display and grid_display.has_method(method):
		grid_display.callv(method, args)

func _shop_display_call(method: StringName, args: Array = []) -> void:
	if shop_display and shop_display.has_method(method):
		shop_display.callv(method, args)

func _show_status(message: String) -> void:
	message = _maybe_append_rotation_hint(message)
	if status_label:
		status_label.text = message
	print(message)
