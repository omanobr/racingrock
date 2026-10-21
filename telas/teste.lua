-- Teste de botoes: qual constante do Lupi (BTN_Z, BTN_X...) cada botao do controle aciona,
-- para os 3 controles, e o numero de qualquer botao apertado (de 0 a 31) no log do console.
-- Para sair: SEGURE o direcional para a esquerda por 1 segundo.
local Cores = require "cores"
local Entrada = require "entrada"

local Tela = {}
Tela.__index = Tela

local BOTOES = {
  { "CIMA", "UP" }, { "BAIXO", "DOWN" }, { "ESQ", "LEFT" }, { "DIR", "RIGHT" },
  { "Z", "BTN_Z" }, { "X", "BTN_X" }, { "Q", "BTN_Q" }, { "E", "BTN_E" }, { "F", "BTN_F" }, { "G", "BTN_G" },
}
-- o botao do controle que o jogo acha que aciona cada constante (entrada.lua)
local SNES = {}
for nome, botao in pairs(Entrada.BOTAO) do
  for _, b in ipairs(BOTOES) do
    if _ENV[b[2]] == botao then SNES[b[2]] = nome end
  end
end

function Tela.nova()
  return setmetatable({ esq = 0, ultimo = "" }, Tela)
end

function Tela:atualizar()
  local segurando = false
  for p = 0, 2 do segurando = segurando or ui.btn(LEFT, p) end
  self.esq = segurando and self.esq + 1 or 0
  if self.esq >= 60 then Jogo.ir("titulo") return end
  for p = 0, 2 do
    for id = 0, 31 do
      if ui.btnp(id, p) then
        self.ultimo = string.format("BOTAO %d NO CONTROLE %d", id, p + 1)
        print("RROCK " .. self.ultimo)
      end
    end
  end
end

function Tela:desenhar()
  ui.cls(Cores.cinza_escuro)
  ui.print("TESTE DE BOTOES", 8, 6, Cores.amarelo)
  ui.print("Aperte cada botao do controle e veja qual quadrado acende.", 8, 20, Cores.branco)
  ui.print("Entre parenteses: o botao que o jogo acha que e (controle Super Nintendo).", 8, 30, Cores.cinza_claro)
  for c, b in ipairs(BOTOES) do
    local x = 70 + (c - 1) * 40
    ui.print(b[1], x + 14 - #b[1] * 3, 56, Cores.branco)
    if SNES[b[2]] then ui.print("(" .. SNES[b[2]] .. ")", x + 6, 160, Cores.cinza_claro) end
    for j = 0, 2 do
      local y = 70 + j * 28
      if c == 1 then ui.print("J" .. (j + 1), 40, y + 6, Cores.branco) end
      ui.rectfill(x, y, x + 29, y + 21, ui.btn(_ENV[b[2]], j) and Cores.verde or Cores.preto)
    end
  end
  ui.print("Ultimo botao apertado (pelo numero): " .. self.ultimo, 8, 190, Cores.amarelo)
  ui.print("O START e o botao 6 no console. Nao use o L do controle 1 (trava o console).", 8, 210, Cores.cinza_claro)
  ui.print("Para sair: segure o direcional para a ESQUERDA por 1 segundo.", 8, 240, Cores.branco)
end

return Tela
