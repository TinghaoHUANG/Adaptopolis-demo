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

func create_facility_with_level(id: String, level: int) -> Facility:
	var facility := create_facility(id)
	if facility:
		facility.upgrade_to_level(level)
	return facility

func get_unlocked_ids(round_number: int) -> Array[String]:
	var unlocked: Array[String] = []
	for id in facility_templates.keys():
		var template: Facility = facility_templates[id]
		if template.unlock_round <= round_number:
			unlocked.append(id)
	if unlocked.is_empty():
		unlocked = facility_templates.keys()
	return unlocked

func get_random_facility(round_number: int, rng: RandomNumberGenerator = null, desired_level: int = 1) -> Facility:
	if facility_templates.is_empty():
		return null
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	desired_level = clamp(desired_level, 1, Facility.MAX_LEVEL)
	var ids: Array[String] = get_unlocked_ids(round_number)
	if ids.is_empty():
		return null
	var id: String = ids[rng.randi_range(0, ids.size() - 1)]
	return create_facility_with_level(id, desired_level)

func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for id in facility_templates.keys():
		result.append(id)
	result.sort()
	return result
