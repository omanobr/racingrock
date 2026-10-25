-- Pista: os dados gerados por ferramentas/preparar_pista.py (pistas/<id>.lua) e consultas
-- rapidas sobre eles (terreno embaixo de um ponto, linha central).
local Pista = {}
Pista.__index = Pista

local byte = string.byte
local DOIS_PI = 2 * math.pi

-- letras do mapa de terreno (string.byte), das zonas da mascara de cada pista: pista (verde),
-- gramado/terra (amarelo, mais devagar), muro (azul, bloqueia), linha de chegada (branco) e
-- fora (vermelho: alem do muro; carro que chegar la volta para a pista)
Pista.ASFALTO, Pista.TERRA, Pista.PAREDE, Pista.CHEGADA, Pista.FORA = 48, 49, 50, 51, 52

-- as pistas, na ordem do menu: { id, nome } (ferramentas/preparar_pista.py)
Pista.LISTA = require "pistas.lista"

function Pista.quantas() return #Pista.LISTA end

-- Variantes de cada pista (v0.28, ideia do Felipe, como no Death Rally): a mesma imagem no
-- sentido inverso (preparar_pista.py grava a linha do meio e a largada ao contrario) e/ou
-- espelhada da esquerda para a direita (o console espelha os tiles: +1024), sem nenhum arquivo
-- novo. De cabeca para baixo nao da: ui.tile so espelha na horizontal.
Pista.VARIANTES = {
  { nome = "" },
  { nome = "INVERSA", inversa = true },
  { nome = "ESPELHADA", espelho = true },
  { nome = "ESPELHADA INVERSA", inversa = true, espelho = true },
}

-- letra do terreno no ponto (x, y) do mundo; fora do mapa e "fora"
local function piso(self, x, y)
  local linha = self.terreno[y // self.passo_terreno + 1]
  if not linha or x < 0 then return 52 end
  return byte(linha, x // self.passo_terreno + 1) or 52
end
Pista.piso = piso

-- na pista espelhada, o ponto x do mundo e o ponto largura - x da imagem
local function piso_espelhado(self, x, y)
  return piso(self, self.largura - x, y)
end

-- a linha central espelhada: x, direcao e curva ao contrario; direita e esquerda trocam
local function espelhar_linha(L, W)
  local m = { x = {}, y = L.y, ang = {}, curva = {}, livre_d = L.livre_e, livre_e = L.livre_d, reta = L.reta }
  for i = 1, #L.x do
    m.x[i] = W - L.x[i]
    m.ang[i] = (-L.ang[i]) % DOIS_PI
    m.curva[i] = -L.curva[i]
  end
  return m
end

-- n: indice em Pista.LISTA; variante: indice em Pista.VARIANTES
function Pista.carregar(n, variante)
  local id = (Pista.LISTA[n] or Pista.LISTA[1]).id
  local dados = require("pistas." .. id)
  -- copia rasa: o modulo (guardado pelo require) fica igual para a proxima corrida
  local p = {}
  for k, v in pairs(dados) do p[k] = v end
  setmetatable(p, Pista)
  p.id = id
  p.variante = Pista.VARIANTES[variante or 1] or Pista.VARIANTES[1]
  p.imagens = {}
  local pasta = Sprites.img[dados.pasta or id]   -- duas pistas podem usar as mesmas folhas
  for i, nome in ipairs(dados.folhas) do p.imagens[i] = pasta[nome] end
  if p.variante.inversa then p.linha, p.grade = dados.inversa, dados.grade_inv end
  if p.variante.espelho then
    p.espelho = true
    p.piso = piso_espelhado
    p.linha = espelhar_linha(p.linha, p.largura)
    local g = {}
    for i, v in ipairs(p.grade) do g[i] = { p.largura - v[1], v[2], (-v[3]) % DOIS_PI } end
    p.grade = g
  end
  p.n = #p.linha.x
  p.passo_terreno = dados.terreno_px
  return p
end

-- nome com a variante ("GRAMADO", "GRAMADO - INVERSA")
function Pista.nome(n, variante)
  local nome = (Pista.LISTA[n] or Pista.LISTA[1]).nome
  local v = Pista.VARIANTES[variante or 1]
  if v and v.nome ~= "" then nome = nome .. " - " .. v.nome end
  return nome
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
