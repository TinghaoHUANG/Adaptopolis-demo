# Adaptopolis MVP: Factions, Metrics, Scenarios

## Scope & Constraints
- Session length: a complete run finishes within 15 minutes.
- Keep current grid, terrain, and existing event framework intact.
- Add one new extreme event: Extreme Drought.
- Add city-wide ecological/heat penalty when overall greenness is too low.
- Deliver three minimal features only:
  - New card library with faction tags, co-benefits, and maintenance/decay.
  - New metrics panel with five dimensions: Resilience, LCC, Heat, Equity, Ecology.
  - Three preset scenarios + a “Faction Trials” mode.

## 1) New Card Library (Factions + Co-benefits + Maintenance)

### Data Schema
Add fields to facility cards (config-driven, e.g., `cards/*.json`):
- `id: string`
- `name: string`
- `faction: 'grey' | 'green' | 'hybrid'`
- `capex: number` (build cost)
- `opex_per_year: number` (baseline O&M)
- `lifetime_years: number`
- `maint_required: number` (per-year maintenance requirement)
- `maint_fulfilled: number` (tracked in runtime/save)
- `failure_curve: { type: 'linear' | 'exp', k: number }` (maps maintenance debt to failure probability or efficacy drop)
- `co_benefits: { heat_delta: number, ecology_delta: number, water_quality_delta: number }`
- `land_use: number` (area or footprint units)
- `build_time_weeks: number`
- `synergy: { adjacency_tags: string[], bonus: number }` (optional)
- `drought_effect: { efficacy_mult: number, heat_mult: number, ecology_mult: number, requires_reuse?: boolean }`

### Initialization & Save Migration
- Bump `game_version`; backfill defaults for existing cards missing new fields.
- Validate `faction` and numeric bounds on load; log and clamp invalid values.

### Simulation Hooks
- Annual/turn maintenance settlement:
  - Compute maintenance debt: `debt = max(0, maint_required - maint_spend)`.
  - Map `debt` via `failure_curve` to either increased failure chance or reduced efficacy.
- Co-benefit aggregation:
  - Accumulate `heat_delta` and `ecology_delta` into city-level channels, consider `synergy` when adjacent tags connect.
- Drought interaction:
  - During Extreme Drought events, apply `drought_effect` multipliers to card efficacy and co-benefits (mitigate if `requires_reuse` is met by a connected reuse component).

### UI/UX
- Card badge: show `Grey/Green/Hybrid` label; add “Filter by Faction”.
- Card details: display CapEx/OpEx/Lifetime/Maintenance needs/Co-benefits and a small marginal curve thumbnail.

### Minimal Library Additions (examples)
- Grey: Pump Station, Seawall.
- Green: Permeable Pavement, Street Canopy Network.
- Hybrid: Storage Tunnel + Channel Naturalization.

### Acceptance
- Placing different factions on the same tiles changes Heat/Ecology and maintenance debt trends over turns;
  grey cards show higher failure probability when under-maintained.

## 2) New Metrics Panel (Resilience, LCC, Heat, Equity, Ecology)

### Metric Definitions
- Resilience Index: `1 - E[loss_with] / E[loss_base]`, sampling existing yearly event set plus new Extreme Drought.
- LCC (Life-Cycle Cost): discounted `CapEx + Σ(OpEx + maintenance) + residual losses` using global discount rate.
- Heat Score: reduction in UHI exposure (area/pop-weighted), driven by green/hybrid cards and maintenance status.
- Equity Score: improvement for vulnerable groups (e.g., reduction in high-risk exposure differential or Gini of exposure).
- Ecology Score: green coverage and connectivity index; carries “low-greenness penalty”.

### Computation & Data Flow
- At each settlement phase, update instantaneous and cumulative values; cache per-card contribution vectors.
- Extreme Drought:
  - Add to event sampler with configurable frequency/intensity.
  - Impacts Heat and Ecology scores and card efficacy via `drought_effect`.
- Low-Greenness Penalty:
  - If `green_index < threshold`, add penalties to Heat Score and LCC (proxy for health/energy costs).

### Visualization
- New 5D radar chart plus numeric values; color thresholds for pass/fail.
- Keep per-settlement computation under ~100 ms by using pre-aggregated contributions and weighted aggregation at runtime.

### Interfaces & Persistence
- Expose metric snapshots to replay and save; export `run_summary.json` with five trajectories and final score breakdown.

### Acceptance
- Toggling Extreme Drought changes Resilience/Heat/Ecology in sensible directions.
- Reducing greenness triggers penalty effects in Heat and LCC.

## 3) Three Preset Scenarios + “Faction Trials” Mode

### Scenario Config Schema (`scenarios/*.json`)
- `id: string`
- `name: string`
- `map_id: string`
- `duration_minutes: 15`
- `budget: number`
- `objectives: { thresholds: { resilience?: number, LCC?: number, heat?: number, equity?: number, ecology?: number } }`
- `allowed_factions?: ('grey'|'green'|'hybrid')[]`
- `banned_cards?: string[]`
- `event_preset: { include_drought: boolean, drought_freq?: number, existing_events: string[] }`
- `scoring: { weights: { resilience: number, LCC: number, heat: number, equity: number, ecology: number } }`

### Preset Scenarios
- A) Inland Plain (pluvial flooding dominant): medium budget, all factions allowed, objectives weight Resilience and LCC; `include_drought: true`.
- B) Hot-Dry City (heat and low-greenness penalty salient): tight budget, green/hybrid provide strong gains; weights favor Heat and Ecology.
- C) Coastal Node (storm surge + drainage bottlenecks): grey needed at key chokepoints, area-wide green for buffering; hybrid optimal; moderate Equity weight.

### Faction Trials Mode
- Same map, three consecutive runs with faction constraints:
  1) `allowed_factions = ['grey']`
  2) `allowed_factions = ['green']`
  3) `allowed_factions = ['hybrid']`
- Auto-generate comparison report: 5D metrics + cost of risk reduction (per-point cost ranking).
- One-click replay with previous build for marginal comparison.

### Menu & Routing
- Main menu adds “Preset Scenarios” and “Faction Trials”; scenario card shows 15-minute duration and scoring weights.

### Scoring & Ending
- Pass condition: meet `objectives` thresholds.
- Final score: weighted sum of five metrics.
- Auto-settle at N turns or 15-minute timeout; unbuilt items refund budget before settlement.

### Acceptance
- Each preset can be completed and scored within ≤ 15 minutes.
- Trials mode outputs a three-run comparison report consistently.

## Suggested Implementation Phases
- Iteration 1: Card library extensions + simulation hooks → metrics panel skeleton (Resilience/LCC) → scenario schema and loading.
- Iteration 2: Heat/Equity/Ecology metrics + drought/low-greenness penalty → UI polish → Trials mode + comparison report.

---

## TODO List (Concise)
- Data: add new card fields; create `cards/*.json` defaults per faction.
- Save/migration: bump version and backfill defaults; validation on load.
- Sim: implement maintenance debt and `failure_curve` efficacy; co-benefit aggregation; drought modifiers.
- UI: faction badge and filter; card details show CapEx/OpEx/Lifetime/Maintenance/Co-benefits.
- Metrics: compute Resilience, LCC, Heat, Equity, Ecology; cache per-card contribution vectors.
- Events: add Extreme Drought to sampler; implement low-greenness penalty to Heat and LCC.
- Viz: 5D radar + thresholds; metrics snapshot and `run_summary.json` export.
- Scenarios: define `scenarios/*.json` schema; author A/B/C presets with weights/objectives.
- Trials: implement faction-locked triple run and auto comparison report; menu entries.
- Performance: ensure settlement step < 100 ms; profile aggregation paths.
- QA: acceptance tests for drought toggling, greenness penalty, and faction comparisons.

