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
const FAILURE_CURVE_LINEAR := "linear"
const FAILURE_CURVE_EXP := "exp"

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
@export var faction: String = ""
@export var capex: float = 0.0
@export var opex_per_year: float = 0.0
@export var lifetime_years: int = 0
@export var maint_required: float = 0.0
@export var maint_fulfilled: float = 0.0
@export var failure_curve: Dictionary = {}
@export var co_benefits: Dictionary = {}
@export var land_use: float = 0.0
@export var build_time_weeks: int = 0
@export var synergy: Dictionary = {}
@export var drought_effect: Dictionary = {}

var base_cost: int = 0
var base_resilience: int = 0
var type_tags: Array[String] = []
var maintenance_debt: float = 0.0
var maintenance_multiplier: float = 1.0

func clone(include_runtime_state: bool = false) -> Facility:
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
	copy.faction = faction
	copy.capex = capex
	copy.opex_per_year = opex_per_year
	copy.lifetime_years = lifetime_years
	copy.maint_required = maint_required
	copy.maint_fulfilled = maint_fulfilled
	copy.failure_curve = failure_curve.duplicate(true)
	copy.co_benefits = co_benefits.duplicate(true)
	copy.land_use = land_use
	copy.build_time_weeks = build_time_weeks
	copy.synergy = synergy.duplicate(true)
	copy.drought_effect = drought_effect.duplicate(true)
	copy.base_cost = base_cost
	copy.base_resilience = base_resilience
	copy.type_tags = type_tags.duplicate()
	if include_runtime_state:
		copy.maintenance_debt = maintenance_debt
		copy.maintenance_multiplier = maintenance_multiplier
	else:
		copy.reset_runtime_state()
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
	facility.faction = data.get("faction", facility.type)
	facility.capex = float(data.get("capex", facility.cost))
	facility.opex_per_year = float(data.get("opex_per_year", 0.0))
	facility.lifetime_years = int(data.get("lifetime_years", 0))
	facility.maint_required = max(float(data.get("maint_required", 0.0)), 0.0)
	facility.maint_fulfilled = max(float(data.get("maint_fulfilled", 0.0)), 0.0)
	facility.failure_curve = facility._sanitize_failure_curve(data.get("failure_curve", {}))
	facility.co_benefits = facility._sanitize_co_benefits(data.get("co_benefits", {}))
	facility.land_use = float(data.get("land_use", 0.0))
	facility.build_time_weeks = int(data.get("build_time_weeks", 0))
	facility.synergy = facility._sanitize_dictionary(data.get("synergy", {}))
	facility.drought_effect = facility._sanitize_drought_effect(data.get("drought_effect", {}))
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
	facility.reset_runtime_state()
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
		"type_tags": type_tags.duplicate(),
		"faction": faction,
		"capex": capex,
		"opex_per_year": opex_per_year,
		"lifetime_years": lifetime_years,
		"maint_required": maint_required,
		"maint_fulfilled": maint_fulfilled,
		"failure_curve": failure_curve.duplicate(true),
		"co_benefits": co_benefits.duplicate(true),
		"land_use": land_use,
		"build_time_weeks": build_time_weeks,
		"synergy": synergy.duplicate(true),
		"drought_effect": drought_effect.duplicate(true)
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

func reset_runtime_state() -> void:
	maint_fulfilled = 0.0
	maintenance_debt = 0.0
	maintenance_multiplier = 1.0

func resolve_maintenance_payment(paid_amount: float) -> void:
	paid_amount = max(paid_amount, 0.0)
	maint_fulfilled = paid_amount
	maintenance_debt = max(0.0, maint_required - paid_amount)
	maintenance_multiplier = _evaluate_failure_curve()

func get_maintenance_multiplier() -> float:
	return maintenance_multiplier

func get_effective_resilience() -> int:
	var adjusted := float(resilience) * maintenance_multiplier
	return int(max(round(adjusted), 0))

func get_runtime_snapshot() -> Dictionary:
	return {
		"maint_fulfilled": maint_fulfilled,
		"maintenance_debt": maintenance_debt,
		"maintenance_multiplier": maintenance_multiplier
	}

func apply_runtime_snapshot(snapshot_variant) -> void:
	if typeof(snapshot_variant) != TYPE_DICTIONARY:
		reset_runtime_state()
		return
	var snapshot: Dictionary = snapshot_variant
	maint_fulfilled = max(float(snapshot.get("maint_fulfilled", 0.0)), 0.0)
	maintenance_debt = max(float(snapshot.get("maintenance_debt", 0.0)), 0.0)
	maintenance_multiplier = clamp(float(snapshot.get("maintenance_multiplier", 1.0)), 0.0, 1.0)

func get_drought_multipliers(drought_active: bool, has_reuse_support: bool) -> Dictionary:
	if not drought_active:
		return {"efficacy": 1.0, "heat": 1.0, "ecology": 1.0}
	var requires_reuse: bool = bool(drought_effect.get("requires_reuse", false))
	if requires_reuse and has_reuse_support:
		return {"efficacy": 1.0, "heat": 1.0, "ecology": 1.0}
	var effect: Dictionary = drought_effect
	var efficacy_mult: float = _clamp_multiplier(float(effect.get("efficacy_mult", 1.0)))
	var heat_mult: float = _clamp_multiplier(float(effect.get("heat_mult", 1.0)))
	var ecology_mult: float = _clamp_multiplier(float(effect.get("ecology_mult", 1.0)))
	return {
		"efficacy": efficacy_mult,
		"heat": heat_mult,
		"ecology": ecology_mult
	}

func _evaluate_failure_curve() -> float:
	if maint_required <= 0.0:
		return 1.0
	if maintenance_debt <= 0.0:
		return 1.0
	var ratio: float = clamp(maintenance_debt / max(maint_required, 0.001), 0.0, 1.0)
	var curve_type: String = String(failure_curve.get("type", FAILURE_CURVE_LINEAR))
	var k_value: float = max(float(failure_curve.get("k", 0.0)), 0.0)
	match curve_type:
		FAILURE_CURVE_EXP:
			return clamp(exp(-k_value * ratio), 0.0, 1.0)
		_:
			return clamp(1.0 - k_value * ratio, 0.0, 1.0)

func _sanitize_failure_curve(curve_variant) -> Dictionary:
	var curve: Dictionary = _sanitize_dictionary(curve_variant)
	var curve_type: String = String(curve.get("type", FAILURE_CURVE_LINEAR))
	if curve_type != FAILURE_CURVE_EXP and curve_type != FAILURE_CURVE_LINEAR:
		curve_type = FAILURE_CURVE_LINEAR
	var k_value: float = max(float(curve.get("k", 0.0)), 0.0)
	return {
		"type": curve_type,
		"k": k_value
	}

func _sanitize_co_benefits(source_variant) -> Dictionary:
	var source: Dictionary = _sanitize_dictionary(source_variant)
	return {
		"heat_delta": float(source.get("heat_delta", 0.0)),
		"ecology_delta": float(source.get("ecology_delta", 0.0)),
		"water_quality_delta": float(source.get("water_quality_delta", 0.0))
	}

func _sanitize_dictionary(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}

func _sanitize_drought_effect(source_variant) -> Dictionary:
	var source: Dictionary = _sanitize_dictionary(source_variant)
	return {
		"efficacy_mult": float(source.get("efficacy_mult", 1.0)),
		"heat_mult": float(source.get("heat_mult", 1.0)),
		"ecology_mult": float(source.get("ecology_mult", 1.0)),
		"requires_reuse": bool(source.get("requires_reuse", false))
	}

func _clamp_multiplier(value: float) -> float:
	return clamp(value, 0.0, 2.0)
