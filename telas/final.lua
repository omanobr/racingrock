-- Final do modo historia: venceu O ADVERSARIO. Primeiro a arte do Felipe (img/tela/final) com
-- "CAMPEAO!", depois o texto.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"
local Texto = require "texto"

local Tela = {}
Tela.__index = Tela

local TEXTO = {
  "A BANDEIRA QUADRICULADA CAI E O ADVERSARIO FICA PARA TRAS,",
  "NO MEIO DA FUMACA.",
  "",
  "PELA PRIMEIRA VEZ, A LIGA RACING ROCK TEM UM NOVO DONO:",
  "VOCE.",
  "",
  "DO FUSCA VELHO DA PRIMEIRA RODADA AO TOPO DO RANKING,",
  "CADA AMASSADO VALEU A PENA.",
  "",
  "PARABENS, CAMPEAO!",
}

function Tela.nova()
  local t = setmetatable({ espera = 90, quadro = 0, texto = false }, Tela)
  local e = Jogo.campeonato
  t.rodadas = e and string.format("CAMPEAO EM %d RODADAS, COM %s NO BOLSO", e.rodada, require("telas.garagem").dinheiro(e.dinheiro)) or ""
  return t
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then
    if not self.texto then
      self.texto, self.espera = true, 30
    else
      Jogo.campeonato = nil
      Jogo.ir("titulo")
    end
  end
end

function Tela:desenhar()
  if not self.texto then
    Menu.imagem("final")
    local w = Texto.largura("f3", "CAMPE\xC3O!")
    ui.rectfill(240 - w // 2 - 12, 6, 240 + w // 2 + 11, 38, Cores.preto)
    Texto.centro("f3", "CAMPE\xC3O!", 11, "amarelo")
    if self.espera <= 0 then
      local s = Entrada.NOME.confirmar .. ": CONTINUAR"
      ui.rectfill(240 - #s * 3 - 4, 255, 240 + #s * 3 + 3, 266, Cores.preto)
      Menu.rodape(s)
    end
    return
  end
  ui.cls(Cores.preto)
  Texto.centro("f3", "CAMPE\xC3O!", 24, "amarelo")
  for i, l in ipairs(TEXTO) do Menu.centro(l, 56 + i * 13, Cores.branco) end
  Menu.centro(self.rodadas, 214, Cores.verde)
  if self.espera <= 0 then Menu.rodape(Entrada.NOME.confirmar .. ": FIM") end
end

return Tela
