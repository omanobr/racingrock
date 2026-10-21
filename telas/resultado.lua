-- Resultado da corrida: ordem de chegada, tempo total, melhor volta e o dinheiro. No modo
-- historia tambem o conserto, os pontos do ranking e o PASSWORD novo (campeonato.lua).
local Entrada = require "entrada"
local Cores = require "cores"
local Campeonato = require "campeonato"

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
      texto = string.format("%do  %-10s  %-10s  ABATES %d  MELHOR VOLTA %s", i, c.nome, situacao, c.abates,
        tempo(c.melhor_volta)),
      cor = c == corrida.jogador and Cores.amarelo or (c.destruido and Cores.cinza or Cores.branco),
    }
  end
  t.premios = {}
  for i, p in ipairs(premios) do t.premios[i] = { string.format("%-24s $%6d", p[1], p[2]), Cores.branco } end
  t.total = string.format("%-24s $%6d", "TOTAL", total)
  -- modo historia: aplica no campeonato (uma vez so, aqui)
  local e = Jogo.campeonato
  if corrida.campeonato and e then
    local antes = Campeonato.posicao(e)
    local res = Campeonato.aplicar(e, corrida, total)
    if res.conserto > 0 then t.premios[#t.premios + 1] = { string.format("%-24s-$%6d", "CONSERTO DO CARRO", res.conserto), Cores.vermelho } end
    t.total = string.format("%-24s $%6d", "VOCE TEM AGORA", e.dinheiro)
    local depois = Campeonato.posicao(e)
    t.ranking = string.format("PONTOS NO RANKING: +%d   (%do -> %do LUGAR)", res.pontos, antes, depois)
    t.senha = "PASSWORD: " .. Campeonato.senha_bonita(e)
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
  ui.cls(Cores.cinza_escuro)
  ui.print("RESULTADO", 213, 20, Cores.amarelo)
  for i, l in ipairs(self.linhas) do ui.print(l.texto, 40, 30 + i * 13, l.cor) end
  ui.print("SEU DINHEIRO", 60, 102, Cores.amarelo)
  for i, p in ipairs(self.premios) do ui.print(p[1], 60, 104 + i * 11, p[2]) end
  local y = 118 + #self.premios * 11
  ui.print(self.total, 60, y, Cores.verde)
  if self.ranking then
    ui.print(self.ranking, 60, y + 16, Cores.amarelo)
    ui.rectfill(0, 214, 479, 233, Cores.preto)
    ui.print(self.senha, 240 - #self.senha * 3, 220, Cores.verde)
  end
  ui.print(Entrada.NOME.confirmar .. ": CONTINUAR", 186, 250, Cores.cinza_claro)
end

return Tela
