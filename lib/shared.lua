local M = {}

local values = {
   q1_base_effect = 0.1,
   q2_base_effect = 0.2,
   q3_base_effect = 0.25,

   unlock_fine_technology_name = "sloptorio-unlock-fine",

   vanilla_quality_levels = {
      -- Vanilla calls level-0 quality "normal"; this project treats it as slop in gameplay language,
      -- so all direct API prototype-name lookups must go through these constants.
      { name = "normal",    level = 0 },
      { name = "uncommon",  level = 1 },
      { name = "rare",      level = 2 },
      { name = "epic",      level = 3 },
      { name = "legendary", level = 5 },
   },

   sloptorio_quality_levels = {
      { name = "slop",      level = 0 },
      { name = "fine",      level = 0 },
      { name = "uncommon",  level = 1 },
      { name = "rare",      level = 2 },
      { name = "epic",      level = 3 },
      { name = "legendary", level = 5 },
   }
}

M.values = values

return M
