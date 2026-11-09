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

-- 2 jogadores (v0.40): a tela dividida em duas visoes de 480 x 134, uma em cima da outra (como
-- no GearX e no Top Gear), com 2 px pretos no meio. Cada visao desenha com ui.camera (desloca)
-- e ui.clip (corta em cima e embaixo: o corte de lado e o que o console desenha errado, e aqui
-- as visoes tem a largura inteira, com as faixas pretas dos lados como na tela de 1 jogador).
local ALTO_2 = 134

-- opcoes: as de Corrida.nova (pista, voltas, autopiloto, jogadores...) e demo
function Tela.nova(opcoes)
  local t = setmetatable({}, Tela)
  t.corrida = Corrida.nova(opcoes or {})
  t.rastros = Rastros.novo()
  t.demo = opcoes and opcoes.demo
  local r = t.corrida
  local alto = #r.jogadores == 1 and 270 or ALTO_2
  t.vistas = {}
  for k, j in ipairs(r.jogadores) do
    t.vistas[k] = { carro = j, oy = (k - 1) * (ALTO_2 + 2), alto = alto, camera = Camera.nova(r.pista, j, alto) }
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
-- cortado pela borda; a faixa preta esconde. alto: altura da visao.
local function desenhar_carros(self, r, x0, y0, alto)
  local tile, carros, folha, tiles = ui.tile, r.carros, self.folha, self.tiles
  local meio, desloca, sombra = Carro.MEIO_QUADRO, Carro.SOMBRA_DESLOCA, self.sombra
  local limite = TELA_W - 2 * meio - 3
  for i = 1, #carros do
    local c = carros[i]
    local sx, sy = (c.x - x0) // 1 - meio, (c.y - y0) // 1 - meio
    if sx >= 0 and sx <= limite and sy > -2 * meio and sy < alto then
      local f, t = c:quadro()
      folha[i], tiles[i] = f, t
      tile(sombra, c:quadro_sombra(), sx + desloca, sy + desloca)
    else
      folha[i] = false
    end
  end
  for i = 1, #carros do
    local f = folha[i]
    if f then
      local c = carros[i]
      tile(f == 1 and c.img or c.img2, tiles[i], (c.x - x0) // 1 - meio, (c.y - y0) // 1 - meio)
    end
  end
end

-- a pista e o que anda nela, numa visao (com 2 jogadores, ja com o ui.camera e o ui.clip dela)
local function desenhar_vista(self, r, v)
  local sem, cam = Tela.sem, v.camera
  local x0, y0 = cam.x0, cam.y0
  if not sem.pista then Fundo.desenhar(r.pista, x0, y0, v.alto) end
  if not sem.efeitos then
    self.rastros:desenhar(x0, y0)
    r.combate:desenhar_chao(x0, y0, r.quadros)
  end
  if not sem.carros then desenhar_carros(self, r, x0, y0, v.alto) end
  if not sem.efeitos then r.combate:desenhar_cima(x0, y0, r.quadros, Cores.amarelo) end
end

function Tela:desenhar()
  local r, vistas = self.corrida, self.vistas
  if #vistas == 1 then
    desenhar_vista(self, r, vistas[1])
  else
    for _, v in ipairs(vistas) do
      ui.camera(0, -v.oy)
      ui.clip(0, v.oy, TELA_W, v.alto)
      desenhar_vista(self, r, v)
    end
    ui.camera()
    ui.clip()
    ui.rectfill(0, ALTO_2, TELA_W - 1, ALTO_2 + 1, Cores.preto)
  end

  -- faixas pretas nos lados: cobrem o vao das colunas de tiles que nao cabem inteiras
  local m = Fundo.MARGEM
  ui.rectfill(0, 0, m - 1, 269, Cores.preto)
  ui.rectfill(TELA_W - m, 0, TELA_W - 1, 269, Cores.preto)

  if not Tela.sem.painel then Hud.desenhar(r, vistas) end
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
