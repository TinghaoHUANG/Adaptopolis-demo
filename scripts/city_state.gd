# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name CityState
extends Node


signal stats_changed
signal facility_registered(facility: Facility)
signal facility_unregistered(facility: Facility)

@export var max_health: int = 20
@export var starting_money: int = 30
@export var base_income: int = 6
@export var perfect_round_bonus: int = 3

var health: int = max_health
var money: int = starting_money
var round_number: int = 1
var last_damage: int = 0
var facilities: Array[Facility] = []

func reset() -> void:
	health = max_health
	money = starting_money
	round_number = 1
	last_damage = 0
	facilities.clear()
	emit_signal("stats_changed")

func register_facility(facility: Facility) -> void:
	facilities.append(facility)
	emit_signal("facility_registered", facility)
	emit_signal("stats_changed")

func unregister_facility(facility: Facility) -> void:
	if facilities.has(facility):
		facilities.erase(facility)
		emit_signal("facility_unregistered", facility)
		emit_signal("stats_changed")

func get_total_resilience() -> int:
	var total: int = 0
	for facility in facilities:
		total += facility.resilience
	return total

func apply_damage(amount: int) -> void:
	last_damage = max(amount, 0)
	if last_damage == 0:
		return
	health = max(health - last_damage, 0)
	emit_signal("stats_changed")

func add_income() -> int:
	var income: int = base_income
	if last_damage == 0:
		income = base_income + perfect_round_bonus
	money += income
	emit_signal("stats_changed")
	return income

func can_afford(cost: int) -> bool:
	return cost <= money

func spend_money(cost: int) -> bool:
	if cost > money:
		return false
	money -= cost
	emit_signal("stats_changed")
	return true

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	emit_signal("stats_changed")

func advance_round() -> void:
	round_number += 1
	last_damage = 0
	emit_signal("stats_changed")

func is_game_over() -> bool:
	return health <= 0

func get_snapshot() -> Dictionary:
	return {
		"health": health,
		"money": money,
		"round": round_number,
		"last_damage": last_damage
	}
