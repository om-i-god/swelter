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
local haze_phase = 0
local haze_amt = 0
local amp_in = 0
local screen_metro

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
  local pa = poll.set("amp_in",   function(v) amp_in = v end)
  pa:start()
  local ph = poll.set("haze_mod", function(v) haze_amt = v end)
  ph:start()
  screen_metro = metro.init(function()
    haze_phase = haze_phase + 0.15
    redraw()
  end, 1/30)
  screen_metro:start()
  redraw()
end

local function draw_bar(x, label, id)
  if not id then return end
  local spec = params:lookup_param(id).controlspec
  local v = params:get(id)
  local norm = (v - spec.minval) / (spec.maxval - spec.minval)
  screen.level(15)
  screen.move(x, 30); screen.text(label)
  screen.level(4); screen.rect(x, 36, 40, 6); screen.stroke()
  screen.level(15); screen.rect(x, 36, math.floor(40 * util.clamp(norm, 0, 1)), 6); screen.fill()
end

function redraw()
  screen.clear()
  -- heat-haze field: faint scanlines whose horizontal offset wavers with
  -- modulation + input level
  local bend = 2 + (haze_amt * 10) + (amp_in * 12)
  screen.level(1)
  for y = 0, 63, 2 do
    local off = math.sin(haze_phase + (y * 0.3)) * bend
    for x = 0, 127, 6 do
      screen.pixel(math.floor((x + off) % 128), y)
    end
  end
  screen.fill()
  -- foreground readout: surfaces on activity, fades after 1.5 s
  if (util.time() - activity) < 1.5 then
    local p = PAGES[page]
    screen.level(15)
    screen.move(4, 10)
    screen.text(p.name .. (shift and " ·rate" or ""))
    local e2id = shift and p.e2s or p.e2
    local e3id = shift and p.e3s or p.e3
    draw_bar(4,  e2id or "—", e2id)
    draw_bar(70, e3id or "—", e3id)
    screen.level(8)
    screen.move(4, 60)
    screen.text("d/w " .. math.floor(params:get("drywet") * 100))
  end
  if bypass then
    screen.level(15); screen.move(124, 10); screen.text_right("DRY")
  end
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
