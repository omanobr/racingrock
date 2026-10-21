-- Opcoes: FPS no rodape e teste de botoes.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"

local Tela = {}
Tela.__index = Tela

local menu = Menu.novo({
  { texto = "FPS NO RODAPE", acao = function() Jogo.rodape = not Jogo.rodape end,
    valor = function() return Jogo.rodape and "SIM" or "NAO" end },
  { texto = "TESTE DE BOTOES", acao = function() Jogo.ir("teste") end },
  { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end },
}, 140, 100, 18, 220)

function Tela.nova()
  return setmetatable({}, Tela)
end

function Tela:atualizar()
  if Entrada.voltar() then Jogo.ir("titulo") return end
  menu:atualizar()
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  Menu.cabecalho("OPCOES")
  menu:desenhar()
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
