-- Desenho do fundo da pista, regiao por regiao (cada regiao usa uma folha so: tiles seguidos da
-- mesma folha = uma carga so). Uma tela toca no maximo 9 folhas.
--
-- Pistas de imagem (v0.27): o fundo e feito de "tiras" de 16 x p.tira px (63), em regioes de
-- 16 colunas x 2 tiras (ferramentas/preparar_pista.py). Uma tela de 480x270 sao ~160 ui.tile;
-- com os tiles de 16x16 da v0.21 eram ~510, e o fundo era ~45% das instrucoes da corrida. A
-- pista de treino continua em tiles de 16x16 (p.mapa).
--
-- Pista espelhada (v0.28, pista.lua): a coluna c da tela e a coluna (colunas - 1 - c) da imagem,
-- desenhada com o tile espelhado (+1024). As mesmas folhas, nenhum arquivo novo.
--
-- O console NAO sabe desenhar imagem cortada pela borda da esquerda ou da direita da tela
-- (v0.11, teste de bordas no aparelho): o pedaco sai no lugar errado, o resto da lista de
-- desenho pode sumir e, com muitos pedacos assim (ui.map em blocos), o chip de video se perde
-- ate reiniciar o console. Por isso so as colunas de 16 px que cabem INTEIRAS na largura da tela
-- sao desenhadas; o vao que sobra em cada lado (0 a 15 px) fica embaixo das faixas pretas de
-- Fundo.MARGEM px que a tela da corrida desenha por cima. Em cima e embaixo pode cortar.
local Fundo = {}

local TS = 16
local TELA_W, TELA_H = 480, 270
Fundo.MARGEM = 16

-- tiras: p.regioes[linha][coluna] = { folha, { tiras da 1a linha }, { tiras da 2a } }; a
-- imagem de cada regiao e posta em .img uma vez so
local function preparar(p)
  for _, linha in ipairs(p.regioes) do
    for _, r in ipairs(linha) do r.img = p.imagens[r[1]] end
  end
  p.regioes_prontas = true
end

-- vistas: { { cx, cy, xa, xb }, ... }: cada visao desenha o ponto (x, y) do mundo em (x - cx,
-- y - cy) da tela, e so as colunas inteiras entre xa e xb da tela. Com 2 jogadores (v0.41, tela
-- dividida lado a lado), cada regiao sai para as duas visoes antes da proxima: uma folha que
-- aparece nas duas e lida do cartao uma vez so.
local function tiras(p, vistas, nv)
  if not p.regioes_prontas then preparar(p) end
  local tile = ui.tile
  local TH, RW, RT = p.tira, p.regiao_w, p.regiao_tiras
  local espelho, C = p.espelho, p.colunas
  -- colunas e linhas de tiras de cada visao e as regioes que alguma delas toca
  local ry0, ry1, rx0, rx1 = p.linhas, -1, C, -1
  for k = 1, nv do
    local v = vistas[k]
    -- colunas inteiras: a primeira comeca em x >= xa, a ultima termina em x <= xb
    local c0, c1 = -(-(v.cx + v.xa) // TS), (v.cx + v.xb) // TS - 1
    local r0, r1 = v.cy // TH, (v.cy + TELA_H - 1) // TH
    if c0 < 0 then c0 = 0 end
    if r0 < 0 then r0 = 0 end
    if c1 >= C then c1 = C - 1 end
    if r1 >= p.linhas then r1 = p.linhas - 1 end
    if espelho then c0, c1 = C - 1 - c1, C - 1 - c0 end   -- colunas da imagem que aparecem
    v.c0, v.c1, v.r0, v.r1 = c0, c1, r0, r1
    if c0 <= c1 and r0 <= r1 then
      if r0 // RT < ry0 then ry0 = r0 // RT end
      if r1 // RT > ry1 then ry1 = r1 // RT end
      if c0 // RW < rx0 then rx0 = c0 // RW end
      if c1 // RW > rx1 then rx1 = c1 // RW end
    end
  end
  local regioes = p.regioes
  for ry = ry0, ry1 do
    local linha = regioes[ry + 1]
    for rx = rx0, rx1 do
      local r = linha[rx + 1]
      local img = r.img
      local base = rx * RW
      for k = 1, nv do
        local v = vistas[k]
        local ta, tb = ry * RT, ry * RT + RT - 1      -- linhas de tiras desta regiao na visao
        if ta < v.r0 then ta = v.r0 end
        if tb > v.r1 then tb = v.r1 end
        local ca, cb = base, base + RW - 1
        if ca < v.c0 then ca = v.c0 end
        if cb > v.c1 then cb = v.c1 end
        if ta <= tb and ca <= cb then
          local cx, cy = v.cx, v.cy
          if espelho then
            local xa = (C - 1 - ca) * TS - cx
            for t = ta, tb do
              local nums, x, y = r[t - ry * RT + 2], xa, t * TH - cy
              for q = ca - base + 1, cb - base + 1 do
                tile(img, nums[q] + 1024, x, y)
                x = x - TS
              end
            end
          else
            local xa = ca * TS - cx
            for t = ta, tb do
              local nums, x, y = r[t - ry * RT + 2], xa, t * TH - cy
              for q = ca - base + 1, cb - base + 1 do
                tile(img, nums[q], x, y)
                x = x + TS
              end
            end
          end
        end
      end
    end
  end
end

-- tiles de 16x16 (pista de treino), regioes de p.regiao_w x p.regiao_h tiles, uma visao
local function mapa(p, camx, camy, xa, xb)
  local tile, imagens = ui.tile, p.imagens
  local c0, c1 = -(-(camx + xa) // TS), (camx + xb) // TS - 1
  local r0, r1 = camy // TS, (camy + TELA_H - 1) // TS
  if c0 < 0 then c0 = 0 end
  if r0 < 0 then r0 = 0 end
  if c1 >= p.colunas then c1 = p.colunas - 1 end
  if r1 >= p.linhas then r1 = p.linhas - 1 end
  local mapa = p.mapa
  local RW, RH = p.regiao_w, p.regiao_h
  local espelho, C = p.espelho, p.colunas
  if espelho then c0, c1 = C - 1 - c1, C - 1 - c0 end
  local ry = r0 - r0 % RH
  while ry <= r1 do
    local ra, rb = ry < r0 and r0 or ry, ry + RH - 1
    if rb > r1 then rb = r1 end
    local rx = c0 - c0 % RW
    while rx <= c1 do
      local ca, cb = rx < c0 and c0 or rx, rx + RW - 1
      if cb > c1 then cb = c1 end
      local img = imagens[mapa[ra + 1][ca + 1] >> 11]
      local y = ra * TS - camy
      local xa, passo, vira = ca * TS - camx, TS, 0
      if espelho then xa, passo, vira = (C - 1 - ca) * TS - camx, -TS, 1024 end
      for r = ra + 1, rb + 1 do
        local linha, x = mapa[r], xa
        for c = ca + 1, cb + 1 do
          tile(img, (linha[c] & 2047) ~ vira, x, y)
          x = x + passo
        end
        y = y + TS
      end
      rx = rx + RW
    end
    ry = ry + RH
  end
end

-- camx, camy: canto de cima a esquerda da tela no mundo (inteiros)
local UMA = { { xa = 0, xb = TELA_W } }
function Fundo.desenhar(p, camx, camy)
  if not p.tira then return mapa(p, camx, camy, 0, TELA_W) end
  local v = UMA[1]
  v.cx, v.cy = camx, camy
  tiras(p, UMA, 1)
end

-- varias visoes (2 jogadores): { { cx, cy, xa, xb }, ... } como em tiras
function Fundo.desenhar_vistas(p, vistas)
  if p.tira then return tiras(p, vistas, #vistas) end
  for _, v in ipairs(vistas) do mapa(p, v.cx, v.cy, v.xa, v.xb) end
end

return Fundo
