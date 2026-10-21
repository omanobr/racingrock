-- Desenho do fundo da pista (tiles de 16x16 de varias folhas), um ui.tile por tile, agrupados
-- por folha (tiles seguidos da mesma folha = uma carga so).
--
-- O console NAO sabe desenhar imagem cortada pela borda da esquerda ou da direita da tela
-- (v0.11, teste de bordas no aparelho): o pedaco sai no lugar errado, o resto da lista de
-- desenho pode sumir e, com muitos pedacos assim (ui.map em blocos), o chip de video se perde
-- ate reiniciar o console. Por isso so as colunas de tiles que cabem INTEIRAS na largura da tela
-- sao desenhadas; o vao que sobra em cada lado (0 a 15 px) fica embaixo das faixas pretas de
-- Fundo.MARGEM px que a tela da corrida desenha por cima. Em cima e embaixo pode cortar.
local Fundo = {}

local TS = 16
local TELA_W, TELA_H = 480, 270
Fundo.MARGEM = 16

local ATE = {}    -- por folha: { x1, y1, t1, x2, y2, t2, ... } do quadro
local N = {}

-- camx, camy: canto de cima a esquerda da tela no mundo (inteiros)
function Fundo.desenhar(p, camx, camy)
  local tile, imagens = ui.tile, p.imagens
  local S = #imagens
  for s = 1, S do N[s] = 0; ATE[s] = ATE[s] or {} end
  -- colunas inteiras: a primeira comeca em x >= 0, a ultima termina em x <= 480
  local c0, c1 = -(-camx // TS), (camx + TELA_W) // TS - 1
  local r0, r1 = camy // TS, (camy + TELA_H - 1) // TS
  if c0 < 0 then c0 = 0 end
  if r0 < 0 then r0 = 0 end
  if c1 >= p.colunas then c1 = p.colunas - 1 end
  if r1 >= p.linhas then r1 = p.linhas - 1 end
  local mapa = p.mapa
  local y = r0 * TS - camy
  local x0 = c0 * TS - camx
  if S == 1 then                         -- uma folha so: desenha direto
    local img = imagens[1]
    for r = r0 + 1, r1 + 1 do
      local linha, x = mapa[r], x0
      for c = c0 + 1, c1 + 1 do
        tile(img, linha[c] & 2047, x, y)
        x = x + TS
      end
      y = y + TS
    end
    return
  end
  for r = r0 + 1, r1 + 1 do
    local linha, x = mapa[r], x0
    for c = c0 + 1, c1 + 1 do
      local val = linha[c]
      local s = val >> 11
      local k = N[s]
      local b = ATE[s]
      b[k + 1], b[k + 2], b[k + 3] = x, y, val & 2047
      N[s] = k + 3
      x = x + TS
    end
    y = y + TS
  end
  for s = 1, S do
    local b, img = ATE[s], imagens[s]
    for k = 1, N[s], 3 do tile(img, b[k + 2], b[k], b[k + 1]) end
  end
end

return Fundo
