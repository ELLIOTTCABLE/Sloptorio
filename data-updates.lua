local shared = require("lib.shared").values
local vanilla_slop_quality_name = shared.vanilla_quality_levels[1].name

local effect_fields = {
   "default_multiplier",
   "inserter_speed_multiplier",
   "fluid_wagon_capacity_multiplier",
   "inventory_size_multiplier",
   "lab_research_speed_multiplier",
   "crafting_machine_speed_multiplier",
   "logistic_cell_charging_energy_multiplier",
   "tool_durability_multiplier",
   "accumulator_capacity_multiplier",
   "flying_robot_max_energy_multiplier",
}

local cost_fields = {
   "crafting_machine_energy_usage_multiplier",
   "beacon_power_usage_multiplier",
}

local baseline_fields = {
   "science_pack_drain_multiplier",
   "mining_drill_resource_drain_multiplier",
}

local function set_quality_fields(quality, field_names, value)
   for _, field_name in ipairs(field_names) do
      quality[field_name] = value
   end
end

local vanilla_fine_quality_icon = data.raw.quality[vanilla_slop_quality_name].icon
local slop_quality = data.raw.quality[vanilla_slop_quality_name]

slop_quality.icon = "__Sloptorio__/graphics/icons/quality-slop.png"
slop_quality.next = "fine"
slop_quality.draw_sprite_by_default = true
set_quality_fields(slop_quality, effect_fields, shared.quality_factors.effect)
set_quality_fields(slop_quality, cost_fields, shared.quality_factors.cost)
set_quality_fields(slop_quality, baseline_fields, shared.quality_factors.baseline)

local fine_quality = {
   type = "quality",
   name = "fine",
   level = 0,
   order = "e",
   next = "uncommon",
   next_probability = 0.1,
   subgroup = "qualities",
   icon = "__base__/graphics/icons/quality-normal.png",
   color = slop_quality.color,
   -- Temporarily disabling for dev; also, buggy: https://forums.factorio.com/viewtopic.php?p=690453
   -- draw_sprite_by_default = false
}

set_quality_fields(fine_quality, effect_fields, shared.quality_factors.baseline)
set_quality_fields(fine_quality, cost_fields, shared.quality_factors.baseline)
set_quality_fields(fine_quality, baseline_fields, shared.quality_factors.baseline)

data:extend({
   fine_quality,
   {
      type = "technology",
      name = shared.unlock_fine_technology_name,
      icon = "__quality__/graphics/technology/quality-module-1.png",
      icon_size = 256,
      effects = {
         {
            type = "unlock-quality",
            quality = "fine",
         },
      },
      prerequisites = {},
      unit = {
         count = 1,
         ingredients = {
            { "automation-science-pack", 1 },
         },
         time = 1,
      },
      hidden = true,
   },
})
