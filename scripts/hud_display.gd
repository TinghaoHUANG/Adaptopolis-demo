# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name HUDDisplay
extends Control

@export var rain_report_label_path: NodePath

var upcoming_forecast: int = 0
var last_report: Dictionary = {}

func _ready() -> void:
	last_report = {}
	_update_label()

func set_forecast(intensity: int) -> void:
	upcoming_forecast = max(intensity, 0)
	_update_label()

func display_rain_report(report: Dictionary) -> void:
	last_report = report.duplicate()
	_update_label()

func _update_label() -> void:
	var label: Label = _get_report_label()
	if label == null:
		return
	var intensity: int = int(last_report.get("intensity", 0))
	var defense: int = int(last_report.get("defense", 0))
	var damage: int = int(last_report.get("damage", 0))
	var forecast_text: String = "?"
	if upcoming_forecast > 0:
		forecast_text = str(upcoming_forecast)
	var lines: Array[String] = []
	lines.append("Next Rain: %s" % forecast_text)
	lines.append("Rain: %d" % intensity)
	lines.append("Defense: %d" % defense)
	lines.append("Damage: %d" % damage)
	label.text = "\n".join(lines)

func _get_report_label() -> Label:
	if rain_report_label_path.is_empty():
		return null
	return get_node_or_null(rain_report_label_path) as Label


