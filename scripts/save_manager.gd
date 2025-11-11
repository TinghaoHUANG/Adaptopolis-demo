# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name SaveManager
extends Node


const GAME_VERSION := 2
const MIN_SUPPORTED_VERSION := 1
const CARD_COUNTER_CLAMP := 999

@export var save_path: String = "user://savegame.json"
var last_loaded_card_state: Dictionary = {}
var last_loaded_meta: Dictionary = {}

func save_game(city_state: CityState, grid_manager: GridManager, card_state: Dictionary = {}) -> bool:
	var data: Dictionary = {
		"meta": _build_meta(),
		"city": city_state.get_snapshot(),
		"grid": grid_manager.serialize_state(),
		"buildings": _vectors_to_raw(grid_manager.get_building_positions()),
		"water": _vectors_to_raw(grid_manager.get_water_positions()),
		"cards": _prepare_card_state(card_state)
	}
	return _write_json(save_path, data)

func load_game(city_state: CityState, grid_manager: GridManager, library: FacilityLibrary) -> bool:
	last_loaded_card_state = {}
	last_loaded_meta = {}
	if not FileAccess.file_exists(save_path):
		return false
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	var raw: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid save format")
		return false
	var prepared: Dictionary = _prepare_loaded_data(parsed)
	if prepared.is_empty():
		push_warning("Unable to prepare save data for loading.")
		return false
	last_loaded_meta = prepared.get("meta", {}).duplicate(true)
	var city_data: Dictionary = _normalize_city_snapshot(prepared.get("city", {}), city_state)
	city_state.facilities.clear()
	city_state.health = city_data.get("health", city_state.max_health)
	city_state.money = city_data.get("money", city_state.starting_money)
	city_state.round_number = city_data.get("round", 1)
	city_state.last_damage = city_data.get("last_damage", 0)
	city_state.developer_mode = city_data.get("developer_mode", false)
	city_state.emit_signal("stats_changed")
	var buildings_raw: Array = prepared.get("buildings", [])
	var building_positions: Array[Vector2i] = _raw_to_vectors(buildings_raw)
	var water_raw: Array = prepared.get("water", [])
	var water_positions: Array[Vector2i] = _raw_to_vectors(water_raw)
	var grid_data: Array = prepared.get("grid", [])
	grid_manager.load_state(grid_data, library, building_positions, water_positions)
	var card_state: Dictionary = prepared.get("cards", {})
	last_loaded_card_state = card_state.duplicate(true)
	return true

func get_last_card_state() -> Dictionary:
	return last_loaded_card_state.duplicate(true)

func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

func _write_json(path: String, data) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to open save path: %s" % path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true

func _prepare_card_state(state) -> Dictionary:
	return _normalize_card_state(state)

func _vectors_to_raw(vectors: Array[Vector2i]) -> Array:
	var result: Array = []
	for vec in vectors:
		result.append([vec.x, vec.y])
	return result

func _raw_to_vectors(raw: Array) -> Array[Vector2i]:
	var vectors: Array[Vector2i] = []
	for entry in raw:
		if typeof(entry) == TYPE_ARRAY and entry.size() >= 2:
			vectors.append(Vector2i(entry[0], entry[1]))
	return vectors

func _build_meta() -> Dictionary:
	return {
		"game_version": GAME_VERSION,
		"saved_at": Time.get_unix_time_from_system()
	}

func _prepare_loaded_data(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = _apply_migrations(data)
	var prepared: Dictionary = {}
	prepared["meta"] = _normalize_meta(migrated.get("meta", {}))
	prepared["city"] = _ensure_dictionary(migrated.get("city", {}))
	prepared["grid"] = _ensure_array(migrated.get("grid", []))
	prepared["buildings"] = _ensure_array(migrated.get("buildings", []))
	prepared["water"] = _ensure_array(migrated.get("water", []))
	prepared["cards"] = _normalize_card_state(migrated.get("cards", {}))
	return prepared

func _apply_migrations(data: Dictionary) -> Dictionary:
	var current_version: int = _extract_version(data.get("meta", {}))
	current_version = max(current_version, MIN_SUPPORTED_VERSION)
	var migrated: Dictionary = data.duplicate(true)
	if current_version < 2:
		migrated = _migrate_v1_to_v2(migrated)
		current_version = 2
	migrated["meta"] = _normalize_meta(migrated.get("meta", {}), current_version)
	return migrated

func _extract_version(meta_variant) -> int:
	if typeof(meta_variant) == TYPE_DICTIONARY:
		var meta: Dictionary = meta_variant
		return int(meta.get("game_version", MIN_SUPPORTED_VERSION))
	return MIN_SUPPORTED_VERSION

func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	var cards_state: Dictionary = _normalize_card_state(migrated.get("cards", {}))
	migrated["cards"] = cards_state
	var meta: Dictionary = _ensure_dictionary(migrated.get("meta", {}))
	meta["migrated_from"] = min(_extract_version(meta), GAME_VERSION)
	meta["game_version"] = 2
	migrated["meta"] = meta
	return migrated

func _normalize_meta(meta_variant, fallback_version: int = GAME_VERSION) -> Dictionary:
	var meta: Dictionary = _ensure_dictionary(meta_variant)
	var version_value := _parse_int(meta.get("game_version", fallback_version), fallback_version)
	meta["game_version"] = max(version_value, MIN_SUPPORTED_VERSION)
	if not meta.has("saved_at"):
		meta["saved_at"] = Time.get_unix_time_from_system()
	return meta

func _normalize_card_state(state_variant) -> Dictionary:
	var normalized: Dictionary = {
		"unlocked": [],
		"next_green_discount": 0,
		"next_build_discount": 0,
		"pending_damage_reduction_once": 0,
		"metadata": {}
	}
	if typeof(state_variant) != TYPE_DICTIONARY:
		return normalized
	var state: Dictionary = (state_variant as Dictionary)
	var unlocked_variant: Variant = state.get("unlocked", [])
	if typeof(unlocked_variant) == TYPE_ARRAY:
		var cleaned: Array[String] = []
		for entry in unlocked_variant:
			var card_id: String = String(entry).strip_edges()
			if card_id.is_empty():
				continue
			if not cleaned.has(card_id):
				cleaned.append(card_id)
		normalized["unlocked"] = cleaned
	var metadata_variant: Variant = state.get("metadata", {})
	if typeof(metadata_variant) == TYPE_DICTIONARY:
		var metadata: Dictionary = {}
		for key in metadata_variant.keys():
			var card_id: String = String(key).strip_edges()
			if card_id.is_empty():
				continue
			var payload_variant: Variant = metadata_variant[key]
			if typeof(payload_variant) == TYPE_DICTIONARY:
				metadata[card_id] = (payload_variant as Dictionary).duplicate(true)
		normalized["metadata"] = metadata
	normalized["next_green_discount"] = clamp(_parse_int(state.get("next_green_discount", 0), 0), 0, CARD_COUNTER_CLAMP)
	normalized["next_build_discount"] = clamp(_parse_int(state.get("next_build_discount", 0), 0), 0, CARD_COUNTER_CLAMP)
	normalized["pending_damage_reduction_once"] = clamp(_parse_int(state.get("pending_damage_reduction_once", 0), 0), 0, CARD_COUNTER_CLAMP)
	return normalized

func _normalize_city_snapshot(city_variant, city_state: CityState) -> Dictionary:
	var snapshot: Dictionary = _ensure_dictionary(city_variant)
	var health: int = clamp(_parse_int(snapshot.get("health", city_state.max_health), city_state.max_health), 0, city_state.max_health)
	var money: float = max(_parse_float(snapshot.get("money", city_state.starting_money), city_state.starting_money), 0.0)
	var round_value: int = max(_parse_int(snapshot.get("round", 1), 1), 1)
	var last_damage: int = max(_parse_int(snapshot.get("last_damage", 0), 0), 0)
	var developer_mode: bool = bool(snapshot.get("developer_mode", false))
	return {
		"health": health,
		"money": money,
		"round": round_value,
		"last_damage": last_damage,
		"developer_mode": developer_mode
	}

func _ensure_array(value) -> Array:
	if typeof(value) == TYPE_ARRAY:
		return (value as Array).duplicate(true)
	return []

func _ensure_dictionary(value) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}

func _parse_int(value, fallback: int) -> int:
	match typeof(value):
		TYPE_INT:
			return value
		TYPE_FLOAT:
			return int(round(value))
		TYPE_STRING:
			var text: String = value
			if text.is_valid_int():
				return int(text)
			if text.is_valid_float():
				return int(round(text.to_float()))
	return fallback

func _parse_float(value, fallback: float) -> float:
	match typeof(value):
		TYPE_FLOAT:
			return value
		TYPE_INT:
			return float(value)
		TYPE_STRING:
			var text: String = value
			if text.is_valid_float():
				return text.to_float()
			if text.is_valid_int():
				return float(int(text))
	return fallback
