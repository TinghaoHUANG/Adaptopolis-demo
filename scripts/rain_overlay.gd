# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

class_name RainOverlay
extends Control


@export var raindrop_texture: Texture2D = preload("res://icons/rain/raindrop_1.png")
@export var fall_duration: float = 1.2
@export var stream_count: int = 14
@export var drops_per_stream: int = 4
@export var drop_alpha: float = 0.55
@export var drop_scale_min: float = 0.05
@export var drop_scale_max: float = 0.11
@export var lateral_jitter_ratio: float = 0.25
@export var vertical_margin_ratio: float = 0.12
@export var coverage_expansion_ratio: float = 0.4
@export var wind_angle: float = 0.28 # radians; positive values drift towards +X
@export var wind_angle_variance: float = 0.06

var _active_tweens: Array[Tween] = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	clip_contents = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	z_index = 150
	z_as_relative = false
	_rng.randomize()

func play(target_rect: Rect2, duration: float = -1.0) -> void:
	var effective_duration: float = duration if duration > 0.0 else fall_duration
	await _run_rain(target_rect, effective_duration)

func reset() -> void:
	for tween in _active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	_active_tweens.clear()
	for child in get_children():
		child.queue_free()
	visible = false

func _run_rain(target_rect: Rect2, duration: float) -> void:
	reset()
	if raindrop_texture == null:
		return
	visible = true
	clip_contents = false
	var expand_x := target_rect.size.x * coverage_expansion_ratio
	var effective_rect := Rect2(
		target_rect.position - Vector2(expand_x * 0.5, 0.0),
		Vector2(target_rect.size.x + expand_x, target_rect.size.y)
	)
	effective_rect.size = Vector2(max(1.0, effective_rect.size.x), max(1.0, effective_rect.size.y))
	await get_tree().process_frame

	var drop_size: Vector2 = raindrop_texture.get_size()
	var streams: int = max(1, stream_count)
	var drops_per_lane: int = max(1, drops_per_stream)
	var vertical_margin: float = effective_rect.size.y * vertical_margin_ratio
	var base_interval: float = duration / drops_per_lane
	var max_finish: float = 0.0

	var centers: Array[float] = []
	if streams <= 1:
		centers.append(effective_rect.position.x + effective_rect.size.x * 0.5)
	else:
		for stream in range(streams):
			var t: float = float(stream) / float(streams - 1)
			centers.append(effective_rect.position.x + t * effective_rect.size.x)

	var spacing: float = effective_rect.size.x / float(max(1, streams))
	for center_x in centers:
		for drop_index in range(drops_per_lane):
			var drop: TextureRect = TextureRect.new()
			drop.texture = raindrop_texture
			drop.stretch_mode = TextureRect.STRETCH_SCALE
			drop.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var scale_factor: float = _rng.randf_range(drop_scale_min, drop_scale_max)
			var scaled_size: Vector2 = drop_size * scale_factor
			drop.size = scaled_size
			drop.pivot_offset = scaled_size * 0.5
			var lean: float = clamp(_rng.randf_range(wind_angle - wind_angle_variance, wind_angle + wind_angle_variance), -1.0, 1.0)
			drop.rotation = -lean
			drop.modulate = Color(0.55, 0.75, 1.0, 0.0)
			add_child(drop)

			var jitter_range: float = spacing * lateral_jitter_ratio
			var jitter: float = _rng.randf_range(-jitter_range, jitter_range)
			var half_width: float = scaled_size.x * 0.5
			var travel: float = effective_rect.size.y + scaled_size.y * 1.4 + vertical_margin
			var drift: float = tan(lean) * travel
			var min_start: float = effective_rect.position.x - min(0.0, drift)
			var max_start: float = effective_rect.position.x + effective_rect.size.x - scaled_size.x - max(0.0, drift)
			if max_start < min_start:
				max_start = min_start
			var start_x: float = clamp(center_x + jitter - half_width, min_start, max_start)
			var start_y: float = effective_rect.position.y - scaled_size.y - vertical_margin
			drop.position = Vector2(start_x, start_y)

			var end_pos: Vector2 = Vector2(start_x + drift, start_y + travel)
			var base_delay: float = float(drop_index) * base_interval
			var delay_jitter: float = _rng.randf_range(0.0, base_interval * 0.5)
			var start_delay: float = base_delay + delay_jitter
			var tween: Tween = create_tween()
			tween.set_trans(Tween.TRANS_LINEAR)
			tween.set_ease(Tween.EASE_IN)
			tween.tween_interval(start_delay)
			var fade_in_time: float = min(duration * 0.25, 0.18)
			tween.tween_property(drop, "modulate:a", drop_alpha, fade_in_time).from(0.0)
			tween.parallel().tween_property(drop, "position", end_pos, duration)
			tween.parallel().tween_property(drop, "modulate:a", 0.0, duration).from(drop_alpha).set_delay(fade_in_time * 0.6)
			tween.connect("finished", Callable(self, "_on_drop_finished").bind(drop, tween))
			_active_tweens.append(tween)
			max_finish = max(max_finish, start_delay + duration)

	await get_tree().create_timer(max_finish).timeout
	reset()

func _on_drop_finished(drop: TextureRect, tween: Tween) -> void:
	_active_tweens.erase(tween)
	if is_instance_valid(drop):
		drop.queue_free()
