-- Diagnostico de desempenho (C.DIAGNOSTICO em config.lua): uma vez por segundo, o FPS medido
-- pelo console (ui.stat(7)) e o uso do processador (ui.stat(1), firmware 0.6.8) vao para o log
-- do console (cabo USB, LOG_CONSOLE.bat) e, se ligado, para o rodape. No simulador, que nao tem ui.stat, usa o relogio do Lua (os.clock).
local Cores = require "cores"
local Tempo = require "tempo"

local D = {}

local relogio
do
  local ok, t = pcall(function() return os.clock() end)
  if ok and type(t) == "number" then relogio = os.clock end
end

D.relogio = relogio   -- nil no console (teste de desempenho: o simulador mede com ele)

function D.stat(n)
  if not ui.stat then return nil end
  local ok, v = pcall(ui.stat, n)
  if ok and type(v) == "number" then return v end
  return nil
end

D.quadros = 0
D.fps = nil          -- ultimo FPS medido (ui.stat(7) ou relogio)

local inicio_segundo, n = nil, 0
local texto = "MEDINDO..."
local rodape_x, rodape_w = (480 - (#texto * 6 + 3)) // 2, #texto * 6 + 3

function D.quadro()
  D.quadros = D.quadros + 1
  n = n + 1
  if n < 60 then return end
  local fps = D.stat(7)
  if not fps and relogio then
    local agora = relogio()
    if inicio_segundo then fps = n / (agora - inicio_segundo) end
    inicio_segundo = agora
  end
  n = 0
  D.fps = fps
  local cpu = D.stat(1)
  texto = (fps and string.format("FPS %.0f", fps) or "FPS ?") .. (cpu and string.format("  CPU %.0f%%", cpu) or "")
  rodape_w = #texto * 6 + 3
  rodape_x = (480 - rodape_w) // 2
  if D.ligado then
    local t = Jogo.tela
    local pista = t and t.corrida and t.corrida.pista.id or "-"
    print(string.format("RROCK FPS %s cpu=%s tela=%s pista=%s mem=%dKB quadro=%d passo=%.2f (%s) dframe=%s",
      fps and string.format("%.0f", fps) or "?", cpu and string.format("%.0f", cpu) or "?", Jogo.nome_tela or "?",
      pista, collectgarbage("count") // 1, D.quadros, Tempo.passo, Tempo.fonte, Tempo.media_frame and string.format("%.2f", Tempo.media_frame) or "?"))
  end
end

function D.desenhar()
  ui.camera()
  ui.clip()
  ui.rectfill(rodape_x, 262, rodape_x + rodape_w, 269, Cores.preto)
  ui.print(texto, rodape_x + 2, 262, Cores.branco)
end

return D
