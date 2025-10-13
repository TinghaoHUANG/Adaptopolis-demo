Adaptopolis v2 — Godot Development Master Document

Adaptopolis is a grid‑based, roguelike city‑building game in Godot 4.4. The player buys and places facilities with distinct shapes on a constrained grid to build resilience against escalating rainfall.

The game focuses on:
- Spatial placement with rotation and obstacles
- Simple but escalating round loop (forecast → rain → income → shop → placement)
- Data‑driven facilities and lightweight UI

1. Architecture and File Structure (current)

/adaptopolis
  /scenes
    main.tscn
  /scripts
    main.gd
    grid_manager.gd
    grid_display.gd
    city_state.gd
    facility.gd
    facility_library.gd
    rain_system.gd
    shop_manager.gd
    shop_display.gd
    ui_manager.gd
    hud_display.gd
    card_bar.gd
    save_manager.gd
    round_summary_animator.gd
    localization.gd
  /data
    facility_data.json
    card_data.json
  /locales
    en.csv, zh.csv
  /icons
    ground/*, facilities/* (placeholder art)

Entry scene: scenes/main.tscn (wires HUD, grid display, shop panel, start/victory menus).

2. Grid System (implemented)

- Board: 6×6 cells managed by GridManager (Node), displayed via GridDisplay (GridContainer+Buttons).
- Obstacles: buildings (4–5 cells) and water (1–3 cells) generated at start.
- Validation:
  - Disallow placement on water.
  - Green Roof must be placed on a building cell.
  - Pump Station must be orthogonally adjacent to water.
  - Occupancy prevents overlap except when performing a stack‑merge with an identical facility.
- Rotation: right‑click (Shift = counter‑clockwise) on the preview.

3. Facility System (implemented)

class_name Facility (Resource)
- id, name, type ("green"|"grey"), type_tags, shape (2D bool), cost, resilience, level(1..3), special_rule, unlock_round
- Leveling: cost multipliers {1.0, 1.9, 3.5}; resilience ×1.5 per extra level
- Merge: stack‑based; overlapping the same footprint with same id and level upgrades the facility. Adjacency merge is disabled.

4. Rain & Economy (implemented)

RainSystem: intensity = rand(base_min..base_max) + per_round_increase×round (defaults 5..10 and +2/round). HUD shows forecast range (min..max).
CityState: base_income=6, perfect_round_bonus=3 when damage==0.

5. Shop, Cards & UI (implemented)

- ShopManager offers 3 facilities per refresh; level bias grows by round (L2 chance ≥6, L3 chance ≥10).
- Purchase requires funds and a valid origin; on success the grid places the facility and offers refresh.
- CardBar (`card_bar.gd`) renders a top-of-screen panel with unlocked cards. Card definitions live in `data/card_data.json` and are loaded by `main.gd`, which evaluates unlock conditions (adjacency, counts, resource thresholds) and applies effects (income bonuses, damage reduction, health restore, cost discounts, etc.).
- Implemented cards cover green, grey, blue, blue-green, and mixed synergies (e.g., Garden City, Storm Defense Network, Blue Corridor, Sponge City, Resilient Metropolis). See the JSON file for full copywriting and the matching logic in `main.gd::_check_card_condition`.
- UI: ShopDisplay lists offers with colored level borders and type dots; HUD shows round, health, funds, resilience; hover panel shows facility details and enables selling for 60% of current cost; RoundSummaryAnimator now also displays card bonuses.

6. Localization

CSV translations loaded via LocalizationManager; `tr()` used in HUD labels. Locales: `en`, `zh`.

7. Codex Directives

All scripts begin with the project directive header. Please keep idiomatic GDScript and prefer clarity.

8. Example Tasks (aligned with current build)

- Grid: Add 6×6→6×8 option guarded by constants and ensure GridDisplay scales buttons accordingly.
- Merge: Add optional adjacency-merge rule (behind a flag) without breaking stack-merge.
- Economy: Implement damage-tiered income while retaining the perfect-round bonus.
- Cards: Add new passive cards (define condition + effect) and update CardBar to display icons or rarity.

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

Document Version 0.3.0
Prepared for Codex-assisted development (Godot 4).
Author: Tinghao HUANG
Date: 2025-10-04
