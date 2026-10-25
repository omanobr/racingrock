-- Desenho do fundo da pista, regiao por regiao (cada regiao usa uma folha so: tiles seguidos da
-- mesma folha = uma carga so). Uma tela toca no maximo 9 folhas.
--
-- Pistas de imagem (v0.27): o fundo e feito de "tiras" de 16 x p.tira px (63), em regioes de
-- 16 colunas x 2 tiras (ferramentas/preparar_pista.py). Uma tela de 480x270 sao ~160 ui.tile;
-- com os tiles de 16x16 da v0.21 eram ~510, e o fundo era ~45% das instrucoes da corrida. A
-- pista de treino continua em tiles de 16x16 (p.mapa).
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

local function tiras(p, camx, camy)
  if not p.regioes_prontas then preparar(p) end
  local tile = ui.tile
  local TH, RW, RT = p.tira, p.regiao_w, p.regiao_tiras
  -- colunas inteiras: a primeira comeca em x >= 0, a ultima termina em x <= 480
  local c0, c1 = -(-camx // TS), (camx + TELA_W) // TS - 1
  local r0, r1 = camy // TH, (camy + TELA_H - 1) // TH
  if c0 < 0 then c0 = 0 end
  if r0 < 0 then r0 = 0 end
  if c1 >= p.colunas then c1 = p.colunas - 1 end
  if r1 >= p.linhas then r1 = p.linhas - 1 end
  local regioes = p.regioes
  for ry = r0 // RT, r1 // RT do
    local linha = regioes[ry + 1]
    local ta, tb = ry * RT, ry * RT + RT - 1        -- linhas de tiras desta regiao na tela
    if ta < r0 then ta = r0 end
    if tb > r1 then tb = r1 end
    for rx = c0 // RW, c1 // RW do
      local r = linha[rx + 1]
      local img = r.img
      local base = rx * RW
      local ca, cb = base, base + RW - 1
      if ca < c0 then ca = c0 end
      if cb > c1 then cb = c1 end
      local xa = ca * TS - camx
      for t = ta, tb do
        local nums, x, y = r[t - ry * RT + 2], xa, t * TH - camy
        for k = ca - base + 1, cb - base + 1 do
          tile(img, nums[k], x, y)
          x = x + TS
        end
      end
    end
  end
end

-- camx, camy: canto de cima a esquerda da tela no mundo (inteiros)
function Fundo.desenhar(p, camx, camy)
  if p.tira then return tiras(p, camx, camy) end
  -- tiles de 16x16 (pista de treino), regioes de p.regiao_w x p.regiao_h tiles
  local tile, imagens = ui.tile, p.imagens
  local c0, c1 = -(-camx // TS), (camx + TELA_W) // TS - 1
  local r0, r1 = camy // TS, (camy + TELA_H - 1) // TS
  if c0 < 0 then c0 = 0 end
  if r0 < 0 then r0 = 0 end
  if c1 >= p.colunas then c1 = p.colunas - 1 end
  if r1 >= p.linhas then r1 = p.linhas - 1 end
  local mapa = p.mapa
  local RW, RH = p.regiao_w, p.regiao_h
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
end

return Fundo
