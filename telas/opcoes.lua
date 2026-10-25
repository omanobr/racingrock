-- Opcoes: FPS no rodape e teste de botoes.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"

local Tela = {}
Tela.__index = Tela

local menu = Menu.novo({
  { texto = "FPS NO RODAP\xC9", acao = function() Jogo.rodape = not Jogo.rodape end,
    valor = function() return Jogo.rodape and "SIM" or "N\xC3O" end },
  { texto = "TESTE DE BOT\xD5ES", acao = function() Jogo.ir("teste") end },
  { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end },
}, 150, 100, 24, 230)

function Tela.nova()
  return setmetatable({}, Tela)
end

function Tela:atualizar()
  if Entrada.voltar() then Jogo.ir("titulo") return end
  menu:atualizar()
end

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho("OP\xC7\xD5ES")
  menu:desenhar()
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
