Adaptopolis — Game Design Document (GDD)

Version: 0.3.0 (matches current implementation)
Engine: Godot 4.4
Languages: English, Chinese (CSV-based)
Genre: Roguelike · Strategy · City-building
Theme: Climate adaptation and urban resilience

1. Game Concept

Adaptopolis is a grid-based, roguelike city-building strategy game about defending a flood‑prone city. Each round rain intensifies, the city takes damage reduced by total resilience, and the player spends funds in a shop to buy and place infrastructural facilities with distinct shapes.

2. Core Gameplay Loop

Start Round
- HUD shows Round, Health, Funds, Resilience; a rain forecast range is displayed.

Rain Phase
- Rain intensity is generated as random(base_min..base_max) + per_round_increase × round.
- Total resilience reduces incoming damage; remaining damage reduces Health.

Income Phase
- If damage is 0, award perfect-round bonus; otherwise award base income. Funds carry over.

Shop + Placement
- Shop offers 3 random facilities. Player selects, optionally rotates, and places on a 6×6 grid with buildings and water obstacles.
- Placement must fit the footprint and respect special rules (see 4. Facilities).

End of Round
- Apply any unlocked card effects (e.g., Garden City adds +3 funds).
- Update Round and forecast; continue until Health ≤ 0 (Game Over) or after 20 rounds (Victory → Endless option).

3. Systems Overview

3.1 City System
- Tracks: Health (max 20), Funds (start 30), Round, facilities, last damage.
- Income: base 6 per round; perfect round bonus +3 when damage == 0.
- Resilience: sum of all facility resilience values.
- Game Over when Health ≤ 0. Victory after completing 20 rounds (then Endless mode optional).

3.2 Rain System
- Parameters: base_min=5, base_max=10, per_round_increase=2.
- Forecast cache: HUD shows (min..max) range for the current round.
- Report includes rain intensity, total resilience, damage, and pump events.

3.3 Grid & Spatial System
- Board: 6×6 grid.
- Obstacles: Random buildings (4–5 cells) and water (1–3 cells) generated at start.
- Rules:
  - No placement on water.
  - Buildings block placement except Green Roofs, which must be placed on building tiles.
  - Pump Station must be orthogonally adjacent to water.
  - Shapes must fit entirely within bounds; preview indicates valid/invalid.
  - Rotation via right-click (Shift for counter‑clockwise).

3.4 Facility System
- Data-driven from JSON (`data/facility_data.json`): id, name, type, type_tags, shape (2D bool), cost, resilience, level, special_rule, unlock_round.
- Levels: 1..3 with cost multipliers {1.0, 1.9, 3.5} and resilience ×1.5 per level beyond 1.
- Merging: Stack-based. Placing an identical facility of the same level fully overlapping the same footprint merges and upgrades the piece. Adjacency merging is disabled.
- Examples (from current catalog): Rain Garden (1×2), Green Roof (1×1, building‑only), Retention Pond (2×2 sliced icon), Pump Station (1×1, needs adjacent water, −0.5 funds/round to activate), plus advanced shapes (Constructed Wetland, Bio‑swale, etc.).

3.5 Shop System
- Offers: 3 per refresh; level bias increases with round (L2 chance ≥6, L3 chance ≥10).
- Purchase: requires sufficient funds and a valid placement origin.
- Skip/Refresh: UI supports skipping a selected offer and refreshing the pool.

3.6 Card System
- Card Bar: persistent panel at the top of the HUD that lists unlocked passive cards.
- Unlocking: cards appear immediately once their in-run condition is satisfied; they persist for the remainder of the run (even if the trigger condition is later broken).
- Synergy Sets (current build, defined in `data/card_data.json`):
  - **Green** — Garden City (+3 funds), Eco Network (adjacent greens reduce damage by 1), Urban Canopy (+2 funds), Sponge Block (damage -2, one-time green cost -1).
  - **Grey** — Storm Defense Network (Flood Wall + Pump Station halve incoming damage), Urban Hardscape (+2 funds but +1 damage pressure when grey ≥ 50%).
  - **Blue** — Blue Corridor (damage -2 and +1 health with pond–wetland–basin corridor), Living Water System (+1 health when ≥2 blue tags).
  - **Blue-Green** — Sponge City (Constructed Wetland adjacency yields damage -2, +1 funds), Eco-Drain Chain (Bio-swale → Trench → Basin chain grants a one-time -3 damage buffer).
  - **Mixed** — Resilient Metropolis (+5 funds and damage -1 with ≥2 of each colour), Circular City (next build cost -1 with balanced colours and funds ≥5), Adaptive Basin System (Pump Station linking Flood Wall + Retention Pond provides damage -3).
- Effects stack alongside base income/damage calculations and are evaluated each round in `main.gd`.

4. Player Progression
- New game: blank 6×6 map with random buildings/water, starting funds 30, health 20.
- Difficulty rises with round via rain escalation.
- Victory after 20 completed rounds; then continue in Endless or restart.

5. Balancing Notes (Current)
- Green (nature-based) options tend to be cheaper and flexible; Grey options costlier but strong.
- Spatial pressure from random buildings + water encourages planning and rotation.
- Simple income (base + perfect bonus) emphasizes damage avoidance without heavy bookkeeping.

6. Localization & UI
- CSV translations (en, zh) loaded at runtime; HUD shows forecast and core stats.
- Facility info panel on hover; supports selling at 60% of current cost.

7. Roadmap (Future)
- Optional adjacency‑merge variant, richer income tiers by damage, events, and synergies; expanded art for all facilities.
Players doing well earn more → buy better Resilience.

Players taking damage earn less → downward pressure.

Creates tension typical of roguelike escalation.

Merging as Relief Mechanic

Merging frees up space while improving efficiency.

Helps manage grid crowding over long runs.

🌐 6. Localization & Accessibility

Base language: English.

Built-in localization hook using TranslationServer.

Font & UI layout should support multilingual expansion (e.g., Chinese).

Color-only cues should also have text/icons for accessibility.

🎨 7. Visual & Audio Direction (Placeholder Phase)

Visual Style (Prototype):

Use ColorRects for all entities:

Empty cell: light gray

Building: dark gray

Green infrastructure: green hues

Grey infrastructure: blue-gray

Water effect: transparent blue overlay

Audio (Optional):

Calm ambient city sounds between rounds.

Rainfall and thunder during attack phase.

Subtle UI click and merge sounds.

Later, this can evolve toward a minimal “isometric city map” aesthetic with soft environmental soundscape.

🧠 8. Educational Layer

The game’s educational intent is to communicate:

That urban resilience is systemic, not one-off.

That green and grey solutions each have pros and cons.

That adaptation is an iterative, resource-limited process.
Each playthrough subtly reinforces systems thinking.

🧩 9. Game Flow Diagram (Text Form)
[Start]
   ↓
[Initialize Map]
   ↓
[Round Start]
   ↓
[Rain Simulation]
   ↓
[Apply Damage → Update Health]
   ↓
[Income Phase → Update Balance]
   ↓
[Shop Phase → Choose Facilities]
   ↓
[Placement Phase → Validate Grid]
   ↓
[Round End → Rain Intensity +1]
   ↓
[Check Game Over → Loop]

🔮 10. Future Expansion Ideas

Terrain System: Lowlands, rivers, and coastlines affect flood risk.

Maintenance Cost: Older facilities degrade unless maintained.

Multi-hazard Mode: Add heatwaves or drought events.

Tech Tree: Unlock advanced solutions (AI drainage, smart sensors).

Story Mode: Procedural missions across different cities.

✅ 11. MVP Feature List (for Alpha)

Grid (6×8) with random obstacles

Facility placement and merging

Rain simulation and damage calculation

Income and balance loop

Shop system with facility randomization

Placeholder visuals with simple colors

English UI with translation-ready keys

Game over condition

🧭 12. Design Philosophy

“Resilience is not built once — it’s maintained every round.”

Adaptopolis is designed to feel like a puzzle of survival and optimization,
while implicitly teaching systems thinking about urban adaptation.

It’s not about “winning” against nature, but about learning to coexist within constraints —
using limited space, money, and knowledge to build a future-ready city.

Document Version: 0.2.5
Prepared for: Codex / Godot 4 Development Team
Author: Tinghao HUANG
Date: 2025-10-04
