-- Marcas de pneu e poeira (v0.29, pedido do Felipe): enfeite no chao, desenhado antes dos carros.
-- Custo controlado (o Felipe perguntou se pesa): no maximo MARCAS pontos de pneu (um anel: os mais
-- velhos somem) e POEIRA nuvens, cada um um ui.rectfill, e so os que estao na tela; ~600 a 900
-- instrucoes por quadro (a corrida usa ~10 mil de ~16 mil).
--   marcas: so derrapando de verdade (deslize alto e rapido), nas 2 rodas de tras, a cada 3 quadros
--   poeira: andando na terra, uma nuvem a cada 5 quadros, que cresce e some em meio segundo
local Cores = require "cores"
local Pista = require "pista"

local Rastros = {}
Rastros.__index = Rastros

local MARCAS, POEIRA, POEIRA_DURA = 64, 16, 0.5
local sin, cos = math.sin, math.cos
local rectfill = ui.rectfill

function Rastros.novo()
  local r = setmetatable({ mx = {}, my = {}, i = 0, px = {}, py = {}, pt = {}, j = 0 }, Rastros)
  for k = 1, MARCAS do r.mx[k], r.my[k] = -9999, -9999 end
  for k = 1, POEIRA do r.px[k], r.py[k], r.pt[k] = -9999, -9999, POEIRA_DURA end
  return r
end

function Rastros:marca(x, y)
  local i = self.i % MARCAS + 1
  self.i = i
  self.mx[i], self.my[i] = x, y
end

function Rastros:atualizar(corrida, dt)
  local q = corrida.quadros
  local pt = self.pt
  for k = 1, POEIRA do pt[k] = pt[k] + dt end
  if q % 3 ~= 0 and q % 5 ~= 0 then return end
  local pista = corrida.pista
  for _, c in ipairs(corrida.carros) do
    if not c.destruido then
      local v = c.v < 0 and -c.v or c.v
      local s, co = sin(c.ang), cos(c.ang)
      local tras = 4 - c.comprimento / 2
      local bx, by = c.x + s * tras, c.y - co * tras      -- meio do para-choque de tras
      if q % 3 == 0 and v > 70 and (c.deslize > 18 or c.deslize < -18) then
        local l = c.largura / 2 - 2
        self:marca(bx + co * l, by + s * l)
        self:marca(bx - co * l, by - s * l)
      end
      if q % 5 == 0 and v > 60 and pista:piso(c.x, c.y) == Pista.TERRA then
        local j = self.j % POEIRA + 1
        self.j = j
        self.px[j], self.py[j], self.pt[j] = bx, by, 0
      end
    end
  end
end

-- x0, y0: canto da tela no mundo; so dentro das faixas pretas dos lados (16 px)
function Rastros:desenhar(x0, y0)
  local mx, my = self.mx, self.my
  local cor = Cores.fundo
  for k = 1, MARCAS do
    local sx, sy = (mx[k] - x0) // 1, (my[k] - y0) // 1
    if sx >= 16 and sx <= 462 and sy >= 0 and sy <= 268 then rectfill(sx, sy, sx + 1, sy + 1, cor) end
  end
  local px, py, pt = self.px, self.py, self.pt
  for k = 1, POEIRA do
    local t = pt[k]
    if t < POEIRA_DURA then
      local r = 1 + (t * 8) // 1                   -- cresce de 1 a 5 px
      local sx, sy = (px[k] - x0) // 1, (py[k] - y0) // 1
      if sx - r >= 16 and sx + r <= 463 and sy - r >= 0 and sy + r <= 269 then
        rectfill(sx - r, sy - r, sx + r, sy + r, t < POEIRA_DURA / 2 and Cores.terra or Cores.terra_escura)
      end
    end
  end
end

return Rastros
