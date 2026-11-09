-- Tela da corrida: atualiza as regras (corrida.lua) e desenha pista, carros e painel.
local Corrida = require "corrida"
local Camera = require "camera"
local Fundo = require "fundo"
local Hud = require "hud"
local Tempo = require "tempo"
local Entrada = require "entrada"
local Cores = require "cores"
local Carro = require "carro"
local Texto = require "texto"
local Rastros = require "rastros"

local Tela = {}
Tela.__index = Tela

local TELA_W = 480

-- partes do desenho desligadas pelo teste de desempenho (telas/desempenho.lua): pista, efeitos
-- (rastros, minas, itens, tiros), carros, painel
Tela.sem = {}

-- 2 jogadores (v0.41): a tela dividida lado a lado, cada um com 240 px (como o carro anda para
-- todos os lados, enxergar 104 px para os lados e 135 para cima e para baixo e melhor que os
-- 67 px para cima e para baixo da divisao em cima/embaixo da v0.40). Sem ui.clip: como nas bordas
-- da tela, cada metade so desenha imagens que cabem inteiras entre xa e xb, e o que passa da
-- metade fica embaixo das faixas pretas (a do meio tem 32 px: 224 a 255). Sem o ui.clip (que
-- quebra o lote), a sombra e cada carro saem para as duas metades numa leitura do cartao so, e
-- as folhas da pista que aparecem nas duas tambem (fundo.lua).
-- Cada visao: carro, ox (onde comeca na tela), largo, camera e, a cada quadro, cx/cy (a tela
-- mostra o ponto (x, y) do mundo em (x - cx, y - cy)); xa/xb: onde cabem imagens; va/vb: o que
-- fica visivel (entre as faixas pretas).
local function vista(carro, pista, ox, largo, xa, xb, va, vb)
  return { carro = carro, ox = ox, largo = largo, camera = Camera.nova(pista, carro, largo),
           xa = xa, xb = xb, va = va, vb = vb }
end

-- opcoes: as de Corrida.nova (pista, voltas, autopiloto, jogadores...) e demo
function Tela.nova(opcoes)
  local t = setmetatable({}, Tela)
  t.corrida = Corrida.nova(opcoes or {})
  t.rastros = Rastros.novo()
  t.demo = opcoes and opcoes.demo
  local r, m = t.corrida, Fundo.MARGEM
  if #r.jogadores == 1 then
    t.vistas = { vista(r.jogador, r.pista, 0, TELA_W, 0, TELA_W, m, TELA_W - m - 1) }
  else
    t.vistas = { vista(r.jogadores[1], r.pista, 0, 240, 0, 240 + m, m, 240 - m - 1),
                 vista(r.jogadores[2], r.pista, 240, 240, 240 - m, TELA_W, 240 + m, TELA_W - m - 1) }
  end
  t.camera = t.vistas[1].camera
  t.folha, t.tiles = {}, {}
  t.sombra = Sprites.img.car.sombra
  t.pausa = false
  return t
end

function Tela:atualizar()
  -- demonstracao (o titulo parado ou DEMONSTRACAO no menu): qualquer botao volta ao titulo
  if self.demo and (Entrada.confirmar() or Entrada.voltar() or Entrada.pausar()) then
    Jogo.ir("titulo")
    return
  end
  if Entrada.pausar() then self.pausa = not self.pausa end
  if self.pausa then
    -- sair no meio: no modo historia volta para a garagem sem mudar nada (como se a corrida
    -- nao tivesse acontecido)
    if Entrada.voltar() then Jogo.ir(self.corrida.campeonato and "garagem" or "titulo") end
    return
  end
  local r = self.corrida
  r:atualizar(Tempo.passo)
  if r.estado ~= "contagem" then self.rastros:atualizar(r, Tempo.passo / 60) end
  for _, v in ipairs(self.vistas) do v.camera:atualizar(Tempo.passo) end
  if r.estado == "fim" and r.tempo - r.fim_em > 3 then
    if self.demo then Jogo.ir("titulo") else Jogo.ir("resultado", r) end
  end
end

-- sombras (todas da mesma folha: uma carga so) e depois os carros (cada modelo tem 2 folhas:
-- as direcoes estao divididas entre elas). Carro (com a sombra, 3 px para a direita) que nao
-- cabe inteiro na largura da tela nao e desenhado: o console desenha errado o que fica
-- cortado pela borda; a faixa preta esconde. Com 2 jogadores, as sombras das duas metades e
-- depois cada carro nas duas (a mesma folha seguida: uma leitura so).
local function desenhar_carros(self, r, vistas)
  local tile, carros, folha, tiles = ui.tile, r.carros, self.folha, self.tiles
  local meio, desloca, sombra = Carro.MEIO_QUADRO, Carro.SOMBRA_DESLOCA, self.sombra
  local n = #carros
  for k = 1, #vistas do
    local v = vistas[k]
    local x0, y0, xa, limite = v.cx, v.cy, v.xa, v.xb - 2 * meio - 3
    for i = 1, n do
      local c = carros[i]
      local q = (k - 1) * n + i
      local sx, sy = (c.x - x0) // 1 - meio, (c.y - y0) // 1 - meio
      if sx >= xa and sx <= limite and sy > -2 * meio and sy < 270 then
        local f, t = c:quadro()
        folha[q], tiles[q] = f, t
        tile(sombra, c:quadro_sombra(), sx + desloca, sy + desloca)
      else
        folha[q] = false
      end
    end
  end
  for i = 1, n do
    local c = carros[i]
    for k = 1, #vistas do
      local q = (k - 1) * n + i
      local f = folha[q]
      if f then
        local v = vistas[k]
        tile(f == 1 and c.img or c.img2, tiles[q], (c.x - v.cx) // 1 - meio, (c.y - v.cy) // 1 - meio)
      end
    end
  end
end

function Tela:desenhar()
  local r, vistas, sem = self.corrida, self.vistas, Tela.sem
  local nv = #vistas
  for k = 1, nv do
    local v = vistas[k]
    v.cx, v.cy = v.camera.x0 - v.ox, v.camera.y0
  end
  if not sem.pista then
    if nv == 1 then Fundo.desenhar(r.pista, vistas[1].cx, vistas[1].cy) else Fundo.desenhar_vistas(r.pista, vistas) end
  end
  if not sem.efeitos then
    for k = 1, nv do
      local v = vistas[k]
      self.rastros:desenhar(v.cx, v.cy, v.va, v.vb)
    end
    for k = 1, nv do
      local v = vistas[k]
      r.combate:desenhar_chao(v.cx, v.cy, r.quadros, v)
    end
  end
  if not sem.carros then desenhar_carros(self, r, vistas) end
  if not sem.efeitos then
    for k = 1, nv do
      local v = vistas[k]
      r.combate:desenhar_cima(v.cx, v.cy, r.quadros, Cores.amarelo, v)
    end
  end

  -- faixas pretas nos lados (e no meio, com 2 jogadores): cobrem o vao das colunas de tiles que
  -- nao cabem inteiras
  local m = Fundo.MARGEM
  ui.rectfill(0, 0, m - 1, 269, Cores.preto)
  ui.rectfill(TELA_W - m, 0, TELA_W - 1, 269, Cores.preto)
  if nv > 1 then ui.rectfill(240 - m, 0, 240 + m - 1, 269, Cores.preto) end

  if not sem.painel then
    if nv == 1 then Hud.desenhar(r) else Hud.desenhar_dois(r, vistas) end
  end
  if self.demo and (r.quadros // 30) % 2 == 0 then
    local s = "DEMONSTRAÇÃO - APERTE START"
    local w = Texto.largura("f2", s)
    ui.rectfill(240 - w // 2 - 8, 196, 240 + w // 2 + 7, 215, Cores.preto)
    Texto.escrever("f2", s, 240 - w // 2, 199, "amarelo")
  end
  if self.pausa then
    ui.rectfill(164, 104, 315, 155, Cores.amarelo_escuro)
    ui.rectfill(165, 105, 314, 154, Cores.preto)
    Texto.centro("f3", "PAUSA", 110, "amarelo")
    local s = Entrada.NOME.pausa .. " CONTINUA  " .. Entrada.NOME.voltar .. " SAI"
    ui.print(s, 240 - #s * 3, 140, Cores.branco)
  end
end

return Tela
