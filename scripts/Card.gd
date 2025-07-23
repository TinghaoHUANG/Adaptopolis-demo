extends Resource

class_name Card

@export var name: String
@export var resilience: int
@export var cost: int
@export var type: String # 'green' or 'grey'

func _init(_name: String = "", _resilience: int = 0, _cost: int = 0, _type: String = ""):
    name = _name
    resilience = _resilience
    cost = _cost
    type = _type

func card_string() -> String:
    var emoji = "🌳" if type == "green" else "🧱"
    return "%s %s | Resilience: %d, Cost: $%d" % [emoji, name, resilience, cost] 