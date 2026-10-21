-- Painel da corrida: volta, posicao, tempo, barras de turbo, vida e municao, minas, a ordem dos
-- carros (X = destruido) e as mensagens (contagem, chegada, destruido).
-- Os textos so sao montados quando o valor muda (string.format todo quadro pesa no console).
local C = require "config"
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

-- barra de 50 px (fracao de 0 a 1) com o rotulo na frente
local function barra(rotulo, y, fracao, cor)
  print_(rotulo, 388, y, Cores.branco)
  if fracao > 1 then fracao = 1 end
  rectfill(420, y + 1, 469, y + 5, Cores.cinza_escuro)
  local w = (fracao * 50) // 1
  if w > 0 then rectfill(420, y + 1, 420 + w - 1, y + 5, cor) end
end

function Hud.desenhar(corrida)
  local j = corrida.jogador
  local volta = j.volta < 1 and 1 or (j.volta > corrida.voltas and corrida.voltas or j.volta)
  caixa(4, 4, 92, 30)
  print_(texto("volta", volta, "VOLTA %d/%d", volta, corrida.voltas), 8, 7, Cores.branco)
  print_(texto("pos", j.posicao, "POSICAO %d/%d", j.posicao, #corrida.carros), 8, 16, Cores.amarelo)
  local decimos = (corrida.tempo * 10) // 1
  print_(texto("tempo", decimos, "%d:%02d.%d", decimos // 600, decimos // 10 % 60, decimos % 10), 8, 25, Cores.cinza_claro)

  -- turbo, vida, municao, minas e dinheiro
  caixa(384, 4, 92, 42)
  barra("TURBO", 6, j.turbo_carga, j.turbo_carga > 0.25 and Cores.azul or Cores.vermelho)
  barra("VIDA", 15, j.vida / C.VIDA, j.vida > 50 and Cores.verde or (j.vida > 25 and Cores.amarelo or Cores.vermelho))
  barra("BALA", 24, j.municao / C.MUNICAO, Cores.amarelo)
  print_(texto("minas", j.minas, "MINAS %d", j.minas), 388, 35, Cores.branco)
  if j.dinheiro > 0 then print_(texto("dinheiro", j.dinheiro, "$%d", j.dinheiro), 436, 35, Cores.verde) end

  -- ordem dos carros
  caixa(384, 50, 92, 4 + 9 * #corrida.classificacao)
  for i, c in ipairs(corrida.classificacao) do
    local cor = c.destruido and Cores.vermelho or (c == j and Cores.amarelo or Cores.cinza_claro)
    local valor = c.destruido and c.nome .. "X" or c.nome
    print_(texto(CHAVE_ORDEM[i], valor, c.destruido and "%d %s X" or "%d %s", i, c.nome), 388, 45 + 9 * i, cor)
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
    if j.destruido then
      print_("DESTRUIDO!", 210, 56, Cores.vermelho)
    else
      print_(texto("chegada", j.posicao, "CHEGOU EM %do!", j.posicao), 196, 56, Cores.amarelo)
    end
  end
end

return Hud
