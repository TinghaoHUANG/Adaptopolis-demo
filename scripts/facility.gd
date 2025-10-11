# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name Facility
extends Resource

const MAX_LEVEL := 3
const LEVEL_COST_MULTIPLIERS := {
	1: 1.0,
	2: 1.9,
	3: 3.5
}
const LEVEL_RESILIENCE_MULTIPLIER := 1.5
const TYPE_SYMBOLS := {
	"green": "🟩",
	"blue": "💧",
	"grey": "⬛"
}

@export var id: String = ""
@export var name: String = ""
@export var type: String = ""
@export var shape: Array = []
@export var cost: int = 0
@export var resilience: int = 0
@export var level: int = 1
@export var description: String = ""
@export var special_rule: String = ""
@export var unlock_round: int = 1

var base_cost: int = 0
var base_resilience: int = 0
var type_tags: Array[String] = []

func clone() -> Facility:
	var copy: Facility = Facility.new()
	copy.id = id
	copy.name = name
	copy.type = type
	copy.shape = _clone_shape(shape)
	copy.cost = cost
	copy.resilience = resilience
	copy.level = level
	copy.description = description
	copy.special_rule = special_rule
	copy.unlock_round = unlock_round
	copy.base_cost = base_cost
	copy.base_resilience = base_resilience
	copy.type_tags = type_tags.duplicate()
	return copy

static func from_dict(data: Dictionary) -> Facility:
	var facility: Facility = Facility.new()
	facility.id = data.get("id", "")
	facility.name = data.get("name", "")
	facility.type = data.get("type", "")
	facility.shape = data.get("shape", [])
	facility.cost = data.get("cost", 0)
	facility.resilience = data.get("resilience", 0)
	facility.level = data.get("level", 1)
	facility.description = data.get("description", "")
	facility.special_rule = data.get("special_rule", "")
	facility.unlock_round = data.get("unlock_round", 1)
	facility.base_cost = facility.cost
	facility.base_resilience = facility.resilience
	var tags = data.get("type_tags", [])
	var collected: Array[String] = []
	if typeof(tags) == TYPE_ARRAY:
		for tag in tags:
			if typeof(tag) == TYPE_STRING and not collected.has(tag):
				collected.append(tag)
	if collected.is_empty():
		if facility.type.is_empty():
			collected = []
		else:
			collected = [facility.type]
	facility.type_tags = collected
	return facility

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"type": type,
		"shape": _clone_shape(shape),
		"cost": cost,
		"resilience": resilience,
		"level": level,
		"description": description,
		"special_rule": special_rule,
		"unlock_round": unlock_round,
		"type_tags": type_tags.duplicate()
	}

func get_type_tags() -> Array[String]:
	if type_tags.is_empty():
		return [type]
	return type_tags.duplicate()

func get_type_dots() -> String:
	var dots: Array[String] = []
	for tag in get_type_tags():
		var symbol: String = TYPE_SYMBOLS.get(tag, "")
		if symbol.is_empty():
			continue
		if not dots.has(symbol):
			dots.append(symbol)
	if dots.is_empty():
		return ""
	var result := ""
	for dot in dots:
		result += dot
	return result

func get_footprint() -> Array[Vector2i]:
	var footprint: Array[Vector2i] = []
	for y: int in range(shape.size()):
		var row: Array = shape[y]
		for x: int in range(row.size()):
			if row[x]:
				footprint.append(Vector2i(x, y))
	return footprint

func can_merge_with(other: Facility) -> bool:
	if other == null:
		return false
	if other.id != id:
		return false
	if other.level != level:
		return false
	if level >= MAX_LEVEL:
		return false
	return true

func merge_with(other: Facility) -> bool:
	if other == null:
		return false
	if other.id != id or other.level != level:
		push_warning("Attempted to merge incompatible facilities: %s vs %s" % [id, other.id])
		return false
	if level >= MAX_LEVEL:
		return false
	level += 1
	_apply_level_stats()
	return true

func upgrade_to_level(target_level: int) -> void:
	target_level = clamp(target_level, 1, MAX_LEVEL)
	level = max(level, 1)
	if base_cost == 0:
		base_cost = cost
	if base_resilience == 0:
		base_resilience = resilience
	if level == target_level:
		_apply_level_stats()
		return
	level = target_level
	_apply_level_stats()

func _apply_level_stats() -> void:
	if base_cost == 0:
		base_cost = cost
	if base_resilience == 0:
		base_resilience = resilience
	resilience = _calculate_resilience_for_level(base_resilience, level)
	cost = _calculate_cost_for_level(base_cost, level)

func _calculate_cost_for_level(source_cost: int, target_level: int) -> int:
	var fallback_key := MAX_LEVEL
	var multiplier := float(LEVEL_COST_MULTIPLIERS.get(target_level, LEVEL_COST_MULTIPLIERS.get(fallback_key, 1.0)))
	return int(round(source_cost * multiplier))

func _calculate_resilience_for_level(source_resilience: int, target_level: int) -> int:
	var result: float = float(source_resilience)
	for _i in range(target_level - 1):
		result *= LEVEL_RESILIENCE_MULTIPLIER
	return int(round(result))

func _clone_shape(source: Array) -> Array:
	var result: Array = []
	for row in source:
		result.append(row.duplicate())
	return result
