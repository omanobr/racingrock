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

-- opcoes: { pista, voltas, autopiloto }
function Tela.nova(opcoes)
  local t = setmetatable({}, Tela)
  t.corrida = Corrida.nova(opcoes or {})
  t.rastros = Rastros.novo()
  t.demo = opcoes and opcoes.demo
  t.camera = Camera.nova(t.corrida.pista, t.corrida.jogador)
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
  self.camera:atualizar(Tempo.passo)
  if r.estado == "fim" and r.tempo - r.fim_em > 3 then
    if self.demo then Jogo.ir("titulo") else Jogo.ir("resultado", r) end
  end
end

-- sombras (todas da mesma folha: uma carga so) e depois os carros (cada modelo tem 2 folhas:
-- as direcoes estao divididas entre elas). Carro (com a sombra, 3 px para a direita) que nao
-- cabe inteiro na largura da tela nao e desenhado: o console desenha errado o que fica
-- cortado pela borda; a faixa preta esconde.
local function desenhar_carros(self, r, x0, y0)
  local tile, carros, folha, tiles = ui.tile, r.carros, self.folha, self.tiles
  local meio, desloca, sombra = Carro.MEIO_QUADRO, Carro.SOMBRA_DESLOCA, self.sombra
  local limite = TELA_W - 2 * meio - 3
  for i = 1, #carros do
    local c = carros[i]
    local sx, sy = (c.x - x0) // 1 - meio, (c.y - y0) // 1 - meio
    if sx >= 0 and sx <= limite and sy > -2 * meio and sy < 270 then
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

function Tela:desenhar()
  local r, cam, sem = self.corrida, self.camera, Tela.sem
  local x0, y0 = cam.x0, cam.y0
  if not sem.pista then Fundo.desenhar(r.pista, x0, y0) end
  if not sem.efeitos then
    self.rastros:desenhar(x0, y0)
    r.combate:desenhar_chao(x0, y0, r.quadros)
  end
  if not sem.carros then desenhar_carros(self, r, x0, y0) end
  if not sem.efeitos then r.combate:desenhar_cima(x0, y0, r.quadros, Cores.amarelo) end

  -- faixas pretas nos lados: cobrem o vao das colunas de tiles que nao cabem inteiras
  local m = Fundo.MARGEM
  ui.rectfill(0, 0, m - 1, 269, Cores.preto)
  ui.rectfill(TELA_W - m, 0, TELA_W - 1, 269, Cores.preto)

  if not sem.painel then Hud.desenhar(r) end
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
