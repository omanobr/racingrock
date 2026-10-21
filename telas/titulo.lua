-- Titulo e menu (provisorio: a arte do titulo vem depois).
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"

local Tela = {}
Tela.__index = Tela

local OPCOES = {
  { "CORRER (PISTA DE TREINO)", function() Jogo.ir("corrida", { pista = 1, voltas = C.VOLTAS }) end },
  { "DEMONSTRACAO (COMPUTADOR PILOTA)", function() Jogo.ir("corrida", { pista = 1, voltas = C.VOLTAS, autopiloto = true }) end },
  { "TESTE DE BOTOES", function() Jogo.ir("teste") end },
  { "TESTE DE DESEMPENHO", function() Jogo.ir("desempenho") end },
  { "FPS NO RODAPE", function() Jogo.rodape = not Jogo.rodape end },
}

function Tela.nova()
  return setmetatable({ escolha = 1, quadro = 0 }, Tela)
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  if Entrada.cima() then self.escolha = (self.escolha - 2) % #OPCOES + 1 end
  if Entrada.baixo() then self.escolha = self.escolha % #OPCOES + 1 end
  if Entrada.confirmar() then OPCOES[self.escolha][2]() end
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.rectfill(120, 40, 359, 79, Cores.preto)
  ui.print("R A C I N G   R O C K", 177, 50, Cores.vermelho)
  ui.print("corrida de combate vista de cima", 144, 64, Cores.cinza_claro)
  for i, o in ipairs(OPCOES) do
    local y = 110 + i * 16
    local texto = o[1]
    if i == #OPCOES then texto = texto .. (Jogo.rodape and ": SIM" or ": NAO") end
    if i == self.escolha then
      ui.rectfill(130, y - 4, 349, y + 10, Cores.vermelho)
      ui.print(texto, 140, y, Cores.branco)
    else
      ui.print(texto, 140, y, Cores.cinza_claro)
    end
  end
  ui.print("v" .. C.VERSAO .. "  " .. Entrada.NOME.confirmar .. ": ESCOLHER", 8, 258, Cores.cinza)
end

return Tela
