-- Cobranca do agiota (v0.33, arte do Felipe: os capangas quebrando o carro na garagem): aparece
-- depois do resultado quando o prazo da divida venceu (campeonato.lua, Campeonato.aplicar), e
-- depois segue para o ranking da rodada.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"
local Texto = require "texto"

local Tela = {}
Tela.__index = Tela

local function dinheiro(v) return require("telas.garagem").dinheiro(v) end

-- cobranca: { levou = $, melhorias = bool }; rodada: os dados do ranking da rodada (telas/rodada.lua)
function Tela.nova(cobranca, rodada)
  local t = setmetatable({ q = 0, rodada = rodada }, Tela)
  t.linhas = {
    "OS CAPANGAS DO AGIOTA VIERAM COBRAR A DIVIDA.",
    "LEVARAM " .. dinheiro(cobranca.levou) .. (cobranca.melhorias and " E AS MELHORIAS DO CARRO." or "."),
  }
  return t
end

function Tela:atualizar()
  self.q = self.q + 1
  if self.q > 40 and Entrada.confirmar() then Jogo.ir("rodada", self.rodada) end
end

function Tela:desenhar()
  Menu.imagem("cobranca")
  ui.rectfill(0, 0, 479, 66, Cores.preto)
  Texto.centro("f3", "COBRAN\xC7A!", 6, "amarelo")
  Menu.centro(self.linhas[1], 38, Cores.branco)
  Menu.centro(self.linhas[2], 50, Cores.vermelho)
  if self.q > 40 then
    local s = Entrada.NOME.confirmar .. ": CONTINUAR"
    ui.rectfill(240 - #s * 3 - 4, 255, 240 + #s * 3 + 3, 266, Cores.preto)
    Menu.rodape(s)
  end
end

return Tela
