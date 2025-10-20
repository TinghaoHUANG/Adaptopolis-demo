# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name HUDDisplay
extends Control

@export var rain_report_label_path: NodePath

var forecast_min: int = 0
var forecast_max: int = 0

func _ready() -> void:
	_update_label()

func set_forecast(forecast_range: Dictionary) -> void:
	forecast_min = int(forecast_range.get("min", 0))
	forecast_max = int(forecast_range.get("max", 0))
	_update_label()

func display_rain_report(_report: Dictionary) -> void:
	# Retained for compatibility; rain panel now only presents forecast.
	pass

func _update_label() -> void:
	var label: Label = _get_report_label()
	if label == null:
		return
	var min_text := "?"
	var max_text := "?"
	if forecast_min > 0 or forecast_max > 0:
		min_text = str(forecast_min)
		max_text = str(forecast_max)
	label.text = "☔ Range: %s - %s" % [min_text, max_text]

func _get_report_label() -> Label:
	if rain_report_label_path.is_empty():
		return null
	return get_node_or_null(rain_report_label_path) as Label
