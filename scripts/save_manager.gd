# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name SaveManager
extends Node


@export var save_path: String = "user://savegame.json"

func save_game(city_state: CityState, grid_manager: GridManager) -> bool:
    var data: Dictionary = {
        "city": city_state.get_snapshot(),
        "grid": grid_manager.serialize_state(),
        "buildings": _vectors_to_raw(grid_manager.get_building_positions()),
        "water": _vectors_to_raw(grid_manager.get_water_positions())
    }
    return _write_json(save_path, data)

func load_game(city_state: CityState, grid_manager: GridManager, library: FacilityLibrary) -> bool:
    if not FileAccess.file_exists(save_path):
        return false
    var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("Invalid save format")
        return false
    var city_data: Dictionary = parsed.get("city", {})
    city_state.facilities.clear()
    city_state.health = clamp(city_data.get("health", city_state.max_health), 0, city_state.max_health)
    city_state.money = city_data.get("money", city_state.starting_money)
    city_state.round_number = max(city_data.get("round", 1), 1)
    city_state.last_damage = city_data.get("last_damage", 0)
    city_state.emit_signal("stats_changed")
    var buildings_raw: Array = parsed.get("buildings", [])
    var building_positions: Array[Vector2i] = _raw_to_vectors(buildings_raw)
    var water_raw: Array = parsed.get("water", [])
    var water_positions: Array[Vector2i] = _raw_to_vectors(water_raw)
    var grid_data: Array = parsed.get("grid", [])
    grid_manager.load_state(grid_data, library, building_positions, water_positions)
    return true

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



