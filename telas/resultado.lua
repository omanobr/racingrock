-- Resultado da corrida: ordem de chegada, tempo total, melhor volta e o dinheiro. No modo
-- historia tambem o conserto, os pontos do ranking e o PASSWORD novo (campeonato.lua).
local Entrada = require "entrada"
local Cores = require "cores"
local Campeonato = require "campeonato"
local Menu = require "menu"
local Texto = require "texto"

local Tela = {}
Tela.__index = Tela

local function tempo(s)
  if not s then return "--" end
  local d = (s * 10) // 1
  return string.format("%d:%02d.%d", d // 600, d // 10 % 60, d % 10)
end

function Tela.nova(corrida)
  local t = setmetatable({ espera = 30 }, Tela)
  local premios, total = corrida:premiar()
  t.linhas = {}
  for i, c in ipairs(corrida.classificacao) do
    local situacao = c.chegou and tempo(c.chegou) or (c.destruido and "DESTRUIDO" or "NAO CHEGOU")
    t.linhas[i] = {
      pos = string.format("%d\xBA", i),
      texto = string.format("%-10s  %-10s  ABATES %d  MELHOR VOLTA %s", c.nome, situacao, c.abates,
        tempo(c.melhor_volta)),
      cor = c == corrida.jogador and Cores.amarelo or (c.destruido and Cores.cinza or Cores.branco),
      jogador = c == corrida.jogador,
    }
  end
  local j = corrida.jogador
  t.titulo = j.destruido and "DESTRU\xCDDO!" or (j.posicao == 1 and "VIT\xD3RIA!" or string.format("%d\xBA LUGAR", j.posicao))
  t.premios = {}
  for i, p in ipairs(premios) do t.premios[i] = { string.format("%-24s $%6d", p[1], p[2]), Cores.branco } end
  t.total = string.format("%-24s $%6d", "TOTAL", total)
  -- modo historia: aplica no campeonato (uma vez so, aqui)
  local e = Jogo.campeonato
  if corrida.campeonato and e then
    local antes = Campeonato.posicao(e)
    local res = Campeonato.aplicar(e, corrida, total)
    if res.minas > 0 then t.premios[#t.premios + 1] = { string.format("%-24s-$%6d", "MINAS", res.minas), Cores.vermelho } end
    if res.conserto > 0 then t.premios[#t.premios + 1] = { string.format("%-24s-$%6d", "CONSERTO DO CARRO", res.conserto), Cores.vermelho } end
    t.total = string.format("%-24s $%6d", "VOCE TEM AGORA", e.dinheiro)
    local depois = Campeonato.posicao(e)
    t.ranking = string.format("PONTOS NO RANKING: +%d   (%do -> %do LUGAR)", res.pontos, antes, depois)
    t.senha = Campeonato.senha_bonita(e)
    t.final = res.venceu_final
    t.historia = true
  end
  return t
end

function Tela:atualizar()
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then
    if self.final then Jogo.ir("final")
    elseif self.historia then Jogo.ir("garagem")
    else Jogo.ir("titulo") end
  end
end

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho(self.titulo)
  -- ordem de chegada
  Menu.painel(16, 34, 448, 6 + 18 * #self.linhas)
  for i, l in ipairs(self.linhas) do
    local y = 37 + (i - 1) * 18
    if l.jogador then ui.rectfill(17, y - 1, 462, y + 16, Cores.vinho) end
    Texto.escrever("f2", l.pos, 24, y, l.jogador and "amarelo" or "branco")
    ui.print(l.texto, 70, y + 4, l.cor)
  end
  -- dinheiro
  local y0 = 46 + 18 * #self.linhas
  ui.print("SEU DINHEIRO", 60, y0, Cores.amarelo)
  for i, p in ipairs(self.premios) do ui.print(p[1], 60, y0 + 2 + i * 10, p[2]) end
  local y = y0 + 14 + #self.premios * 10
  ui.print(self.total, 60, y, Cores.verde)
  if self.ranking then
    ui.print(self.ranking, 60, y + 13, Cores.amarelo)
    Menu.painel(70, 214, 340, 31, Cores.amarelo_escuro)
    ui.print("PASSWORD:", 82, 226, Cores.cinza_claro)
    Texto.escrever("f3", self.senha, 150, 218, "amarelo")
  end
  Menu.rodape(Entrada.NOME.confirmar .. ": CONTINUAR")
end

return Tela
