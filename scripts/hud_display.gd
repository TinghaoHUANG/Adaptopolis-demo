# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name HUDDisplay
extends Control

@export var rain_report_label_path: NodePath

func _ready() -> void:
    display_rain_report({})

func display_rain_report(report: Dictionary) -> void:
    var label: Label = _get_report_label()
    if label == null:
        return
    var intensity: int = int(report.get("intensity", 0))
    var defense: int = int(report.get("defense", 0))
    var damage: int = int(report.get("damage", 0))
    label.text = "Rain: %d\nDefense: %d\nDamage: %d" % [intensity, defense, damage]

func _get_report_label() -> Label:
    if rain_report_label_path.is_empty():
        return null
    return get_node_or_null(rain_report_label_path) as Label
