# TODO List

## Card Library Foundations
- Expand card JSON schema with faction, maintenance, co-benefit, and drought fields across the existing library.
- Migrate save/load flow to bump `game_version`, backfill new defaults, and validate/clamp values on load.
- Implement annual maintenance settlement that converts maintenance debt into efficacy/failure modifiers via each card’s `failure_curve`.
- Aggregate per-card heat/ecology co-benefits (including adjacency synergies) so faction choices influence city-level channels immediately.
- Wire Extreme Drought hooks that apply each card’s `drought_effect`, including mitigation when reuse components are connected.
- Update the card browser UI with faction badges/filters plus expanded detail panes, and add the exemplar faction-specific cards to exercise the new schema.

## Metrics & Events
- Build per-card contribution caches and settlement aggregation hooks to support all five metrics efficiently.
- Implement the Resilience Index (with Extreme Drought sampling) and the discounted Life-Cycle Cost metric.
- Author the Extreme Drought event definition, knobs, and sampler integration shared by both metrics and card logic.
- Add the Heat score plus low-greenness penalty path, followed by Equity and Ecology scores using the shared aggregation backbone.
- Ship the radar chart UI, numeric thresholds, and persistence/export of metric snapshots (including `run_summary.json`).

## Scenarios & Trials
- Introduce the `scenarios/*.json` schema loader to support data-driven presets.
- Author and balance the three preset scenarios (Inland Plain, Hot-Dry City, Coastal Node) with budgets, objectives, drought presets, and scoring weights.
- Implement the “Faction Trials” triple-run flow with faction locks, auto comparison report, and per-point cost ranking.
- Update menus/routing so the new scenarios and Trials mode are discoverable with their duration and scoring weights.

## Scoring, Performance, QA
- Finalize scoring/end-of-run handling (objective checks, weighted final score, timeout auto-settle, refund rules).
- Profile and optimize settlement steps to stay under 100 ms despite the new metrics and aggregation work.
- Add automated/regression checks for drought toggling effects, low-greenness penalties, and faction-trials comparisons.
