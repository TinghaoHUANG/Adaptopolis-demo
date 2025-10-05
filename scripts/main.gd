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

	start_new_game()

func start_new_game() -> void:
	selected_offer_index = -1
	city_state.reset()
	grid_manager.clear()
	if grid_display:
		_grid_display_call("set_preview_facility", [null])
		_grid_display_call("refresh_all")
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
	if not shop_manager:
		return false
	return _shop_purchase_offer(index, grid_manager, origin)

func save_game() -> bool:
	if not save_manager:
		return false
	var success := save_manager.save_game(city_state, grid_manager)
	if success:
		_show_status("Game saved.")
	return success

func load_game() -> bool:
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
	if grid_display:
		_grid_display_call("set_preview_facility", [null])
		_grid_display_call("clear_preview")
		_grid_display_call("refresh_all")
	if shop_display:
		_shop_display_call("clear_selection")
	_show_status("Placed %s (Lv %d)." % [facility.name, facility.level])
	_update_button_state()
	_shop_refresh_offers()

func _on_offers_changed(offers: Array) -> void:
	if shop_display:
		_shop_display_call("set_offers", [offers])
	if grid_display and selected_offer_index >= 0:
		var current_offers := _shop_get_offers()
		if selected_offer_index < current_offers.size():
			_grid_display_call("set_preview_facility", [current_offers[selected_offer_index]])
		else:
			selected_offer_index = -1
			_grid_display_call("set_preview_facility", [null])

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
	selected_offer_index = index
	if index < 0:
		if grid_display:
			_grid_display_call("set_preview_facility", [null])
		_show_status("Select a facility to prepare for placement.")
		return
	var offers := _shop_get_offers()
	if index >= offers.size():
		selected_offer_index = -1
		if grid_display:
			_grid_display_call("set_preview_facility", [null])
		return
	var facility = offers[index]
	if grid_display:
		_grid_display_call("set_preview_facility", [facility])
	_show_status("Selected %s for %d funds. Click a grid tile to place." % [facility.name, facility.cost])

func _on_shop_skip_selected(index: int) -> void:
	if not shop_manager:
		return
	if _shop_skip_offer(index):
		selected_offer_index = -1
		if grid_display:
			_grid_display_call("set_preview_facility", [null])
		if shop_display:
			_shop_display_call("clear_selection")
		_show_status("Skipped offer. Pick another facility when ready.")

func _on_shop_refresh_requested() -> void:
	_shop_refresh_offers()
	selected_offer_index = -1
	if grid_display:
		_grid_display_call("set_preview_facility", [null])
	if shop_display:
		_shop_display_call("clear_selection")
	_show_status("Shop refreshed with new options.")

func _on_grid_cell_clicked(position: Vector2i) -> void:
	if selected_offer_index < 0:
		_show_status("Select a facility before placing it on the grid.")
		return
	if attempt_purchase(selected_offer_index, position):
		selected_offer_index = -1
		if shop_display:
			_shop_display_call("clear_selection")
		if grid_display:
			_grid_display_call("set_preview_facility", [null])
			_grid_display_call("clear_preview")
	else:
		# Failure feedback handled by purchase_failed signal.
		pass

func _bind_controls() -> void:
	next_round_button = null
	if not next_round_button_path.is_empty():
		next_round_button = get_node_or_null(next_round_button_path) as Button
	if next_round_button:
		var pressed_callable := Callable(self, "_on_next_round_pressed")
		if next_round_button.is_connected("pressed", pressed_callable):
			next_round_button.disconnect("pressed", pressed_callable)
		next_round_button.connect("pressed", pressed_callable)

func _on_next_round_pressed() -> void:
	if city_state and city_state.is_game_over():
		return
	var report := simulate_round()
	if grid_display:
		_grid_display_call("refresh_all")
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
	next_round_button.disabled = city_state != null and city_state.is_game_over()

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

func _shop_purchase_offer(index: int, manager: Node, origin: Vector2i) -> bool:
	if shop_manager and shop_manager.has_method("purchase_offer"):
		return bool(shop_manager.call("purchase_offer", index, manager, origin))
	return false

func _grid_display_call(method: StringName, args: Array = []) -> void:
	if grid_display and grid_display.has_method(method):
		grid_display.callv(method, args)

func _shop_display_call(method: StringName, args: Array = []) -> void:
	if shop_display and shop_display.has_method(method):
		shop_display.callv(method, args)

func _show_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print(message)














