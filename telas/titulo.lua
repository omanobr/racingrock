-- Titulo e menu principal (provisorio: a arte do titulo vem depois).
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Pista = require "pista"
local Menu = require "menu"

local Tela = {}
Tela.__index = Tela

local menu = Menu.novo({
  { texto = "MODO HISTORIA", acao = function() Jogo.ir("historia") end },
  { texto = "CORRIDA RAPIDA", acao = function() Jogo.ir("rapida") end },
  { texto = "DEMONSTRACAO (COMPUTADOR PILOTA)", acao = function()
    Jogo.ir("corrida", { pista = C.PISTA, voltas = Pista.LISTA[C.PISTA].voltas, autopiloto = true })
  end },
  { texto = "OPCOES", acao = function() Jogo.ir("opcoes") end },
}, 140, 110, 18, 220)

function Tela.nova()
  return setmetatable({}, Tela)
end

function Tela:atualizar()
  menu:atualizar()
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.rectfill(120, 30, 359, 77, Cores.preto)
  ui.print("R A C I N G   R O C K", 177, 42, Cores.vermelho)
  ui.print("corrida de combate vista de cima", 144, 58, Cores.cinza_claro)
  menu:desenhar()
  ui.print("v" .. C.VERSAO .. "  " .. Entrada.NOME.confirmar .. ": ESCOLHER", 8, 258, Cores.cinza)
end

return Tela
