-- Resultado da corrida: ordem de chegada (com os retratos), tempo total, melhor volta e o
-- dinheiro. No modo historia tambem o mercado negro, a recompensa, o conserto, o agiota e o
-- PASSWORD novo (campeonato.lua); depois vem o ranking da rodada (telas/rodada.lua).
local Entrada = require "entrada"
local Cores = require "cores"
local Campeonato = require "campeonato"
local Menu = require "menu"
local Texto = require "texto"
local Som = require "som"
local DT = require "dados_telas"

local Tela = {}
Tela.__index = Tela

local function tempo(s)
  if not s then return "--" end
  local d = (s * 10) // 1
  return string.format("%d:%02d.%d", d // 600, d // 10 % 60, d % 10)
end

function Tela.nova(corrida)
  local t = setmetatable({ espera = 30 }, Tela)
  Som.musica("menu")
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
      retrato = c.retrato,
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
    local antes = Campeonato.ranking(e)
    local rodada_antes = e.rodada
    local res = Campeonato.aplicar(e, corrida, total)
    local function linha(texto, valor, cor)
      t.premios[#t.premios + 1] = { string.format("%-24s%s$%6d", texto, valor < 0 and "-" or " ", math.abs(valor)), cor }
    end
    local r = res.recompensa
    if r then linha(r.ok and "RECOMPENSA: " .. r.nome or "MULTA: " .. r.nome .. " ESCAPOU", r.valor,
      r.ok and Cores.verde or Cores.vermelho) end
    if res.mercado > 0 then linha("MERCADO NEGRO", -res.mercado, Cores.vermelho) end
    if res.conserto > 0 then linha("CONSERTO DO CARRO", -res.conserto, Cores.vermelho) end
    if res.agiota then
      linha(res.agiota.melhorias and "AGIOTA (+ AS MELHORIAS)" or "O AGIOTA COBROU", -res.agiota.levou, Cores.vermelho)
    end
    t.total = string.format("%-24s $%6d", "VOCE TEM AGORA", e.dinheiro)
    t.senha = Campeonato.senha_bonita(e)
    t.final = res.venceu_final
    t.historia = true
    -- para o ranking da rodada: antes e depois, e quem voce destruiu
    local abatidos = {}
    for _, c in ipairs(corrida.carros) do
      if c.abatido_por == corrida.jogador then abatidos[#abatidos + 1] = c.nome end
    end
    t.rodada = { antes = antes, rodada_antes = rodada_antes, pontos = res.pontos, abatidos = abatidos }
  end
  return t
end

function Tela:atualizar()
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then
    if self.final then Jogo.ir("final")
    elseif self.historia then Jogo.ir("rodada", self.rodada)
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
    if l.retrato then ui.tile(Sprites.img.ui.ret16, l.retrato, 62, y) end
    ui.print(l.texto, 84, y + 4, l.cor)
  end
  -- dinheiro
  local y0 = 46 + 18 * #self.linhas
  ui.print("SEU DINHEIRO", 60, y0, Cores.amarelo)
  for i, p in ipairs(self.premios) do ui.print(p[1], 60, y0 + 2 + i * 9, p[2]) end
  local y = y0 + 14 + #self.premios * 9
  ui.print(self.total, 60, y, Cores.verde)
  if self.senha then
    Menu.painel(60, 226, 360, 27, Cores.amarelo_escuro)
    ui.print("PASSWORD:", 72, 236, Cores.cinza_claro)
    Texto.escrever("f3", self.senha, 136, 228, "amarelo")
  end
  Menu.rodape(Entrada.NOME.confirmar .. ": CONTINUAR")
end

return Tela
