local quality_prediction = require("lib.quality_prediction")
local defaults = require("lib.tuning_defaults").values

local function scale_quality_effect(effect, base_step, exponent, scale)
   if effect <= 0 then
      return effect
   end

   local normalized_steps = effect / base_step
   local curved_steps = normalized_steps ^ exponent
   return base_step * curved_steps * scale
end

local function ensure_fine_unlocked()
   for _, force in pairs(game.forces) do
      local tech = force.technologies["sloptorio-unlock-fine"]
      if tech then
         tech.researched = true
      end
   end
end

local function report_line(message, player_index)
   log("[Sloptorio] " .. message)

   if player_index then
      local player = game.get_player(player_index)
      if player then
         player.print("[Sloptorio] " .. message)
         return
      end
   end

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
   local module_quality_scale = settings.startup["sloptorio-module-quality-scale"].value
   local module_quality_base_step = settings.startup["sloptorio-module-quality-base-step"].value
   local module_quality_exponent = settings.startup["sloptorio-module-quality-exponent"].value

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
      q1_base_effect = defaults.q1_base_effect,
      q2_base_effect = defaults.q2_base_effect,
      q3_base_effect = defaults.q3_base_effect,
      q1_expected_effect = scale_quality_effect(defaults.q1_base_effect, module_quality_base_step, module_quality_exponent, module_quality_scale),
      q2_expected_effect = scale_quality_effect(defaults.q2_base_effect, module_quality_base_step, module_quality_exponent, module_quality_scale),
      q3_expected_effect = scale_quality_effect(defaults.q3_base_effect, module_quality_base_step, module_quality_exponent, module_quality_scale),
      module_quality_scale = module_quality_scale,
      module_quality_base_step = module_quality_base_step,
      module_quality_exponent = module_quality_exponent,
      module_quality_per_level_bonus = settings.startup["sloptorio-module-quality-per-level-bonus"].value,
      quality_levels = quality_levels,
   }
end

local function report_lines(lines, player_index)
   for _, line in ipairs(lines) do
      report_line(line, player_index)
   end
end

local function report_quality_matrices(player_index)
   local runtime_values = read_runtime_values()

   report_lines(quality_prediction.build_matrix_report_lines(runtime_values), player_index)
end

local function report_quality_config(player_index)
   local runtime_values = read_runtime_values()
   report_lines(quality_prediction.build_config_report_lines(runtime_values), player_index)
end

local function report_quality_matrix(player_index)
   local runtime_values = read_runtime_values()
   report_lines(quality_prediction.build_prediction_matrix_lines(runtime_values), player_index)
end

local function report_quality_cap(player_index)
   local runtime_values = read_runtime_values()
   report_lines(quality_prediction.build_module_cap_report_lines(runtime_values), player_index)
end

local function handle_slop_command(command)
   local verb, topic = (command.parameter or ""):match("^(%S+)%s+(%S+)$")

   if verb == "debug" and topic == "config" then
      report_quality_config(command.player_index)
      return
   end

   if verb == "debug" and topic == "matrix" then
      report_quality_matrix(command.player_index)
      return
   end

   if verb == "debug" and topic == "cap" then
      report_quality_cap(command.player_index)
      return
   end

   report_line("usage: /slop debug [config|matrix|cap]", command.player_index)
end

local function register_slop_commands()
   commands.remove_command("slop")
   commands.add_command("slop", { "", "Usage: /slop debug [config|matrix|cap]" }, handle_slop_command)
end

local function initialize_sloptorio()
   ensure_fine_unlocked()
end

register_slop_commands()

script.on_init(initialize_sloptorio)
script.on_load(register_slop_commands)
script.on_configuration_changed(function()
   register_slop_commands()
   initialize_sloptorio()
end)
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
