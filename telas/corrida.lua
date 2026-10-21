-- Tela da corrida: atualiza as regras (corrida.lua) e desenha pista, carros e painel.
local Corrida = require "corrida"
local Camera = require "camera"
local Fundo = require "fundo"
local Hud = require "hud"
local Tempo = require "tempo"
local Entrada = require "entrada"
local Cores = require "cores"

local Tela = {}
Tela.__index = Tela

local TELA_W = 480

-- opcoes: { pista, voltas, autopiloto }
function Tela.nova(opcoes)
  local t = setmetatable({}, Tela)
  t.corrida = Corrida.nova(opcoes or {})
  t.camera = Camera.nova(t.corrida.pista, t.corrida.jogador)
  t.sombra = Sprites.img.car.t_som
  t.quadros = {}
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

  -- sombras (todas da mesma folha, em seguida: uma carga so) e depois os carros. Carro (com a
  -- sombra, 3 px para a direita) que nao cabe inteiro na largura da tela nao e desenhado: o
  -- console desenha errado o que fica cortado pela borda; a faixa preta esconde o sumico.
  local tile, carros, quadros = ui.tile, r.carros, self.quadros
  local sombra = self.sombra
  for i = 1, #carros do
    local c = carros[i]
    local sx, sy = (c.x - x0) // 1 - 16, (c.y - y0) // 1 - 16
    if sx >= 0 and sx <= TELA_W - 35 and sy > -32 and sy < 270 then
      local q = c:quadro()
      quadros[i] = q
      tile(sombra, q, sx + 3, sy + 3)
    else
      quadros[i] = false
    end
  end
  for i = 1, #carros do
    local q = quadros[i]
    if q then
      local c = carros[i]
      tile(c.img, q, (c.x - x0) // 1 - 16, (c.y - y0) // 1 - 16)
    end
  end

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
