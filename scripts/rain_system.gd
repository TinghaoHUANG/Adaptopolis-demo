# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name RainSystem
extends Node


@export var base_min: int = 5
@export var base_max: int = 10
@export var per_round_increase: int = 2

var has_cached_forecast: bool = false
var cached_intensity: int = 0
var cached_round: int = 0

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var last_intensity: int = 0

func _ready() -> void:
	rng.randomize()

func seed(value: int) -> void:
	rng.seed = value

func calculate_intensity(round_number: int) -> int:
	var base: int = rng.randi_range(base_min, base_max)
	return base + round_number * per_round_increase

func simulate_round(city: CityState) -> Dictionary:
	var intensity: int
	if has_cached_forecast and cached_round == city.round_number:
		intensity = cached_intensity
		has_cached_forecast = false
	else:
		intensity = calculate_intensity(city.round_number)
	last_intensity = intensity
	var result := _apply_facility_effects(city)
	var total_resilience: int = int(result.get("resilience", city.get_total_resilience()))
	var damage: int = max(intensity - total_resilience, 0)
	return {
		"intensity": intensity,
		"resilience": total_resilience,
		"damage": damage,
		"pump_events": result.get("pump_events", [])
	}

func _apply_facility_effects(city: CityState) -> Dictionary:
	var resilience_total: float = 0.0
	var pump_events: Array = []
	for facility: Facility in city.facilities:
		if facility == null:
			continue
		if facility.id == "pump_station":
			var event := {
				"facility": facility,
				"cost": 0.5,
				"active": false,
				"resilience": facility.resilience
			}
			if city.spend_money(0.5):
				event["active"] = true
				resilience_total += facility.resilience
			pump_events.append(event)
		else:
			resilience_total += facility.resilience
	return {
		"resilience": int(resilience_total),
		"pump_events": pump_events
	}

func prepare_forecast(round_number: int) -> Dictionary:
	if has_cached_forecast and cached_round == round_number:
		return get_forecast_range(round_number)
	cached_intensity = calculate_intensity(round_number)
	cached_round = round_number
	has_cached_forecast = true
	last_intensity = cached_intensity
	return get_forecast_range(round_number)

func get_forecast_range(round_number: int) -> Dictionary:
	var min_value := base_min + round_number * per_round_increase
	var max_value := base_max + round_number * per_round_increase
	return {
		"min": min_value,
		"max": max_value
	}

func get_forecast() -> int:
	return cached_intensity if has_cached_forecast else 0
