# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name Facility
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var type: String = ""
@export var shape: Array = []
@export var cost: int = 0
@export var resilience: int = 0
@export var level: int = 1
@export var description: String = ""
@export var special_rule: String = ""

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
		"special_rule": special_rule
	}

func get_footprint() -> Array[Vector2i]:
	var footprint: Array[Vector2i] = []
	for y: int in range(shape.size()):
		var row: Array = shape[y]
		for x: int in range(row.size()):
			if row[x]:
				footprint.append(Vector2i(x, y))
	return footprint

func merge_with(other: Facility) -> void:
	if other.id != id or other.level != level:
		push_warning("Attempted to merge incompatible facilities: %s vs %s" % [id, other.id])
		return
	level += 1
	resilience = int(round(resilience * 1.5))
	cost = int(round(cost * 1.3))

func _clone_shape(source: Array) -> Array:
	var result: Array = []
	for row in source:
		result.append(row.duplicate())
	return result
