-- Resultado da corrida: ordem de chegada, tempo total e melhor volta.
local Entrada = require "entrada"
local Cores = require "cores"

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
      texto = string.format("%do  %-6s  %-10s  ABATES %d  MELHOR VOLTA %s", i, c.nome, situacao, c.abates,
        tempo(c.melhor_volta)),
      cor = c == corrida.jogador and Cores.amarelo or (c.destruido and Cores.cinza or Cores.branco),
    }
  end
  t.premios = {}
  for i, p in ipairs(premios) do t.premios[i] = string.format("%-24s $%5d", p[1], p[2]) end
  t.total = string.format("%-24s $%5d", "TOTAL", total)
  return t
end

function Tela:atualizar()
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then Jogo.ir("titulo") end
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.print("RESULTADO", 213, 24, Cores.amarelo)
  for i, l in ipairs(self.linhas) do ui.print(l.texto, 60, 40 + i * 13, l.cor) end
  ui.print("SEU DINHEIRO", 60, 116, Cores.amarelo)
  for i, p in ipairs(self.premios) do ui.print(p, 60, 118 + i * 11, Cores.branco) end
  ui.print(self.total, 60, 132 + #self.premios * 11, Cores.verde)
  ui.print(Entrada.NOME.confirmar .. ": CONTINUAR", 186, 220, Cores.cinza_claro)
end

return Tela
