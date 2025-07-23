extends Node

class_name Rain

static func generate_rain_attack(round_number: int) -> int:
	var base = randi_range(5, 10)
	var scaling = round_number * 2
	return base + scaling 
