local M = {}

M.values = {
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
