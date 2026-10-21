-- Fisica de um carro, no jeito do Death Rally (1996), visto de cima.
--
-- O carro tem uma direcao (ang: 0 = para cima, cresce no sentido horario, em radianos) e
-- uma velocidade (v, px/s; negativa = de re). Enquanto vira, cresce um "deslize": o carro
-- anda um pouco de lado, para fora da curva, mais com pneu ruim (aderencia alta) e na terra.
-- Batidas em outros carros viram um empurrao (kx, ky) que some rapido.
-- Os comandos (acel, freio, volante, turbo) sao postos pelo jogador ou pelo computador.
local C = require "config"
local Pista = require "pista"

local Carro = {}
Carro.__index = Carro

local sin, cos, atan, exp, abs = math.sin, math.cos, math.atan, math.exp, math.abs
local DOIS_PI = 2 * math.pi
local PAREDE, FORA = Pista.PAREDE, Pista.FORA

-- pontos de contato com o muro (para frente, para a direita), em px, como no Death Rally:
-- bico (bit 1), cantos da frente (2 esquerdo, 4 direito), cantos de tras (8, 16) e o meio das
-- laterais (32, 64). O carro tem ~26 x 13.
local SONDA_F = { 13, 10, 10, -11, -11, 0, 0 }
local SONDA_R = { 0, -6, 6, -6, 6, -7, 7 }
local ESQUERDA = 2 | 8 | 32
local DIREITA = 4 | 16 | 64

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
  c.nome, c.img, c.humano = def.nome, def.img, def.humano
  c.batidas = 0
  c.no_muro = 0        -- segundos com o meio do carro no muro (corrida.lua resgata)
  c.tempo_travado = 0  -- segundos encostado no muro sem conseguir sair
  return c
end

-- quais pontos de contato estao no muro (bits) e quantos, com o carro em (x, y, a)
function Carro:bate(x, y, a, pista)
  local s, c = sin(a), cos(a)
  local m, n, bit = 0, 0, 1
  for i = 1, 7 do
    local f, r = SONDA_F[i], SONDA_R[i]
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

  -- volante: vira menos devagar; de re, ao contrario. Nao gira se o giro encostar no muro.
  local vol = self.volante
  if vol ~= 0 and v ~= 0 then
    local f = abs(v) / C.GIRO_VEL
    if f > 1 then f = 1 end
    local giro = self.giro * f * dt * vol
    if v < 0 then giro = -giro end
    local a = (self.ang + giro) % DOIS_PI
    if self:bate(self.x, self.y, a, pista) == 0 then self.ang = a end
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
  local lado = d * (v / 70) * ader / M
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
  -- ja estava encostado no muro (empurrado por outro carro): so anda se for para sair dele
  -- (na v0.1 andava livre e o carro atravessava o muro e sumia pelo gramado)
  local _, antes = self:bate(self.x, self.y, self.ang, pista)
  if antes > 0 then
    if n < antes then self.x, self.y = nx, ny else self.travado = true end
    return
  end
  -- bateu: fica onde estava
  self.batidas = self.batidas + 1
  self.bateu = true
  self.kx, self.ky, self.deslize = 0, 0, 0
  local v = self.v
  if m & 1 ~= 0 or m & 6 == 6 or (v < 0 and m & 24 ~= 0) then
    self.v = v * C.MURO_VOLTA                     -- de frente (ou de re, de traseira): volta
  else
    local giro = C.MURO_GIRO
    if m & DIREITA ~= 0 and m & ESQUERDA == 0 then giro = -giro end   -- encostou do lado direito: vira a esquerda
    local a = (self.ang + giro) % DOIS_PI
    if self:bate(self.x, self.y, a, pista) == 0 then self.ang = a end
    self.v = v * C.MURO_PERDA
  end
end

-- quadro da folha (0 a 24) e espelho, para a direcao atual (48 direcoes de 7,5 graus)
function Carro:quadro()
  local d = (self.ang * 48 / DOIS_PI + 0.5) // 1 % 48
  if d <= 24 then return d end
  return (48 - d) + 1024
end

return Carro
