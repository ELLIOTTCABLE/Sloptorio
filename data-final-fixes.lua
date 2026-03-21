local shared = require("lib.shared").values
local vanilla_slop_quality_name = shared.vanilla_quality_levels[1].name

local function startup_double(name)
   return tonumber(settings.startup[name].value) or 0
end

data.raw.quality[vanilla_slop_quality_name].next = "fine"
data.raw.quality[vanilla_slop_quality_name].next_probability = startup_double("sloptorio-normal-next-probability")
data.raw.quality.fine.next_probability = startup_double("sloptorio-fine-next-probability")
data.raw.quality.uncommon.next_probability = startup_double("sloptorio-uncommon-next-probability")
data.raw.quality.rare.next_probability = startup_double("sloptorio-rare-next-probability")
data.raw.quality.epic.next_probability = startup_double("sloptorio-epic-next-probability")

local MODULE_QUALITY_SCALE = startup_double("sloptorio-module-quality-scale")
local MODULE_QUALITY_BASE_STEP = startup_double("sloptorio-module-quality-base-step")
local MODULE_QUALITY_EXPONENT = startup_double("sloptorio-module-quality-exponent")
local QUALITY_DEFAULT_MULTIPLIER_BASE = startup_double("sloptorio-quality-default-multiplier-base")

for _, quality in pairs(data.raw.quality) do
   quality.default_multiplier = 1 + QUALITY_DEFAULT_MULTIPLIER_BASE * (quality.level or 0)
end

local function scale_quality_effect(effect)
   if effect <= 0 then
      return effect
   end

   local normalized_steps = effect / MODULE_QUALITY_BASE_STEP
   local curved_steps = normalized_steps ^ MODULE_QUALITY_EXPONENT
   return MODULE_QUALITY_BASE_STEP * curved_steps * MODULE_QUALITY_SCALE
end

for _, module in pairs(data.raw.module) do
   if module.effect and module.effect.quality then
      module.effect.quality = scale_quality_effect(module.effect.quality)
   end
end

for _, type in pairs({
   "assembling-machine",
   "rocket-silo",
   "lab",
}) do
   for _, entity in pairs(data.raw[type]) do
      if not entity.effect_receiver then
         entity.effect_receiver = {}
      end
      if not entity.effect_receiver.base_effect then
         entity.effect_receiver.base_effect = {}
      end
      entity.effect_receiver.base_effect.quality = startup_double("sloptorio-base-effect-quality")
   end
end
