#!/usr/bin/env lua

package.path = table.concat({
   "./?.lua",
   "./?/init.lua",
   package.path,
}, ";")

local quality_prediction = require("lib.quality_prediction")

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
      baseEffectQuality = num("baseEffectQuality", 7.5),
      normalNextProbability = num("normalNextProbability", 0.10),
      fineNextProbability = num("fineNextProbability", 0.10),
      uncommonNextProbability = num("uncommonNextProbability", 0.10),
      rareNextProbability = num("rareNextProbability", 0.10),
      epicNextProbability = num("epicNextProbability", 0.10),
      q1Effect = num("q1Effect", 0.01),
      q2Effect = num("q2Effect", 0.02),
      q3Effect = num("q3Effect", 0.025),
      moduleQualityPerLevelBonus = num("moduleQualityPerLevelBonus", 0.30),
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
      quality_levels = {
         { name = "normal", level = 0 },
         { name = "fine", level = 0 },
         { name = "uncommon", level = 1 },
         { name = "rare", level = 2 },
         { name = "epic", level = 3 },
         { name = "legendary", level = 5 },
      },
   }

   local lines = quality_prediction.build_matrix_report_lines(runtime_values)
   for _, line in ipairs(lines) do
      print(line)
   end
end

main()
