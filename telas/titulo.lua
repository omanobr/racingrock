-- Titulo e menu (provisorio: a arte do titulo vem depois).
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Carros = require "carros"
local Pista = require "pista"

local Tela = {}
Tela.__index = Tela

-- { texto, acao, valor (opcional: texto do valor atual) }
local function proximo_carro()
  C.MODELO = Carros[Carros.indice(C.MODELO) % #Carros + 1].id
end

local function proxima_pista()
  C.PISTA = C.PISTA % Pista.quantas() + 1
end

local OPCOES = {
  { "CORRER", function() Jogo.ir("corrida", { pista = C.PISTA, voltas = Pista.LISTA[C.PISTA].voltas }) end },
  { "PISTA", proxima_pista, function() return Pista.LISTA[C.PISTA].nome end },
  { "SEU CARRO", proximo_carro, function() return Carros[Carros.indice(C.MODELO)].nome end },
  { "DEMONSTRACAO (COMPUTADOR PILOTA)", function()
    Jogo.ir("corrida", { pista = C.PISTA, voltas = Pista.LISTA[C.PISTA].voltas, autopiloto = true })
  end },
  { "TESTE DE BOTOES", function() Jogo.ir("teste") end },
  { "FPS NO RODAPE", function() Jogo.rodape = not Jogo.rodape end, function() return Jogo.rodape and "SIM" or "NAO" end },
}

function Tela.nova()
  return setmetatable({ escolha = 1 }, Tela)
end

-- ficha do carro escolhido (carros.lua), montada so quando o carro muda
local TRACAO = { traseira = "TRASEIRA", dianteira = "DIANTEIRA", integral = "INTEGRAL" }
local ficha_de, ficha_texto
local function ficha()
  if ficha_de ~= C.MODELO then
    local m = Carros[Carros.indice(C.MODELO)]
    ficha_de = C.MODELO
    ficha_texto = string.format("VELOC %d  ACEL %d  ADER %d  BLIND %d  ARMA %d  TRACAO %s", m.velocidade,
      m.aceleracao, m.aderencia, m.blindagem, m.arma, TRACAO[m.tracao] or "?")
  end
  return ficha_texto
end

function Tela:atualizar()
  if Entrada.cima() then self.escolha = (self.escolha - 2) % #OPCOES + 1 end
  if Entrada.baixo() then self.escolha = self.escolha % #OPCOES + 1 end
  if Entrada.confirmar() then OPCOES[self.escolha][2]() end
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.rectfill(120, 24, 359, 63, Cores.preto)
  ui.print("R A C I N G   R O C K", 177, 34, Cores.vermelho)
  ui.print("corrida de combate vista de cima", 144, 48, Cores.cinza_claro)
  for i, o in ipairs(OPCOES) do
    local y = 80 + i * 18
    local texto = o[1]
    if o[3] then texto = texto .. ": " .. o[3]() end
    if i == self.escolha then
      ui.rectfill(110, y - 4, 369, y + 10, Cores.vermelho)
      ui.print(texto, 120, y, Cores.branco)
    else
      ui.print(texto, 120, y, Cores.cinza_claro)
    end
  end
  local f = ficha()
  ui.print(f, 240 - #f * 3, 232, Cores.amarelo)
  ui.print("v" .. C.VERSAO .. "  " .. Entrada.NOME.confirmar .. ": ESCOLHER", 8, 258, Cores.cinza)
end

return Tela
