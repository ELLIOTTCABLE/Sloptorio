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
--   slop_next_probability: normal.next_probability (Pn)
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
   local start_chance = clamp01((params.base_effect_quality + params.module_quality_bonus) *
      params.slop_next_probability)

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
      { label = "Game start",                   max_level = 1 },
      { label = "Quality module (research)",    max_level = 3 },
      { label = "Epic quality (research)",      max_level = 4 },
      { label = "Legendary quality (research)", max_level = 5 },
   }

   return module_scenarios, research_stages
end

local function format_percent_cell(x, decimals)
   return string.format("%." .. tostring(decimals or 4) .. "f%%", x * 100)
end

local function format_delta_cell(x)
   return string.format("%.1f%%", x * 100)
end

local function format_relative_delta(current, baseline)
   local epsilon = 1e-12
   if math.abs(baseline) <= epsilon then
      if math.abs(current - baseline) <= epsilon then
         return "0.0%"
      end
      return "inf"
   end

   local relative_change = ((current - baseline) / baseline) * 100
   return string.format("%+.1f%%", relative_change)
end

local function format_fixed(x)
   return string.format("%.6f", x)
end

local function quantize_quality_module_effect(effect)
   return math.floor((effect * 1000) + 1e-9) / 1000
end

local function compute_module_quality_bonus(runtime_values, base_tier_effect, module_quality_level)
   local quality_multiplier = 1 + (module_quality_level * runtime_values.quality_default_multiplier_base)
   local effective_tier_effect = quantize_quality_module_effect(base_tier_effect * quality_multiplier)
   return 4 * effective_tier_effect
end

local function quality_level_by_name(runtime_values, quality_name, fallback)
   for _, quality in ipairs(runtime_values.sloptorio_quality_levels or {}) do
      if quality.name == quality_name then
         return quality.level
      end
   end
   return fallback
end

local function build_legendary_module_scenarios(runtime_values)
   local module_tiers = {
      { label = "Q1", effect = runtime_values.q1_effect },
      { label = "Q2", effect = runtime_values.q2_effect },
      { label = "Q3", effect = runtime_values.q3_effect },
   }
   local module_qualities = {
      { suffix = "U", name = "uncommon",  fallback = 1 },
      { suffix = "R", name = "rare",      fallback = 2 },
      { suffix = "E", name = "epic",      fallback = 3 },
      { suffix = "L", name = "legendary", fallback = 5 },
   }

   local scenarios = {}
   for _, module_quality in ipairs(module_qualities) do
      local module_quality_level = quality_level_by_name(runtime_values, module_quality.name, module_quality.fallback)
      for _, module_tier in ipairs(module_tiers) do
         table.insert(scenarios, {
            label = "4x" .. module_tier.label .. module_quality.suffix,
            bonus = compute_module_quality_bonus(runtime_values, module_tier.effect, module_quality_level),
         })
      end
   end

   return scenarios
end

local function display_width(value)
   local _, count = string.gsub(value, "[^\128-\193]", "")
   return count
end

local function pad_right(value, width)
   return value .. string.rep(" ", width - display_width(value))
end

local function pad_left(value, width)
   return string.rep(" ", width - display_width(value)) .. value
end

local function parse_decimal_percent_cell(value)
   local sign, int_part, frac_part, percent_suffix, marker_suffix = value:match("^([+-]?)(%d+)%.(%d+)(%%)([*=]?)$")
   if sign == nil then
      sign, int_part, frac_part = value:match("^([+-]?)(%d+)%.(%d+)$")
      percent_suffix = ""
      marker_suffix = ""
   end
   if sign == nil then
      return nil
   end

   return {
      sign = sign,
      int_part = int_part,
      frac_part = frac_part,
      suffix = percent_suffix .. marker_suffix,
   }
end

local function build_matrix_table_lines(headers, rows)
   local decimal_specs = {}
   local column_count = #headers
   for i = 2, column_count do
      decimal_specs[i] = {
         sign_width = 0,
         int_width = 0,
         frac_width = 0,
         suffix_width = 0,
      }
   end

   for _, row in ipairs(rows) do
      for i = 2, column_count do
         local parsed = parse_decimal_percent_cell(row[i])
         if parsed then
            if parsed.sign ~= "" then
               decimal_specs[i].sign_width = 1
            end
            local int_width = display_width(parsed.int_part)
            local frac_width = display_width(parsed.frac_part)
            local suffix_width = display_width(parsed.suffix)
            if int_width > decimal_specs[i].int_width then
               decimal_specs[i].int_width = int_width
            end
            if frac_width > decimal_specs[i].frac_width then
               decimal_specs[i].frac_width = frac_width
            end
            if suffix_width > decimal_specs[i].suffix_width then
               decimal_specs[i].suffix_width = suffix_width
            end
         end
      end
   end

   local rendered_rows = {}
   for row_index, row in ipairs(rows) do
      rendered_rows[row_index] = {}
      for i, cell in ipairs(row) do
         if i == 1 then
            rendered_rows[row_index][i] = cell
         else
            local parsed = parse_decimal_percent_cell(cell)
            local spec = decimal_specs[i]
            if parsed and spec.int_width > 0 and spec.frac_width > 0 then
               local sign_part = parsed.sign
               if sign_part == "" and spec.sign_width > 0 then
                  sign_part = " "
               end
               local int_part = string.rep(" ", spec.int_width - display_width(parsed.int_part)) .. parsed.int_part
               local frac_part = parsed.frac_part .. string.rep(" ", spec.frac_width - display_width(parsed.frac_part))
               local suffix_part = parsed.suffix .. string.rep(" ", spec.suffix_width - display_width(parsed.suffix))
               rendered_rows[row_index][i] = sign_part .. int_part .. "." .. frac_part .. suffix_part
            else
               rendered_rows[row_index][i] = cell
            end
         end
      end
   end

   local widths = {}
   for i, header in ipairs(headers) do
      widths[i] = display_width(header)
   end
   for _, row in ipairs(rendered_rows) do
      for i, cell in ipairs(row) do
         local cell_width = display_width(cell)
         if cell_width > widths[i] then
            widths[i] = cell_width
         end
      end
   end

   local lines = {}
   local header_cells = {}
   for i, header in ipairs(headers) do
      if i == 1 then
         header_cells[i] = pad_right(header, widths[i])
      else
         header_cells[i] = pad_left(header, widths[i])
      end
   end
   table.insert(lines, table.concat(header_cells, "  "))

   for _, row in ipairs(rendered_rows) do
      local cells = {}
      for i, cell in ipairs(row) do
         if i == 1 then
            cells[i] = pad_right(cell, widths[i])
         else
            cells[i] = pad_left(cell, widths[i])
         end
      end
      table.insert(lines, table.concat(cells, "  "))
   end

   return lines
end

local function build_table_lines_with_widths(headers, rows, widths)
   local lines = {}
   local header_cells = {}
   for i, header in ipairs(headers) do
      table.insert(header_cells, pad_right(header, widths[i]))
   end
   table.insert(lines, table.concat(header_cells, "  "))

   for _, row in ipairs(rows) do
      local cells = {}
      for i, cell in ipairs(row) do
         table.insert(cells, pad_right(cell, widths[i]))
      end
      table.insert(lines, table.concat(cells, "  "))
   end

   return lines
end

local function build_table_lines(headers, rows)
   local widths = {}
   for i, header in ipairs(headers) do
      widths[i] = display_width(header)
   end

   for _, row in ipairs(rows) do
      for i, cell in ipairs(row) do
         local cell_width = display_width(cell)
         if cell_width > widths[i] then
            widths[i] = cell_width
         end
      end
   end

   return build_table_lines_with_widths(headers, rows, widths)
end

local function make_vanilla_distribution(start_chance, max_level)
   local q = clamp01(start_chance)
   local out = {
      normal = 0,
      uncommon = 0,
      rare = 0,
      epic = 0,
      legendary = 0,
   }

   if max_level <= 1 then
      out.normal = 1
      return out
   end

   out.normal = 1 - q
   out.uncommon = q * 0.9

   if max_level <= 3 then
      out.rare = q * 0.1
      return out
   end

   out.rare = q * 0.09

   if max_level <= 4 then
      out.epic = q * 0.01
      return out
   end

   out.epic = q * 0.009
   out.legendary = q * 0.001
   return out
end

local function build_stage_matrix_rows(runtime_values, stage, module_scenarios)
   local rows = {}

   local VANILLA_BASE_EFFECT = 0
   local VANILLA_Q1_EFFECT = 0.1
   local VANILLA_Q2_EFFECT = 0.2
   local VANILLA_Q3_EFFECT = 0.25
   local VANILLA_NORMAL_NEXT_PROBABILITY = 0.1
   local VANILLA_DEFAULT_MULTIPLIER_BASE = 0.3
   local vanilla_bonus_by_label = {
      none = 0,
      ["4xQ1"] = 4 * VANILLA_Q1_EFFECT,
      ["4xQ2"] = 4 * VANILLA_Q2_EFFECT,
      ["4xQ3"] = 4 * VANILLA_Q3_EFFECT,
   }

   local scenarios = {}
   for _, scenario in ipairs(module_scenarios) do
      table.insert(scenarios, scenario)
   end
   if stage.max_level == 5 then
      local quality_scenarios = build_legendary_module_scenarios(runtime_values)
      for _, scenario in ipairs(quality_scenarios) do
         table.insert(scenarios, scenario)
      end
   end

   local function vanilla_bonus_for_label(label)
      local base = vanilla_bonus_by_label[label]
      if base ~= nil then
         return base
      end

      local q_tier, q_quality = label:match("^4xQ([123])([UREL]?)$")
      if q_tier == nil then
         return 0
      end

      local base_effect_by_tier = {
         ["1"] = VANILLA_Q1_EFFECT,
         ["2"] = VANILLA_Q2_EFFECT,
         ["3"] = VANILLA_Q3_EFFECT,
      }
      local module_quality_level_by_suffix = {
         [""] = 0,
         U = 1,
         R = 2,
         E = 3,
         L = 5,
      }

      local base_effect = base_effect_by_tier[q_tier]
      local module_quality_level = module_quality_level_by_suffix[q_quality or ""]
      if base_effect == nil or module_quality_level == nil then
         return 0
      end

      local quality_multiplier = 1 + (module_quality_level * VANILLA_DEFAULT_MULTIPLIER_BASE)
      local effective_tier_effect = quantize_quality_module_effect(base_effect * quality_multiplier)
      return 4 * effective_tier_effect
   end

   for i, scenario in ipairs(scenarios) do
      local distribution = M.compute_distribution({
         base_effect_quality = runtime_values.base_effect_quality,
         module_quality_bonus = scenario.bonus,
         slop_next_probability = runtime_values.slop_next_probability,
         fine_next_probability = runtime_values.fine_next_probability,
         uncommon_next_probability = runtime_values.uncommon_next_probability,
         rare_next_probability = runtime_values.rare_next_probability,
         epic_next_probability = runtime_values.epic_next_probability,
         max_level = stage.max_level,
      })

      local vanilla_module_bonus = vanilla_bonus_for_label(scenario.label)
      local vanilla_start_chance = clamp01((VANILLA_BASE_EFFECT + vanilla_module_bonus) * VANILLA_NORMAL_NEXT_PROBABILITY)
      local vanilla_distribution = make_vanilla_distribution(vanilla_start_chance, stage.max_level)

      local row = {
         scenario.label,
         format_percent_cell(distribution.normal, 5),
         format_percent_cell(distribution.fine, 2),
         format_relative_delta(distribution.fine, vanilla_distribution.normal),
         stage.max_level >= 3 and format_percent_cell(distribution.uncommon, 3) or "-",
         stage.max_level >= 3 and format_relative_delta(distribution.uncommon, vanilla_distribution.uncommon) or "-",
         stage.max_level >= 3 and format_percent_cell(distribution.rare, 4) or "-",
         stage.max_level >= 3 and format_relative_delta(distribution.rare, vanilla_distribution.rare) or "-",
         stage.max_level >= 4 and format_percent_cell(distribution.epic, 5) or "-",
         stage.max_level >= 4 and format_relative_delta(distribution.epic, vanilla_distribution.epic) or "-",
         stage.max_level >= 5 and format_percent_cell(distribution.legendary, 6) or "-",
         stage.max_level >= 5 and format_relative_delta(distribution.legendary, vanilla_distribution.legendary) or "-",
      }

      table.insert(rows, row)
   end

   return rows
end

function M.build_matrix_report_lines(runtime_values)
   local lines = {}

   table.insert(lines, "=== config ===")
   local config_lines = M.build_config_report_lines(runtime_values)
   for _, line in ipairs(config_lines) do
      table.insert(lines, line)
   end

   table.insert(lines, "")
   table.insert(lines, "=== matrix ===")
   local matrix_lines = M.build_prediction_matrix_lines(runtime_values)
   for _, line in ipairs(matrix_lines) do
      table.insert(lines, line)
   end

   table.insert(lines, "")
   table.insert(lines, "=== cap analysis ===")
   local cap_lines = M.build_module_cap_report_lines(runtime_values)
   for _, line in ipairs(cap_lines) do
      table.insert(lines, line)
   end

   return lines
end

function M.build_config_report_lines(runtime_values)
   local q1_ratio = runtime_values.q1_expected_effect ~= 0 and
       (runtime_values.q1_effect / runtime_values.q1_expected_effect) or 0
   local q2_ratio = runtime_values.q2_expected_effect ~= 0 and
       (runtime_values.q2_effect / runtime_values.q2_expected_effect) or 0
   local q3_ratio = runtime_values.q3_expected_effect ~= 0 and
       (runtime_values.q3_effect / runtime_values.q3_expected_effect) or 0

   return {
      "cfg: B=" .. format_fixed(runtime_values.base_effect_quality)
      .. "  P[s/f/u/r/e]="
      .. table.concat({
         format_fixed(runtime_values.slop_next_probability),
         format_fixed(runtime_values.fine_next_probability),
         format_fixed(runtime_values.uncommon_next_probability),
         format_fixed(runtime_values.rare_next_probability),
         format_fixed(runtime_values.epic_next_probability),
      }, "/")
      .. "  Q[1/2/3]="
      .. table.concat({
         format_fixed(runtime_values.q1_effect),
         format_fixed(runtime_values.q2_effect),
         format_fixed(runtime_values.q3_effect),
      }, "/"),
      "runtime scaler: scale/step/exp="
      .. table.concat({
         format_fixed(runtime_values.module_quality_scale),
         format_fixed(runtime_values.module_quality_base_step),
         format_fixed(runtime_values.module_quality_exponent),
      }, "/")
      .. "  quality-default-multiplier-base=" .. format_fixed(runtime_values.quality_default_multiplier_base),
      "meta-quality model: quality modules rounded down to 0.1%",
      "q-base[1/2/3]="
      .. table.concat({
         format_fixed(runtime_values.q1_base_effect),
         format_fixed(runtime_values.q2_base_effect),
         format_fixed(runtime_values.q3_base_effect),
      }, "/"),
      "q-expected[1/2/3]="
      .. table.concat({
         format_fixed(runtime_values.q1_expected_effect),
         format_fixed(runtime_values.q2_expected_effect),
         format_fixed(runtime_values.q3_expected_effect),
      }, "/"),
      "q-ratio actual/expected[1/2/3]="
      .. table.concat({
         format_fixed(q1_ratio),
         format_fixed(q2_ratio),
         format_fixed(q3_ratio),
      }, "/"),
      "matrix values are percentages; Δv* are relative vs vanilla (base_effect=0, vanilla P[n/u/r/e]=0.1; F↔vanilla N/slop)",
   }
end

function M.build_prediction_matrix_lines(runtime_values)
   local lines = {}

   local module_scenarios, research_stages = M.build_matrix_inputs(runtime_values)
   local headers = { "mod", "S", "F", "ΔvF", "U", "ΔvU", "R", "ΔvR", "E", "ΔvE", "L", "ΔvL" }
   local rows_by_stage = {}

   for _, stage in ipairs(research_stages) do
      local stage_rows = build_stage_matrix_rows(runtime_values, stage, module_scenarios)
      rows_by_stage[#rows_by_stage + 1] = {
         title = "[max=" .. tostring(stage.max_level) .. "] " .. stage.label,
         rows = stage_rows,
      }
   end

   for _, stage in ipairs(rows_by_stage) do
      table.insert(lines, stage.title)
      local table_lines = build_matrix_table_lines(headers, stage.rows)
      for _, line in ipairs(table_lines) do
         table.insert(lines, line)
      end
      table.insert(lines, "")
   end

   if lines[#lines] == "" then
      table.remove(lines)
   end

   return lines
end

local function compute_start_chance(runtime_values, module_tier_effect, module_quality_level)
   local quality_multiplier = 1 + (module_quality_level * runtime_values.quality_default_multiplier_base)
   local effective_tier_effect = quantize_quality_module_effect(module_tier_effect * quality_multiplier)
   local total_module_bonus = 4 * effective_tier_effect
   local combined = runtime_values.base_effect_quality + total_module_bonus
   return clamp01(combined * runtime_values.slop_next_probability), total_module_bonus
end

function M.build_module_cap_report_lines(runtime_values)
   local lines = {}

   local levels = runtime_values.sloptorio_quality_levels

   local tiers = {
      { name = "Q1", effect = runtime_values.q1_effect },
      { name = "Q2", effect = runtime_values.q2_effect },
      { name = "Q3", effect = runtime_values.q3_effect },
   }

   local epsilon = 0.000001
   local start_chance = {}
   local rows = {}
   for i, level in ipairs(levels) do
      start_chance[i] = {}
      local row = {
         level.name .. "(" .. tostring(level.level) .. ")",
      }

      local none_chance = clamp01(runtime_values.base_effect_quality * runtime_values.slop_next_probability)
      start_chance[i][0] = none_chance
      table.insert(row, format_percent_cell(none_chance))

      local tier_cells = {}
      for j, tier in ipairs(tiers) do
         local chance = compute_start_chance(runtime_values, tier.effect, level.level)
         start_chance[i][j] = chance
         tier_cells[j] = format_percent_cell(chance)
      end

      local gain_none_to_q1 = start_chance[i][1] - start_chance[i][0]
      local gain_q1_to_q2 = start_chance[i][2] - start_chance[i][1]
      local gain_q2_to_q3 = start_chance[i][3] - start_chance[i][2]

      table.insert(row, tier_cells[1])
      table.insert(row, format_delta_cell(gain_none_to_q1) .. ((gain_none_to_q1 <= epsilon) and "*" or ""))
      table.insert(row, tier_cells[2])
      table.insert(row, format_delta_cell(gain_q1_to_q2) .. ((gain_q1_to_q2 <= epsilon) and "*" or ""))
      table.insert(row, tier_cells[3])
      table.insert(row, format_delta_cell(gain_q2_to_q3) .. ((gain_q2_to_q3 <= epsilon) and "*" or ""))

      if i == 1 then
         table.insert(row, "-")
         table.insert(row, "-")
         table.insert(row, "-")
      else
         local previous_level = levels[i - 1]
         for j = 1, #tiers do
            local gain = start_chance[i][j] - start_chance[i - 1][j]
            local marker = ""
            if previous_level.level == level.level then
               marker = "="
            elseif gain <= epsilon then
               marker = "*"
            end
            table.insert(row, format_delta_cell(gain) .. marker)
         end
      end

      table.insert(rows, row)
   end

   local table_lines = build_matrix_table_lines({ "lvl", "none", "Q1", "Δn1", "Q2", "Δ12", "Q3", "Δ23", "ΔQ1", "ΔQ2", "ΔQ3" },
      rows)
   table.insert(lines,
      "bonus/level(default_multiplier)=" .. format_fixed(runtime_values.quality_default_multiplier_base)
      .. "  (quality modules rounded down to 0.1%; =same prototype level, *=capped)")
   for _, line in ipairs(table_lines) do
      table.insert(lines, line)
   end

   return lines
end

return M
