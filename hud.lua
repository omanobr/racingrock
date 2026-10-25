-- Painel da corrida (v0.26), nos 4 cantos:
--   em cima a esquerda: posicao grande (1o/4), volta e tempo; embaixo dele a ordem dos carros
--     (cor do carro, nome, vida; X = destruido)
--   em cima a direita: mapinha da pista (img/mapa/<id>) com os carros
--   embaixo a esquerda: vida e municao (barras de LEDs) e as minas
--   embaixo a direita: velocimetro (km/h e a rampa de LEDs: ate 80% e a velocidade normal do
--     carro, o resto so com turbo) e a carga do turbo
-- Barras (ideia do Felipe): a imagem da barra inteira (img/ui/barras) e um retangulo preto por
-- cima, a "mascara", cobrindo os LEDs apagados. (Com ui.clip tambem daria, mas cortar imagem de
-- lado e o que o console desenha errado na borda da tela; o retangulo e seguro.)
-- Os textos so sao montados quando o valor muda (string.format todo quadro pesa no console).
-- Os numeros grandes vem de img/ui/painel (so algarismos, ~9 KB): cada folha desenhada e lida
-- inteira do cartao naquele quadro, e as fontes f2 e f3 inteiras eram ~54 KB.
local C = require "config"
local Cores = require "cores"
local Texto = require "texto"
local D = require "dados_interface"
local Efx = require "dados_efeitos"

local Hud = {}

local rectfill, print_, tile = ui.rectfill, ui.print, ui.tile
local B = D.barras
local cache = {}
local CHAVE_ORDEM = { "ordem1", "ordem2", "ordem3", "ordem4", "ordem5", "ordem6", "ordem7", "ordem8" }
local COR_CARRO = { ver = Cores.vermelho, azu = Cores.azul, ama = Cores.amarelo, pra = Cores.cinza_claro }

local function texto(chave, valor, formato, ...)
  local c = cache[chave]
  if not c or c.valor ~= valor then
    c = { valor = valor, s = string.format(formato, ...) }
    cache[chave] = c
  end
  return c.s
end

local function painel(x, y, w, h, borda)
  rectfill(x, y, x + w - 1, y + h - 1, borda or Cores.cinza_escuro)
  rectfill(x + 1, y + 1, x + w - 2, y + h - 2, Cores.preto)
end

-- mascara de uma barra de 24 LEDs (100x7) desenhada em (x, y): cobre os LEDs apagados
local function mascara(x, y, fracao)
  local n = (fracao * 24 + 0.999) // 1
  if n < 0 then n = 0 end
  if n < 24 then rectfill(x + 2 + 4 * n, y + 1, x + 96, y + 5, Cores.preto) end
end

-- mensagem no meio da tela, em letra grande
local function aviso(s, borda)
  local w = Texto.largura("f3", s)
  painel(240 - w // 2 - 10, 52, w + 20, 33, borda or Cores.amarelo_escuro)
  Texto.escrever("f3", s, 240 - w // 2, 57, "amarelo")
end

local P = D.painel

-- n (inteiro >= 0) em algarismos pequenos do painel, a partir de x; devolve o x depois dele
local function numero(img, n, x, y)
  local d = 1
  while d * 10 <= n do d = d * 10 end
  repeat
    tile(img, P.f2 + n // d % 10, x, y)
    x = x + P.avanco
    d = d // 10
  until d == 0
  return x
end

-- n alinhado a direita (o ultimo algarismo termina em x_dir)
local function numero_dir(img, n, x_dir, y)
  local x = x_dir - P.avanco
  repeat
    tile(img, P.f2 + n % 10, x, y)
    n = n // 10
    x = x - P.avanco
  until n == 0
end

function Hud.desenhar(corrida)
  local j = corrida.jogador
  local ui_img = Sprites.img.ui
  local barras = ui_img.barras
  local efx = Sprites.img.efx.e16
  local carros = corrida.classificacao
  local n = #corrida.carros
  local m = corrida.mapa
  local mx = m and 472 - m.w

  -- Ordem pensada nas trocas de imagem: cada troca le a folha inteira do cartao, e o console
  -- aguenta umas 32 por quadro (pista + carros ja usam ate ~20). Primeiro os paineis
  -- (retangulos), depois cada folha de uma vez so, depois os retangulos e os textos.
  painel(4, 4, 100, 41)                       -- posicao, volta e tempo
  painel(4, 48, 100, 5 + 10 * #carros)        -- ordem dos carros
  if m then painel(mx - 2, 4, m.w + 4, m.h + 4) end
  painel(4, 219, 150, 49)                     -- vida, municao e minas
  painel(324, 219, 152, 49)                   -- velocimetro e turbo

  -- numeros (img/ui/painel): posicao, ordinal, volta e km/h
  local pn = ui_img.painel
  tile(pn, P.f3 + j.posicao % 10, 9, 10)
  tile(pn, P.ordinal, 25, 8)
  local volta = j.volta < 1 and 1 or (j.volta > corrida.voltas and corrida.voltas or j.volta)
  local x = numero(pn, volta, 50, 17)
  tile(pn, P.barra, x, 17)
  numero(pn, corrida.voltas, x + P.avanco, 17)
  local v = j.v > 0 and j.v or -j.v
  numero_dir(pn, (v * C.KMH) // 1, 410, 222)
  -- mapinha
  if m then ui.spr(m.img, mx, 6) end
  -- icones: conserto, municao, minas
  tile(efx, Efx.conserto[1], 8, 221)
  tile(efx, Efx.municao[1], 8, 236)
  for k = 1, j.minas do tile(efx, Efx.mina[1], 8 + (k - 1) * 16, 251) end
  -- barras (o tile tem 140 px de largura, mesmo nas de 100: o tile inteiro tem de caber na
  -- tela), as mascaras e o contorno da rampa do velocimetro, que a mascara apaga
  tile(barras, B.vida, 28, 226)
  tile(barras, B.municao, 28, 241)
  tile(barras, B.turbo, 330, 257)
  tile(barras, B.velocidade, 330, 239)
  mascara(28, 226, j.vida / C.VIDA)
  mascara(28, 241, j.municao / C.MUNICAO)
  mascara(330, 257, j.turbo_carga)
  local f = v / j.vmax
  local acesos
  if f <= 1 then
    acesos = (f * 27.2 + 0.5) // 1
  else
    acesos = 27 + ((f - 1) * 11.3 + 0.5) // 1
    if acesos > 34 then acesos = 34 end
  end
  if acesos < 34 then rectfill(332 + 4 * acesos, 240, 466, 250, Cores.preto) end
  tile(barras, B.velocidade_contorno, 330, 239)

  -- ordem dos carros (cor, nome, vida) e os carros no mapinha
  for i, c in ipairs(carros) do
    local y = 51 + 10 * (i - 1)
    rectfill(8, y + 1, 13, y + 6, COR_CARRO[c.cor] or Cores.cinza)
    if not c.destruido then
      local vida = c.vida
      local w = (vida * 0.2) // 1
      rectfill(80, y + 2, 99, y + 5, Cores.cinza_escuro)
      if w > 0 then rectfill(80, y + 2, 79 + w, y + 5, vida > 50 and Cores.verde or (vida > 25 and Cores.amarelo or Cores.vermelho)) end
    end
  end
  if m then
    local esc = m.escala
    for i = #carros, 1, -1 do
      local c = carros[i]
      if not c.destruido then
        local px, py = mx + 1 + (c.x * esc) // 1, 7 + (c.y * esc) // 1
        if c == j then
          rectfill(px - 2, py - 2, px + 2, py + 2, Cores.preto)
          rectfill(px - 1, py - 1, px + 1, py + 1, (corrida.quadros // 8) % 2 == 0 and Cores.branco or Cores.vermelho)
        else
          rectfill(px - 1, py - 1, px + 1, py + 1, COR_CARRO[c.cor] or Cores.cinza)
        end
      end
    end
  end

  -- textos pequenos
  print_(texto("de", n, "/%d", n), 27, 26, Cores.cinza_claro)
  print_("VOLTA", 50, 8, Cores.cinza)
  local decimos = (corrida.tempo * 10) // 1
  print_(texto("tempo", decimos, "%d:%02d.%d", decimos // 600, decimos // 10 % 60, decimos % 10), 50, 35,
    Cores.cinza_claro)
  for i, c in ipairs(carros) do
    local y = 51 + 10 * (i - 1)
    local cor = c.destruido and Cores.cinza or (c == j and Cores.amarelo or Cores.cinza_claro)
    print_(texto(CHAVE_ORDEM[i], c.nome, "%d %s", i, c.nome), 17, y, cor)
    if c.destruido then print_("X", 92, y, Cores.vermelho) end
  end
  if j.dinheiro > 0 then print_(texto("dinheiro", j.dinheiro, "$%d", j.dinheiro), 64, 256, Cores.verde) end
  print_("KM/H", 414, 230, Cores.cinza)
  print_("TURBO", 436, 257, j.turbo and j.turbo_carga > 0 and Cores.azul_claro or Cores.cinza)

  -- contagem, largada e chegada
  if corrida.estado == "contagem" then
    local k = corrida.contagem // 1 + 1
    aviso(texto("contagem", k, "%d", k))
  elseif corrida.tempo < 1 then
    aviso("VAI!", Cores.verde)
  elseif corrida.estado == "fim" then
    if j.destruido then
      aviso("DESTRU\xCDDO!", Cores.vermelho)
    else
      aviso(texto("chegada", j.posicao, "%d\xBA LUGAR!", j.posicao))
    end
  end
end

return Hud
