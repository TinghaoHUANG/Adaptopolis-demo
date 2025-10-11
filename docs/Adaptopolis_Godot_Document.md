Adaptopolis v2 — Godot Development Master Document

Adaptopolis is a grid-based, roguelike city-building game developed in Godot 4.
The player acts as the mayor of a climate-vulnerable city and must build adaptive infrastructures to protect the city from increasingly severe floods.

The game combines:

Tetris-like spatial placement (facilities of different shapes)

Roguelike progression loop (buy, build, survive)

Educational simulation of urban resilience and sustainability

The design emphasizes the real-world dilemma of limited space, funding, and increasing environmental risk.

1. Core Design Pillars

Spatial Strategy — Each facility has a unique geometric shape and must fit in a 6×8 grid with random obstacles.

Adaptive Planning — Green and grey infrastructures interact differently; “Green Roofs” can cover buildings.

Progressive Challenge — Each round, rainfall intensifies; player income varies based on damage.

Replayability — Random maps, random facility offers, and emergent synergy encourage replay.

Education Through Play — Reflects climate adaptation principles through tangible decisions.

2. Architecture and File Structure

/adaptopolis
 /scenes
  main_menu.tscn
  game_scene.tscn
  grid_manager.tscn
  /ui
   hud.tscn
   card_shop.tscn
   localization_menu.tscn
  /tiles
   base_tile.tscn
   facility_tile.tscn
   obstacle_tile.tscn
  /effects
   rain_simulation.tscn
 /scripts
  main.gd
  grid_manager.gd
  facility.gd
  facility_library.gd
  city_state.gd
  rain_system.gd
  shop_manager.gd
  localization.gd
  ui_manager.gd
  save_manager.gd
 /data
  facility_data.json
 /locales
  en.csv
  zh.csv
 /docs
  Adaptopolis_Godot_Document.md

3. Grid System Design

The playable area is a 6×8 grid implemented via TileMap or a custom grid manager.

Each cell:

class_name GridCell
var position: Vector2i
var occupied: bool = false
var facility_ref: Facility = null
var is_building: bool = false


At game start, randomly generate 2–3 building blocks (is_building = true) as obstacles.
These gray tiles restrict facility placement (except Green Roofs).

Placement validation:
Check bounds of each shape cell.
Ensure unoccupied, unless facility type == "Green Roof".
On success → mark occupied.

4. Facility System

Each facility is an infrastructure card that can be purchased and placed on the grid.

Facility.gd:

class_name Facility
var id: String
var name: String
var type: String # "green" or "grey"
var shape: Array
var cost: int
var resilience: int
var level: int = 1


Shape example:

var shape = [
    [true, true],
    [false, true]
]


Merge rule: if two adjacent facilities share the same id and level, merge automatically:
level += 1, resilience *= 1.5, cost *= 1.3.

5. Rain and Damage System

Each round triggers a rain event:

var base = randi_range(5, 10)
var rain_intensity = base + round_number * 2


Damage calculation:

var total_Resilience = city.get_total_resilience()
var effective_damage = max(rain_intensity - total_Resilience, 0)
city.health -= effective_damage


Rain intensity increases with each round.

6. Economy and Shop System

Round flow:

End of round → city earns income based on damage.

Add income to balance.

Open shop → display 3–5 random facilities.

Player buys, places, or skips.

Example:

func generate_offers(n: int = 3) -> Array[Facility]:
    return facility_library.get_random_facilities(n)

7. Placeholder Art Plan

Use ColorRect for visuals until assets exist.

Empty ground: light gray
Building: dark gray
Green facility: green shades
Grey facility: blue-gray
Rain overlay: transparent blue

Example:

func update_visual():
    if type == "green":
        modulate = Color(0.3, 0.8, 0.3)
    else:
        modulate = Color(0.5, 0.5, 0.6)

8. Localization System

Use TranslationServer.

Example:

label.text = tr("ROUND_START")


en.csv:

ROUND_START,Round Start
BUY_FACILITY,Buy Facility
SKIP_TURN,Skip


zh.csv:

ROUND_START,回合开始
BUY_FACILITY,购买设施
SKIP_TURN,跳过


Switch locale:

TranslationServer.set_locale("zh")

9. Facility Data (facility_data.json)
[
  {
    "id": "rain_garden",
    "name": "Rain Garden",
    "type": "green",
    "cost": 5,
    "resilience": 2,
    "shape": [[true, true]],
    "description": "Absorbs stormwater and reduces runoff."
  },
  {
    "id": "flood_wall",
    "name": "Flood Wall",
    "type": "grey",
    "cost": 12,
    "resilience": 5,
    "shape": [[true, true, true]],
    "description": "A strong but expensive flood Resilience."
  },
  {
    "id": "green_roof",
    "name": "Green Roof",
    "type": "green",
    "cost": 6,
    "resilience": 2,
    "shape": [[true]],
    "special_rule": "Can be placed on building tiles."
  },
  {
    "id": "retention_pond",
    "name": "Retention Pond",
    "type": "green",
    "cost": 10,
    "resilience": 4,
    "shape": [[true, true], [true, true]],
    "description": "Stores excess rainfall to prevent flooding."
  }
]

10. Codex Directives

Every script file begins with:

# Adaptopolis Codex Directive:
# You are helping build a grid-based, roguelike city-building game in Godot 4.
# Each facility has a Tetris-like shape placed on a 2D grid.
# Some facilities merge and upgrade when adjacent.
# Placeholder art uses ColorRect; localization uses TranslationServer.
# Please write idiomatic GDScript.

11. Example Prompts for Codex

Prompt 1 — Grid Placement

Create a GDScript grid manager that handles placement on a 6×8 grid. Validate facility shapes (2D boolean arrays) and prevent overlap unless the facility is a Green Roof.

Prompt 2 — Facility Merge

Detect adjacent identical facilities of the same level and merge them into an upgraded version with increased resilience.

Prompt 3 — Rain Simulation

Implement rainfall intensity scaling with round progression, and apply damage based on city Resilience.

Prompt 4 — Localization-Ready UI

Create UI buttons using TranslationServer strings (English by default, Chinese supported).

12. Future Hooks

event_manager.gd — random events (e.g., government grant, storm surge)
combo_manager.gd — adjacency bonuses between facilities
data_loader.gd — modular loading of JSON data
visual_manager.gd — centralized sprite/animation control

13. MVP Target Checklist

[x] Grid system with random obstacles
[x] Facility placement and rotation
[x] Merge/upgrade mechanic
[x] Rainfall damage simulation
[x] Shop and economy loop
[x] ColorRect placeholders
[x] English UI with translation hooks

14. Game Loop Summary

Round start → show stats.

Rain phase → simulate damage.

Income phase → add money.

Shop phase → buy/place/skip.

Next round → increase rain.

Game over → health ≤ 0.

15. Design Philosophy

Adaptopolis transforms climate adaptation into a spatial problem-solving experience.
Players face limited space, increasing floods, and economic trade-offs — mirroring real urban resilience challenges.

Document Version 0.2.5
Prepared for Codex-assisted development (Godot 4).
Author: Tinghao HUANG
Date: 2025-10-04
