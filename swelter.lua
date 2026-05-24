-- Swelter
-- live tape + heat-haze effect
--
--      E1 : dry/wet
--      K2 : next page
--  hold K3: bypass (A/B dry)
--  hold K1: E2/E3 reach rates

engine.name = "Swelter"

-- {param_id, display, controlspec, engine_command_name}
local PARAMS = {
  {"drywet",        "dry/wet",       controlspec.new(0, 1,   'lin', 0, 0.5),  "drywet"},
  {"trim",          "input trim",    controlspec.new(0, 2,   'lin', 0, 1.0),  "trim"},
  {"out_trim",      "output trim",   controlspec.new(0, 2,   'lin', 0, 1.0),  "out_trim"},
  {"drive",         "drive",         controlspec.new(0, 1,   'lin', 0, 0.0),  "drive"},
  {"wow",           "wow",           controlspec.new(0, 1,   'lin', 0, 0.0),  "wow"},
  {"wow_rate",      "wow rate",      controlspec.new(0.05, 2, 'exp', 0, 0.5), "wow_rate"},
  {"flutter",       "flutter",       controlspec.new(0, 1,   'lin', 0, 0.0),  "flutter"},
  {"flutter_rate",  "flutter rate",  controlspec.new(4, 14,  'lin', 0, 8.0),  "flutter_rate"},
  {"mirage",        "mirage mix",    controlspec.new(0, 1,   'lin', 0, 0.0),  "mirage"},
  {"mirage_detune", "mirage detune", controlspec.new(-25, 25,'lin', 0, 8.0),  "mirage_detune"},
  {"haze",          "haze",          controlspec.new(0, 1,   'lin', 0, 0.0),  "haze"},
  {"haze_rate",     "haze rate",     controlspec.new(0.1, 8, 'exp', 0, 2.0),  "haze_rate"},
  {"haze_turb",     "haze turbulence",controlspec.new(0, 1,  'lin', 0, 0.5),  "haze_turb"},
  {"dropout",       "dropout",       controlspec.new(0, 1,   'lin', 0, 0.0),  "dropout"},
  {"age",           "tape age",      controlspec.new(0, 1,   'lin', 0, 0.0),  "age"},
  {"hiss",          "hiss",          controlspec.new(0, 1,   'lin', 0, 0.0),  "hiss"},
}

local function add_params()
  params:add_separator("swelter")
  for _, p in ipairs(PARAMS) do
    local id, name, spec, cmd = p[1], p[2], p[3], p[4]
    params:add_control(id, name, spec)
    params:set_action(id, function(v) engine[cmd](v) end)
  end
end

function init()
  audio.level_monitor(0)
  add_params()
  params:bang()
  redraw()
end

function redraw()
  screen.clear()
  screen.level(4)
  screen.move(64, 36)
  screen.text_center("swelter")
  screen.update()
end
