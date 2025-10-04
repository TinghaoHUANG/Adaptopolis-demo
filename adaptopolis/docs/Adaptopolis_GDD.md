Adaptopolis — Game Design Document (GDD)

Version: 0.2
Engine: Godot 4
Language: English (multilingual support planned)
Genre: Roguelike · Strategy · City-building
Theme: Climate adaptation and urban resilience

🎯 1. Game Concept

Adaptopolis is a grid-based, roguelike city-building strategy game where the player acts as the mayor of a city threatened by increasingly frequent and powerful floods.
Each round, players build adaptive infrastructure to strengthen the city’s resilience while balancing limited funds and spatial constraints.

The gameplay reflects real-world urban climate adaptation challenges:

Limited land for green infrastructure

Cost trade-offs between “grey” (engineered) and “green” (nature-based) systems

Increasing disaster intensity due to climate change

The tension between short-term protection and long-term sustainability

🧩 2. Core Gameplay Loop

The main gameplay loop operates in turns (rounds) and alternates between disaster impact and planning phases.

Loop Summary:

Start Round

Show round number, city stats (Health, Balance, Resilience).

Random rain intensity is generated.

Rain Phase

Flood event hits the city.

City’s total resilience reduces incoming damage.

Any remaining damage decreases city health.

Income Phase

Income is generated depending on how much damage was avoided.

Full income if no damage, reduced income if partially damaged.

Added to the city’s balance.

Shop Phase

Player is presented with 3–5 random facilities to purchase.

Facilities have shapes (Tetris-style), types (green/grey), and costs.

The player can buy and place facilities on the grid or skip the round.

Placement Phase

The city map (6×8 grid) has limited space and some fixed “building obstacles.”

Facilities must fit geometrically; green roofs can overlap buildings.

Placement affects synergy and long-term defense.

End of Round

Update stats → prepare for next rainfall (stronger than before).

Continue until city health ≤ 0 (Game Over).

⚙️ 3. Systems Overview
3.1 City System

Tracks:

Health — how close the city is to collapse (starts at 100).

Balance — current funds available.

Income — generated after each round.

Infrastructure — all placed facilities (and their resilience).

Calculations:

Total Resilience = Σ(Facility.Resilience)
Effective Damage = Rain Intensity - Total Resilience


If health ≤ 0 → city collapses → game ends.

3.2 Rain System

Each round has a randomly generated rain intensity that scales with the round number:

Rain = random(5–10) + round_number * 2


Future variants may include weather events:

Heavy Storm (high damage)

Mild Rain (low damage)

Infrastructure Failure (reduced defense temporarily)

3.3 Economy System

Players start with an initial balance (e.g., $20).

Income each round:

Condition	Income
No damage	+20
Light damage (≤3)	+15
Moderate (≤7)	+10
Severe (>7)	+5

Balance carries over between rounds, allowing players to save up for expensive facilities.

3.4 Facility System

Each facility card has:

Attribute	Description
ID	Unique identifier
Name	Display name
Type	"Green" or "Grey"
Cost	Money to build
Resilience	Defensive strength
Shape	2D boolean grid
Level	Upgrades through merging
Types of Facilities
Type	Example	Description
Green	Rain Garden, Green Roof, Retention Pond	Nature-based solutions; often synergize; flexible
Grey	Flood Wall, Dike Expansion	Engineered defenses; expensive but powerful
Merging

Two adjacent identical facilities of the same level automatically merge.

Merged facility gains higher level (e.g., Level 2 → +50% resilience).

Adds strategic layer: positioning for merge potential.

Example Facilities
Name	Type	Shape	Cost	Resilience
Rain Garden	Green	1×2	5	2
Green Roof	Green	1×1	6	2 (can overlay)
Flood Wall	Grey	1×3	12	5
Retention Pond	Green	2×2	10	4
3.5 Grid & Spatial System

Map: 6×8 grid.
Obstacles: Randomly generated “buildings” (2–3 per map).

Cannot be built over (except by Green Roofs).

Create strategic spatial constraints similar to Backpack Battles.

Placement Rules:

Facility must fully fit inside the grid.

Facility cannot overlap existing infrastructure (except Green Roofs).

Shapes are fixed; no rotation unless player unlocks upgrade (future feature).

3.6 Shop System

After each round:

Shop displays random 3–5 facilities.

Player can buy multiple if affordable.

Optional “refresh” button (spend money to reroll offers).

Facilities come from a defined pool with rarity weighting.

Rarity tiers:

Tier	Description	Appearance Chance
Common	Basic facilities	70%
Rare	Advanced shapes	25%
Epic	Unique/synergy facilities	5%
3.7 Synergy & Adjacency Effects (Future Expansion)

Facilities may boost each other when adjacent:

Two green infrastructures → +10% defense bonus.

Green Roof above building → +income bonus.

Grey + Green combination → improved overall defense efficiency.

This encourages players to think spatially rather than stacking.

3.8 Events (Future System)

Occasional random events between rounds to add unpredictability:

Government Grant (+money)

Storm Surge (+damage next round)

Public Protest (some facilities disabled)

Technological Breakthrough (reduce cost temporarily)

🎮 4. Player Progression

Each new game starts on a blank city map.

Difficulty scales dynamically with the number of rounds survived.

The game ends when health ≤ 0, displaying:

Survived Rounds

Total Infrastructure Built

Highest Facility Level

City Resilience Score (optional formula)

Longer-term (future roadmap):

Persistent unlocks (e.g., new facility types)

Achievement-style goals (e.g., “Survive 10 rounds without flood damage”)

📊 5. Balancing Principles

Trade-off between Cost and Flexibility

Grey = high defense, expensive, rigid.

Green = lower defense, cheaper, synergistic, space-efficient.

Spatial Pressure

Random building obstacles ensure no two playthroughs feel identical.

Placement becomes both a math and geometry puzzle.

Income-Damage Feedback Loop

Players doing well earn more → buy better defense.

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

Document Version: 0.2
Prepared for: Codex / Godot 4 Development Team
Author: Tinghao HUANG
Date: 2025-10-04
