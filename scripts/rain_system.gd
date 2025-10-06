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
	var total_defense: int = city.get_total_resilience()
	var damage: int = max(intensity - total_defense, 0)
	city.apply_damage(damage)
	return {
		"intensity": intensity,
		"defense": total_defense,
		"damage": damage
	}



func prepare_forecast(round_number: int) -> int:
	if has_cached_forecast and cached_round == round_number:
		return cached_intensity
	cached_intensity = calculate_intensity(round_number)
	cached_round = round_number
	has_cached_forecast = true
	last_intensity = cached_intensity
	return cached_intensity

func get_forecast() -> int:
	return cached_intensity if has_cached_forecast else 0
