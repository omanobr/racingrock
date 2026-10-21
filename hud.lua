-- Painel da corrida: volta, posicao, tempo, turbo, a ordem dos carros e a contagem da largada.
-- Os textos so sao montados quando o valor muda (string.format todo quadro pesa no console).
local Cores = require "cores"

local Hud = {}

local rectfill, print_ = ui.rectfill, ui.print
local cache = {}
local CHAVE_ORDEM = { "ordem1", "ordem2", "ordem3", "ordem4", "ordem5", "ordem6", "ordem7", "ordem8" }

local function texto(chave, valor, formato, ...)
  local c = cache[chave]
  if not c or c.valor ~= valor then
    c = { valor = valor, s = string.format(formato, ...) }
    cache[chave] = c
  end
  return c.s
end

local function caixa(x, y, w, h)
  rectfill(x, y, x + w - 1, y + h - 1, Cores.preto)
end

function Hud.desenhar(corrida)
  local j = corrida.jogador
  local volta = j.volta < 1 and 1 or (j.volta > corrida.voltas and corrida.voltas or j.volta)
  caixa(4, 4, 92, 30)
  print_(texto("volta", volta, "VOLTA %d/%d", volta, corrida.voltas), 8, 7, Cores.branco)
  print_(texto("pos", j.posicao, "POSICAO %d/%d", j.posicao, #corrida.carros), 8, 16, Cores.amarelo)
  local decimos = (corrida.tempo * 10) // 1
  print_(texto("tempo", decimos, "%d:%02d.%d", decimos // 600, decimos // 10 % 60, decimos % 10), 8, 25, Cores.cinza_claro)

  -- turbo
  caixa(384, 4, 92, 12)
  print_("TURBO", 388, 7, Cores.branco)
  local w = (j.turbo_carga * 50) // 1
  if w > 0 then rectfill(420, 7, 420 + w - 1, 12, j.turbo_carga > 0.25 and Cores.azul or Cores.vermelho) end

  -- ordem dos carros
  caixa(384, 20, 92, 4 + 9 * #corrida.classificacao)
  for i, c in ipairs(corrida.classificacao) do
    print_(texto(CHAVE_ORDEM[i], c.nome, "%d %s", i, c.nome), 388, 15 + 9 * i, c == j and Cores.amarelo or Cores.cinza_claro)
  end

  if corrida.estado == "contagem" then
    local n = corrida.contagem // 1 + 1
    caixa(222, 50, 36, 20)
    print_(texto("contagem", n, "%d", n), 237, 56, Cores.amarelo)
  elseif corrida.tempo < 1 then
    caixa(222, 50, 36, 20)
    print_("JA!", 231, 56, Cores.verde)
  elseif corrida.estado == "fim" then
    caixa(180, 50, 120, 20)
    print_(texto("chegada", j.posicao, "CHEGOU EM %do!", j.posicao), 196, 56, Cores.amarelo)
  end
end

return Hud
