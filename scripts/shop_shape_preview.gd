class_name ShopShapePreview
extends Control

const CELL_SIZE := Vector2(14, 14)
const CELL_GAP := 3.0
const PADDING := Vector2(6, 6)
const FILLED_COLOR := Color(0.75, 0.77, 0.80, 1.0)
const BORDER_COLOR := Color(0.15, 0.17, 0.20, 0.8)
const BACKGROUND_COLOR := Color(0.08, 0.09, 0.12, 0.65)
const EMPTY_SIZE := Vector2(60, 32)

var _footprint: Array[Vector2i] = []
var _bounds_origin: Vector2i = Vector2i.ZERO
var _bounds_size: Vector2i = Vector2i.ONE

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_clip_contents(true)

func set_facility(facility: Facility) -> void:
	if facility == null:
		_set_footprint([])
		return
	_set_footprint(facility.get_footprint())

func _set_footprint(cells: Array) -> void:
	_footprint.clear()
	for cell in cells:
		if typeof(cell) == TYPE_VECTOR2I:
			_footprint.append(cell)
	_recalculate_bounds()
	queue_redraw()

func _recalculate_bounds() -> void:
	if _footprint.is_empty():
		_bounds_origin = Vector2i.ZERO
		_bounds_size = Vector2i.ONE
		set_custom_minimum_size(EMPTY_SIZE)
		return
	var min_x := _footprint[0].x
	var max_x := _footprint[0].x
	var min_y := _footprint[0].y
	var max_y := _footprint[0].y
	for cell in _footprint:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)
	_bounds_origin = Vector2i(min_x, min_y)
	_bounds_size = Vector2i((max_x - min_x) + 1, (max_y - min_y) + 1)
	var content_size := _content_size()
	var target_size := content_size + PADDING * 2.0
	target_size.x = max(target_size.x, EMPTY_SIZE.x)
	target_size.y = max(target_size.y, EMPTY_SIZE.y)
	set_custom_minimum_size(target_size)

func _content_size() -> Vector2:
	var width := float(_bounds_size.x) * CELL_SIZE.x + float(max(_bounds_size.x - 1, 0)) * CELL_GAP
	var height := float(_bounds_size.y) * CELL_SIZE.y + float(max(_bounds_size.y - 1, 0)) * CELL_GAP
	return Vector2(width, height)

func _draw() -> void:
	if _footprint.is_empty():
		return
	var content_size := _content_size()
	var origin := (size - content_size) * 0.5
	var background_rect := Rect2(origin - PADDING, content_size + PADDING * 2.0)
	draw_rect(background_rect, BACKGROUND_COLOR, true)
	draw_rect(background_rect, BORDER_COLOR, false, 1.0)
	for cell in _footprint:
		var local := cell - _bounds_origin
		var position := origin + Vector2(
			float(local.x) * (CELL_SIZE.x + CELL_GAP),
			float(local.y) * (CELL_SIZE.y + CELL_GAP)
		)
		var rect := Rect2(position, CELL_SIZE)
		draw_rect(rect, FILLED_COLOR, true)
		draw_rect(rect, BORDER_COLOR, false, 1.0)
