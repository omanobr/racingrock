-- Menu de lista, usado por todas as telas: direcional para cima e para baixo escolhe, B confirma.
-- (O A, voltar, cada tela trata do seu jeito.)
-- opcoes: { { texto = "..." ou funcao, acao = funcao, valor = funcao (texto do valor, opcional),
--             ativo = funcao (opcional: false = cinza, nao escolhe) }, ... }
local Entrada = require "entrada"
local Cores = require "cores"

local Menu = {}
Menu.__index = Menu

function Menu.novo(opcoes, x, y, passo, largura)
  return setmetatable({ opcoes = opcoes, escolha = 1, x = x or 130, y = y or 100, passo = passo or 16,
                        largura = largura or 240 }, Menu)
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
    if i == self.escolha then
      ui.rectfill(x - 10, y - 4, x - 10 + self.largura - 1, y + 10, Cores.vermelho)
      ui.print(texto, x, y, ativo and Cores.branco or Cores.cinza_claro)
    else
      ui.print(texto, x, y, ativo and Cores.cinza_claro or Cores.cinza)
    end
  end
end

-- titulo de tela: faixa preta com o texto no meio
function Menu.cabecalho(texto, direita)
  ui.rectfill(0, 0, 479, 19, Cores.preto)
  ui.print(texto, 240 - #texto * 3, 6, Cores.amarelo)
  if direita then ui.print(direita, 472 - #direita * 6, 6, Cores.cinza_claro) end
end

-- texto centralizado
function Menu.centro(texto, y, cor)
  ui.print(texto, 240 - #texto * 3, y, cor or Cores.branco)
end

-- rodape com a ajuda dos botoes
function Menu.rodape(texto)
  ui.print(texto, 240 - #texto * 3, 258, Cores.cinza)
end

return Menu
