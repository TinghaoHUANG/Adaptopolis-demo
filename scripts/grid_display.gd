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
@export var cell_size: Vector2 = Vector2(128, 128)
@export var empty_color: Color = Color(0.20, 0.22, 0.26)
@export var building_color: Color = Color(0.35, 0.37, 0.45)
@export var water_color: Color = Color(0.18, 0.32, 0.55)
@export var green_color: Color = Color(0.25, 0.50, 0.35)
@export var grey_color: Color = Color(0.40, 0.42, 0.50)
@export var preview_valid_color: Color = Color(0.40, 0.70, 0.45)
@export var preview_invalid_color: Color = Color(0.70, 0.40, 0.40)
@export var ground_textures: Array[Texture2D] = []
@export var building_texture: Texture2D
@export var water_texture: Texture2D
@export var empty_icon: String = "⬜"

var grid_manager: GridManager = null
var preview_facility: Facility = null
var hover_origin: Vector2i = Vector2i(-1, -1)
var cells: Dictionary = {}
var preview_cells: Array[Vector2i] = []

const LEVEL2_HIGHLIGHT: Color = Color(0.64, 0.45, 0.93, 1.0)
const LEVEL3_HIGHLIGHT: Color = Color(0.96, 0.80, 0.30, 1.0)
const LEVEL_BORDER_WIDTH: int = 4
const NO_HIGHLIGHT: Color = Color(0, 0, 0, 0)
const HIGHLIGHT_PANEL_NAME := "HighlightOverlay"

const FACILITY_TEXTURE_SETS := {
	"green_roof": [
		preload("res://icons/facilities/greenroof_1.png")
	],
	"rain_garden": [
		preload("res://icons/facilities/raingarden_1.png")
	],
	"constructed_wetland": [
		preload("res://icons/facilities/wetland_1.png")
	],
	"pump_station": [
		preload("res://icons/facilities/pump_1.png")
	],
	"flood_wall": [
		preload("res://icons/facilities/floodwall_1.png")
	],
	"bio_swale": [
		preload("res://icons/facilities/bioswale_1.png"),
		preload("res://icons/facilities/bioswale_2.png"),
		preload("res://icons/facilities/bioswale_3.png"),
		preload("res://icons/facilities/bioswale_4.png")
	],
	"infiltration_trench": [
		preload("res://icons/facilities/infiltrationtrench_1.png")
	],
	"permeable_pavement": [
		preload("res://icons/facilities/permeablepavement_1.png")
	],
	"stormwater_tree": [
		preload("res://icons/facilities/stormwatertree_1.png")
	]
}

const RETENTION_POND_ICONS := {
	Vector2i(0, 0): preload("res://icons/facilities/retentionpond_1_upperleft.png"),
	Vector2i(1, 0): preload("res://icons/facilities/retentionpond_1_upperright.png"),
	Vector2i(0, 1): preload("res://icons/facilities/retentionpond_1_lowerleft.png"),
	Vector2i(1, 1): preload("res://icons/facilities/retentionpond_1_lowerright.png")
}

var flood_wall_vertical_texture: Texture2D = null

func _ready() -> void:
	columns = grid_columns
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_prepare_orientation_textures()
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
			var base_texture := _get_ground_texture(pos)
			if facility:
				var icon_texture := _get_facility_icon(facility, pos)
				var label := "" if icon_texture else _format_facility_label(facility)
				var highlight_color := _get_level_highlight(facility.level)
				var display_texture := icon_texture if icon_texture else base_texture
				_set_cell_visual(pos, label, display_texture, empty_color, false, highlight_color, facility)
				var button: Button = cells.get(pos)
				if button:
					button.self_modulate = Color.WHITE
			elif cell and cell.is_water:
				_set_cell_visual(pos, "", water_texture, water_color, true)
			elif cell and cell.is_building:
				_set_cell_visual(pos, "", building_texture, building_color, false)
			else:
				_set_cell_visual(pos, "", base_texture, empty_color, false)

func get_cell_center(cell_position: Vector2i) -> Vector2:
	var button: Button = cells.get(cell_position)
	if button == null:
		return Vector2.ZERO
	var rect: Rect2 = button.get_global_rect()
	return rect.position + rect.size * 0.5

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
			button.text = ""
			button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			add_child(button)
			var pos := Vector2i(x, y)
			cells[pos] = button
			button.expand_icon = true
			_apply_button_style(button, _get_ground_texture(pos), empty_color)
			button.self_modulate = Color.WHITE
			var highlight_panel := Panel.new()
			highlight_panel.name = HIGHLIGHT_PANEL_NAME
			highlight_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
			highlight_panel.visible = false
			highlight_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			highlight_panel.z_index = 1
			highlight_panel.z_as_relative = false
			button.add_child(highlight_panel)
			button.connect("pressed", Callable(self, "_on_cell_pressed").bind(pos))
			button.connect("mouse_entered", Callable(self, "_on_cell_mouse_entered").bind(pos))
			button.connect("mouse_exited", Callable(self, "_on_cell_mouse_exited").bind(pos))

func _apply_button_style(button: Button, texture: Texture2D, color: Color) -> void:
	var normal_box: StyleBoxFlat = StyleBoxFlat.new()
	normal_box.bg_color = color
	normal_box.set_border_width_all(1)
	normal_box.border_color = color.darkened(0.35)
	normal_box.set_corner_radius_all(6)
	var hover_box: StyleBoxFlat = normal_box.duplicate()
	hover_box.bg_color = color.lightened(0.12)
	var pressed_box: StyleBoxFlat = normal_box.duplicate()
	pressed_box.bg_color = color.darkened(0.15)
	button.add_theme_stylebox_override("normal", normal_box)
	button.add_theme_stylebox_override("hover", hover_box)
	button.add_theme_stylebox_override("pressed", pressed_box)
	button.add_theme_stylebox_override("focus", hover_box)
	button.icon = texture
	button.expand_icon = texture != null
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 20)

func _get_ground_texture(pos: Vector2i) -> Texture2D:
	if ground_textures.is_empty():
		return null
	var index: int = abs((pos.x + pos.y) % ground_textures.size())
	return ground_textures[index]

func _set_cell_visual(pos: Vector2i, label: String, texture: Texture2D, fallback_color: Color, disabled: bool, highlight_color: Color = NO_HIGHLIGHT, facility: Facility = null) -> void:
	var button: Button = cells.get(pos)
	if button == null:
		return
	button.disabled = disabled
	if label.is_empty():
		button.text = ""
	else:
		button.text = label
	if label.is_empty() and texture == null:
		button.text = empty_icon
	var icon_texture := texture if label.is_empty() else null
	_apply_button_style(button, icon_texture, fallback_color)
	_update_highlight(button, highlight_color, facility, pos)
	button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if disabled else Control.CURSOR_POINTING_HAND
	if not preview_cells.has(pos):
		button.self_modulate = Color.WHITE

func _get_level_highlight(level: int) -> Color:
	if level <= 1:
		return NO_HIGHLIGHT
	if level == 2:
		return LEVEL2_HIGHLIGHT
	return LEVEL3_HIGHLIGHT

func _update_highlight(button: Button, highlight_color: Color, facility: Facility, grid_position: Vector2i) -> void:
	var panel: Panel = button.get_node_or_null(HIGHLIGHT_PANEL_NAME)
	if panel == null:
		return
	if highlight_color.a <= 0.0 or facility == null or grid_manager == null:
		panel.visible = false
		return
	panel.visible = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.draw_center = false
	var left_same := grid_manager.get_facility_at(grid_position + Vector2i.LEFT) == facility
	var right_same := grid_manager.get_facility_at(grid_position + Vector2i.RIGHT) == facility
	var up_same := grid_manager.get_facility_at(grid_position + Vector2i.UP) == facility
	var down_same := grid_manager.get_facility_at(grid_position + Vector2i.DOWN) == facility
	style.set_border_width(SIDE_LEFT, 0 if left_same else LEVEL_BORDER_WIDTH)
	style.set_border_width(SIDE_RIGHT, 0 if right_same else LEVEL_BORDER_WIDTH)
	style.set_border_width(SIDE_TOP, 0 if up_same else LEVEL_BORDER_WIDTH)
	style.set_border_width(SIDE_BOTTOM, 0 if down_same else LEVEL_BORDER_WIDTH)
	style.border_color = highlight_color
	style.set_corner_radius_all(8)
	style.shadow_color = Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.45)
	style.shadow_offset = Vector2.ZERO
	style.shadow_size = LEVEL_BORDER_WIDTH * 8
	var expand := float(LEVEL_BORDER_WIDTH) * 0.75
	style.expand_margin_left = expand
	style.expand_margin_right = expand
	style.expand_margin_top = expand
	style.expand_margin_bottom = expand
	panel.add_theme_stylebox_override("panel", style)

func _get_facility_icon(facility: Facility, grid_position: Vector2i) -> Texture2D:
	if facility == null:
		return null
	match facility.id:
		"green_roof":
			return _get_textured_icon(facility, grid_position)
		"rain_garden":
			return _get_textured_icon(facility, grid_position)
		"constructed_wetland":
			return _get_textured_icon(facility, grid_position)
		"pump_station":
			return _get_textured_icon(facility, grid_position)
		"flood_wall":
			return _get_flood_wall_icon(facility)
		"bio_swale":
			return _get_textured_icon(facility, grid_position)
		"infiltration_trench":
			return _get_textured_icon(facility, grid_position)
		"permeable_pavement":
			return _get_textured_icon(facility, grid_position)
		"stormwater_tree":
			return _get_textured_icon(facility, grid_position)
		"retention_pond":
			return _get_retention_pond_icon(facility, grid_position)
		_:
			return null

func _get_retention_pond_icon(facility: Facility, grid_position: Vector2i) -> Texture2D:
	if grid_manager == null:
		return null
	var origin := grid_manager.get_facility_origin(facility)
	var offset := grid_position - origin
	var footprint := facility.get_footprint()
	if footprint.is_empty():
		return null
	var min_x := footprint[0].x
	var min_y := footprint[0].y
	for f_offset in footprint:
		min_x = min(min_x, f_offset.x)
		min_y = min(min_y, f_offset.y)
	var normalized := Vector2i(offset.x - min_x, offset.y - min_y)
	return RETENTION_POND_ICONS.get(normalized, null)

func _format_facility_label(facility: Facility) -> String:
	if facility == null:
		return ""
	if FACILITY_TEXTURE_SETS.has(facility.id) or facility.id == "retention_pond":
		return ""
	var icon: String = "🌱" if facility.type == "green" else "🏗️"
	if facility.id == "green_roof":
		icon = "🏡"
	return icon

func _get_textured_icon(facility: Facility, grid_position: Vector2i) -> Texture2D:
	if facility == null:
		return null
	if not FACILITY_TEXTURE_SETS.has(facility.id):
		return null
	var textures: Array = FACILITY_TEXTURE_SETS[facility.id]
	if textures.is_empty():
		return null
	if textures.size() == 1:
		return textures[0]
	var index := _get_facility_cell_index(facility, grid_position)
	if index < 0:
		return textures[0]
	return textures[min(index, textures.size() - 1)]

func _get_facility_cell_index(facility: Facility, grid_position: Vector2i) -> int:
	if grid_manager == null:
		return -1
	var origin := grid_manager.get_facility_origin(facility)
	var offset := grid_position - origin
	var footprint: Array = facility.get_footprint()
	if footprint.is_empty():
		return -1
	var sorted_offsets: Array = footprint.duplicate()
	sorted_offsets.sort_custom(Callable(self, "_compare_offsets"))
	for i in range(sorted_offsets.size()):
		if sorted_offsets[i] == offset:
			return i
	return -1

func _get_flood_wall_icon(facility: Facility) -> Texture2D:
	if facility == null:
		return null
	_prepare_orientation_textures()
	if not FACILITY_TEXTURE_SETS.has("flood_wall"):
		return null
	var textures: Array = FACILITY_TEXTURE_SETS["flood_wall"]
	if textures.is_empty():
		return null
	var base_texture: Texture2D = textures[0]
	var footprint := facility.get_footprint()
	if footprint.is_empty():
		return base_texture
	var min_x := footprint[0].x
	var max_x := footprint[0].x
	var min_y := footprint[0].y
	var max_y := footprint[0].y
	for offset in footprint:
		min_x = min(min_x, offset.x)
		max_x = max(max_x, offset.x)
		min_y = min(min_y, offset.y)
		max_y = max(max_y, offset.y)
	var width := (max_x - min_x) + 1
	var height := (max_y - min_y) + 1
	if height > width and flood_wall_vertical_texture:
		return flood_wall_vertical_texture
	return base_texture

func _prepare_orientation_textures() -> void:
	if flood_wall_vertical_texture != null:
		return
	if not FACILITY_TEXTURE_SETS.has("flood_wall"):
		return
	var textures: Array = FACILITY_TEXTURE_SETS["flood_wall"]
	if textures.is_empty():
		return
	var base_texture: Texture2D = textures[0]
	if base_texture == null:
		return
	var source_image: Image = base_texture.get_image()
	if source_image == null:
		return
	var rotated_image := source_image.duplicate()
	rotated_image.rotate_90(true)
	flood_wall_vertical_texture = ImageTexture.create_from_image(rotated_image)
	if flood_wall_vertical_texture:
		flood_wall_vertical_texture.resource_name = "FloodWallVertical"

func _compare_offsets(a: Vector2i, b: Vector2i) -> bool:
	if a.y == b.y:
		return a.x < b.x
	return a.y < b.y

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
