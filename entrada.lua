-- Controles. "p" e o numero do jogador: 0, 1 ou 2.
--
-- Botao do controle (estilo Super Nintendo) -> constante do Lupi. No simulador a ligacao e
-- pela posicao (BTN_Z = o de baixo, B; BTN_X = o da direita, A...). No console e outra
-- (descoberta no GearX, tela de teste). ui.log so existe no simulador.
local E = {}

local NO_CONSOLE = ui.log == nil
local BOTAO = NO_CONSOLE
  and { B = BTN_Z, A = BTN_G, X = BTN_X, Y = BTN_F, L = BTN_Q, R = BTN_E }
  or { B = BTN_Z, A = BTN_X, X = BTN_Q, Y = BTN_E, L = BTN_F, R = BTN_G }
E.BOTAO = BOTAO
E.NO_CONSOLE = NO_CONSOLE
local B, A, X, Y, R = BOTAO.B, BOTAO.A, BOTAO.X, BOTAO.Y, BOTAO.R

-- Na corrida (o L fica de fora: no controle 1 ele faz o console parar uns segundos)
function E.acelera(p) return ui.btn(B, p) or ui.btn(UP, p) end
function E.freia(p) return ui.btn(A, p) or ui.btn(DOWN, p) end
function E.esquerda(p) return ui.btn(LEFT, p) end
function E.direita(p) return ui.btn(RIGHT, p) end
function E.turbo(p) return ui.btn(X, p) end
function E.atira(p) return ui.btn(Y, p) end
function E.mina(p) return ui.btnp(R, p) end

E.NOME = { confirmar = "B", voltar = "A", acelerar = "B", frear = "A", turbo = "X", atirar = "Y", mina = "R",
           pausa = "START" }

-- START: no console e o botao 6 (sem constante). No simulador o 6 e o A: la a pausa fica no
-- START de um controle de verdade (15 no raylib) e no L do teclado (tecla G).
local PAUSA = NO_CONSOLE and { 6 } or { 15, BOTAO.L }
function E.pausar()
  for p = 0, 2 do
    for i = 1, #PAUSA do
      if ui.btnp(PAUSA[i], p) then return true end
    end
  end
  return false
end

-- Menus: qualquer jogador pode mexer.
local function algum(botao)
  for p = 0, 2 do
    if ui.btnp(botao, p) then return true end
  end
  return false
end

function E.confirmar() return algum(B) end
function E.voltar() return algum(A) end
function E.cima() return algum(UP) end
function E.baixo() return algum(DOWN) end
function E.esq() return algum(LEFT) end
function E.dir() return algum(RIGHT) end

return E
