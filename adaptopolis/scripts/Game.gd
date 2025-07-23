extends Control

var city: City
var round_number: int = 1
var card_pool: Array = []
var current_cards: Array = []

@onready var lbl_status = $StatusPanel/StatusLabel
@onready var lbl_rain = $VBox/RainLabel
@onready var vbox_cards = $VBox/CardVBox
@onready var btn_next = $NextRoundButton
@onready var lbl_green = $StatusBar/GreenLabel
@onready var lbl_grey = $StatusBar/GreyLabel

func _ready():
	randomize()
	city = City.new()
	_init_card_pool()
	update_ui()
	btn_next.pressed.connect(_on_next_round)

func _init_card_pool():
	card_pool = [
		Card.new("Rain Garden", 2, 5, "green"),
		Card.new("Bioswale", 3, 7, "green"),
		Card.new("Retention Pond", 4, 10, "green"),
		Card.new("Drainage Upgrade", 5, 12, "grey"),
		Card.new("Flood Wall", 6, 15, "grey"),
		Card.new("Green Roof", 2, 6, "green"),
		Card.new("Dike Expansion", 7, 20, "grey"),
	]

func draw_random_cards(n: int = 3) -> Array:
	var pool = card_pool.duplicate()
	pool.shuffle()
	return pool.slice(0, n)

func update_ui():
	lbl_status.text = "🏙️ Round %d\nHealth: %d\nBalance: $%d\nIncome: $%d\nDefense: %d" % [round_number, city.health, city.balance, city.income, city.get_total_resilience()]
	for child in vbox_cards.get_children():
		vbox_cards.remove_child(child)
		child.queue_free()
	current_cards = draw_random_cards()
	for i in range(current_cards.size()):
		var card = current_cards[i]
		var btn = Button.new()
		btn.text = "%d. %s" % [i+1, card.card_string()]
		btn.disabled = not city.can_afford(card)
		btn.pressed.connect(_on_card_pressed.bind(i))
		vbox_cards.add_child(btn)
	lbl_rain.text = ""
	btn_next.disabled = false
	# Update status bar with green and grey infrastructure counts
	var green_count = 0
	var grey_count = 0
	for card in city.infrastructure:
		if card.type == "green":
			green_count += 1
		elif card.type == "grey":
			grey_count += 1
	lbl_green.text = "🌳 %d" % green_count
	lbl_grey.text = "🧱 %d" % grey_count

func _on_card_pressed(idx):
	var card = current_cards[idx]
	if city.buy_card(card):
		update_ui()

func _on_next_round():
	btn_next.disabled = true
	var rain = Rain.generate_rain_attack(round_number)
	var damage = city.apply_damage(rain)
	city.adjust_income(damage)
	city.add_income_to_balance()
	lbl_rain.text = "🌧️ Rainfall: %d\n💥 Damage Taken: %d" % [rain, damage]
	if city.health <= 0:
		lbl_status.text = "💀 Game Over — The city has fallen."
		vbox_cards.clear()
		btn_next.disabled = true
	else:
		round_number += 1
		await get_tree().create_timer(1.5).timeout
		update_ui() 
