-- Modo historia: novo jogo (com a historia), continuar o jogo desta sessao ou digitar um
-- password (campeonato.lua).
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"
local Campeonato = require "campeonato"

local Tela = {}
Tela.__index = Tela

local HISTORIA = {
  "2027. AS CORRIDAS DE RUA VIRARAM GUERRA.",
  "",
  "NA LIGA CLANDESTINA RACING ROCK VALE TUDO:",
  "METRALHADORA, MINA E MUITA LATARIA AMASSADA.",
  "",
  "VOCE CHEGA COM UM FUSCA VELHO E 500 DOLARES,",
  "NO ULTIMO LUGAR DE UM RANKING DE 20 PILOTOS.",
  "",
  "A CADA RODADA, ESCOLHA UMA CORRIDA: FACIL, MEDIA",
  "OU DIFICIL. GANHE DINHEIRO E PONTOS, CONSERTE O",
  "CARRO, COMPRE MELHORIAS E CARROS MELHORES.",
  "",
  "CHEGUE AO 1o LUGAR DO RANKING E DESAFIE",
  "O ADVERSARIO, O DONO DA LIGA.",
  "",
  "O CONSOLE NAO GUARDA O JOGO: ANOTE O PASSWORD",
  "QUE APARECE NA GARAGEM.",
}

local function novo_jogo()
  Jogo.campeonato = Campeonato.novo()
  Jogo.tela.intro = true
end

function Tela.nova()
  local t = setmetatable({ intro = false }, Tela)
  local opcoes = {}
  if Jogo.campeonato then
    opcoes[#opcoes + 1] = { texto = "CONTINUAR", acao = function() Jogo.ir("garagem") end }
  end
  opcoes[#opcoes + 1] = { texto = "NOVO JOGO", acao = novo_jogo }
  opcoes[#opcoes + 1] = { texto = "PASSWORD", acao = function() Jogo.ir("senha") end }
  opcoes[#opcoes + 1] = { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end }
  t.menu = Menu.novo(opcoes, 186, 112, 24, 150)
  return t
end

function Tela:atualizar()
  if self.intro then
    if Entrada.confirmar() then Jogo.ir("garagem") end
    return
  end
  if Entrada.voltar() then Jogo.ir("titulo") return end
  self.menu:atualizar()
end

function Tela:desenhar()
  Menu.fundo()
  if self.intro then
    Menu.cabecalho("A LIGA")
    Menu.painel(48, 34, 384, 218)
    for i, l in ipairs(HISTORIA) do Menu.centro(l, 28 + i * 12, Cores.branco) end
    Menu.rodape(Entrada.NOME.confirmar .. ": PARA A GARAGEM")
    return
  end
  Menu.cabecalho("MODO HISTÓRIA")
  Menu.centro("CAMPEONATO DA LIGA RACING ROCK", 64, Cores.amarelo)
  Menu.centro("20 PILOTOS, 1 RANKING, NENHUMA REGRA", 78, Cores.cinza)
  self.menu:desenhar()
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
