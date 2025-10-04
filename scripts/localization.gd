# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name LocalizationManager
extends Node

@export var default_locale: String = "en"

var loaded_locales: Dictionary = {}

func _ready() -> void:
    if default_locale != TranslationServer.get_locale():
        TranslationServer.set_locale(default_locale)

func load_locale(locale_code: String, path: String) -> void:
    if not FileAccess.file_exists(path):
        push_warning("Missing locale file: %s" % path)
        return
    var translation: Translation = Translation.new()
    translation.locale = locale_code
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    while not file.eof_reached():
        var line: String = file.get_line().strip_edges()
        if line.is_empty():
            continue
        var parts: Array = line.split(",", false, 2)
        if parts.size() < 2:
            continue
        translation.add_message(parts[0], parts[1])
    file.close()
    TranslationServer.add_translation(translation)
    loaded_locales[locale_code] = path

func set_locale(locale_code: String) -> void:
    if not loaded_locales.has(locale_code):
        push_warning("Locale not loaded: %s" % locale_code)
        return
    TranslationServer.set_locale(locale_code)

func get_available_locales() -> Array[String]:
    var result: Array[String] = []
    for key in loaded_locales.keys():
        result.append(key)
    result.sort()
    return result

func ensure_loaded(locales: Dictionary) -> void:
    for code in locales.keys():
        if loaded_locales.has(code):
            continue
        load_locale(code, locales[code])

