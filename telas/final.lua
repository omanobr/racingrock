-- Final do modo historia: venceu O ADVERSARIO.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"

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
  local t = setmetatable({ espera = 90, quadro = 0 }, Tela)
  local e = Jogo.campeonato
  t.rodadas = e and string.format("CAMPEAO EM %d RODADAS, COM %s NO BOLSO", e.rodada, require("telas.garagem").dinheiro(e.dinheiro)) or ""
  return t
end

function Tela:atualizar()
  self.quadro = self.quadro + 1
  self.espera = self.espera - 1
  if self.espera <= 0 and Entrada.confirmar() then
    Jogo.campeonato = nil
    Jogo.ir("titulo")
  end
end

function Tela:desenhar()
  ui.cls(Cores.preto)
  local pisca = (self.quadro // 20) % 2 == 0
  Menu.centro("R A C I N G   R O C K", 30, pisca and Cores.amarelo or Cores.vermelho)
  for i, l in ipairs(TEXTO) do Menu.centro(l, 56 + i * 13, Cores.branco) end
  Menu.centro(self.rodadas, 214, Cores.verde)
  if self.espera <= 0 then Menu.rodape(Entrada.NOME.confirmar .. ": FIM") end
end

return Tela
