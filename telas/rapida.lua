-- Corrida rapida: escolhe a pista e o carro e corre (sem campeonato).
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Carros = require "carros"
local Pista = require "pista"
local Menu = require "menu"

local Tela = {}
Tela.__index = Tela

local TRACAO = { traseira = "TRASEIRA", dianteira = "DIANTEIRA", integral = "INTEGRAL" }

-- a ficha do carro numa linha (tambem usada na garagem)
function Tela.ficha(m)
  return string.format("VELOC %d  ACEL %d  ADER %d  BLIND %d  ARMA %d  TRACAO %s", m.velocidade, m.aceleracao,
    m.aderencia, m.blindagem, m.arma, TRACAO[m.tracao] or "?")
end

local menu = Menu.novo({
  { texto = "CORRER", acao = function() Jogo.ir("corrida", { pista = C.PISTA, voltas = Pista.LISTA[C.PISTA].voltas }) end },
  { texto = "PISTA", acao = function() C.PISTA = C.PISTA % Pista.quantas() + 1 end,
    valor = function() return Pista.LISTA[C.PISTA].nome end },
  { texto = "SEU CARRO", acao = function() C.MODELO = Carros[Carros.indice(C.MODELO) % #Carros + 1].id end,
    valor = function() return Carros[Carros.indice(C.MODELO)].nome end },
  { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end },
}, 140, 90, 18, 220)

-- texto da ficha so muda quando o carro muda
local ficha_de, ficha_texto

function Tela.nova()
  return setmetatable({}, Tela)
end

function Tela:atualizar()
  if Entrada.voltar() then Jogo.ir("titulo") return end
  menu:atualizar()
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  Menu.cabecalho("CORRIDA RAPIDA")
  menu:desenhar()
  local m = Carros[Carros.indice(C.MODELO)]
  if ficha_de ~= m.id then ficha_de, ficha_texto = m.id, Tela.ficha(m) end
  ui.tile(Sprites.img.car[m.id .. "_ver"], 0, 220, 172)
  Menu.centro(ficha_texto, 222, Cores.amarelo)
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
