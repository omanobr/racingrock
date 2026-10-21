-- Fisica de um carro, no jeito do Death Rally (1996), visto de cima.
--
-- O carro tem uma direcao (ang: 0 = para cima, cresce no sentido horario, em radianos) e
-- uma velocidade (v, px/s; negativa = de re). Enquanto vira, cresce um "deslize": o carro
-- anda um pouco de lado, para fora da curva, mais com pneu ruim (aderencia alta) e na terra.
-- Batidas em outros carros viram um empurrao (kx, ky) que some rapido.
-- Os comandos (acel, freio, volante, turbo) sao postos pelo jogador ou pelo computador.
local C = require "config"
local Pista = require "pista"
local Dados = require "dados_carros"

local Carro = {}
Carro.__index = Carro

local sin, cos, atan, exp, abs = math.sin, math.cos, math.atan, math.exp, math.abs
local DOIS_PI = 2 * math.pi
local PAREDE, FORA = Pista.PAREDE, Pista.FORA

-- pontos de contato com o muro, como no Death Rally: bico (bit 1), cantos da frente (2 esquerdo,
-- 4 direito), cantos de tras (8, 16) e o meio das laterais (32, 64). Medidos a partir do
-- tamanho de cada modelo (dados_carros.lua): para frente (F) e para a direita (R), em px.

local function sondas(comprimento, largura)
  local f, r = comprimento / 2, largura / 2
  return { f, f - 3, f - 3, -f + 2, -f + 2, 0, 0 }, { 0, -r + 1, r - 1, -r + 1, r - 1, -r, r }
end

-- desenho: DIRECOES direcoes; os quadros 0..metade estao nas folhas (0..POR_FOLHA-1 na primeira,
-- o resto na segunda) e as outras direcoes sao esses espelhados (+1024)
local DIRECOES, POR_FOLHA = Dados.direcoes, Dados.por_folha
Carro.MEIO_QUADRO = Dados.quadro // 2

function Carro.novo(def)
  local c = setmetatable({}, Carro)
  c.x, c.y, c.ang = def.x, def.y, def.ang
  c.v, c.vx, c.vy, c.deslize, c.kx, c.ky = 0, 0, 0, 0, 0, 0
  c.M = def.M
  c.aderencia = def.aderencia or C.ADERENCIA
  c.giro = math.rad(3.75 / (C.GIRO_BASE - 0.05 * (def.motor or 0)) * 70)
  c.vmax = (C.ACEL * c.M) / (C.ARRASTO + C.ARRASTO_ACEL)
  c.acel, c.freio, c.turbo, c.volante = false, false, false, 0
  c.turbo_carga = 1
  c.nome, c.humano = def.nome, def.humano
  c.img, c.img2, c.sombra, c.sombra2 = def.img, def.img2, def.sombra, def.sombra2   -- as 2 folhas de cada
  local medida = Dados[def.modelo] or { comprimento = 30, largura = 15 }
  c.comprimento, c.largura = medida.comprimento, medida.largura
  c.sonda_f, c.sonda_r = sondas(c.comprimento, c.largura)
  c.batidas = 0
  c.no_muro = 0        -- segundos com o meio do carro no muro (corrida.lua resgata)
  c.tempo_travado = 0  -- segundos encostado no muro sem conseguir sair
  return c
end

-- quais pontos de contato estao no muro (bits) e quantos, com o carro em (x, y, a)
function Carro:bate(x, y, a, pista)
  local s, c = sin(a), cos(a)
  local m, n, bit = 0, 0, 1
  local sf, sr = self.sonda_f, self.sonda_r
  for i = 1, 7 do
    local f, r = sf[i], sr[i]
    local p = pista:piso(x + s * f + c * r, y - c * f + s * r)
    if p == PAREDE or p == FORA then m, n = m | bit, n + 1 end
    bit = bit << 1
  end
  return m, n
end

function Carro:atualizar(dt, pista)
  -- elastico (corrida.lua, so no computador): como no Death Rally, multiplica a potencia
  local M, v = self.M * (self.elastico or 1), self.v
  local k = C.ARRASTO

  -- turbo (o tanque esvazia em ~3,7 s e enche devagar), acelerador, freio
  local turbo = self.turbo and self.turbo_carga > 0
  if turbo then
    self.turbo_carga = self.turbo_carga - 0.27 * dt
    v = v + C.ACEL_TURBO * M * dt
    k = k + C.ARRASTO_ACEL
  else
    self.turbo_carga = self.turbo_carga + 0.0137 * dt
    if self.turbo_carga > 1 then self.turbo_carga = 1 end
    if self.acel then
      v = v + C.ACEL * M * dt
      k = k + C.ARRASTO_ACEL
    end
  end
  if self.freio and not self.acel then
    v = v - C.FREIO * M * (v > 0 and 1 or 0.5) * dt
    local re = -C.RE_MAX * self.vmax
    if v < re then v = re end
  end

  local ader = self.aderencia
  local chao = pista:piso(self.x, self.y)
  if chao == Pista.TERRA then
    k = k + C.ARRASTO_TERRA
    ader = ader * C.TERRA_ESCORREGA
  end
  -- meio do carro no muro ou fora da pista: corrida.lua resgata (fora: 4x mais rapido)
  if chao == PAREDE then self.no_muro = self.no_muro + dt
  elseif chao == FORA then self.no_muro = self.no_muro + 4 * dt
  else self.no_muro = 0 end

  -- volante: gira ate parado (ideia do Felipe na v0.16, para sair de canto de muro), mais
  -- devagar; de re, ao contrario. Encostado no muro pode girar, desde que o giro nao enfie o
  -- carro mais (no maximo uma ponta encostada): era isso que prendia o carro nos cantos.
  local vol = self.volante
  if vol ~= 0 then
    local f = abs(v) / C.GIRO_VEL
    if f < C.GIRO_PARADO then f = C.GIRO_PARADO elseif f > 1 then f = 1 end
    local giro = self.giro * f * dt * vol
    if v < 0 then giro = -giro end
    local a = (self.ang + giro) % DOIS_PI
    local m, n = self:bate(self.x, self.y, a, pista)
    if m == 0 then
      self.ang = a
    else
      local _, agora = self:bate(self.x, self.y, self.ang, pista)
      if n <= agora or n <= 1 then self.ang = a end
    end
  end

  -- deslize
  local d = self.deslize
  if v > 0 then d = d + vol * C.DESLIZE_SOBE * dt end
  if d > 0 then
    d = d - C.DESLIZE_DESCE * dt
    if d < 0 then d = 0 elseif d > C.DESLIZE_MAX then d = C.DESLIZE_MAX end
  elseif d < 0 then
    d = d + C.DESLIZE_DESCE * dt
    if d > 0 then d = 0 elseif d < -C.DESLIZE_MAX then d = -C.DESLIZE_MAX end
  end
  self.deslize = d
  local lado = d * (v / (70 * C.ESCALA)) * ader / M
  if lado > C.DESLIZE_FREIA or lado < -C.DESLIZE_FREIA then k = k + C.ARRASTO end

  v = v * exp(-k * dt)
  self.v = v

  local va = self.ang - atan(lado / 11)
  local vx, vy = sin(va) * v, -cos(va) * v
  self.vx, self.vy = vx, vy
  local kx, ky = self.kx, self.ky
  local fim = exp(-C.EMPURRAO_FIM * dt)
  self.kx, self.ky = kx * fim, ky * fim
  self:mover(self.x + (vx + kx) * dt, self.y + (vy + ky) * dt, pista)
  self.tempo_travado = self.travado and (self.tempo_travado or 0) + dt or 0
end

function Carro:mover(nx, ny, pista)
  self.travado = false
  local m, n = self:bate(nx, ny, self.ang, pista)
  if m == 0 then
    self.x, self.y = nx, ny
    return
  end
  -- ja estava encostado no muro: anda se nao encostar mais do que ja estava (sai ou desliza
  -- ao longo do muro). Na v0.1 andava livre e atravessava o muro; na v0.12-0.16 so andava se
  -- fosse para sair, e o carro travava nos cantos.
  local m0, antes = self:bate(self.x, self.y, self.ang, pista)
  if antes > 0 then
    if n <= antes then
      self.x, self.y = nx, ny
      self.v = self.v * C.MURO_ARRASTA ^ (1 / 60)    -- arrastando no muro: perde velocidade
    else
      -- empurrando o muro: a velocidade zera (na v0.16 ela subia ate ~100 com o carro parado, e
      -- a re demorava a fazer efeito)
      self.travado = true
      self.v = self.v * 0.5
    end
    self:desencostar(m0, antes, pista)
    return
  end
  -- bateu: fica onde estava, e a reacao depende do angulo com o muro (a direcao do muro vem dos
  -- pontos de contato que bateram). Quase de frente: volta. De raspao: perde so a parte da
  -- velocidade que ia contra o muro e gira para ficar paralelo a ele, escorregando (na v0.16,
  -- nas curvas arredondadas as duas quinas batiam juntas, contava como "de frente" e o carro
  -- grudava na curva).
  self.batidas = self.batidas + 1
  self.bateu = true
  self.deslize = 0
  local v = self.v
  local nx_, ny_ = self:normal_do_muro(m)
  local s, c = sin(self.ang), cos(self.ang)
  local sentido = v < 0 and -1 or 1
  local dx, dy = s * sentido, -c * sentido              -- para onde o carro esta indo
  local contra = -(dx * nx_ + dy * ny_)                 -- 1 = de frente com o muro, 0 = paralelo
  self.kx, self.ky = 0, 0
  if contra > 0 then self.impacto = abs(v) * contra end   -- combate.lua tira vida
  if contra > C.MURO_DE_FRENTE then
    self.v = v * C.MURO_VOLTA                           -- de frente: volta
    return
  end
  if contra > 0 then
    -- gira na direcao do muro (no maximo MURO_GIRO), se o giro nao enfiar o carro no muro
    local tx, ty = dx + contra * nx_, dy + contra * ny_   -- direcao ao longo do muro
    local alvo = atan(tx * sentido, -ty * sentido)
    local dif = (alvo - self.ang + math.pi) % DOIS_PI - math.pi
    if dif > C.MURO_GIRO then dif = C.MURO_GIRO elseif dif < -C.MURO_GIRO then dif = -C.MURO_GIRO end
    local a = (self.ang + dif) % DOIS_PI
    local _, n = self:bate(self.x, self.y, a, pista)
    if n <= 1 then self.ang = a end
    self.v = v * (1 - C.MURO_PERDA * contra)
    -- e um empurraozinho para fora, para nao ficar raspando
    local q = abs(v) * contra * C.MURO_SEPARA
    self.kx, self.ky = nx_ * q, ny_ * q
  end
end

-- direcao (unitaria) para fora do muro, a partir dos pontos de contato que bateram (bits m)
function Carro:normal_do_muro(m)
  local s, c = sin(self.ang), cos(self.ang)
  local sf, sr = self.sonda_f, self.sonda_r
  local ex, ey, bit = 0, 0, 1
  for i = 1, 7 do
    if m & bit ~= 0 then
      ex, ey = ex - (s * sf[i] + c * sr[i]), ey - (-c * sf[i] + s * sr[i])
    end
    bit = bit << 1
  end
  local d = (ex * ex + ey * ey) ^ 0.5
  if d < 0.01 then return -s, c end
  return ex / d, ey / d
end

-- com pontas no muro (bits m), afasta o carro 1 px na direcao contraria a elas, se isso o
-- desencostar um pouco (assim ele nao fica preso com a quina dentro do muro)
function Carro:desencostar(m, n, pista)
  local ex, ey = self:normal_do_muro(m)
  local x, y = self.x + ex, self.y + ey
  local _, depois = self:bate(x, y, self.ang, pista)
  if depois < n then self.x, self.y = x, y end
end

-- folha (1 ou 2) e tile (com o espelho, +1024) da direcao atual
function Carro:quadro()
  local d = (self.ang * DIRECOES / DOIS_PI + 0.5) // 1 % DIRECOES
  local espelho = 0
  if d > DIRECOES // 2 then d, espelho = DIRECOES - d, 1024 end
  if d < POR_FOLHA then return 1, d + espelho end
  return 2, d - POR_FOLHA + espelho
end

return Carro
