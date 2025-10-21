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
@export var exit_button_path: NodePath
@export var victory_menu_path: NodePath
@export var victory_label_path: NodePath
@export var victory_restart_button_path: NodePath
@export var victory_endless_button_path: NodePath
@export var facility_info_panel_path: NodePath
@export var facility_info_title_path: NodePath
@export var facility_info_details_path: NodePath
@export var facility_info_sell_button_path: NodePath
@export var card_bar_path: NodePath
@export var card_data_path: String = "res://data/card_data.json"
@export var card_info_panel_path: NodePath
@export var card_info_title_path: NodePath
@export var card_info_details_path: NodePath

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
var next_round_button: BaseButton = null
var selected_offer_index: int = -1
var selected_preview_facility: Facility = null
var dragged_facility: Facility = null
var dragged_original_origin: Vector2i = Vector2i.ZERO
var start_menu: Control = null
var start_button: BaseButton = null
var hud_container: Control = null
var shop_panel: Control = null
var restart_button: Button = null
var exit_button: Button = null
var victory_menu: Control = null
var victory_label: Label = null
var victory_restart_button: Button = null
var victory_endless_button: Button = null
var facility_info_panel: PanelContainer = null
var facility_info_title: Label = null
var facility_info_details: RichTextLabel = null
var facility_info_sell_button: Button = null
var round_summary_animator: RoundSummaryAnimator = null
var hovered_facility: Facility = null
var hovered_sell_price: int = 0
var facility_info_hovered: bool = false
var hover_info_delay: float = 1.0
var hover_info_timer: Timer = null
var pending_hover_facility: Facility = null
var facility_info_hide_timer: Timer = null
var game_active: bool = false
var endless_mode: bool = false
var round_animation_active: bool = false
var card_bar: CardBar = null
var acquired_cards: Array[Dictionary] = []
var acquired_card_lookup: Dictionary = {}
var card_definitions: Dictionary = {}
var card_order: Array[String] = []
var next_green_discount: int = 0
var next_build_discount: int = 0
var pending_damage_reduction_once: int = 0
var card_info_panel: PanelContainer = null
var card_info_title: Label = null
var card_info_details: RichTextLabel = null
var card_hover_timer: Timer = null
var card_info_hide_timer: Timer = null
var pending_hover_card: Dictionary = {}
var pending_hover_card_source: Control = null
var card_info_hovered: bool = false
var card_info_target_control: Control = null
var tutorial_overlay: TutorialOverlay = null
var tutorial_shown: bool = false
var ui_layer: CanvasLayer = null
var base_resolution: Vector2 = Vector2(
	float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
	float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
)
const STATUS_COLOR_NORMAL := Color(1, 1, 1, 1)
const STATUS_COLOR_WARNING := Color(1, 0.33, 0.33, 1)
const STATUS_ICON_WARNING := "⚠️"
const VICTORY_ROUND_TARGET := 20
const FACILITY_INFO_HIDE_DELAY := 0.12
const GARDEN_CITY_IDS := [
	"rain_garden",
	"green_roof",
	"permeable_pavement",
	"bio_swale",
	"tree_trench",
	"infiltration_trench"
]
const CARD_ADJACENT_DIRECTIONS := [
	Vector2i.UP,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.RIGHT
]
const CARD_INFO_MARGIN := 12.0

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
	start_button = get_node_or_null(start_button_path) as BaseButton
	hud_container = get_node_or_null(hud_container_path) as Control
	shop_panel = get_node_or_null(shop_panel_path) as Control
	restart_button = get_node_or_null(restart_button_path) as Button
	exit_button = get_node_or_null(exit_button_path) as Button
	victory_menu = get_node_or_null(victory_menu_path) as Control
	victory_label = get_node_or_null(victory_label_path) as Label
	victory_restart_button = get_node_or_null(victory_restart_button_path) as Button
	victory_endless_button = get_node_or_null(victory_endless_button_path) as Button
	facility_info_panel = get_node_or_null(facility_info_panel_path) as PanelContainer
	facility_info_title = get_node_or_null(facility_info_title_path) as Label
	facility_info_details = get_node_or_null(facility_info_details_path) as RichTextLabel
	facility_info_sell_button = get_node_or_null(facility_info_sell_button_path) as Button
	card_bar = get_node_or_null(card_bar_path) as CardBar
	card_info_panel = get_node_or_null(card_info_panel_path) as PanelContainer
	card_info_title = get_node_or_null(card_info_title_path) as Label
	card_info_details = get_node_or_null(card_info_details_path) as RichTextLabel
	tutorial_overlay = get_node_or_null("UI/TutorialOverlay") as TutorialOverlay
	if tutorial_overlay:
		tutorial_overlay.visible = false
		if not tutorial_overlay.is_connected("tutorial_finished", Callable(self, "_on_tutorial_finished")):
			tutorial_overlay.connect("tutorial_finished", Callable(self, "_on_tutorial_finished"))
	if facility_info_panel:
		facility_info_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		facility_info_panel.connect("mouse_entered", Callable(self, "_on_facility_info_mouse_entered"))
		facility_info_panel.connect("mouse_exited", Callable(self, "_on_facility_info_mouse_exited"))
	if facility_info_sell_button:
		facility_info_sell_button.connect("pressed", Callable(self, "_on_facility_sell_pressed"))
	if card_info_panel:
		card_info_panel.anchor_left = 0.0
		card_info_panel.anchor_top = 0.0
		card_info_panel.anchor_right = 0.0
		card_info_panel.anchor_bottom = 0.0
		card_info_panel.offset_left = 0.0
		card_info_panel.offset_top = 0.0
		card_info_panel.offset_right = 0.0
		card_info_panel.offset_bottom = 0.0
		card_info_panel.mouse_filter = Control.MOUSE_FILTER_PASS
		card_info_panel.visible = false
		card_info_panel.z_index = 200
		card_info_panel.z_as_relative = false
		card_info_panel.connect("mouse_entered", Callable(self, "_on_card_info_mouse_entered"))
		card_info_panel.connect("mouse_exited", Callable(self, "_on_card_info_mouse_exited"))
	_bind_controls()

	facility_info_hide_timer = Timer.new()
	facility_info_hide_timer.one_shot = true
	facility_info_hide_timer.wait_time = FACILITY_INFO_HIDE_DELAY
	facility_info_hide_timer.connect("timeout", Callable(self, "_on_facility_info_hide_timeout"))
	add_child(facility_info_hide_timer)

	grid_display = get_node_or_null(grid_display_path) as GridDisplay
	if grid_display:
		_grid_display_call("set_grid_manager", [grid_manager])
		grid_display.connect("cell_clicked", Callable(self, "_on_grid_cell_clicked"))
		grid_display.connect("cell_hovered", Callable(self, "_on_grid_cell_hovered"))
		grid_display.connect("cell_hover_exited", Callable(self, "_on_grid_cell_hover_exited"))

	shop_display = get_node_or_null(shop_display_path) as ShopDisplay
	if shop_display:
		shop_display.connect("offer_selected", Callable(self, "_on_shop_offer_selected"))
		shop_display.connect("skip_selected", Callable(self, "_on_shop_skip_selected"))
		shop_display.connect("refresh_requested", Callable(self, "_on_shop_refresh_requested"))

	if card_bar:
		card_bar.connect("card_hovered", Callable(self, "_on_card_hovered"))
		card_bar.connect("card_hover_exited", Callable(self, "_on_card_hover_exited"))


	grid_manager.set_city_state(city_state)
	facility_library.load_from_json(facility_data_path)
	shop_manager.set_library(facility_library)
	shop_manager.set_city_state(city_state)
	localization.ensure_loaded(locale_files)
	ui_manager.set_city_state(city_state)

	if city_state and not city_state.is_connected("stats_changed", Callable(self, "_on_city_stats_changed")):
		city_state.connect("stats_changed", Callable(self, "_on_city_stats_changed"))

	grid_manager.connect("facility_placed", Callable(self, "_on_facility_placed"))
	grid_manager.connect("facility_removed", Callable(self, "_on_grid_facility_removed"))
	grid_manager.connect("facility_merged", Callable(self, "_on_grid_facility_merged"))
	grid_manager.connect("facility_moved", Callable(self, "_on_grid_facility_moved"))
	shop_manager.connect("facility_purchased", Callable(self, "_on_facility_purchased"))
	shop_manager.connect("offers_changed", Callable(self, "_on_offers_changed"))
	shop_manager.connect("purchase_failed", Callable(self, "_on_purchase_failed"))

	ui_layer = get_node_or_null("UI") as CanvasLayer
	if ui_layer and round_summary_animator == null:
		round_summary_animator = RoundSummaryAnimator.new()
		round_summary_animator.name = "RoundSummaryAnimator"
		ui_layer.add_child(round_summary_animator)
		if grid_display:
			round_summary_animator.set_grid_display(grid_display)

	hover_info_timer = Timer.new()
	hover_info_timer.one_shot = true
	add_child(hover_info_timer)
	hover_info_timer.connect("timeout", Callable(self, "_on_hover_info_timeout"))

	card_hover_timer = Timer.new()
	card_hover_timer.one_shot = true
	add_child(card_hover_timer)
	card_hover_timer.connect("timeout", Callable(self, "_on_card_hover_timeout"))

	card_info_hide_timer = Timer.new()
	card_info_hide_timer.one_shot = true
	card_info_hide_timer.wait_time = FACILITY_INFO_HIDE_DELAY
	add_child(card_info_hide_timer)
	card_info_hide_timer.connect("timeout", Callable(self, "_on_card_info_hide_timeout"))

	_update_ui_scale()
	var root_window: Window = get_tree().root
	if root_window and not root_window.is_connected("size_changed", Callable(self, "_on_window_size_changed")):
		root_window.connect("size_changed", Callable(self, "_on_window_size_changed"))

	_load_card_definitions()
	_reset_cards()
	_show_start_menu()

func start_new_game() -> void:
	_cancel_dragged_facility(false)
	_clear_selection_preview()
	_hide_facility_info()
	selected_offer_index = -1
	endless_mode = false
	game_active = true
	_reset_cards()
	_hide_start_menu()
	_hide_victory_menu()
	city_state.reset()
	grid_manager.clear()
	if round_summary_animator:
		round_summary_animator.reset()
		round_animation_active = false
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
	var forecast_range := _update_forecast()
	if ui_manager:
		ui_manager.show_rain_report({})
	_show_status("A new city rises. Rain forecast: %s. Select a facility to begin building." % _format_forecast_range(forecast_range))
	_update_button_state()
	_evaluate_card_unlocks()
	if tutorial_overlay and not tutorial_shown:
		var steps := _build_tutorial_steps()
		if not steps.is_empty():
			tutorial_shown = true
			tutorial_overlay.call_deferred("start", steps)

func simulate_round() -> Dictionary:
	var report: Dictionary = rain_system.simulate_round(city_state)
	ui_manager.show_rain_report(report)
	var card_effects := _apply_card_post_rain(report)
	var income := city_state.add_income()
	report["income"] = income
	var bonus_income := int(card_effects.get("income_bonus", 0))
	if bonus_income > 0:
		city_state.add_money(bonus_income)
	report["card_bonus"] = bonus_income
	if card_effects.has("health_restored") and card_effects["health_restored"] > 0:
		report["card_health_restore"] = card_effects["health_restored"]
	if card_effects.has("damage_delta"):
		report["card_damage_delta"] = card_effects["damage_delta"]
	if card_effects.has("damage_after"):
		report["damage"] = card_effects["damage_after"]
	city_state.advance_round()
	return report

func _prepare_facility_for_purchase(facility: Facility) -> Dictionary:
	var info := {
		"original_cost": 0,
		"green_discount_used": 0,
		"build_discount_used": 0
	}
	if facility == null:
		return info
	var cost := facility.cost
	info["original_cost"] = cost
	if _facility_has_tag(facility, "green") and next_green_discount > 0:
		var use := int(min(next_green_discount, cost))
		cost = max(cost - use, 0)
		info["green_discount_used"] = use
	if next_build_discount > 0:
		var use_general := int(min(next_build_discount, cost))
		cost = max(cost - use_general, 0)
		info["build_discount_used"] = use_general
	facility.cost = cost
	return info

func _commit_purchase_discounts(discount_info: Dictionary) -> void:
	var green_used := int(discount_info.get("green_discount_used", 0))
	if green_used > 0:
		next_green_discount = max(0, next_green_discount - green_used)
	var build_used := int(discount_info.get("build_discount_used", 0))
	if build_used > 0:
		next_build_discount = max(0, next_build_discount - build_used)

func _revert_facility_cost(facility: Facility, discount_info: Dictionary) -> void:
	if facility == null:
		return
	if discount_info.has("original_cost"):
		facility.cost = int(discount_info["original_cost"])

func attempt_purchase(index: int, origin: Vector2i) -> bool:
	if _is_dragging():
		_show_status("Finish relocating the current facility before placing new builds.")
		return false
	if not shop_manager:
		return false
	var discount_info: Dictionary = {}
	if selected_preview_facility:
		discount_info = _prepare_facility_for_purchase(selected_preview_facility)
	var success := _shop_purchase_offer(index, grid_manager, origin, selected_preview_facility)
	if success:
		_commit_purchase_discounts(discount_info)
	else:
		if selected_preview_facility:
			_revert_facility_cost(selected_preview_facility, discount_info)
	return success

func save_game() -> bool:
	if _is_dragging():
		_show_status("Place the facility you're moving before saving.")
		return false
	if not save_manager:
		return false
	var success := save_manager.save_game(city_state, grid_manager, _get_card_state_snapshot())
	if success:
		_show_status("Game saved.")
	return success

func load_game() -> bool:
	_cancel_dragged_facility(true)
	_clear_selection_preview()
	_hide_facility_info()
	if not save_manager:
		return false
	var loaded := save_manager.load_game(city_state, grid_manager, facility_library)
	if loaded:
		if round_summary_animator:
			round_summary_animator.reset()
			round_animation_active = false
		if grid_display:
			_grid_display_call("refresh_all")
		_apply_card_state(save_manager.get_last_card_state())
		var forecast_range := _update_forecast()
		if ui_manager:
			ui_manager.show_rain_report({})
		_show_status("Save loaded. Rain forecast: %s. Continue defending the city." % _format_forecast_range(forecast_range))
		_evaluate_card_unlocks()
	_update_button_state()
	return loaded

func _on_facility_placed(_facility, _origin: Vector2i) -> void:
	if grid_display:
		_grid_display_call("refresh_all")
	_evaluate_card_unlocks()

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
	_show_warning(message)

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

func _cancel_hover_schedule() -> void:
	if hover_info_timer:
		hover_info_timer.stop()
	pending_hover_facility = null
	if facility_info_hide_timer:
		facility_info_hide_timer.stop()

func _schedule_facility_info(facility: Facility) -> void:
	_cancel_hover_schedule()
	if round_animation_active:
		return
	if facility == null:
		_hide_facility_info()
		return
	if hovered_facility == facility and facility_info_panel and facility_info_panel.visible:
		return
	if hovered_facility != null and hovered_facility != facility:
		_hide_facility_info()
	pending_hover_facility = facility
	if hover_info_delay <= 0.0:
		_show_facility_info(facility)
		return
	if hover_info_timer:
		hover_info_timer.start(hover_info_delay)

func _on_hover_info_timeout() -> void:
	var facility := pending_hover_facility
	pending_hover_facility = null
	if facility == null:
		return
	if grid_manager == null:
		return
	_show_facility_info(facility)

func _on_grid_cell_clicked(position: Vector2i) -> void:
	if not game_active:
		return
	if round_animation_active:
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

func _on_grid_cell_hovered(position: Vector2i) -> void:
	if not game_active:
		return
	if grid_manager == null:
		return
	var facility := grid_manager.get_facility_at(position)
	_schedule_facility_info(facility)

func _on_grid_cell_hover_exited(_position: Vector2i) -> void:
	_cancel_hover_schedule()
	if hovered_facility == null:
		return
	if grid_manager == null:
		_hide_facility_info()
		return
	if facility_info_hovered:
		return
	if facility_info_panel and facility_info_panel.visible:
		var panel_rect := facility_info_panel.get_global_rect()
		if panel_rect.has_point(get_viewport().get_mouse_position()):
			return
	if facility_info_hide_timer:
		facility_info_hide_timer.start()

func _show_facility_info(facility: Facility) -> void:
	if facility == null:
		return
	hovered_facility = facility
	hovered_sell_price = _calculate_sell_price(facility)
	_position_facility_info(facility)
	var dots := facility.get_type_dots()
	var prefix := "%s " % dots if not dots.is_empty() else ""
	if facility_info_panel:
		facility_info_panel.visible = true
	if facility_info_title:
		facility_info_title.text = "%s%s (Lv %d)" % [prefix, facility.name, facility.level]
	if facility_info_details:
		var lines: Array[String] = []
		if facility.description != "":
			lines.append(facility.description)
			lines.append("")
		lines.append("[b]Resilience:[/b] %d" % facility.resilience)
		lines.append("[b]Level:[/b] %d" % facility.level)
		facility_info_details.bbcode_text = "\n".join(lines)
	if facility_info_sell_button:
		facility_info_sell_button.text = "Sell (💰%d)" % hovered_sell_price
		facility_info_sell_button.disabled = hovered_sell_price <= 0

func _hide_facility_info() -> void:
	_cancel_hover_schedule()
	hovered_facility = null
	hovered_sell_price = 0
	facility_info_hovered = false
	if facility_info_hide_timer:
		facility_info_hide_timer.stop()
	if facility_info_panel:
		facility_info_panel.visible = false

func _on_facility_info_mouse_entered() -> void:
	facility_info_hovered = true
	if facility_info_hide_timer:
		facility_info_hide_timer.stop()

func _on_facility_info_mouse_exited() -> void:
	facility_info_hovered = false
	if facility_info_panel and facility_info_panel.visible:
		var panel_rect := facility_info_panel.get_global_rect()
		if panel_rect.has_point(get_viewport().get_mouse_position()):
			return
	if hovered_facility != null and facility_info_hide_timer:
		facility_info_hide_timer.start()

func _on_facility_info_hide_timeout() -> void:
	if facility_info_hovered:
		return
	_hide_facility_info()

func _position_facility_info(facility: Facility) -> void:
	if facility_info_panel == null:
		return
	if grid_manager == null or grid_display == null:
		return
	var cells := grid_manager.get_facility_cells(facility)
	if cells.is_empty():
		cells.append(grid_manager.get_facility_origin(facility))
	var center := Vector2.ZERO
	for pos in cells:
		center += grid_display.get_cell_center(pos)
	center /= max(1, cells.size())
	var panel_size := facility_info_panel.size
	if panel_size == Vector2.ZERO:
		panel_size = facility_info_panel.get_combined_minimum_size()
	var offset := Vector2(panel_size.x * 0.5, panel_size.y + 12)
	var target := center - offset
	var viewport_rect := get_viewport().get_visible_rect()
	var viewport_size := Vector2(viewport_rect.size.x, viewport_rect.size.y)
	var clamped := Vector2(
		clamp(target.x, 8.0, viewport_size.x - panel_size.x - 8.0),
		clamp(target.y, 8.0, viewport_size.y - panel_size.y - 8.0)
	)
	facility_info_panel.global_position = clamped

func _calculate_sell_price(facility: Facility) -> int:
	if facility == null:
		return 0
	return max(1, int(round(facility.cost * 0.6)))

func _on_facility_sell_pressed() -> void:
	if not game_active:
		return
	if hovered_facility == null:
		return
	var facility := hovered_facility
	var sell_price := hovered_sell_price
	if sell_price <= 0:
		return
	if grid_manager:
		grid_manager.remove_facility(facility)
	if city_state:
		city_state.add_money(sell_price)
	_hide_facility_info()
	if grid_display:
		_grid_display_call("refresh_all")
	_show_status("Sold %s (Lv %d) for %d funds." % [facility.name, facility.level, sell_price])

func _on_grid_facility_removed(facility: Facility) -> void:
	if facility == hovered_facility:
		_hide_facility_info()
	_evaluate_card_unlocks()

func _on_grid_facility_moved(facility: Facility, _new_origin: Vector2i, _previous_origin: Vector2i) -> void:
	if facility == hovered_facility:
		_position_facility_info(facility)
	_evaluate_card_unlocks()

func _on_grid_facility_merged(facility: Facility, absorbed: Facility) -> void:
	if hovered_facility == absorbed:
		_hide_facility_info()
	elif hovered_facility == facility:
		_position_facility_info(facility)
	_evaluate_card_unlocks()

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
	var rotating_drag := _is_dragging()
	if selected_preview_facility == null:
		return
	if grid_display:
		var rect := grid_display.get_global_rect()
		if not rect.has_point(mouse_event.position):
			return
	var clockwise := not mouse_event.shift_pressed
	_rotate_preview(clockwise)
	if rotating_drag:
		dragged_facility = selected_preview_facility
	get_viewport().set_input_as_handled()

func _bind_controls() -> void:
	if not next_round_button_path.is_empty():
		next_round_button = get_node_or_null(next_round_button_path) as BaseButton
	if next_round_button:
		var pressed_callable := Callable(self, "_on_next_round_pressed")
		if next_round_button.is_connected("pressed", pressed_callable):
			next_round_button.disconnect("pressed", pressed_callable)
		next_round_button.connect("pressed", pressed_callable)

	_connect_button(start_button, "_on_start_pressed")
	_connect_button(restart_button, "_on_restart_pressed")
	_connect_button(exit_button, "_on_exit_pressed")
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
	if round_animation_active:
		return
	var report := simulate_round()
	if grid_display:
		_grid_display_call("refresh_all")
	if round_summary_animator:
		round_animation_active = true
		_update_button_state()
		await round_summary_animator.play_round_report(city_state.facilities.duplicate(), grid_manager, grid_display, report)
		round_animation_active = false
		_update_button_state()
	if not endless_mode and city_state.round_number > VICTORY_ROUND_TARGET:
		_handle_victory(report)
		return
	_update_forecast()
	var intensity := int(report.get("intensity", 0))
	var resilience_value := int(report.get("resilience", 0))
	var damage := int(report.get("damage", 0))
	var income := int(report.get("income", 0))
	var card_bonus := int(report.get("card_bonus", 0))
	var message := "Rain %d vs Resilience %d → Damage %d. Earned 💰%d." % [intensity, resilience_value, damage, income]
	if card_bonus > 0:
		message += " Card bonus 💰%d." % card_bonus
	var damage_delta := int(report.get("card_damage_delta", 0))
	if damage_delta > 0:
		message += " Cards prevented %d damage." % damage_delta
	elif damage_delta < 0:
		message += " Card penalty %+d damage." % damage_delta
	var health_gain := int(report.get("card_health_restore", 0))
	if health_gain > 0:
		message += " Cards restored ❤️%d." % health_gain
	_show_status(message)
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
	if round_animation_active:
		disabled = true
	next_round_button.disabled = disabled

func _format_forecast_range(forecast_range: Dictionary) -> String:
	var min_value := int(forecast_range.get("min", 0))
	var max_value := int(forecast_range.get("max", 0))
	if min_value == 0 and max_value == 0:
		return "?"
	return "%d - %d" % [min_value, max_value]

func _update_forecast() -> Dictionary:
	if rain_system == null or city_state == null:
		return {}
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
	_hide_facility_info()
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
	if card_bar:
		card_bar.visible = false
	_hide_card_info()
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
	if card_bar:
		card_bar.visible = true
	_hide_card_info()
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
	_hide_facility_info()
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

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_victory_endless_pressed() -> void:
	endless_mode = true
	game_active = true
	_hide_victory_menu()
	var forecast_range := _update_forecast()
	_show_status("Endless mode engaged. Rain forecast: %s." % _format_forecast_range(forecast_range))
	_update_button_state()

func _connect_button(button: BaseButton, method_name: String) -> void:
	if button == null:
		return
	var callable := Callable(self, method_name)
	if button.is_connected("pressed", callable):
		button.disconnect("pressed", callable)
	button.connect("pressed", callable)

func _is_dragging() -> bool:
	return dragged_facility != null

func _rotation_hint() -> String:
	return "Right-click to rotate."

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
	return "Selected %s for %d funds. Right-click to rotate. Stack identical facilities to upgrade. Click a grid tile to place." % [facility.name, facility.cost]

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
	if _is_dragging() and dragged_facility == selected_preview_facility:
		_show_status("Adjusted %s orientation. Choose a new tile for its top-left corner." % selected_preview_facility.name)
	else:
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
	_cancel_hover_schedule()
	_hide_facility_info()
	dragged_facility = facility
	dragged_original_origin = grid_manager.get_facility_origin(facility)
	grid_manager.remove_facility(facility)
	if grid_display:
		_grid_display_call("set_preview_facility", [facility])
	selected_preview_facility = facility
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
	selected_preview_facility = null
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
	selected_preview_facility = null
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
		_set_status_text(message, STATUS_COLOR_NORMAL)
	print(message)

func _show_warning(message: String) -> void:
	var formatted := "%s %s" % [STATUS_ICON_WARNING, _maybe_append_rotation_hint(message)]
	if status_label:
		_set_status_text(formatted, STATUS_COLOR_WARNING)
	print(formatted)

func _set_status_text(text: String, color: Color) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

func _build_tutorial_steps() -> Array:
	var steps: Array = []
	_append_tutorial_step(steps, "UI/HUD/StatsContainer", "Keep an eye on rounds, health, funds, and resilience here.", 20.0)
	_append_tutorial_step(steps, "UI/HUD/RainPanel", "Upcoming rainfall is shown here so you can prepare.", 18.0)
	_append_tutorial_step(steps, "UI/ShopPanel", "Buy new facilities from the shop to expand your city.", 18.0)
	_append_tutorial_step(steps, "UI/CardBar", "Unlocked cards and their bonuses appear here.", 18.0)
	_append_tutorial_step(steps, "UI/GridDisplay", "Place facilities on the grid to build storm resilience.", 24.0)
	_append_tutorial_step(steps, "UI/HUD/NextRoundButton", "Advance to the next round once you are ready.", 18.0)
	return steps

func _append_tutorial_step(steps: Array, path: String, message: String, padding: float = 16.0) -> void:
	var node := get_node_or_null(path)
	if node == null or not (node is Control):
		return
	steps.append({
		"target": node,
		"message": message,
		"padding": padding
	})

func _on_tutorial_finished() -> void:
	# Tutorial ended; ensure future games skip the guided overlay.
	pass

func _reset_cards() -> void:
	acquired_cards.clear()
	acquired_card_lookup.clear()
	next_green_discount = 0
	next_build_discount = 0
	pending_damage_reduction_once = 0
	_hover_cancel_card_schedule()
	_hide_card_info()
	_refresh_card_bar()

func _refresh_card_bar() -> void:
	if card_bar == null:
		return
	var display_cards: Array = []
	for card_info in acquired_cards:
		var entry := {
			"id": card_info.get("id", ""),
			"name": card_info.get("name", "Card"),
			"description": card_info.get("description", "")
		}
		display_cards.append(entry)
	card_bar.show_cards(display_cards)

func _hover_cancel_card_schedule() -> void:
	if card_hover_timer:
		card_hover_timer.stop()
	if card_info_hide_timer:
		card_info_hide_timer.stop()
	pending_hover_card = {}
	pending_hover_card_source = null
	card_info_hovered = false

func _show_card_info(card_info: Dictionary, source: Control = null) -> void:
	if card_info_panel == null:
		return
	if source != null:
		card_info_target_control = source
	elif card_info_target_control == null and pending_hover_card_source != null:
		card_info_target_control = pending_hover_card_source
	var title := String(card_info.get("name", "Card"))
	var description := String(card_info.get("description", ""))
	if description.is_empty():
		description = "[i]No details available yet.[/i]"
	if card_info_title:
		card_info_title.text = title
	if card_info_details:
		card_info_details.bbcode_text = description
	card_info_panel.visible = true
	card_info_panel.reset_size()
	_position_card_info(card_info_target_control)
	card_info_hovered = false

func _hide_card_info() -> void:
	if card_info_panel:
		card_info_panel.visible = false
	card_info_hovered = false
	card_info_target_control = null
	pending_hover_card_source = null

func _on_card_hovered(card_info: Dictionary, card_widget: Control) -> void:
	if card_info.is_empty():
		return
	pending_hover_card = card_info.duplicate(true)
	pending_hover_card_source = card_widget
	if card_info_hide_timer:
		card_info_hide_timer.stop()
	if card_hover_timer:
		card_hover_timer.stop()
	if hover_info_delay <= 0.0:
		_show_card_info(pending_hover_card, pending_hover_card_source)
	else:
		card_hover_timer.start(hover_info_delay)

func _on_card_hover_exited(_card_info: Dictionary, card_widget: Control) -> void:
	pending_hover_card = {}
	if pending_hover_card_source == card_widget:
		pending_hover_card_source = null
	if card_hover_timer:
		card_hover_timer.stop()
	if card_info_panel and card_info_panel.visible:
		if card_info_hide_timer:
			card_info_hide_timer.start(FACILITY_INFO_HIDE_DELAY)

func _on_card_hover_timeout() -> void:
	if pending_hover_card.is_empty():
		return
	_show_card_info(pending_hover_card, pending_hover_card_source)
	pending_hover_card = {}
	pending_hover_card_source = null

func _on_card_info_mouse_entered() -> void:
	card_info_hovered = true
	if card_info_hide_timer:
		card_info_hide_timer.stop()

func _on_card_info_mouse_exited() -> void:
	card_info_hovered = false
	if card_info_panel and card_info_panel.visible:
		var panel_rect := card_info_panel.get_global_rect()
		if panel_rect.has_point(get_viewport().get_mouse_position()):
			return
	if card_info_hide_timer:
		card_info_hide_timer.start(FACILITY_INFO_HIDE_DELAY)

func _on_card_info_hide_timeout() -> void:
	if card_info_hovered:
		return
	_hide_card_info()

func _position_card_info(source: Control) -> void:
	if card_info_panel == null:
		return
	if source != null and not is_instance_valid(source):
		source = null
	var viewport := get_viewport()
	var viewport_rect := viewport.get_visible_rect()
	var panel_size := card_info_panel.size
	if panel_size == Vector2.ZERO:
		panel_size = card_info_panel.get_combined_minimum_size()
	var desired_pos := viewport.get_mouse_position() + Vector2(CARD_INFO_MARGIN, CARD_INFO_MARGIN)
	if source != null:
		var card_rect := source.get_global_rect()
		desired_pos = card_rect.position + Vector2(card_rect.size.x + CARD_INFO_MARGIN, 0.0)
		if desired_pos.x + panel_size.x > viewport_rect.size.x - CARD_INFO_MARGIN:
			desired_pos.x = card_rect.position.x - panel_size.x - CARD_INFO_MARGIN
	var max_x := viewport_rect.size.x - panel_size.x - CARD_INFO_MARGIN
	var max_y := viewport_rect.size.y - panel_size.y - CARD_INFO_MARGIN
	if max_x < CARD_INFO_MARGIN:
		max_x = CARD_INFO_MARGIN
	if max_y < CARD_INFO_MARGIN:
		max_y = CARD_INFO_MARGIN
	desired_pos.x = clampf(desired_pos.x, CARD_INFO_MARGIN, max_x)
	desired_pos.y = clampf(desired_pos.y, CARD_INFO_MARGIN, max_y)
	card_info_panel.global_position = desired_pos

func _on_window_size_changed() -> void:
	_update_ui_scale()

func _update_ui_scale() -> void:
	if ui_layer == null:
		return
	var viewport := get_viewport()
	var viewport_rect: Rect2 = viewport.get_visible_rect()
	var viewport_size: Vector2 = viewport_rect.size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	if base_resolution.x <= 0 or base_resolution.y <= 0:
		base_resolution = viewport_size
	var scale_factor: float = min(viewport_size.x / base_resolution.x, viewport_size.y / base_resolution.y)
	if scale_factor <= 0:
		scale_factor = 1.0
	var scaled_size: Vector2 = base_resolution * scale_factor
	var transform := Transform2D.IDENTITY
	transform.x = Vector2(scale_factor, 0.0)
	transform.y = Vector2(0.0, scale_factor)
	var offset := Vector2.ZERO
	if scale_factor != 0.0:
		offset = (viewport_size - scaled_size) * 0.5 / scale_factor
	transform.origin = offset
	viewport.canvas_transform = transform
	ui_layer.offset = Vector2.ZERO

func _has_card(card_id: String) -> bool:
	return acquired_card_lookup.has(card_id)

func _unlock_card(card_id: String) -> void:
	if acquired_card_lookup.has(card_id):
		return
	var definition: Dictionary = card_definitions.get(card_id, {})
	if definition.is_empty():
		push_warning("Unknown card id: %s" % card_id)
		return
	var card_info := _create_card_info(definition)
	acquired_cards.append(card_info)
	acquired_card_lookup[card_id] = card_info
	_apply_card_on_unlock(card_id, card_info)
	_refresh_card_bar()
	_show_status("Unlocked card: %s!" % card_info.get("name", card_id))

func _evaluate_card_unlocks() -> void:
	for card_id in card_order:
		if _has_card(card_id):
			continue
		if _check_card_condition(card_id):
			_unlock_card(card_id)

func _has_three_unique_green_facilities() -> bool:
	if city_state == null:
		return false
	var unique_green_ids: Dictionary = {}
	for facility in city_state.facilities:
		var cast_facility := facility as Facility
		if cast_facility == null:
			continue
		if not GARDEN_CITY_IDS.has(cast_facility.id):
			continue
		unique_green_ids[cast_facility.id] = true
		if unique_green_ids.size() >= 3:
			return true
	return false

func _create_card_info(definition: Dictionary) -> Dictionary:
	var card_name := String(definition.get("name", definition.get("id", "")))
	var effect_summary := String(definition.get("effect_summary", definition.get("description", "")))
	var condition_summary := String(definition.get("condition_summary", ""))
	var description := effect_summary.strip_edges()
	var trimmed_condition := condition_summary.strip_edges()
	if description.is_empty():
		description = trimmed_condition
	elif not trimmed_condition.is_empty():
		description = "%s\n%s" % [description, trimmed_condition]
	return {
		"id": String(definition.get("id", "")),
		"name": card_name,
		"description": description.strip_edges(),
		"_meta": {}
	}

func _apply_card_on_unlock(card_id: String, card_info: Dictionary) -> void:
	var metadata_variant: Variant = card_info.get("_meta", {})
	var metadata: Dictionary = {}
	if typeof(metadata_variant) == TYPE_DICTIONARY:
		metadata = metadata_variant
	match card_id:
		"sponge_block":
			next_green_discount += 1
			metadata["green_discount_applied"] = true
		"circular_city":
			next_build_discount += 1
			metadata["build_discount_applied"] = true
		"eco_drain_chain":
			pending_damage_reduction_once += 3
			metadata["pending_reduction_granted"] = true
		_:
			pass
	card_info["_meta"] = metadata

func _load_card_definitions() -> void:
	card_definitions.clear()
	card_order.clear()
	if card_data_path.is_empty():
		return
	if not FileAccess.file_exists(card_data_path):
		push_warning("Card data not found: %s" % card_data_path)
		return
	var file: FileAccess = FileAccess.open(card_data_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open card data: %s" % card_data_path)
		return
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_ARRAY:
		push_warning("Card data must be an array: %s" % card_data_path)
		return
	for entry in parsed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_dict: Dictionary = entry as Dictionary
		var id := String(entry_dict.get("id", ""))
		if id.is_empty():
			continue
		card_definitions[id] = entry_dict.duplicate(true)
		if not card_order.has(id):
			card_order.append(id)

func _check_card_condition(card_id: String) -> bool:
	if city_state == null or grid_manager == null:
		return false
	match card_id:
		"garden_city":
			return _has_three_unique_green_facilities()
		"eco_network":
			return _has_adjacent_green_pair()
		"urban_canopy":
			return _facility_exists("tree_trench") and _facility_exists("green_roof")
		"sponge_block":
			return _facility_exists("permeable_pavement") and _facility_exists("rain_garden") and _facility_exists("infiltration_trench")
		"storm_defense_network":
			return _facilities_adjacent_by_ids("flood_wall", "pump_station")
		"urban_hardscape":
			return _check_urban_hardscape_condition()
		"blue_corridor":
			return _check_blue_corridor_condition()
		"living_water_system":
			return _count_facilities_with_tag("blue") >= 2
		"sponge_city":
			return _check_sponge_city_condition()
		"eco_drain_chain":
			return _check_eco_drain_chain_condition()
		"resilient_metropolis":
			return _count_facilities_with_tag("green") >= 2 and _count_facilities_with_tag("grey") >= 2 and _count_facilities_with_tag("blue") >= 2
		"circular_city":
			return _count_facilities_with_tag("green") >= 1 and _count_facilities_with_tag("grey") >= 1 and _count_facilities_with_tag("blue") >= 1 and city_state.money >= 5.0
		"adaptive_basin_system":
			return _check_adaptive_basin_condition()
		_:
			return false

func _facility_exists(facility_id: String) -> bool:
	if city_state == null:
		return false
	for facility in city_state.facilities:
		if facility == null:
			continue
		if facility.id == facility_id:
			return true
	return false

func _get_facilities_by_id(facility_id: String) -> Array[Facility]:
	var result: Array[Facility] = []
	if city_state == null:
		return result
	for facility in city_state.facilities:
		var cast_facility := facility as Facility
		if cast_facility == null:
			continue
		if cast_facility.id == facility_id:
			result.append(cast_facility)
	return result

func _facility_has_tag(facility: Facility, tag: String) -> bool:
	if facility == null:
		return false
	if facility.type == tag:
		return true
	for existing in facility.get_type_tags():
		if existing == tag:
			return true
	return false

func _count_facilities_with_tag(tag: String) -> int:
	if city_state == null:
		return 0
	var count := 0
	for facility in city_state.facilities:
		var cast_facility := facility as Facility
		if cast_facility == null:
			continue
		if _facility_has_tag(cast_facility, tag):
			count += 1
	return count

func _count_total_facilities() -> int:
	if city_state == null:
		return 0
	return city_state.facilities.size()

func _has_adjacent_green_pair() -> bool:
	if city_state == null or grid_manager == null:
		return false
	var greens: Array[Facility] = []
	for facility in city_state.facilities:
		var cast_facility := facility as Facility
		if cast_facility == null:
			continue
		if _facility_has_tag(cast_facility, "green"):
			greens.append(cast_facility)
	var total := greens.size()
	for i in range(total):
		for j in range(i + 1, total):
			if _facilities_adjacent(greens[i], greens[j]):
				return true
	return false

func _facilities_adjacent_by_ids(id_a: String, id_b: String) -> bool:
	var list_a := _get_facilities_by_id(id_a)
	var list_b := _get_facilities_by_id(id_b)
	if list_a.is_empty() or list_b.is_empty():
		return false
	for facility_a in list_a:
		for facility_b in list_b:
			if facility_a == facility_b:
				continue
			if _facilities_adjacent(facility_a, facility_b):
				return true
	return false

func _facilities_adjacent(a: Facility, b: Facility) -> bool:
	if grid_manager == null or a == null or b == null:
		return false
	var cells := grid_manager.get_facility_cells(a)
	for cell in cells:
		for dir in CARD_ADJACENT_DIRECTIONS:
			var neighbor := grid_manager.get_facility_at(cell + dir)
			if neighbor == b:
				return true
	return false

func _facility_adjacent_to_any(source: Facility, targets: Array) -> bool:
	for candidate in targets:
		if candidate == null or candidate == source:
			continue
		if _facilities_adjacent(source, candidate):
			return true
	return false

func _check_blue_corridor_condition() -> bool:
	if not (_facility_exists("retention_pond") and _facility_exists("detention_basin") and _facility_exists("constructed_wetland")):
		return false
	var wetlands := _get_facilities_by_id("constructed_wetland")
	var ponds := _get_facilities_by_id("retention_pond")
	var basins := _get_facilities_by_id("detention_basin")
	for wet in wetlands:
		if _facility_adjacent_to_any(wet, ponds) and _facility_adjacent_to_any(wet, basins):
			return true
	return false

func _check_sponge_city_condition() -> bool:
	if not _facility_exists("constructed_wetland"):
		return false
	var wetlands := _get_facilities_by_id("constructed_wetland")
	var greens: Array[Facility] = []
	for facility in city_state.facilities:
		var cast_facility := facility as Facility
		if cast_facility == null or cast_facility.id == "constructed_wetland":
			continue
		if _facility_has_tag(cast_facility, "green"):
			greens.append(cast_facility)
	if greens.is_empty():
		return false
	for wet in wetlands:
		if _facility_adjacent_to_any(wet, greens):
			return true
	return false

func _check_eco_drain_chain_condition() -> bool:
	if not (_facility_exists("bio_swale") and _facility_exists("infiltration_trench") and _facility_exists("detention_basin")):
		return false
	var trenches := _get_facilities_by_id("infiltration_trench")
	var bios := _get_facilities_by_id("bio_swale")
	var basins := _get_facilities_by_id("detention_basin")
	for trench in trenches:
		if _facility_adjacent_to_any(trench, bios) and _facility_adjacent_to_any(trench, basins):
			return true
	return false

func _check_adaptive_basin_condition() -> bool:
	if not (_facility_exists("retention_pond") and _facility_exists("flood_wall") and _facility_exists("pump_station")):
		return false
	var pumps := _get_facilities_by_id("pump_station")
	var ponds := _get_facilities_by_id("retention_pond")
	var walls := _get_facilities_by_id("flood_wall")
	for pump in pumps:
		if _facility_adjacent_to_any(pump, ponds) and _facility_adjacent_to_any(pump, walls):
			return true
	return false

func _check_urban_hardscape_condition() -> bool:
	var total := _count_total_facilities()
	if total <= 0:
		return false
	var grey := _count_facilities_with_tag("grey")
	return grey * 2 >= total

func _get_card_state_snapshot() -> Dictionary:
	var unlocked: Array[String] = []
	var metadata: Dictionary = {}
	for card_info in acquired_cards:
		var card_id := String(card_info.get("id", ""))
		if card_id.is_empty():
			continue
		unlocked.append(card_id)
		var stored_meta_variant: Variant = card_info.get("_meta", {})
		if typeof(stored_meta_variant) == TYPE_DICTIONARY:
			var stored_meta: Dictionary = stored_meta_variant
			metadata[card_id] = stored_meta.duplicate(true)
	return {
		"unlocked": unlocked,
		"next_green_discount": next_green_discount,
		"next_build_discount": next_build_discount,
		"pending_damage_reduction_once": pending_damage_reduction_once,
		"metadata": metadata
	}

func _apply_card_state(state: Dictionary) -> void:
	_reset_cards()
	var unlocked_variant: Variant = state.get("unlocked", [])
	var metadata_variant: Variant = state.get("metadata", {})
	var metadata: Dictionary = {}
	if typeof(metadata_variant) == TYPE_DICTIONARY:
		metadata = (metadata_variant as Dictionary).duplicate(true)
	var unlocked_array: Array = []
	if typeof(unlocked_variant) == TYPE_ARRAY:
		unlocked_array = (unlocked_variant as Array).duplicate()
	for entry_variant in unlocked_array:
		var card_id := String(entry_variant)
		if card_id.is_empty():
			continue
		var definition: Dictionary = card_definitions.get(card_id, {})
		if definition.is_empty():
			continue
		var card_info := _create_card_info(definition)
		var stored_meta_variant: Variant = metadata.get(card_id, {})
		if typeof(stored_meta_variant) == TYPE_DICTIONARY:
			var stored_meta: Dictionary = stored_meta_variant
			card_info["_meta"] = stored_meta.duplicate(true)
		acquired_cards.append(card_info)
		acquired_card_lookup[card_id] = card_info
	next_green_discount = int(state.get("next_green_discount", 0))
	next_build_discount = int(state.get("next_build_discount", 0))
	pending_damage_reduction_once = int(state.get("pending_damage_reduction_once", 0))
	_refresh_card_bar()

func _apply_card_post_rain(report: Dictionary) -> Dictionary:
	var damage_before := int(report.get("damage", 0))
	var damage_multiplier := 1.0
	var damage_reduction := 0
	var damage_penalty := 0
	var income_bonus := 0
	var health_restore := 0
	var stats_changed := false
	if pending_damage_reduction_once > 0:
		damage_reduction += pending_damage_reduction_once
		pending_damage_reduction_once = 0
	for card_info in acquired_cards:
		var card_id := String(card_info.get("id", ""))
		match card_id:
			"garden_city":
				income_bonus += 3
			"eco_network":
				damage_reduction += 1
			"urban_canopy":
				income_bonus += 2
			"sponge_block":
				damage_reduction += 2
			"storm_defense_network":
				damage_multiplier *= 0.5
			"urban_hardscape":
				income_bonus += 2
				damage_penalty += 1
			"blue_corridor":
				damage_reduction += 2
				health_restore += 1
			"living_water_system":
				health_restore += 1
			"sponge_city":
				damage_reduction += 2
				income_bonus += 1
			"resilient_metropolis":
				income_bonus += 5
				damage_reduction += 1
			"adaptive_basin_system":
				damage_reduction += 3
			_:
				pass
	var damage_after := damage_before
	damage_after = int(round(float(damage_after) * damage_multiplier))
	if damage_after < 0:
		damage_after = 0
	damage_after = max(damage_after - damage_reduction, 0)
	damage_after = max(damage_after + damage_penalty, 0)
	var damage_delta := damage_before - damage_after
	if damage_delta != 0:
		if damage_delta > 0:
			var heal := damage_delta
			var previous_health := city_state.health
			city_state.health = min(city_state.max_health, city_state.health + heal)
			if city_state.health != previous_health:
				stats_changed = true
		else:
			var extra := -damage_delta
			var prev_health := city_state.health
			city_state.health = max(0, city_state.health - extra)
			if city_state.health != prev_health:
				stats_changed = true
	var actual_health_restore := 0
	if health_restore > 0:
		var before_health := city_state.health
		city_state.health = min(city_state.max_health, city_state.health + health_restore)
		actual_health_restore = city_state.health - before_health
		if actual_health_restore > 0:
			stats_changed = true
	city_state.last_damage = damage_after
	if stats_changed:
		city_state.emit_signal("stats_changed")
	return {
		"income_bonus": income_bonus,
		"health_restored": actual_health_restore,
		"damage_delta": damage_delta,
		"damage_after": damage_after
	}
