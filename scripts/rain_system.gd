# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name RainSystem
extends Node

const CityState = preload("res://scripts/city_state.gd")

@export var base_min: int = 5
@export var base_max: int = 10
@export var per_round_increase: int = 2

var rng := RandomNumberGenerator.new()
var last_intensity: int = 0

func _ready() -> void:
    rng.randomize()

func seed(value: int) -> void:
    rng.seed = value

func calculate_intensity(round_number: int) -> int:
    var base := rng.randi_range(base_min, base_max)
    last_intensity = base + round_number * per_round_increase
    return last_intensity

func simulate_round(city: CityState) -> Dictionary:
    var intensity := calculate_intensity(city.round_number)
    var total_defense := city.get_total_resilience()
    var damage := max(intensity - total_defense, 0)
    city.apply_damage(damage)
    return {
        "intensity": intensity,
        "defense": total_defense,
        "damage": damage
    }
