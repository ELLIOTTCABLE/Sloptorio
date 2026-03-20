data.raw.quality.normal.next = "fine"
data.raw.quality.normal.next_probability = settings.startup["sloptorio-normal-next-probability"].value
data.raw.quality.fine.next_probability = settings.startup["sloptorio-fine-next-probability"].value
data.raw.quality.uncommon.next_probability = settings.startup["sloptorio-uncommon-next-probability"].value
data.raw.quality.rare.next_probability = settings.startup["sloptorio-rare-next-probability"].value
data.raw.quality.epic.next_probability = settings.startup["sloptorio-epic-next-probability"].value

local MODULE_QUALITY_SCALE = settings.startup["sloptorio-module-quality-scale"].value
local MODULE_QUALITY_BASE_STEP = settings.startup["sloptorio-module-quality-base-step"].value
local MODULE_QUALITY_EXPONENT = settings.startup["sloptorio-module-quality-exponent"].value
local QUALITY_DEFAULT_MULTIPLIER_BASE = settings.startup["sloptorio-quality-default-multiplier-base"].value

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
      entity.effect_receiver.base_effect.quality = settings.startup["sloptorio-base-effect-quality"].value
   end
end
