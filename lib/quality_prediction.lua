local M = {}

local function clamp01(x)
   if x < 0 then
      return 0
   end
   if x > 1 then
      return 1
   end
   return x
end

-- Model definition for deterministic quality predictions.
--
-- Inputs:
--   base_effect_quality: machine baseline quality effect (B)
--   module_quality_bonus: total module quality bonus for scenario (M)
--   normal_next_probability: normal.next_probability (Pn)
--   fine_next_probability: fine.next_probability (Pf)
--   uncommon_next_probability: uncommon.next_probability (Pu)
--   rare_next_probability: rare.next_probability (Pr)
--   epic_next_probability: epic.next_probability (Pe)
--   max_level: highest unlocked output level index
--     1=fine, 2=uncommon, 3=rare, 4=epic, 5=legendary
--
-- Computation:
--   S = clamp01((B + M) * Pn)
--   normal = 1 - S
--
--   cF = (max_level >= 2) and Pf or 0
--   fine = S * (1 - cF)
--
--   at_uncommon = S * cF
--   cU = (max_level >= 3) and Pu or 0
--   uncommon = at_uncommon * (1 - cU)
--
--   at_rare = at_uncommon * cU
--   cR = (max_level >= 4) and Pr or 0
--   rare = at_rare * (1 - cR)
--
--   at_epic = at_rare * cR
--   cE = (max_level >= 5) and Pe or 0
--   epic = at_epic * (1 - cE)
--   legendary = at_epic * cE
--
-- Locked levels are represented by setting continuation to 0 above the unlock ceiling,
-- which absorbs all probability mass into the highest unlocked level.
function M.compute_distribution(params)
   local start_chance = clamp01((params.base_effect_quality + params.module_quality_bonus) * params.normal_next_probability)

   local continue_from_fine = params.max_level >= 2 and params.fine_next_probability or 0
   local continue_from_uncommon = params.max_level >= 3 and params.uncommon_next_probability or 0
   local continue_from_rare = params.max_level >= 4 and params.rare_next_probability or 0
   local continue_from_epic = params.max_level >= 5 and params.epic_next_probability or 0

   local out = {
      normal = 1 - start_chance,
      fine = 0,
      uncommon = 0,
      rare = 0,
      epic = 0,
      legendary = 0,
   }

   out.fine = start_chance * (1 - continue_from_fine)

   local at_uncommon = start_chance * continue_from_fine
   out.uncommon = at_uncommon * (1 - continue_from_uncommon)

   local at_rare = at_uncommon * continue_from_uncommon
   out.rare = at_rare * (1 - continue_from_rare)

   local at_epic = at_rare * continue_from_rare
   out.epic = at_epic * (1 - continue_from_epic)
   out.legendary = at_epic * continue_from_epic

   return out
end

function M.build_matrix_inputs(runtime_values)
   local module_scenarios = {
      { label = "none", bonus = 0 },
      { label = "4xQ1", bonus = 4 * runtime_values.q1_effect },
      { label = "4xQ2", bonus = 4 * runtime_values.q2_effect },
      { label = "4xQ3", bonus = 4 * runtime_values.q3_effect },
   }

   local research_stages = {
      { label = "Game start", max_level = 1 },
      { label = "Quality module (research)", max_level = 3 },
      { label = "Epic quality (research)", max_level = 4 },
      { label = "Legendary quality (research)", max_level = 5 },
   }

   return module_scenarios, research_stages
end

local function format_percent(x)
   return string.format("%.4f%%", x * 100)
end

local function format_fixed(x)
   return string.format("%.6f", x)
end

local function format_distribution_for_stage(distribution, max_level)
   local parts = {
      "normal=" .. format_percent(distribution.normal),
      "fine=" .. format_percent(distribution.fine),
   }

   if max_level >= 3 then
      table.insert(parts, "uncommon=" .. format_percent(distribution.uncommon))
      table.insert(parts, "rare=" .. format_percent(distribution.rare))
   end

   if max_level >= 4 then
      table.insert(parts, "epic=" .. format_percent(distribution.epic))
   end

   if max_level >= 5 then
      table.insert(parts, "legendary=" .. format_percent(distribution.legendary))
   end

   return table.concat(parts, ", ")
end

function M.build_matrix_report_lines(runtime_values)
   local lines = {
      "=== quality prediction report ===",
      "configured values:",
      "base_effect_quality=" .. string.format("%.6f", runtime_values.base_effect_quality),
      "normal.next_probability=" .. string.format("%.6f", runtime_values.normal_next_probability),
      "fine.next_probability=" .. string.format("%.6f", runtime_values.fine_next_probability),
      "uncommon.next_probability=" .. string.format("%.6f", runtime_values.uncommon_next_probability),
      "rare.next_probability=" .. string.format("%.6f", runtime_values.rare_next_probability),
      "epic.next_probability=" .. string.format("%.6f", runtime_values.epic_next_probability),
      "quality-module effect=" .. string.format("%.6f", runtime_values.q1_effect),
      "quality-module-2 effect=" .. string.format("%.6f", runtime_values.q2_effect),
      "quality-module-3 effect=" .. string.format("%.6f", runtime_values.q3_effect),
   }

   local module_scenarios, research_stages = M.build_matrix_inputs(runtime_values)
   for _, stage in ipairs(research_stages) do
      table.insert(lines, "--- max_level=" .. tostring(stage.max_level) .. " (" .. stage.label .. ") ---")

      for _, scenario in ipairs(module_scenarios) do
         local distribution = M.compute_distribution({
            base_effect_quality = runtime_values.base_effect_quality,
            module_quality_bonus = scenario.bonus,
            normal_next_probability = runtime_values.normal_next_probability,
            fine_next_probability = runtime_values.fine_next_probability,
            uncommon_next_probability = runtime_values.uncommon_next_probability,
            rare_next_probability = runtime_values.rare_next_probability,
            epic_next_probability = runtime_values.epic_next_probability,
            max_level = stage.max_level,
         })

         local total =
            distribution.normal
            + distribution.fine
            + distribution.uncommon
            + distribution.rare
            + distribution.epic
            + distribution.legendary

         table.insert(
            lines,
            scenario.label
            .. ": " .. format_distribution_for_stage(distribution, stage.max_level)
            .. ", total=" .. format_percent(total)
         )
      end
   end

   table.insert(lines, "=== end quality prediction report ===")

   local cap_lines = M.build_module_cap_report_lines(runtime_values)
   for _, line in ipairs(cap_lines) do
      table.insert(lines, line)
   end

   return lines
end

local function compute_start_chance(runtime_values, module_tier_effect, module_quality_level)
   local quality_multiplier = 1 + (module_quality_level * runtime_values.module_quality_per_level_bonus)
   local total_module_bonus = 4 * module_tier_effect * quality_multiplier
   local combined = runtime_values.base_effect_quality + total_module_bonus
   return clamp01(combined * runtime_values.normal_next_probability), total_module_bonus
end

function M.build_module_cap_report_lines(runtime_values)
   local lines = {
      "=== module cap analysis (tier x quality-level) ===",
      "notes:",
      "quality levels use QualityPrototype.level values",
      "module tiers are Q1/Q2/Q3 module prototypes",
      "cap criterion: marginal start-chance gain <= 0.000001",
      "assumed per-level module effect bonus=" .. format_fixed(runtime_values.module_quality_per_level_bonus),
   }

   local levels = runtime_values.quality_levels

   local tiers = {
      { name = "Q1", effect = runtime_values.q1_effect },
      { name = "Q2", effect = runtime_values.q2_effect },
      { name = "Q3", effect = runtime_values.q3_effect },
   }

   local epsilon = 0.000001
   local start_chance = {}

   table.insert(lines, "start chance matrix (fully unlocked context):")
   for i, level in ipairs(levels) do
      start_chance[i] = {}
      local row_parts = {
         level.name .. "(level=" .. tostring(level.level) .. ")",
      }

      for j, tier in ipairs(tiers) do
         local chance = compute_start_chance(runtime_values, tier.effect, level.level)
         start_chance[i][j] = chance
         table.insert(row_parts, tier.name .. "=" .. format_percent(chance))
      end

      table.insert(lines, table.concat(row_parts, ", "))
   end

   table.insert(lines, "tier-up marginal gains at each quality level:")
   for i, level in ipairs(levels) do
      local gain_q1_to_q2 = start_chance[i][2] - start_chance[i][1]
      local gain_q2_to_q3 = start_chance[i][3] - start_chance[i][2]

      table.insert(
         lines,
         level.name
         .. ": Q1->Q2=" .. format_percent(gain_q1_to_q2)
         .. ((gain_q1_to_q2 <= epsilon) and " (capped)" or "")
         .. ", Q2->Q3=" .. format_percent(gain_q2_to_q3)
         .. ((gain_q2_to_q3 <= epsilon) and " (capped)" or "")
      )
   end

   table.insert(lines, "quality-level-up marginal gains at each module tier:")
   for j, tier in ipairs(tiers) do
      for i = 1, #levels - 1 do
         local from_level = levels[i]
         local to_level = levels[i + 1]
         local gain = start_chance[i + 1][j] - start_chance[i][j]
         table.insert(
            lines,
            tier.name
            .. " " .. from_level.name .. "->" .. to_level.name
            .. "=" .. format_percent(gain)
            .. ((gain <= epsilon) and " (capped)" or "")
         )
      end
   end

   table.insert(lines, "=== end module cap analysis ===")
   return lines
end

return M
