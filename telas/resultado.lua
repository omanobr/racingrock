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
  corrida:classificar()
  t.linhas = {}
  for i, c in ipairs(corrida.classificacao) do
    t.linhas[i] = {
      texto = string.format("%do  %-8s  %s  MELHOR VOLTA %s", i, c.nome, c.chegou and tempo(c.chegou) or "NAO CHEGOU",
        tempo(c.melhor_volta)),
      cor = c == corrida.jogador and Cores.amarelo or Cores.branco,
    }
  end
  return t
end

function Tela:atualizar()
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then Jogo.ir("titulo") end
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.print("RESULTADO", 213, 40, Cores.amarelo)
  for i, l in ipairs(self.linhas) do ui.print(l.texto, 96, 70 + i * 14, l.cor) end
  ui.print(Entrada.NOME.confirmar .. ": CONTINUAR", 186, 220, Cores.cinza_claro)
end

return Tela
