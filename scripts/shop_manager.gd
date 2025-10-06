# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name ShopManager
extends Node


signal offers_changed(offers: Array)
signal purchase_failed(reason: String)
signal facility_purchased(facility: Facility)

@export var offer_size: int = 3

var library: FacilityLibrary = null
var city_state: CityState = null
var current_offers: Array[Facility] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()

func set_library(value: FacilityLibrary) -> void:
    library = value

func set_city_state(value: CityState) -> void:
    city_state = value

func refresh_offers() -> Array[Facility]:
    current_offers.clear()
    if library == null:
        push_warning("ShopManager requires a FacilityLibrary")
        return current_offers
    for i: int in range(offer_size):
        var facility: Facility = library.get_random_facility(rng)
        if facility:
            current_offers.append(facility)
    emit_signal("offers_changed", current_offers.duplicate())
    return current_offers

func get_offers() -> Array[Facility]:
    return current_offers.duplicate()

func purchase_offer(index: int, grid_manager: GridManager, origin: Vector2i, template_override: Facility = null) -> bool:
    if index < 0 or index >= current_offers.size():
        emit_signal("purchase_failed", "Invalid offer index")
        return false
    if city_state == null:
        emit_signal("purchase_failed", "City state unavailable")
        return false
    var source: Facility = current_offers[index]
    var facility: Facility
    if template_override != null and template_override.id == source.id:
        facility = template_override.clone()
    else:
        facility = source.clone()
    if not city_state.can_afford(facility.cost):
        emit_signal("purchase_failed", "Insufficient funds")
        return false
    if not grid_manager.can_place_facility(facility, origin):
        emit_signal("purchase_failed", "Invalid placement")
        return false
    city_state.spend_money(facility.cost)
    var placed: bool = grid_manager.place_facility(facility, origin)
    if not placed:
        # Refund if placement failed after spending money.
        city_state.money += facility.cost
        emit_signal("purchase_failed", "Placement failed")
        return false
    current_offers.remove_at(index)
    emit_signal("offers_changed", current_offers.duplicate())
    emit_signal("facility_purchased", facility)
    return true

func skip_offer(index: int) -> bool:
    if index < 0 or index >= current_offers.size():
        return false
    current_offers.remove_at(index)
    emit_signal("offers_changed", current_offers.duplicate())
    return true
