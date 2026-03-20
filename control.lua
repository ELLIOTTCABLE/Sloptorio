local quality_prediction = require("lib.quality_prediction")

local function ensure_fine_unlocked()
   for _, force in pairs(game.forces) do
      local tech = force.technologies["sloptorio-unlock-fine"]
      if tech then
         tech.researched = true
      end
   end
end

local function report_line(message)
   log("[Sloptorio] " .. message)
   game.print("[Sloptorio] " .. message)
end

local function read_runtime_values()
   local normal = prototypes.quality.normal
   local fine = prototypes.quality.fine
   local uncommon = prototypes.quality.uncommon
   local rare = prototypes.quality.rare
   local epic = prototypes.quality.epic

   local q1 = prototypes.item["quality-module"]
   local q2 = prototypes.item["quality-module-2"]
   local q3 = prototypes.item["quality-module-3"]

   local assembler = prototypes.entity["assembling-machine-1"]
   local base_effect = assembler and assembler.effect_receiver and assembler.effect_receiver.base_effect or nil

   local quality_levels = {
      { name = "normal", level = (normal and normal.level) or 0 },
      { name = "fine", level = (fine and fine.level) or 0 },
      { name = "uncommon", level = (uncommon and uncommon.level) or 1 },
      { name = "rare", level = (rare and rare.level) or 2 },
      { name = "epic", level = (epic and epic.level) or 3 },
   }
   local legendary = prototypes.quality.legendary
   table.insert(quality_levels, { name = "legendary", level = (legendary and legendary.level) or 5 })

   return {
      base_effect_quality = (base_effect and base_effect.quality) or 0,
      normal_next_probability = (normal and normal.next_probability) or 0,
      fine_next_probability = (fine and fine.next_probability) or 0,
      uncommon_next_probability = (uncommon and uncommon.next_probability) or 0,
      rare_next_probability = (rare and rare.next_probability) or 0,
      epic_next_probability = (epic and epic.next_probability) or 0,
      q1_effect = (q1 and q1.module_effects and q1.module_effects.quality) or 0,
      q2_effect = (q2 and q2.module_effects and q2.module_effects.quality) or 0,
      q3_effect = (q3 and q3.module_effects and q3.module_effects.quality) or 0,
      module_quality_per_level_bonus = settings.startup["sloptorio-module-quality-per-level-bonus"].value,
      quality_levels = quality_levels,
   }
end

local function report_quality_matrices()
   local runtime_values = read_runtime_values()

   local lines = quality_prediction.build_matrix_report_lines(runtime_values)
   for _, line in ipairs(lines) do
      report_line(line)
   end
end

local function initialize_sloptorio()
   ensure_fine_unlocked()
   report_quality_matrices()
end

script.on_init(initialize_sloptorio)
script.on_configuration_changed(initialize_sloptorio)
script.on_event(defines.events.on_force_created, function(event)
   local force = event.force
   if not force then
      return
   end
   local tech = force.technologies["sloptorio-unlock-fine"]
   if tech then
      tech.researched = true
   end
end)
