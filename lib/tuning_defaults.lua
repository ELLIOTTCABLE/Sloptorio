local M = {}

M.values = {
   base_effect_quality = 3.75,
   normal_next_probability = 0.20,
   fine_next_probability = 0.10,
   uncommon_next_probability = 0.10,
   rare_next_probability = 0.10,
   epic_next_probability = 0.10,
   module_quality_scale = 0.2,
   module_quality_base_step = 0.01,
   module_quality_exponent = 1.25,
   quality_default_multiplier_base = 0.45,
   q1_base_effect = 0.1,
   q2_base_effect = 0.2,
   q3_base_effect = 0.25,
   quality_levels = {
      { name = "normal",    level = 0 },
      { name = "fine",      level = 0 },
      { name = "uncommon",  level = 1 },
      { name = "rare",      level = 2 },
      { name = "epic",      level = 3 },
      { name = "legendary", level = 5 },
   },
}

return M
