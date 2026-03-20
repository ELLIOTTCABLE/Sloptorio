data.raw.quality.normal.next = "fine"
data.raw.quality.normal.next_probability = 0.1
data.raw.quality.fine.next_probability = 0.1
data.raw.quality.uncommon.next_probability = 0.1
data.raw.quality.rare.next_probability = 0.1
data.raw.quality.epic.next_probability = 0.1

local MODULE_QUALITY_SCALE = 1.0
local MODULE_QUALITY_BASE_STEP = 0.01
local MODULE_QUALITY_EXPONENT = 1.25

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
      entity.effect_receiver.base_effect.quality = 7.5
   end
end
