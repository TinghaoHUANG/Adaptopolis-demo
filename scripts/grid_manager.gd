# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name GridManager
extends Node

const Facility = preload("res://scripts/facility.gd")
const CityState = preload("res://scripts/city_state.gd")
const FacilityLibrary = preload("res://scripts/facility_library.gd")

signal facility_placed(facility: Facility, origin: Vector2i)
signal facility_removed(facility: Facility)
signal facility_merged(facility: Facility, absorbed: Facility)

const GRID_WIDTH := 6
const GRID_HEIGHT := 8

class GridCell:
	var position: Vector2i
	var occupied: bool = false
	var facility_ref: Facility = null
	var is_building: bool = false

	func _init(pos: Vector2i) -> void:
		position = pos

var grid: Array = []
var facility_cells: Dictionary = {} # maps Facility -> Array[Vector2i]
var facility_origins: Dictionary = {}
var city_state: CityState = null
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	initialize()

func set_city_state(state: CityState) -> void:
	city_state = state

func initialize(seed: int = 0) -> void:
	rng = RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
	else:
		rng.randomize()
	clear()

func clear(generate_buildings: bool = true) -> void:
	_create_grid()
	if generate_buildings:
		_generate_buildings()
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

func apply_buildings(positions: Array) -> void:
	for row in grid:
		for cell: GridCell in row:
			cell.is_building = false
			if cell.facility_ref == null:
				cell.occupied = false
	for entry in positions:
		var pos: Vector2i = _to_vector2i(entry)
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.is_building = true
		if cell.facility_ref == null:
			cell.occupied = true

func can_place_facility(facility: Facility, origin: Vector2i) -> bool:
	var footprint: Array[Vector2i] = facility.get_footprint()
	for offset in footprint:
		var target: Vector2i = origin + offset
		var cell: GridCell = get_cell(target)
		if cell == null:
			return false
		if cell.is_building and facility.id == "green_roof":
			continue
		if cell.occupied:
			return false
	return true

func place_facility(facility: Facility, origin: Vector2i) -> bool:
	if not can_place_facility(facility, origin):
		return false
	var footprint: Array[Vector2i] = facility.get_footprint()
	var occupied_positions: Array[Vector2i] = []
	for offset in footprint:
		var target: Vector2i = origin + offset
		var cell: GridCell = get_cell(target)
		cell.occupied = true
		cell.facility_ref = facility
		if cell.is_building and facility.id == "green_roof":
			# Building remains flagged but is now capped by the facility.
			pass
		occupied_positions.append(target)
	facility_cells[facility] = occupied_positions
	facility_origins[facility] = origin
	if city_state:
		city_state.register_facility(facility)
	emit_signal("facility_placed", facility, origin)
	_resolve_merges(facility)
	return true

func _resolve_merges(facility: Facility) -> void:
	var neighbors: Array[Facility] = _get_neighbor_facilities(facility)
	for neighbor in neighbors:
		if neighbor == facility:
			continue
		if neighbor.id != facility.id:
			continue
		if neighbor.level != facility.level:
			continue
		var absorbed_cells: Array[Vector2i] = (facility_cells.get(neighbor, []) as Array[Vector2i]).duplicate()
		remove_facility(neighbor)
		facility.merge_with(neighbor)
		if not facility_cells.has(facility):
			facility_cells[facility] = []
		for pos in absorbed_cells:
			var cell: GridCell = get_cell(pos)
			if cell == null:
				continue
			cell.occupied = true
			cell.facility_ref = facility
			if not facility_cells[facility].has(pos):
				facility_cells[facility].append(pos)
		emit_signal("facility_merged", facility, neighbor)

func remove_facility(facility: Facility) -> void:
	if not facility_cells.has(facility):
		return
	var positions: Array[Vector2i] = facility_cells[facility] as Array[Vector2i]
	for pos in positions:
		var cell: GridCell = get_cell(pos)
		if cell == null:
			continue
		cell.facility_ref = null
		cell.occupied = cell.is_building
	facility_cells.erase(facility)
	facility_origins.erase(facility)
	if city_state:
		city_state.unregister_facility(facility)
	emit_signal("facility_removed", facility)

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
	return facility_cells.get(facility, []).duplicate()

func _get_neighbor_facilities(facility: Facility) -> Array[Facility]:
	var neighbors: Array[Facility] = []
	var seen: Dictionary = {}
	var directions: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var positions: Array[Vector2i] = facility_cells.get(facility, []) as Array[Vector2i]
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

func load_state(data: Array, library: FacilityLibrary, building_positions: Array = []) -> void:
	clear(false)
	if building_positions.is_empty():
		_generate_buildings()
	else:
		apply_buildings(building_positions)
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
		facility.level = entry.get("level", 1)
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
