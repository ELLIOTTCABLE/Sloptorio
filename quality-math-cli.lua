#!/usr/bin/env lua

package.path = table.concat({
   "./?.lua",
   "./?/init.lua",
   package.path,
}, ";")

local quality_prediction = require("lib.quality_prediction")
local defaults = require("lib.tuning_defaults").values

local function scale_quality_effect(effect)
   if effect <= 0 then
      return effect
   end

   local normalized_steps = effect / defaults.module_quality_base_step
   local curved_steps = normalized_steps ^ defaults.module_quality_exponent
   return defaults.module_quality_base_step * curved_steps * defaults.module_quality_scale
end

local function clamp01(x)
   if x < 0 then
      return 0
   end
   if x > 1 then
      return 1
   end
   return x
end

local function parse_args(argv)
   local args = {}

   for _, token in ipairs(argv) do
      local key, value = token:match("^%-%-(.-)=(.*)$")
      if key then
         args[key] = value
      else
         local bare = token:match("^%-%-(.+)$")
         if bare then
            args[bare] = true
         end
      end
   end

   local function num(key, fallback)
      local raw = args[key]
      if raw == nil then
         return fallback
      end
      local parsed = tonumber(raw)
      if parsed == nil then
         error("Invalid numeric value for --" .. key .. ": " .. tostring(raw))
      end
      return parsed
   end

   local cfg = {
      baseEffectQuality = num("baseEffectQuality", defaults.base_effect_quality),
      normalNextProbability = num("normalNextProbability", defaults.normal_next_probability),
      fineNextProbability = num("fineNextProbability", defaults.fine_next_probability),
      uncommonNextProbability = num("uncommonNextProbability", defaults.uncommon_next_probability),
      rareNextProbability = num("rareNextProbability", defaults.rare_next_probability),
      epicNextProbability = num("epicNextProbability", defaults.epic_next_probability),
      q1Effect = num("q1Effect", scale_quality_effect(defaults.q1_base_effect)),
      q2Effect = num("q2Effect", scale_quality_effect(defaults.q2_base_effect)),
      q3Effect = num("q3Effect", scale_quality_effect(defaults.q3_base_effect)),
      moduleQualityPerLevelBonus = num("moduleQualityPerLevelBonus", defaults.module_quality_per_level_bonus),
      targetNormal = args.targetNormal and num("targetNormal", 0.25) or nil,
   }

   return cfg
end

local function main()
   local cfg = parse_args(arg)

   if cfg.targetNormal ~= nil then
      local target_start_chance = clamp01(1 - cfg.targetNormal)
      local denom = clamp01(cfg.normalNextProbability)
      cfg.baseEffectQuality = denom > 0 and (target_start_chance / denom) or 0
   end

   local runtime_values = {
      base_effect_quality = cfg.baseEffectQuality,
      normal_next_probability = cfg.normalNextProbability,
      fine_next_probability = cfg.fineNextProbability,
      uncommon_next_probability = cfg.uncommonNextProbability,
      rare_next_probability = cfg.rareNextProbability,
      epic_next_probability = cfg.epicNextProbability,
      q1_effect = cfg.q1Effect,
      q2_effect = cfg.q2Effect,
      q3_effect = cfg.q3Effect,
      module_quality_per_level_bonus = cfg.moduleQualityPerLevelBonus,
      quality_levels = defaults.quality_levels,
   }

   local lines = quality_prediction.build_matrix_report_lines(runtime_values)
   for _, line in ipairs(lines) do
      print(line)
   end
end

main()
