-- Titulo e menu principal, com a arte do Felipe (img/tela/titulo e logo). Ao ligar o jogo, so a
-- imagem, o logo e "APERTE START" piscando; apertando, o menu aparece por cima da imagem (pedido
-- do Felipe). Voltando ao titulo depois, o menu ja aparece. Parado DEMO segundos no "APERTE
-- START", roda uma demonstracao (pista, variacao e carro sorteados), como nos fliperamas.
local C = require "config"
local Entrada = require "entrada"
local Cores = require "cores"
local Pista = require "pista"
local Menu = require "menu"
local Texto = require "texto"
local D = require "dados_telas"
local Som = require "som"

local Tela = {}
Tela.__index = Tela

local DEMO = 20

-- corrida de demonstracao: o computador pilota os 4; qualquer botao volta ao titulo
local function demonstracao(pista, variante)
  local Carros = require "carros"
  Jogo.ir("corrida", { pista = pista or math.random(2, Pista.quantas()), variante = variante or math.random(4),
                       voltas = 2, autopiloto = true, demo = true, modelo = Carros[math.random(#Carros)].id })
end

local menu = Menu.novo({
  { texto = "MODO HIST\xD3RIA", acao = function() Jogo.ir("historia") end },
  { texto = "CORRIDA R\xC1PIDA", acao = function() Jogo.ir("rapida") end },
  { texto = "DEMONSTRA\xC7\xC3O", acao = function() demonstracao(C.PISTA, C.VARIANTE) end },
  { texto = "OP\xC7\xD5ES", acao = function() Jogo.ir("opcoes") end },
}, 166, 152, 22, 192)

function Tela.nova()
  Som.musica()   -- (ja tocando desde a abertura; aqui so quando o jogo comeca no titulo)
  return setmetatable({ quadro = 0 }, Tela)
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  if not Jogo.titulo_visto then
    if Entrada.confirmar() or Entrada.pausar() then Jogo.titulo_visto = true
    elseif self.quadro > DEMO * 60 then demonstracao() end
    return
  end
  menu:atualizar()
end

function Tela:desenhar()
  Menu.imagem("titulo")
  local L = D.logo
  ui.spr(Sprites.img.tela.logo, 240 - L.w // 2, 2)
  if not Jogo.titulo_visto then
    if (self.quadro // 30) % 2 == 0 then
      local w = Texto.largura("f2", "APERTE START")
      ui.rectfill(240 - w // 2 - 10, 226, 240 + w // 2 + 9, 247, Cores.preto)
      Texto.escrever("f2", "APERTE START", 240 - w // 2, 229, "amarelo")
    end
    return
  end
  Menu.painel(130, 144, 220, 98, Cores.amarelo_escuro)
  menu:desenhar()
  ui.rectfill(16, 255, 63, 266, Cores.preto)
  ui.print("v" .. C.VERSAO, 20, 258, Cores.cinza)
  local s = Entrada.NOME.confirmar .. ": ESCOLHER"
  ui.rectfill(240 - #s * 3 - 4, 255, 240 + #s * 3 + 3, 266, Cores.preto)
  Menu.rodape(s)
end

return Tela
