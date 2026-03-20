data:extend({
   {
      type = "quality",
      name = "fine",
      level = 0,
      color = data.raw.quality.uncommon.color,
      order = "e",
      next = "uncommon",
      next_probability = 0.1,
      subgroup = "qualities",
      icon = data.raw.quality.normal.icon,
      beacon_power_usage_multiplier = 1,
      mining_drill_resource_drain_multiplier = 1,
      science_pack_drain_multiplier = 1,
   },
   {
      type = "technology",
      name = "sloptorio-unlock-fine",
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
