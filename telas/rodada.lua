-- Ranking depois de cada rodada do modo historia (como no Death Rally): os 20 pilotos deslizam da
-- posicao de antes para a de agora, os pontos sobem, e embaixo as "noticias da liga" (quem trocou
-- de carro, quem lidera, quem voce mandou para o ferro-velho, para onde voce foi).
local Entrada = require "entrada"
local Cores = require "cores"
local Menu = require "menu"
local Carros = require "carros"
local Campeonato = require "campeonato"
local DT = require "dados_telas"
local Lote = require "lote"

local Tela = {}
Tela.__index = Tela

local ESPERA, ANDA = 30, 90   -- quadros parado antes de comecar e quadros deslizando

local function chave(l) return l.jogador and "voce" or l.rival end

-- canto de cada posicao (2 colunas de 10, como na tela de ranking da garagem)
local function lugar(i)
  local col, lin = (i - 1) // 10, (i - 1) % 10
  return 44 + col * 216, 36 + lin * 18
end

-- manchetes da rodada (no maximo 3)
local function noticias(antes, depois, rodada_antes, abatidos)
  local n = {}
  for _, nome in ipairs(abatidos) do
    if #n < 1 then n[#n + 1] = "VOCE MANDOU " .. nome .. " PARA O FERRO-VELHO!" end
  end
  local pos_antes, pos_agora
  for i, l in ipairs(antes) do if l.jogador then pos_antes = i end end
  for i, l in ipairs(depois) do if l.jogador then pos_agora = i end end
  if pos_agora < pos_antes then n[#n + 1] = string.format("VOCE SOBE PARA %do NO RANKING", pos_agora)
  elseif pos_agora > pos_antes then n[#n + 1] = string.format("VOCE CAI PARA %do NO RANKING", pos_agora)
  else n[#n + 1] = string.format("VOCE CONTINUA EM %do", pos_agora) end
  -- rivais que trocaram de carro (o primeiro que achar)
  for i, p in ipairs(Campeonato.PILOTOS) do
    local a, b = Campeonato.carro_do_rival(i, rodada_antes), Campeonato.carro_do_rival(i, rodada_antes + 1)
    if b ~= a and #n < 3 then
      n[#n + 1] = string.format("%s TROCA O %s POR UM %s", p[1], Carros[a].nome, Carros[b].nome)
      break
    end
  end
  if #n < 3 then
    local l1, l0 = depois[1], antes[1]
    if chave(l1) ~= chave(l0) then n[#n + 1] = l1.nome .. " ASSUME A LIDERANCA DA LIGA"
    else n[#n + 1] = string.format("%s SEGUE NA FRENTE COM %d PONTOS", l1.nome, l1.pontos) end
  end
  return n
end

-- dados: { antes = ranking antes da corrida, rodada_antes, pontos, abatidos = { nomes } }
function Tela.nova(dados)
  local t = setmetatable({ q = 0 }, Tela)
  local e = Jogo.campeonato
  local depois = Campeonato.ranking(e)
  t.linhas = {}
  local de = {}
  for i, l in ipairs(dados.antes) do de[chave(l)] = { i, l.pontos } end
  for i, l in ipairs(depois) do
    local a = de[chave(l)] or { i, l.pontos }
    t.linhas[#t.linhas + 1] = { de = a[1], para = i, pontos_de = a[2], pontos = l.pontos, nome = l.nome,
                                carro = Carros[l.carro].nome, jogador = l.jogador,
                                retrato = l.jogador and DT.retrato.jogador or l.rival - 1 }
  end
  -- o jogador por ultimo: desenhado por cima dos outros enquanto desliza
  table.sort(t.linhas, function(a, b) return (a.jogador and 1 or 0) < (b.jogador and 1 or 0) end)
  t.noticias = noticias(dados.antes, depois, dados.rodada_antes, dados.abatidos or {})
  t.titulo = string.format("RANKING - RODADA %d", dados.rodada_antes + 1)
  return t
end

function Tela:atualizar()
  self.q = self.q + 1
  if Entrada.confirmar() then
    if self.q < ESPERA + ANDA then self.q = ESPERA + ANDA   -- pula a animacao
    else Jogo.ir("garagem") end
  end
end

-- uma linha do ranking, a fracao f do caminho entre a posicao de antes e a de agora
local function linha(l, f)
  local x0, y0 = lugar(l.de)
  local x1, y1 = lugar(l.para)
  local x, y = (x0 + (x1 - x0) * f) // 1, (y0 + (y1 - y0) * f) // 1
  local pos = f < 1 and l.de or l.para
  local pontos = (l.pontos_de + (l.pontos - l.pontos_de) * f + 0.5) // 1
  if l.jogador then ui.rectfill(x - 26, y - 5, x + 187, y + 12, Cores.vinho) end
  Lote.tile(Sprites.img.ui.ret16, l.retrato, x - 22, y - 4)
  local cor = l.jogador and Cores.amarelo or Cores.branco
  ui.print(string.format("%2d. %-10s %-7s %3d", pos, l.nome, l.carro, pontos), x, y, cor)
  if f >= 1 and l.para ~= l.de then
    local sobe = l.para < l.de
    ui.print((sobe and "+" or "-") .. math.abs(l.de - l.para), x + 168, y, sobe and Cores.verde or Cores.vermelho)
  end
end

function Tela:desenhar()
  Menu.fundo()
  Menu.cabecalho("RANKING", self.titulo:match("RODADA %d+"))
  local f = (self.q - ESPERA) / ANDA
  if f < 0 then f = 0 elseif f > 1 then f = 1 end
  f = f * f * (3 - 2 * f)   -- suave no comeco e no fim
  local eu
  for _, l in ipairs(self.linhas) do
    if l.jogador then eu = l else linha(l, f) end
  end
  if eu then
    Lote.desenhar()   -- a sua linha passa por cima das outras quando elas trocam de lugar
    linha(eu, f)
  end
  -- noticias da liga
  Menu.painel(12, 220, 456, 36, Cores.amarelo_escuro)
  for i, s in ipairs(self.noticias) do
    if i <= 3 then ui.print(s, 22, 211 + i * 11 + (i == 1 and 2 or 0), i == 1 and Cores.amarelo or Cores.branco) end
  end
  Menu.rodape(Entrada.NOME.confirmar .. ": CONTINUAR")
end

return Tela
