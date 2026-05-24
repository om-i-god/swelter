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

-- e2/e3 = depth macros; e2s/e3s = the rate params reached by holding K1
local PAGES = {
  {name="REFRACTION",   e2="wow",     e3="flutter",  e2s="wow_rate",  e3s="flutter_rate"},
  {name="HAZE/MIRAGE",  e2="haze",    e3="mirage",   e2s="haze_rate", e3s="mirage_detune"},
  {name="TAPE",         e2="drive",   e3="age",      e2s="hiss",      e3s=nil},
  {name="WEAR",         e2="dropout", e3="out_trim", e2s=nil,         e3s=nil},
}
local page = 1
local shift = false
local bypass = false
local activity = 0

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

function enc(n, d)
  activity = util.time()
  if n == 1 then
    params:delta("drywet", d)
  else
    local p = PAGES[page]
    local id
    if n == 2 then id = shift and p.e2s or p.e2
    else            id = shift and p.e3s or p.e3 end
    if id then params:delta(id, d) end
  end
  redraw()
end

function key(n, z)
  activity = util.time()
  if n == 1 then
    shift = (z == 1)
  elseif n == 2 then
    if z == 1 then page = (page % #PAGES) + 1 end
  elseif n == 3 then
    bypass = (z == 1)
    engine.drywet(bypass and 0 or params:get("drywet"))
  end
  redraw()
end
