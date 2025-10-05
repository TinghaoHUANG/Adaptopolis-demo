# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name FacilityLibrary
extends Node


var facility_templates: Dictionary = {}
var data_path: String = ""

func load_from_json(path: String) -> void:
    data_path = path
    facility_templates.clear()
    if not FileAccess.file_exists(path):
        push_warning("Facility data not found: %s" % path)
        return
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    var raw: String = file.get_as_text()
    file.close()
    var parsed: Variant = JSON.parse_string(raw)
    if typeof(parsed) != TYPE_ARRAY:
        push_warning("Facility data must be an array: %s" % path)
        return
    for entry in parsed:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var facility: Facility = Facility.from_dict(entry)
        facility_templates[facility.id] = facility

func reload() -> void:
    if data_path.is_empty():
        return
    load_from_json(data_path)

func has_facility(id: String) -> bool:
    return facility_templates.has(id)

func create_facility(id: String) -> Facility:
    if not facility_templates.has(id):
        push_warning("Unknown facility requested: %s" % id)
        return null
    return facility_templates[id].clone()

func get_random_facility(rng: RandomNumberGenerator = null) -> Facility:
    if facility_templates.is_empty():
        return null
    if rng == null:
        rng = RandomNumberGenerator.new()
        rng.randomize()
    var keys: Array = facility_templates.keys()
    var id: String = keys[rng.randi_range(0, keys.size() - 1)]
    return facility_templates[id].clone()

func get_all_ids() -> Array[String]:
    var result: Array[String] = []
    for id in facility_templates.keys():
        result.append(id)
    result.sort()
    return result


