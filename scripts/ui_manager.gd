# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name UIManager
extends Node

const CityState = preload("res://scripts/city_state.gd")

@export var hud_path: NodePath
@export var round_label_path: NodePath
@export var health_label_path: NodePath
@export var money_label_path: NodePath

var city_state: CityState = null

func set_city_state(state: CityState) -> void:
    if city_state:
        if city_state.is_connected("stats_changed", Callable(self, "_on_stats_changed")):
            city_state.disconnect("stats_changed", Callable(self, "_on_stats_changed"))
    city_state = state
    if city_state:
        city_state.connect("stats_changed", Callable(self, "_on_stats_changed"))
        _on_stats_changed()

func _on_stats_changed() -> void:
    if city_state == null:
        return
    var stats := city_state.get_snapshot()
    update_round(stats["round"])
    update_health(stats["health"], city_state.max_health)
    update_money(stats["money"])

func update_round(round_number: int) -> void:
    var label := _get_label(round_label_path)
    if label:
        label.text = "%s %d" % [tr("ROUND_START"), round_number]

func update_health(health: int, max_health: int) -> void:
    var label := _get_label(health_label_path)
    if label:
        label.text = "%d / %d" % [health, max_health]

func update_money(money: int) -> void:
    var label := _get_label(money_label_path)
    if label:
        label.text = "%s %d" % [tr("BUY_FACILITY"), money]

func show_rain_report(report: Dictionary) -> void:
    var hud := _get_node(hud_path)
    if hud and hud.has_method("display_rain_report"):
        hud.call("display_rain_report", report)

func _get_label(path: NodePath):
    var node := _get_node(path)
    if node and node is Label:
        return node
    return null

func _get_node(path: NodePath) -> Node:
    if path.is_empty():
        return null
    return get_node_or_null(path)
