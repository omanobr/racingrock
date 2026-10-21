-- Desenho do fundo da pista (tiles de 16x16 de varias folhas). Tres jeitos, escolhidos por
-- C.FUNDO, para comparar no aparelho (teste de desempenho):
--
--   "visao" : uma tabela no formato do ui.map (o mesmo que o servidor gera dos mapas do Tiled,
--             como no caio-pernocas e no balao-gatinho) cobrindo a tela com folga. So e refeita
--             quando a camera sai da folga; o resto e uma chamada ui.map por quadro.
--   "mapa"  : a pista cortada em blocos fixos de 16x16 tiles (feitos uma vez); desenha os
--             blocos que aparecem (ate 9 chamadas ui.map). Zero conta em Lua, mas cada bloco
--             carrega as folhas dele de novo.
--   "tiles" : um ui.tile por tile, agrupados por folha (uma carga por folha). O que ja se sabe
--             que funciona no console, mas sao ~560 chamadas por quadro.
local Fundo = {}

local TS = 16
local TELA_W, TELA_H = 480, 270

-- ---------------------------------------------------------------- "visao"
local VW, VH = 40, 26      -- tiles na visao (640x416 px: a tela + 5 tiles de folga para cada lado)
local FOLGA = 4            -- refaz quando a camera chega a menos de 4 tiles da borda da visao

local function nova_camada(p, w, h)
  local camada = { metadata = { width = w, height = h, tile_size = TS }, tilesets = {} }
  for _, nome in ipairs(p.folhas) do
    camada[nome] = {}
    camada.tilesets[nome] = nome
  end
  return camada
end

local function preparar_visao(p)
  local v = { camada = nova_camada(p, VW, VH), c0 = -999, r0 = -999, usados = {}, n_usados = {} }
  v.tabelas = {}
  for s, nome in ipairs(p.folhas) do
    v.tabelas[s] = v.camada[nome]
    v.usados[s], v.n_usados[s] = {}, 0
  end
  return v
end

local function refazer_visao(p, v, c0, r0)
  local tabelas, usados, n_usados = v.tabelas, v.usados, v.n_usados
  for s = 1, #tabelas do               -- apaga o que foi posto da ultima vez
    local t, u = tabelas[s], usados[s]
    for k = 1, n_usados[s] do t[u[k]] = nil end
    n_usados[s] = 0
  end
  local mapa, cols, lins = p.mapa, p.colunas, p.linhas
  local i = 0
  for r = r0 + 1, r0 + VH do
    local linha = mapa[r]
    if linha then
      for c = c0 + 1, c0 + VW do
        i = i + 1
        local val = linha[c]
        if val then
          local s = val >> 11
          local k = n_usados[s] + 1
          n_usados[s] = k
          usados[s][k] = i
          tabelas[s][i] = val & 2047
        end
      end
    else
      i = i + VW
    end
  end
  v.c0, v.r0 = c0, r0
  v.refeitas = (v.refeitas or 0) + 1
end

local function desenhar_visao(p, camx, camy)
  local v = p.visao
  if not v then v = preparar_visao(p); p.visao = v end
  local c, r = camx // TS, camy // TS
  if c < v.c0 + FOLGA or r < v.r0 + FOLGA or c + TELA_W // TS + 1 > v.c0 + VW - FOLGA
    or r + TELA_H // TS + 1 > v.r0 + VH - FOLGA then
    refazer_visao(p, v, c - (VW - TELA_W // TS) // 2, r - (VH - TELA_H // TS) // 2)
  end
  ui.camera(camx, camy)
  ui.map(v.camada, v.c0 * TS, v.r0 * TS)
  ui.camera()
end

-- ---------------------------------------------------------------- "mapa"
local BLOCO = 16

local function preparar_blocos(p)
  local blocos = {}
  for br = 0, (p.linhas - 1) // BLOCO do
    blocos[br] = {}
    for bc = 0, (p.colunas - 1) // BLOCO do
      local camada = nova_camada(p, BLOCO, BLOCO)
      local i = 0
      for r = br * BLOCO + 1, br * BLOCO + BLOCO do
        local linha = p.mapa[r]
        for c = bc * BLOCO + 1, bc * BLOCO + BLOCO do
          i = i + 1
          local val = linha and linha[c]
          if val then camada[p.folhas[val >> 11]][i] = val & 2047 end
        end
      end
      for _, nome in ipairs(p.folhas) do     -- folha que nao aparece no bloco: fora da camada
        if next(camada[nome]) == nil then camada[nome] = nil; camada.tilesets[nome] = nil end
      end
      blocos[br][bc] = camada
    end
  end
  return blocos
end

local function desenhar_blocos(p, camx, camy)
  local blocos = p.blocos
  if not blocos then blocos = preparar_blocos(p); p.blocos = blocos end
  local px = BLOCO * TS
  ui.camera(camx, camy)
  for br = camy // px, (camy + TELA_H - 1) // px do
    local linha = blocos[br]
    if linha then
      for bc = camx // px, (camx + TELA_W - 1) // px do
        local camada = linha[bc]
        if camada then ui.map(camada, bc * px, br * px) end
      end
    end
  end
  ui.camera()
end

-- ---------------------------------------------------------------- "tiles"
local ATE = {}    -- por folha: { x1, y1, t1, x2, y2, t2, ... } do quadro
local N = {}

local function desenhar_tiles(p, camx, camy)
  local tile, imagens = ui.tile, p.imagens
  local S = #imagens
  for s = 1, S do N[s] = 0; ATE[s] = ATE[s] or {} end
  local c0, r0 = camx // TS, camy // TS
  local c1, r1 = (camx + TELA_W - 1) // TS, (camy + TELA_H - 1) // TS
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

local MODOS = { visao = desenhar_visao, mapa = desenhar_blocos, tiles = desenhar_tiles }

-- camx, camy: canto de cima a esquerda da tela no mundo (inteiros)
function Fundo.desenhar(p, camx, camy, modo)
  MODOS[modo](p, camx, camy)
end

return Fundo
