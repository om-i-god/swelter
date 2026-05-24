-- Swelter
-- live tape + heat-haze effect
--
--      E1 : dry/wet
--      K2 : next page
--  hold K3: bypass (A/B dry)
--  hold K1: E2/E3 reach rates

engine.name = "Swelter"

function init()
  audio.level_monitor(0)   -- engine is the sole path input reaches output
  redraw()
end

function redraw()
  screen.clear()
  screen.level(4)
  screen.move(64, 36)
  screen.text_center("swelter")
  screen.update()
end
