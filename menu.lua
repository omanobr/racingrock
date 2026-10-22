-- Menu de lista, usado por todas as telas: direcional para cima e para baixo escolhe, B confirma.
-- (O A, voltar, cada tela trata do seu jeito.)
-- opcoes: { { texto = "..." ou funcao, acao = funcao, valor = funcao (texto do valor, opcional),
--             ativo = funcao (opcional: false = cinza, nao escolhe) }, ... }
-- Letras grandes (texto.lua, f2) com a palheta de guitarra na opcao escolhida; pequeno = true
-- usa a letra do console (listas com colunas: oficina, loja).
local Entrada = require "entrada"
local Cores = require "cores"
local Texto = require "texto"

local Menu = {}
Menu.__index = Menu

function Menu.novo(opcoes, x, y, passo, largura, pequeno)
  return setmetatable({ opcoes = opcoes, escolha = 1, x = x or 130, y = y or 100, passo = passo or 20,
                        largura = largura or 240, pequeno = pequeno }, Menu)
end

function Menu:atual() return self.opcoes[self.escolha] end

function Menu:atualizar()
  local n = #self.opcoes
  if Entrada.cima() then self.escolha = (self.escolha - 2) % n + 1 end
  if Entrada.baixo() then self.escolha = self.escolha % n + 1 end
  if Entrada.confirmar() then
    local o = self.opcoes[self.escolha]
    if not o.ativo or o.ativo() then o.acao() end
  end
end

function Menu:desenhar()
  local x = self.x
  for i, o in ipairs(self.opcoes) do
    local y = self.y + (i - 1) * self.passo
    local texto = type(o.texto) == "function" and o.texto() or o.texto
    if o.valor then texto = texto .. ": " .. o.valor() end
    local ativo = not o.ativo or o.ativo()
    local escolhida = i == self.escolha
    if self.pequeno then
      if escolhida then ui.rectfill(x - 10, y - 4, x - 10 + self.largura - 1, y + 10, Cores.vinho) end
      ui.print(texto, x, y, (escolhida and ativo) and Cores.branco or (ativo and Cores.cinza_claro or Cores.cinza))
    else
      if escolhida then
        ui.rectfill(x - 22, y - 2, x - 22 + self.largura - 1, y + 15, Cores.vinho)
        Texto.extra("palheta", x - 18, y)
      end
      Texto.escrever("f2", texto, x, y, (escolhida and ativo) and "amarelo" or (ativo and "branco" or "cinza"))
    end
  end
end

-- titulo de tela: faixa preta com a zebrada amarela e o titulo grande no meio (y 0 a 27)
function Menu.cabecalho(texto, direita)
  ui.rectfill(0, 0, 479, 27, Cores.preto)
  for x = 0, 468, 12 do Texto.extra("zebrada", x, 6) end
  local w = Texto.largura("f3", texto)
  ui.rectfill(240 - w // 2 - 12, 0, 240 + w // 2 + 11, 27, Cores.preto)
  ui.rectfill(0, 27, 479, 27, Cores.amarelo_escuro)
  Texto.escrever("f3", texto, 240 - w // 2, 2, "amarelo")
  if direita then
    local dw = #direita * 6
    ui.rectfill(470 - dw, 7, 475, 20, Cores.preto)
    ui.print(direita, 473 - dw, 10, Cores.cinza_claro)
  end
end

-- fundo das telas de menu
function Menu.fundo()
  ui.cls(Cores.fundo)
end

-- painel: caixa preta com borda
function Menu.painel(x, y, w, h, borda)
  ui.rectfill(x, y, x + w - 1, y + h - 1, borda or Cores.cinza_escuro)
  ui.rectfill(x + 1, y + 1, x + w - 2, y + h - 2, Cores.preto)
end

-- texto pequeno centralizado
function Menu.centro(texto, y, cor)
  ui.print(texto, 240 - #texto * 3, y, cor or Cores.branco)
end

-- rodape com a ajuda dos botoes
function Menu.rodape(texto)
  ui.print(texto, 240 - #texto * 3, 258, Cores.cinza)
end

return Menu
