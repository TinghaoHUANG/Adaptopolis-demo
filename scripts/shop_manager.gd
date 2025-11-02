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
var locked_slots: Array[bool] = []
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func set_library(value: FacilityLibrary) -> void:
	library = value

func set_city_state(value: CityState) -> void:
	city_state = value

func refresh_offers() -> Array[Facility]:
	var previous_offers := current_offers.duplicate()
	var previous_locks := locked_slots.duplicate()
	current_offers.clear()
	locked_slots.clear()
	if library == null:
		push_warning("ShopManager requires a FacilityLibrary")
		return current_offers
	var round_number := city_state.round_number if city_state else 1
	for i: int in range(offer_size):
		var reuse_locked: bool = i < previous_offers.size() and i < previous_locks.size() and previous_locks[i]
		var facility: Facility = null
		if reuse_locked:
			facility = previous_offers[i]
		if facility == null:
			var level := _determine_offer_level(round_number)
			facility = library.get_random_facility(round_number, rng, level)
		if facility != null:
			current_offers.append(facility)
			locked_slots.append(reuse_locked)
	emit_signal("offers_changed", current_offers.duplicate())
	return current_offers

func get_offers() -> Array[Facility]:
	return current_offers.duplicate()

func get_locked_slots() -> Array[bool]:
	return locked_slots.duplicate()

func reset_locked_slots() -> void:
	locked_slots.clear()

func set_offer_locked(index: int, locked: bool) -> void:
	if index < 0 or index >= current_offers.size():
		return
	if index >= locked_slots.size():
		var previous_size := locked_slots.size()
		locked_slots.resize(current_offers.size())
		for i in range(previous_size, locked_slots.size()):
			locked_slots[i] = false
	locked_slots[index] = locked

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
	if index < locked_slots.size():
		locked_slots.remove_at(index)
	emit_signal("offers_changed", current_offers.duplicate())
	emit_signal("facility_purchased", facility)
	return true

func skip_offer(index: int) -> bool:
	if index < 0 or index >= current_offers.size():
		return false
	current_offers.remove_at(index)
	if index < locked_slots.size():
		locked_slots.remove_at(index)
	emit_signal("offers_changed", current_offers.duplicate())
	return true

func _determine_offer_level(round_number: int) -> int:
	if round_number >= 10 and rng.randf() < 0.15:
		return Facility.MAX_LEVEL
	if round_number >= 6 and rng.randf() < 0.25:
		return 2
	return 1
