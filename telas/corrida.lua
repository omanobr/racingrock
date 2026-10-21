-- Tela da corrida: atualiza as regras (corrida.lua) e desenha pista, carros e painel.
local Corrida = require "corrida"
local Camera = require "camera"
local Fundo = require "fundo"
local Hud = require "hud"
local Tempo = require "tempo"
local Entrada = require "entrada"
local Cores = require "cores"
local Carro = require "carro"

local Tela = {}
Tela.__index = Tela

local TELA_W = 480

-- opcoes: { pista, voltas, autopiloto }
function Tela.nova(opcoes)
  local t = setmetatable({}, Tela)
  t.corrida = Corrida.nova(opcoes or {})
  t.camera = Camera.nova(t.corrida.pista, t.corrida.jogador)
  t.folha, t.tiles = {}, {}
  t.sombra = Sprites.img.car.sombra
  t.pausa = false
  return t
end

function Tela:atualizar()
  if Entrada.pausar() then self.pausa = not self.pausa end
  if self.pausa then
    if Entrada.voltar() then Jogo.ir("titulo") end
    return
  end
  local r = self.corrida
  r:atualizar(Tempo.passo)
  self.camera:atualizar(Tempo.passo)
  if r.estado == "fim" and r.tempo - r.fim_em > 3 then Jogo.ir("resultado", r) end
end

function Tela:desenhar()
  local r, cam = self.corrida, self.camera
  local x0, y0 = cam.x0, cam.y0
  Fundo.desenhar(r.pista, x0, y0)
  r.combate:desenhar_chao(x0, y0, r.quadros)

  -- sombras (todas da mesma folha: uma carga so) e depois os carros (cada modelo tem 2 folhas:
  -- as direcoes estao divididas entre elas). Carro (com a sombra, 3 px para a direita) que nao
  -- cabe inteiro na largura da tela nao e desenhado: o console desenha errado o que fica
  -- cortado pela borda; a faixa preta esconde.
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

  r.combate:desenhar_cima(x0, y0, r.quadros, Cores.amarelo)

  -- faixas pretas nos lados: cobrem o vao das colunas de tiles que nao cabem inteiras
  local m = Fundo.MARGEM
  ui.rectfill(0, 0, m - 1, 269, Cores.preto)
  ui.rectfill(TELA_W - m, 0, TELA_W - 1, 269, Cores.preto)

  Hud.desenhar(r)
  if self.pausa then
    ui.rectfill(170, 110, 309, 149, Cores.preto)
    ui.print("PAUSA", 225, 116, Cores.amarelo)
    ui.print(Entrada.NOME.pausa .. " CONTINUA  " .. Entrada.NOME.voltar .. " SAI", 180, 132, Cores.branco)
  end
end

return Tela
