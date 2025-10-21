# Adaptopolis

Adaptopolis is a turn-based, storm-survival city builder played on a 6×6 grid. Each round, you buy and place adaptive infrastructure, brace for incoming rainfall, and keep the city alive as the weather intensifies. The key is to well orginaze your blue, green or grey infrastructures within the limited funds and space, also discover their combined benefits!

---

## Quick Start

### Download & Play (Windows)
- Grab the latest `Adaptopolis_demo_v*.exe` from this repository.  
- Double-click the file to launch the game—no installation required.

### Play From Source
1. Install [Godot 4.4+](https://godotengine.org/).
2. Open this folder as a project.
3. Run `scenes/main.tscn`.

---

## How a Round Works
1. **Review the HUD**
   - **Stats Panel:** Shows current round, health, funds, and resilience.
   - **Rain Forecast:** Displays the rainfall range you must prepare for.
2. **Shop & Plan**
   - Browse the offers on the right panel.
   - Hover to preview; click to select; right-click to rotate.
   - Buying spends funds immediately, so plan placements before you purchase.
3. **Place Facilities**
   - Left-click a tile on the grid to place the selected facility.
   - Drag to reposition before ending the round; use right-click to rotate clockwise.
4. **End the Round**
   - Press **Next Round** when you’re satisfied with the layout.
   - Rainfall hits, resilience absorbs damage, and leftover damage harms health.
   - Survive to collect income, apply card bonuses, and refresh the shop.

Repeat the loop, expanding infrastructure and chasing synergies as storms grow stronger.

---

## Controls & Tips
- **Left Click:** Select shop item / place facility.
- **Right Click:** Rotate selected facility clockwise.
- **Drag:** Move a placed facility before ending the round.
- **Cards:** Unlock automatically by meeting their conditions (e.g., specific adjacency or facility counts). Hover the card bar for details.
- **Synergies:** Combine green, blue, and grey infrastructure to balance income, resilience, and grid space.
- **Endless Mode:** Survive 20 rounds to secure the city, then continue in endless play for higher scores.

---

## Breakpoints to Watch
- **Funds**: Buildings cost money and some facilities (e.g., pumps) have maintenance cost after every round.
- **Resilience vs. Forecast**: Always check forecast ranges; stack resilience to prepare your city  agains storms.
- **Grid Space**: Large facilities can block placement; use single-tile options (e.g., Stormwater Tree) to fill gaps. And don't forget to level up your facility by simply overlaping and merge two same facilities.
- **Card Unlocks**: Many bonuses trigger from specific patterns—experiment with layouts to discover them.

---

## Feedback
Have ideas, bugs, or balance notes? Open an issue or drop a message, I’d love to hear how your city survived the storms!***
