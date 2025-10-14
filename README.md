# Adaptopolis

Adaptopolis is a grid-based, roguelike city-building prototype built with Godot 4.4. Players steward a flood-prone city by purchasing and placing adaptive infrastructure on a constrained 6×6 grid while rainfall intensity escalates every round.

## Game Objective

Keep the city alive for as many rounds as possible while climate-driven storms intensify. Balance health, funds, and resilience by investing in green, grey, and blue infrastructure, unlocking synergy cards, and reacting to escalating rainfall before the city’s health reaches zero.

## Gameplay Overview

1. **Plan & Place** – Begin each run with a small budget, a randomized map, and a rotating shop. Buy facilities, rotate and drag them onto the 6×6 grid, and plan spatial synergies that boost resilience or income.
2. **Endure the Storm** – The `RainSystem` rolls stronger rainfall every round; the combined resilience of placed facilities reduces incoming damage, while leftover damage chips away at city health.
3. **Earn & Reinvest** – Surviving the storm grants baseline income plus any bonuses from cards. Spend wisely in the shop, refresh offers, or save for larger infrastructure projects.
4. **Unlock Cards** – Meeting spatial or compositional goals unlocks passive cards (e.g., Garden City, Storm Defense Network) that deliver bonuses like extra funds, damage reduction, or construction discounts.
5. **Repeat & Escalate** – Rainfall scales up relentlessly. Survive 20 rounds to “secure” the city, then push further in endless mode to chase high scores and experiment with new layouts.

## Project Layout

- `scripts/` – Core gameplay scripts (grid, facilities, rain, shop, localization, save/load, UI wiring).
- `data/facility_data.json` – Facility catalog used by the shop and placement systems.
- `data/card_data.json` – Passive card definitions (conditions, effects, copy) consumed by the card system.
- `locales/` – CSV localization tables for English (`en.csv`) and Chinese (`zh.csv`).
- `docs/` – Design references including the condensed Godot document and full game design document.
- `scenes/` – Main entry scene and UI wiring (see `scenes/main.tscn`).

## Core Systems

- **Grid Manager** (`scripts/grid_manager.gd`): Manages the 6×6 board, building/water obstacles, placement validation, and stack-based merging (place identical, same-level facilities fully overlapping to upgrade).
- **City State** (`scripts/city_state.gd`): Tracks health, funds, income, and facility registry.
- **Rain System** (`scripts/rain_system.gd`): Escalates rainfall each round and applies damage against the city’s total resilience; provides a forecast range to HUD.
- **Shop Manager** (`scripts/shop_manager.gd`): Generates random facility offers, validates purchases and placement, and refreshes the pool.
- **Card Bar** (`scripts/card_bar.gd` + card logic in `scripts/main.gd`): Displays unlocked passive cards defined in `data/card_data.json` (e.g., Garden City, Storm Defense Network, Sponge City, Resilient Metropolis) and applies their income/damage/health/cost effects.
- **Save Manager** (`scripts/save_manager.gd`): Serializes the grid, building layout, water tiles, and city snapshot to `user://savegame.json`.
- **Localization Manager** (`scripts/localization.gd`): Loads CSV translations and switches locales through `TranslationServer`.
- **Main Entry** (`scripts/main.gd`): Wires systems, runs the round loop, handles UI, rotation, drag-move, victory/endless flow.

## Getting Started

1. Install [Godot 4.4+](https://godotengine.org/).
2. Open the `adaptopolis` folder as a Godot project.
3. Ensure `data/facility_data.json` and `locales/*.csv` remain in place—they are loaded at runtime.
4. Run the main scene `scenes/main.tscn`.

## Design References

- `docs/Adaptopolis_Godot_Document.md` – Implementation-focused overview of systems and directives.
- `docs/Adaptopolis_GDD.md` – Game design document aligned to the current implementation.

## Versioning

Current documentation version: **0.3.0**. Future updates should align both docs and this README with version increments.


## MCP Helper Scripts

Use the helper scripts in `tools/` to avoid reconfiguring environment variables every time:

1. `tools\start_godot_mcp.cmd` – launches the Godot MCP server with the correct `GODOT_PATH` and Node runtime.
2. `tools\start_mcp_inspector.cmd` – opens the MCP Inspector. When the command window prints `http://localhost:xxxx/`, copy that address, append `?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json`, and open it in your browser.

Example browser URL:

```
http://localhost:6274/?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json
```

After the page loads, choose `local-godot` and start the server; the tools panel will then be available.
