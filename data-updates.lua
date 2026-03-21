local shared = require("lib.shared").values
local vanilla_slop_quality_name = shared.vanilla_quality_levels[1].name

data:extend({
   {
      type = "quality",
      name = "fine",
      level = 0,
      order = "e",
      next = "uncommon",
      next_probability = 0.1,
      subgroup = "qualities",
      beacon_power_usage_multiplier = 1,
      mining_drill_resource_drain_multiplier = 1,
      science_pack_drain_multiplier = 1,
      icon = data.raw.quality[vanilla_slop_quality_name].icon,
      color = data.raw.quality[vanilla_slop_quality_name].color,
   },
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
