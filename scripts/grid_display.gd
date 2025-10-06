# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name GridDisplay
extends GridContainer


signal cell_clicked(position: Vector2i)
signal cell_hovered(position: Vector2i)
signal cell_hover_exited(position: Vector2i)

@export var grid_manager_path: NodePath
@export var grid_columns: int = 6
@export var grid_rows: int = 6
@export var cell_size: Vector2 = Vector2(64, 64)
@export var empty_color: Color = Color(0.20, 0.22, 0.26)
@export var building_color: Color = Color(0.35, 0.37, 0.45)
@export var green_color: Color = Color(0.25, 0.50, 0.35)
@export var grey_color: Color = Color(0.40, 0.42, 0.50)
@export var preview_valid_color: Color = Color(0.40, 0.70, 0.45)
@export var preview_invalid_color: Color = Color(0.70, 0.40, 0.40)
@export var empty_icon: String = "⬜"

var grid_manager: GridManager = null
var preview_facility: Facility = null
var hover_origin: Vector2i = Vector2i(-1, -1)
var cells: Dictionary = {}
var preview_cells: Array[Vector2i] = []

func _ready() -> void:
	columns = grid_columns
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_rebuild_cells()
	if not grid_manager_path.is_empty():
		var node: GridManager = get_node_or_null(grid_manager_path) as GridManager
		if node:
			set_grid_manager(node)

func set_grid_manager(manager: GridManager) -> void:
	if grid_manager == manager:
		return
	if grid_manager:
		if grid_manager.is_connected("facility_placed", Callable(self, "_on_grid_updated")):
			grid_manager.disconnect("facility_placed", Callable(self, "_on_grid_updated"))
			grid_manager.disconnect("facility_removed", Callable(self, "_on_grid_updated"))
			grid_manager.disconnect("facility_merged", Callable(self, "_on_grid_updated"))
		if grid_manager.is_connected("facility_moved", Callable(self, "_on_grid_moved")):
			grid_manager.disconnect("facility_moved", Callable(self, "_on_grid_moved"))
	grid_manager = manager
	if grid_manager:
		grid_manager.connect("facility_placed", Callable(self, "_on_grid_updated"))
		grid_manager.connect("facility_removed", Callable(self, "_on_grid_updated"))
		grid_manager.connect("facility_merged", Callable(self, "_on_grid_updated"))
		grid_manager.connect("facility_moved", Callable(self, "_on_grid_moved"))
	refresh_all()

func set_preview_facility(facility: Facility) -> void:
	preview_facility = facility
	if preview_facility == null:
		clear_preview()
	else:
		_update_preview()

func refresh_all() -> void:
	clear_preview()
	if grid_manager == null:
		return
	for y in range(grid_rows):
		for x in range(grid_columns):
			var pos: Vector2i = Vector2i(x, y)
			var facility: Facility = grid_manager.get_facility_at(pos)
			var cell := grid_manager.get_cell(pos)
			if facility:
				var color: Color = green_color if facility.type == "green" else grey_color
				_set_cell_visual(pos, _format_facility_label(facility), color)
			elif cell and cell.is_building:
				_set_cell_visual(pos, "🏢", building_color)
			else:
				_set_cell_visual(pos, "", empty_color)

func clear_preview() -> void:
	for pos in preview_cells:
		var button: Button = cells.get(pos)
		if button:
			button.self_modulate = Color.WHITE
	preview_cells.clear()
	hover_origin = Vector2i(-1, -1)

func _rebuild_cells() -> void:
	for child in get_children():
		child.queue_free()
	cells.clear()
	preview_cells.clear()
	for y in range(grid_rows):
		for x in range(grid_columns):
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.flat = true
			button.toggle_mode = false
			button.custom_minimum_size = cell_size
			button.text = empty_icon
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			add_child(button)
			var pos := Vector2i(x, y)
			cells[pos] = button
			_apply_button_color(button, empty_color)
			button.self_modulate = Color.WHITE
			button.connect("pressed", Callable(self, "_on_cell_pressed").bind(pos))
			button.connect("mouse_entered", Callable(self, "_on_cell_mouse_entered").bind(pos))
			button.connect("mouse_exited", Callable(self, "_on_cell_mouse_exited").bind(pos))

func _apply_button_color(button: Button, color: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_border_width_all(1)
	normal.border_color = color.darkened(0.35)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate()
	hover.bg_color = color.lightened(0.12)
	var pressed := normal.duplicate()
	pressed.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)

func _set_cell_visual(pos: Vector2i, label: String, color: Color) -> void:
	var button: Button = cells.get(pos)
	if button == null:
		return
	var display_text := label
	if display_text.is_empty():
		display_text = empty_icon
	button.text = display_text
	_apply_button_color(button, color)
	if not preview_cells.has(pos):
		button.self_modulate = Color.WHITE

func _format_facility_label(facility: Facility) -> String:
	var icon: String = "🌱" if facility.type == "green" else "🏗️"
	if facility.id == "green_roof":
		icon = "🏡"
	if facility.level > 1:
		return "%s Lv%d" % [icon, facility.level]
	return icon

func _show_preview(origin: Vector2i) -> void:
	clear_preview()
	if preview_facility == null:
		return
	var highlight_positions: Array[Vector2i] = []
	for offset in preview_facility.get_footprint():
		highlight_positions.append(origin + offset)
	var valid: bool = grid_manager != null and grid_manager.can_place_facility(preview_facility, origin)
	var highlight_color: Color = preview_valid_color if valid else preview_invalid_color
	for pos in highlight_positions:
		var button: Button = cells.get(pos)
		if button == null:
			continue
		button.self_modulate = highlight_color
	preview_cells = highlight_positions
	hover_origin = origin

func _update_preview() -> void:
	if preview_facility == null:
		clear_preview()
		return
	if hover_origin.x < 0 or hover_origin.y < 0:
		return
	_show_preview(hover_origin)

func _on_cell_pressed(pos: Vector2i) -> void:
	emit_signal("cell_clicked", pos)

func _on_cell_mouse_entered(pos: Vector2i) -> void:
	emit_signal("cell_hovered", pos)
	hover_origin = pos
	if preview_facility:
		_show_preview(pos)

func _on_cell_mouse_exited(pos: Vector2i) -> void:
	emit_signal("cell_hover_exited", pos)
	if hover_origin == pos:
		clear_preview()

func _on_grid_moved(_facility, _new_origin: Vector2i, _previous_origin: Vector2i) -> void:
	_on_grid_updated(_facility, _new_origin)

func _on_grid_updated(_facility, _origin = Vector2i.ZERO) -> void:
	refresh_all()
