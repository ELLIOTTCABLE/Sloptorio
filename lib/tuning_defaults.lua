local M = {}

M.values = {
   base_effect_quality = 7.5,
   normal_next_probability = 0.10,
   fine_next_probability = 0.10,
   uncommon_next_probability = 0.10,
   rare_next_probability = 0.10,
   epic_next_probability = 0.10,
   module_quality_scale = 1.0,
   module_quality_base_step = 0.01,
   module_quality_exponent = 1.25,
   module_quality_per_level_bonus = 0.30,
   q1_base_effect = 0.01,
   q2_base_effect = 0.02,
   q3_base_effect = 0.025,
   quality_levels = {
      { name = "normal", level = 0 },
      { name = "fine", level = 0 },
      { name = "uncommon", level = 1 },
      { name = "rare", level = 2 },
      { name = "epic", level = 3 },
      { name = "legendary", level = 5 },
   },
}

return M
