-- Desenho do fundo da pista (tiles de 16x16 de varias folhas), um ui.tile por tile, agrupados
-- por folha (tiles seguidos da mesma folha = uma carga so).
--
-- As pistas da v0.21 em diante sao divididas em regioes (p.regiao_w x p.regiao_h tiles) e cada
-- regiao usa uma folha so (ferramentas/preparar_pista.py): o fundo e desenhado regiao por
-- regiao, direto. Na v0.21 cada tile era separado por folha antes de desenhar, e isso era ~70%
-- das instrucoes da corrida (o console rodava a 48-54 FPS nas pistas de imagem).
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
  -- colunas inteiras: a primeira comeca em x >= 0, a ultima termina em x <= 480
  local c0, c1 = -(-camx // TS), (camx + TELA_W) // TS - 1
  local r0, r1 = camy // TS, (camy + TELA_H - 1) // TS
  if c0 < 0 then c0 = 0 end
  if r0 < 0 then r0 = 0 end
  if c1 >= p.colunas then c1 = p.colunas - 1 end
  if r1 >= p.linhas then r1 = p.linhas - 1 end
  local mapa = p.mapa
  local RW, RH = p.regiao_w, p.regiao_h
  if RW then
    local ry = r0 - r0 % RH
    while ry <= r1 do
      local ra, rb = ry < r0 and r0 or ry, ry + RH - 1
      if rb > r1 then rb = r1 end
      local rx = c0 - c0 % RW
      while rx <= c1 do
        local ca, cb = rx < c0 and c0 or rx, rx + RW - 1
        if cb > c1 then cb = c1 end
        local img = imagens[mapa[ra + 1][ca + 1] >> 11]
        local y, xa = ra * TS - camy, ca * TS - camx
        for r = ra + 1, rb + 1 do
          local linha, x = mapa[r], xa
          for c = ca + 1, cb + 1 do
            tile(img, linha[c] & 2047, x, y)
            x = x + TS
          end
          y = y + TS
        end
        rx = rx + RW
      end
      ry = ry + RH
    end
    return
  end
  local y = r0 * TS - camy
  local x0 = c0 * TS - camx
  for s = 1, S do N[s] = 0; ATE[s] = ATE[s] or {} end
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
