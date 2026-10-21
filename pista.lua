-- Pista: os dados gerados por ferramentas/preparar_pista.py (pistas/<id>.lua) e consultas
-- rapidas sobre eles (terreno embaixo de um ponto, linha central).
local Pista = {}
Pista.__index = Pista

local byte = string.byte

-- letras do mapa de terreno (string.byte)
Pista.ASFALTO, Pista.TERRA, Pista.PAREDE, Pista.CHEGADA = 48, 49, 50, 51

local LISTA = { "p0" }   -- ids das pistas, na ordem do menu

function Pista.quantas() return #LISTA end

function Pista.carregar(n)
  local id = LISTA[n] or LISTA[1]
  local dados = require("pistas." .. id)
  local p = setmetatable(dados, Pista)
  p.id = id
  p.imagens = {}
  for i, nome in ipairs(dados.folhas) do p.imagens[i] = Sprites.img[id][nome] end
  p.n = #dados.linha.x
  p.passo_terreno = dados.terreno_px
  return p
end

-- letra do terreno no ponto (x, y) do mundo; fora do mapa e parede
function Pista:piso(x, y)
  local linha = self.terreno[y // self.passo_terreno + 1]
  if not linha or x < 0 then return 50 end
  return byte(linha, x // self.passo_terreno + 1) or 50
end

-- avanca/recua o indice da linha central mais perto de (x, y), a partir de i (poucos passos
-- por quadro: o carro anda no maximo ~6 px por quadro e os pontos estao a 16 px)
function Pista:seguir(i, x, y)
  local lx, ly, n = self.linha.x, self.linha.y, self.n
  local dx, dy = lx[i] - x, ly[i] - y
  local d = dx * dx + dy * dy
  for _ = 1, 4 do
    local j = i % n + 1
    dx, dy = lx[j] - x, ly[j] - y
    local dj = dx * dx + dy * dy
    if dj >= d then break end
    i, d = j, dj
  end
  for _ = 1, 4 do
    local j = (i - 2) % n + 1
    dx, dy = lx[j] - x, ly[j] - y
    local dj = dx * dx + dy * dy
    if dj >= d then break end
    i, d = j, dj
  end
  return i
end

-- indice mais perto (busca completa: so na largada e depois de um teleporte)
function Pista:mais_perto(x, y)
  local lx, ly = self.linha.x, self.linha.y
  local melhor, menor = 1, math.huge
  for i = 1, self.n do
    local dx, dy = lx[i] - x, ly[i] - y
    local d = dx * dx + dy * dy
    if d < menor then melhor, menor = i, d end
  end
  return melhor
end

return Pista
