# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name Main
extends Node

const CityState = preload("res://scripts/city_state.gd")
const GridManager = preload("res://scripts/grid_manager.gd")
const FacilityLibrary = preload("res://scripts/facility_library.gd")
const RainSystem = preload("res://scripts/rain_system.gd")
const ShopManager = preload("res://scripts/shop_manager.gd")
const LocalizationManager = preload("res://scripts/localization.gd")
const UIManager = preload("res://scripts/ui_manager.gd")
const SaveManager = preload("res://scripts/save_manager.gd")

@export var grid_manager_path: NodePath
@export var city_state_path: NodePath
@export var rain_system_path: NodePath
@export var shop_manager_path: NodePath
@export var localization_path: NodePath
@export var ui_manager_path: NodePath
@export var save_manager_path: NodePath
@export var facility_library_path: NodePath

@export var facility_data_path: String = "res://data/facility_data.json"
@export var locale_files := {
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

func _ready() -> void:
    city_state = _ensure_node(city_state_path, CityState)
    grid_manager = _ensure_node(grid_manager_path, GridManager)
    facility_library = _ensure_node(facility_library_path, FacilityLibrary)
    rain_system = _ensure_node(rain_system_path, RainSystem)
    shop_manager = _ensure_node(shop_manager_path, ShopManager)
    localization = _ensure_node(localization_path, LocalizationManager)
    ui_manager = _ensure_node(ui_manager_path, UIManager)
    save_manager = _ensure_node(save_manager_path, SaveManager)

    grid_manager.set_city_state(city_state)
    facility_library.load_from_json(facility_data_path)
    shop_manager.set_library(facility_library)
    shop_manager.set_city_state(city_state)
    localization.ensure_loaded(locale_files)
    ui_manager.set_city_state(city_state)

    grid_manager.connect("facility_placed", Callable(self, "_on_facility_placed"))
    shop_manager.connect("facility_purchased", Callable(self, "_on_facility_purchased"))

    start_new_game()

func start_new_game() -> void:
    city_state.reset()
    grid_manager.clear()
    shop_manager.refresh_offers()

func simulate_round() -> Dictionary:
    var report := rain_system.simulate_round(city_state)
    ui_manager.show_rain_report(report)
    city_state.add_income()
    city_state.advance_round()
    return report

func attempt_purchase(index: int, origin: Vector2i) -> bool:
    if not shop_manager:
        return false
    return shop_manager.purchase_offer(index, grid_manager, origin)

func save_game() -> bool:
    if not save_manager:
        return false
    return save_manager.save_game(city_state, grid_manager)

func load_game() -> bool:
    if not save_manager:
        return false
    return save_manager.load_game(city_state, grid_manager, facility_library)

func _on_facility_placed(facility, origin: Vector2i) -> void:
    # Hook for future VFX or analytics.
    pass

func _on_facility_purchased(facility) -> void:
    # Refresh offers when a purchase succeeds.
    shop_manager.refresh_offers()

func _ensure_node(path: NodePath, script_type) -> Node:
    if not path.is_empty():
        var existing := get_node_or_null(path)
        if existing:
            return existing
    var node := script_type.new()
    add_child(node)
    return node
