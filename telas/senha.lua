-- Digitar o password (estilo Super Nintendo): 8 letras. Direcional para os lados escolhe a
-- casa, para cima e para baixo troca a letra; B confere; A volta (na primeira casa) ou volta
-- uma casa.
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"
local Campeonato = require "campeonato"
local Texto = require "texto"

local Tela = {}
Tela.__index = Tela

local ALFA = Campeonato.ALFABETO
local N = #ALFA

-- o ultimo password digitado nesta sessao (para corrigir uma letra sem digitar tudo de novo)
local ultimo

function Tela.nova()
  local t = setmetatable({ casa = 1, letras = {}, aviso = nil, aviso_t = 0 }, Tela)
  local base = ultimo or (Jogo.campeonato and Campeonato.senha(Jogo.campeonato)) or "AAAAAAAA"
  for i = 1, 8 do t.letras[i] = ALFA:find(base:sub(i, i), 1, true) or 1 end
  return t
end

function Tela:texto()
  local s = {}
  for i = 1, 8 do s[i] = ALFA:sub(self.letras[i], self.letras[i]) end
  return table.concat(s)
end

function Tela:atualizar()
  if self.aviso_t > 0 then self.aviso_t = self.aviso_t - 1 end
  if Entrada.esq() then self.casa = (self.casa - 2) % 8 + 1 end
  if Entrada.dir() then self.casa = self.casa % 8 + 1 end
  local l = self.letras
  -- segurando cima/baixo, depois de 1/3 de segundo a letra corre (4 por segundo... 15)
  local segura = 0
  for p = 0, 2 do
    if ui.btn(UP, p) then segura = 1 elseif ui.btn(DOWN, p) then segura = -1 end
  end
  self.segura = segura ~= 0 and (self.segura or 0) + 1 or 0
  local repete = self.segura > 20 and self.segura % 4 == 0
  if Entrada.cima() or (repete and segura == 1) then l[self.casa] = l[self.casa] % N + 1 end
  if Entrada.baixo() or (repete and segura == -1) then l[self.casa] = (l[self.casa] - 2) % N + 1 end
  if Entrada.voltar() then
    if self.casa == 1 then Jogo.ir("historia") return end
    self.casa = self.casa - 1
  end
  if Entrada.confirmar() then
    ultimo = self:texto()
    local e = Campeonato.ler_senha(ultimo)
    if e then
      Jogo.campeonato = e
      Jogo.ir("garagem")
    else
      self.aviso, self.aviso_t = "PASSWORD INVALIDO: CONFIRA AS LETRAS", 180
    end
  end
end

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho("PASSWORD")
  Menu.centro("DIGITE O PASSWORD QUE VOCE ANOTOU", 60, Cores.cinza_claro)
  -- 8 casas de 27 px, com um espaco no meio (ABCD EFGH)
  local x0 = 240 - (8 * 31 + 14) // 2
  for i = 1, 8 do
    local x = x0 + (i - 1) * 31 + (i > 4 and 14 or 0)
    local aqui = i == self.casa
    Menu.painel(x, 96, 27, 33, aqui and Cores.amarelo or Cores.cinza_escuro)
    if aqui then ui.rectfill(x + 1, 97, x + 25, 127, Cores.vinho) end
    local k = self.letras[i]
    Texto.escrever("f3", ALFA:sub(k, k), x + 5, 101, "amarelo")
    if aqui then
      ui.print("^", x + 11, 86, Cores.amarelo)
      ui.print("v", x + 11, 133, Cores.amarelo)
    end
  end
  if self.aviso_t > 0 then Menu.centro(self.aviso, 160, Cores.vermelho) end
  Menu.centro("LETRAS: " .. ALFA, 190, Cores.cinza)
  Menu.centro("CIMA/BAIXO: TROCA A LETRA   ESQUERDA/DIREITA: CASA", 230, Cores.cinza_claro)
  Menu.rodape(Entrada.NOME.confirmar .. ": CONFERIR   " .. Entrada.NOME.voltar .. ": VOLTAR")
end

return Tela
