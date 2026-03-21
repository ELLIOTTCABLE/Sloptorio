# Sloptorio TODO

## Done now

- Applied a first-pass quality-factor profile on the normal/slop quality prototype for easy engine-supported multipliers:
  - effect multipliers (`default`, inserter, inventory, fluid-wagon, lab-research, crafting-speed, logistic-cell charging, tool-durability, accumulator, flying-robot energy) are set to `0.5`.
  - cost multipliers (crafting-machine energy usage, beacon power usage) are set to `1.5`.
  - constrained baseline-only multipliers (`science_pack_drain_multiplier`, `mining_drill_resource_drain_multiplier`) are set to `1`.

## Remaining nontrivial quality effects

### Can affect, but requires invasive prototype patching

- Weapon/turret range quality effects:
  - Why nontrivial: `QualityPrototype.range_multiplier` is constrained to `[1, 3]`, so slop cannot reduce range directly.
  - Approach: down-tune base `attack_parameters.range` (and related nested range fields) across affected prototypes, then let higher qualities recover from that baseline.
  - Prior art: Inverted Quality does a recursive pass over nested attack parameters in `prototypes/override-final/negative-quality.lua`.

- Additive bonuses that are clamped to nonnegative quality bonuses:
  - Examples: equipment grid width/height, electric pole wire reach/supply area, beacon supply area bonus, mining drill mining radius bonus, module slot bonuses, roboport charging-station count bonus, asteroid collector radius bonus.
  - Why nontrivial: these quality fields are additive bonuses and cannot be negative.
  - Approach: reduce base prototype values (carefully, per type), keep slop bonus at zero, and use higher tiers to recover if needed.

- Effects gated by prototype flags:
  - Examples: `quality_affects_module_slots`, `quality_affects_supply_area_distance`, `quality_affects_mining_radius`, `uses_quality_drain_modifier`, `charging_station_count_affected_by_quality`.
  - Why nontrivial: quality fields have no effect unless the prototype opt-in flag is enabled.
  - Approach: patch these flags where appropriate, then tune quality and/or base prototype values.

- Prototypes that define per-quality dictionaries:
  - Examples: crafting machine `crafting_speed_quality_multiplier`, `energy_usage_quality_multiplier`, `module_slots_quality_bonus`.
  - Why nontrivial: dictionary entries override quality-prototype defaults.
  - Approach: detect dictionary-bearing prototypes and patch dictionaries explicitly.

### Cannot directly increase penalty above baseline with quality prototype alone

- Mining drill resource drain and lab science pack drain:
  - `mining_drill_resource_drain_multiplier` and `science_pack_drain_multiplier` are constrained to `[0, 1]`.
  - Consequence: slop cannot be made more draining than baseline using those two quality fields.
  - Workaround: patch base prototype drain behavior instead (if desired), not quality prototype values.

- Quality effects that are hard-coded additive with nonnegative constraints:
  - Any "bonus-only" quality field where negative values are forbidden cannot express a slop penalty directly.
  - Workaround: base-prototype down-tuning + positive tiers canceling/recovering.

## Next implementation passes

- Build a central patch table for the invasive "base down-tune" domains (no ad-hoc scattered edits).
- Add diagnostics that print sampled prototype stats for slop/fine/uncommon to validate intended deltas.
- Add regression checks around dictionary overrides and opt-in flags so slop penalties are not silently bypassed.

## UX bugs / polish

- `draw_sprite_by_default` on normal/slop still has icon rendering oddities (quality icon-on-icon behavior).
- Need clear textual presentation: "Slop" shown on slop items, minimal noise on fine items.
