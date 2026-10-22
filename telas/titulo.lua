-- Titulo e menu principal (provisorio: o logo e a ilustracao vem da arte do Felipe,
-- arte-original/interface/PROMPTS-HUD.md).
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Pista = require "pista"
local Menu = require "menu"
local Texto = require "texto"

local Tela = {}
Tela.__index = Tela

local menu = Menu.novo({
  { texto = "MODO HIST\xD3RIA", acao = function() Jogo.ir("historia") end },
  { texto = "CORRIDA R\xC1PIDA", acao = function() Jogo.ir("rapida") end },
  { texto = "DEMONSTRA\xC7\xC3O", acao = function()
    Jogo.ir("corrida", { pista = C.PISTA, voltas = Pista.LISTA[C.PISTA].voltas, autopiloto = true })
  end },
  { texto = "OP\xC7\xD5ES", acao = function() Jogo.ir("opcoes") end },
}, 166, 132, 22, 192)

function Tela.nova()
  return setmetatable({ quadro = 0 }, Tela)
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  menu:atualizar()
end

function Tela:desenhar()
  Menu.fundo()
  -- faixa do titulo: zebrada em cima e embaixo
  ui.rectfill(0, 30, 479, 103, Cores.preto)
  for x = 0, 468, 12 do
    Texto.extra("zebrada", x, 30)
    Texto.extra("zebrada", x, 88)
  end
  ui.rectfill(0, 46, 479, 87, Cores.preto)
  Texto.centro("f3", "RACING ROCK", 52, "amarelo")
  Menu.centro("CORRIDA DE COMBATE VISTA DE CIMA", 78, Cores.cinza_claro)
  -- dois carros dos lados do menu
  ui.spr(Sprites.img.car.puma_3q, 24, 150)
  ui.spr(Sprites.img.car.opala_3q, 340, 146)
  menu:desenhar()
  ui.print("v" .. C.VERSAO, 20, 258, Cores.cinza)
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER")
end

return Tela
