extends Node

class_name City

@export var health: int = 100
@export var income: int = 20
@export var balance: int = 20
var infrastructure: Array = [] # Array of Card

func get_total_resilience() -> int:
	var total = 0
	for card in infrastructure:
		total += card.resilience
	return total

func apply_damage(damage: int) -> int:
	var effective_damage = max(damage - get_total_resilience(), 0)
	health -= effective_damage
	return effective_damage

func adjust_income(damage_received: int) -> void:
	if damage_received == 0:
		income = 20
	elif damage_received <= 3:
		income = 15
	elif damage_received <= 7:
		income = 10
	else:
		income = 5

func add_income_to_balance() -> void:
	balance += income

func can_afford(card: Card) -> bool:
	return card.cost <= balance

func buy_card(card: Card) -> bool:
	if can_afford(card):
		balance -= card.cost
		infrastructure.append(card)
		return true
	return false 
