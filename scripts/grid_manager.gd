# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name GridManager
extends Node


signal facility_placed(facility: Facility, origin: Vector2i)
signal facility_removed(facility: Facility)
signal facility_merged(facility: Facility, absorbed: Facility)
signal facility_moved(facility: Facility, new_origin: Vector2i, previous_origin: Vector2i)

const GRID_WIDTH := 6
const GRID_HEIGHT := 6

class GridCell:
	var position: Vector2i
	var occupied: bool = false
	var facility_ref: Facility = null
	var is_building: bool = false
	var is_water: bool = false

	func _init(pos: Vector2i) -> void:
		position = pos

var grid: Array = []
var facility_cells: Dictionary = {} # maps Facility -> Array[Vector2i]
var facility_origins: Dictionary = {}
var city_state: CityState = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var water_positions: Array[Vector2i] = []

func _ready() -> void:
	initialize()

func set_city_state(state: CityState) -> void:
	city_state = state

func initialize(seed_value: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	clear()

func clear(generate_buildings: bool = true, generate_water: bool = true) -> void:
	_create_grid()
	water_positions.clear()
	if generate_buildings:
		_generate_buildings()
	if generate_water:
		_generate_water_bodies()
	facility_cells.clear()
	facility_origins.clear()

func _create_grid() -> void:
	grid.clear()
	for y in range(GRID_HEIGHT):
		var row: Array[GridCell] = []
		for x in range(GRID_WIDTH):
			row.append(GridCell.new(Vector2i(x, y)))
		grid.append(row)

func _generate_buildings() -> void:
	var building_count: int = rng.randi_range(2, 3)
	var occupied_positions: Array[Vector2i] = []
	for i in range(building_count):
		var attempt: int = 0
		while attempt < 8:
			var pos: Vector2i = Vector2i(rng.randi_range(0, GRID_WIDTH - 1), rng.randi_range(0, GRID_HEIGHT - 1))
			if not occupied_positions.has(pos):
				occupied_positions.append(pos)
				break
			attempt += 1
	for pos in occupied_positions:
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.occupied = true
		cell.is_building = true

func _generate_water_bodies() -> void:
	var desired_count: int = rng.randi_range(3, 4)
	var attempts: int = 0
	water_positions.clear()
	while water_positions.size() < desired_count and attempts < 64:
		attempts += 1
		var pos := Vector2i(rng.randi_range(0, GRID_WIDTH - 1), rng.randi_range(0, GRID_HEIGHT - 1))
		if water_positions.has(pos):
			continue
		var cell := get_cell(pos)
		if cell == null:
			continue
		if cell.is_building or cell.is_water:
			continue
		cell.is_water = true
		cell.occupied = true
		water_positions.append(pos)

func apply_buildings(positions: Array) -> void:
	for row in grid:
		for cell: GridCell in row:
			cell.is_building = false
			if cell.facility_ref == null and not cell.is_water:
				cell.occupied = false
	for entry in positions:
		var pos: Vector2i = _to_vector2i(entry)
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.is_building = true
		if cell.facility_ref == null:
			cell.occupied = true

func apply_water(positions: Array) -> void:
	for row in grid:
		for cell: GridCell in row:
			cell.is_water = false
			if cell.facility_ref == null and not cell.is_building:
				cell.occupied = false
	for entry in positions:
		var pos: Vector2i = _to_vector2i(entry)
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.is_water = true
		if cell.facility_ref == null:
			cell.occupied = true
	water_positions.clear()
	for entry in positions:
		water_positions.append(_to_vector2i(entry))

func _validate_placement(facility: Facility, origin: Vector2i, allow_self_overlap: bool) -> Dictionary:
	var merge_target: Facility = null
	for offset in facility.get_footprint():
		var target: Vector2i = origin + offset
		var cell: GridCell = get_cell(target)
		if cell == null or cell.is_water:
			return {"allowed": false, "merge_target": null}
		var occupant: Facility = cell.facility_ref
		var can_use_building: bool = cell.is_building and facility.id == "green_roof"
		if merge_target != null and occupant == null and not can_use_building:
			return {"allowed": false, "merge_target": null}
		if occupant != null:
			if occupant == facility:
				if allow_self_overlap:
					continue
				return {"allowed": false, "merge_target": null}
			if not facility.can_merge_with(occupant):
				return {"allowed": false, "merge_target": null}
			if merge_target == null:
				merge_target = occupant
			elif merge_target != occupant:
				return {"allowed": false, "merge_target": null}
			continue
		if cell.is_building:
			if not can_use_building:
				return {"allowed": false, "merge_target": null}
			continue
		if cell.occupied:
			return {"allowed": false, "merge_target": null}
	return {"allowed": true, "merge_target": merge_target}

func can_place_facility(facility: Facility, origin: Vector2i) -> bool:
	var result: Dictionary = _validate_placement(facility, origin, false)
	return result.get("allowed", false)

func can_relocate_facility(facility: Facility, origin: Vector2i) -> bool:
	if facility == null:
		return false
	if not facility_cells.has(facility):
		return false
	var result: Dictionary = _validate_placement(facility, origin, true)
	return result.get("allowed", false)

func place_facility(facility: Facility, origin: Vector2i) -> bool:
	var result: Dictionary = _validate_placement(facility, origin, false)
	if not result.get("allowed", false):
		return false
	var merge_target: Facility = result.get("merge_target", null)
	if merge_target:
		remove_facility(merge_target)
	facility_origins[facility] = origin
	_set_facility_footprint(facility)
	if city_state:
		city_state.register_facility(facility)
	emit_signal("facility_placed", facility, origin)
	if merge_target and facility.merge_with(merge_target):
		_set_facility_footprint(facility)
		if city_state:
			city_state.emit_signal("stats_changed")
		emit_signal("facility_merged", facility, merge_target)
	return true

func move_facility(facility: Facility, origin: Vector2i) -> bool:
	if facility == null:
		return false
	if not facility_cells.has(facility):
		return false
	var result: Dictionary = _validate_placement(facility, origin, true)
	if not result.get("allowed", false):
		return false
	var merge_target: Facility = result.get("merge_target", null)
	var previous_origin: Vector2i = facility_origins.get(facility, Vector2i.ZERO)
	_clear_facility_cells(facility)
	if merge_target and merge_target != facility:
		remove_facility(merge_target)
	facility_origins[facility] = origin
	_set_facility_footprint(facility)
	emit_signal("facility_moved", facility, origin, previous_origin)
	if merge_target and merge_target != facility and facility.merge_with(merge_target):
		_set_facility_footprint(facility)
		if city_state:
			city_state.emit_signal("stats_changed")
		emit_signal("facility_merged", facility, merge_target)
	return true

func _resolve_merges(facility: Facility) -> void:
	# Adjacency-based merging has been disabled; stacking now handles all merge logic.
	pass

func remove_facility(facility: Facility) -> void:
	if not facility_cells.has(facility):
		return
	_clear_facility_cells(facility)
	facility_cells.erase(facility)
	facility_origins.erase(facility)
	if city_state:
		city_state.unregister_facility(facility)
	emit_signal("facility_removed", facility)

func _clear_facility_cells(facility: Facility) -> void:
	if not facility_cells.has(facility):
		return
	var positions = facility_cells[facility] as Array[Vector2i]
	for pos in positions:
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.facility_ref = null
		cell.occupied = cell.is_building or cell.is_water
	facility_cells[facility].clear()

func get_cell(position: Vector2i) -> GridCell:
	if position.x < 0 or position.y < 0:
		return null
	if position.x >= GRID_WIDTH or position.y >= GRID_HEIGHT:
		return null
	return grid[position.y][position.x]

func get_facility_at(position: Vector2i) -> Facility:
	var cell: GridCell = get_cell(position)
	if cell == null:
		return null
	return cell.facility_ref

func get_facility_origin(facility: Facility) -> Vector2i:
	return facility_origins.get(facility, Vector2i.ZERO)

func get_facility_cells(facility: Facility) -> Array[Vector2i]:
	var source = facility_cells.get(facility, [])
	var result: Array[Vector2i] = []
	for pos in source:
		result.append(pos)
	return result

func _get_neighbor_facilities(facility: Facility) -> Array[Facility]:
	var neighbors: Array[Facility] = []
	var seen: Dictionary = {}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var positions = facility_cells.get(facility, []) as Array[Vector2i]
	for pos in positions:
		for dir in directions:
			var neighbor_pos: Vector2i = pos + dir
			var neighbor_cell: GridCell = get_cell(neighbor_pos)
			if neighbor_cell == null:
				continue
			var neighbor_facility: Facility = neighbor_cell.facility_ref
			if neighbor_facility == null:
				continue
			if neighbor_facility == facility:
				continue
			if not seen.has(neighbor_facility):
				neighbors.append(neighbor_facility)
				seen[neighbor_facility] = true
	return neighbors

func serialize_state() -> Array:
	var snapshot: Array[Dictionary] = []
	for facility in facility_cells.keys():
		var origin: Vector2i = facility_origins.get(facility, Vector2i.ZERO)
		var cells: Array = []
		for pos in facility_cells[facility]:
			cells.append([pos.x, pos.y])
		snapshot.append({
			"id": facility.id,
			"level": facility.level,
			"origin": [origin.x, origin.y],
			"cells": cells
		})
	return snapshot

func load_state(data: Array, library: FacilityLibrary, building_positions: Array = [], water_positions_override: Array = []) -> void:
	clear(false, false)
	if building_positions.is_empty():
		_generate_buildings()
	else:
		apply_buildings(building_positions)
	if water_positions_override.is_empty():
		_generate_water_bodies()
	else:
		apply_water(water_positions_override)
	if data == null:
		return
	for entry in data:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id: String = entry.get("id", "")
		if id.is_empty():
			continue
		var facility: Facility = library.create_facility(id)
		if facility == null:
			continue
		var target_level: int = entry.get("level", 1)
		facility.upgrade_to_level(target_level)
		var origin_array: Array = entry.get("origin", [0, 0])
		var origin: Vector2i = Vector2i(origin_array[0], origin_array[1])
		place_facility(facility, origin)

func get_building_positions() -> Array[Vector2i]:
	var buildings: Array[Vector2i] = []
	for row in grid:
		for cell: GridCell in row:
			if cell.is_building:
				buildings.append(cell.position)
	return buildings

func _to_vector2i(value) -> Vector2i:
	if typeof(value) == TYPE_VECTOR2I:
		return value
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2i(value[0], value[1])
	return Vector2i.ZERO



func _set_facility_footprint(facility: Facility) -> void:
	if facility == null:
		return
	var origin: Vector2i = facility_origins.get(facility, Vector2i.ZERO)
	var footprint: Array[Vector2i] = facility.get_footprint()
	facility_cells[facility] = []
	for offset in footprint:
		var pos: Vector2i = origin + offset
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.occupied = true
		cell.facility_ref = facility
		facility_cells[facility].append(pos)

func get_water_positions() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row in grid:
		for cell: GridCell in row:
			if cell.is_water:
				result.append(cell.position)
	return result
