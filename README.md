# Adaptopolis

Adaptopolis is a grid-based, roguelike city-building prototype built with Godot 4. Players steward a flood-prone city by purchasing and placing adaptive infrastructure on a constrained 6×6 grid while rainfall intensity escalates every round.

## Project Layout

- `scripts/` – Core gameplay scripts (grid, facilities, rain, shop, localization, save/load, UI wiring).
- `data/facility_data.json` – Facility catalog used by the shop and placement systems.
- `locales/` – CSV localization tables for English (`en.csv`) and Chinese (`zh.csv`).
- `docs/` – Design references including the condensed Godot document and full game design document.
- `scenes/` – Placeholder subdirectories for future scene assets (`ui/`, `tiles/`, `effects/`).

## Core Systems

- **Grid Manager** (`scripts/grid_manager.gd`): Manages the 6×6 board, building obstacles, placement validation, and automatic merging of identical adjacent facilities.
- **City State** (`scripts/city_state.gd`): Tracks health, funds, income, and facility registry.
- **Rain System** (`scripts/rain_system.gd`): Escalates rainfall each round and applies damage against the city’s total resilience.
- **Shop Manager** (`scripts/shop_manager.gd`): Generates random facility offers, validates purchases, and hands off placement.
- **Save Manager** (`scripts/save_manager.gd`): Serializes the grid, building layout, and city snapshot to `user://savegame.json`.
- **Localization Manager** (`scripts/localization.gd`): Loads CSV translations and switches locales through `TranslationServer`.
- **Main Entry** (`scripts/main.gd`): Wires the managers together, refreshes offers, and runs the round loop hooks.

## Getting Started

1. Install [Godot 4.2+](https://godotengine.org/).
2. Open the `adaptopolis` folder as a Godot project.
3. Ensure `data/facility_data.json` and `locales/*.csv` remain in place—they are loaded at runtime.
4. Run the main scene (to be authored) or attach `scripts/main.gd` to a root node for testing the logic flow.

## Design References

- `docs/Adaptopolis_Godot_Document.md` – Implementation-focused overview of systems and directives.
- `docs/Adaptopolis_GDD.md` – Full game design document used for balancing and future feature planning.

## Versioning

Current documentation version: **0.2.2**. Future updates should align both docs and this README with version increments.


## MCP Helper Scripts

Use the helper scripts in `tools/` to avoid reconfiguring environment variables every time:

1. `tools\start_godot_mcp.cmd` – launches the Godot MCP server with the correct `GODOT_PATH` and Node runtime.
2. `tools\start_mcp_inspector.cmd` – opens the MCP Inspector. When the command window prints `http://localhost:xxxx/`, copy that address, append `?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json`, and open it in your browser.

Example browser URL:

```
http://localhost:6274/?serversFile=d:/adaptopolis/tools/mcp_inspector_config.json
```

After the page loads, choose `local-godot` and start the server; the tools panel will then be available.


