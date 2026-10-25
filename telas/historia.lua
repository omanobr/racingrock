-- Modo historia: novo jogo (escolhe o nivel dos rivais e mostra a historia), continuar o jogo
-- desta sessao ou digitar um password (campeonato.lua).
local C = require "config"
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
  "OU DIFICIL (CARROS CADA VEZ MELHORES). GANHE",
  "DINHEIRO E PONTOS, CONSERTE O CARRO, COMPRE",
  "MELHORIAS, MINAS E CARROS MELHORES.",
  "",
  "CHEGUE AO 1o LUGAR DO RANKING E DESAFIE",
  "O ADVERSARIO, O DONO DA LIGA.",
  "",
  "O CONSOLE NAO GUARDA O JOGO: ANOTE O PASSWORD",
  "QUE APARECE NA GARAGEM.",
}

-- o que cada nivel muda (C.NIVEIS), embaixo do menu de nivel
local EXPLICA = {
  {
    "OS CARROS DOS RIVAIS ANDAM 5% MENOS QUE OS IGUAIS AOS SEUS.",
    "ELES ERRAM MAIS AS CURVAS E A MIRA E NAO LEVAM MINAS.",
    "OS PREMIOS SAO 20% MENORES.",
  },
  {
    "OS CARROS DOS RIVAIS SAO IGUAIS AOS SEUS. ELES PILOTAM BEM,",
    "USAM O TURBO NAS RETAS E UM DELES LEVA MINAS.",
  },
  {
    "OS CARROS DOS RIVAIS ANDAM 5% MAIS: COM O FUSCA, ELES CHEGAM",
    "A 143 KM/H E VOCE A 136. NAO ERRAM CURVA, QUASE NAO ERRAM",
    "TIRO E DOIS DELES LEVAM MINAS. OS PREMIOS SAO 40% MAIORES.",
  },
}

function Tela.nova()
  local t = setmetatable({ modo = "menu" }, Tela)
  local opcoes = {}
  if Jogo.campeonato then
    opcoes[#opcoes + 1] = { texto = "CONTINUAR", acao = function() Jogo.ir("garagem") end }
  end
  opcoes[#opcoes + 1] = { texto = "NOVO JOGO", acao = function() t.modo = "nivel" end }
  opcoes[#opcoes + 1] = { texto = "PASSWORD", acao = function() Jogo.ir("senha") end }
  opcoes[#opcoes + 1] = { texto = "VOLTAR", acao = function() Jogo.ir("titulo") end }
  t.menu = Menu.novo(opcoes, 186, 112, 24, 150)
  -- nivel dos rivais, para o campeonato inteiro (vai no password)
  local niveis = {}
  for i, n in ipairs(C.NIVEIS) do
    niveis[i] = { texto = n.nome, acao = function()
      Jogo.campeonato = Campeonato.novo(i)
      t.modo = "historia"
    end }
  end
  t.menu_nivel = Menu.novo(niveis, 196, 64, 24, 130)
  t.menu_nivel.escolha = 2
  return t
end

function Tela:atualizar()
  if self.modo == "historia" then
    if Entrada.confirmar() then Jogo.ir("garagem") end
    return
  end
  if self.modo == "nivel" then
    if Entrada.voltar() then self.modo = "menu" return end
    self.menu_nivel:atualizar()
    return
  end
  if Entrada.voltar() then Jogo.ir("titulo") return end
  self.menu:atualizar()
end

function Tela:desenhar()
  Menu.fundo()
  if self.modo == "historia" then
    Menu.cabecalho("A LIGA")
    Menu.painel(48, 32, 384, 222)
    for i, l in ipairs(HISTORIA) do Menu.centro(l, 28 + i * 12, Cores.branco) end
    Menu.rodape(Entrada.NOME.confirmar .. ": PARA A GARAGEM")
    return
  end
  if self.modo == "nivel" then
    Menu.cabecalho("N\xCDVEL DOS RIVAIS")
    Menu.centro("VALE PARA O CAMPEONATO INTEIRO (VAI NO PASSWORD)", 40, Cores.cinza_claro)
    self.menu_nivel:desenhar()
    Menu.painel(36, 146, 408, 62)
    for i, l in ipairs(EXPLICA[self.menu_nivel.escolha] or {}) do Menu.centro(l, 148 + i * 13, Cores.branco) end
    Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
    return
  end
  Menu.cabecalho("MODO HIST\xD3RIA")
  Menu.centro("CAMPEONATO DA LIGA RACING ROCK", 64, Cores.amarelo)
  Menu.centro("20 PILOTOS, 1 RANKING, NENHUMA REGRA", 78, Cores.cinza)
  self.menu:desenhar()
  Menu.rodape(Entrada.NOME.confirmar .. ": ESCOLHER   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
