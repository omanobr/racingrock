-- Camera: segue o carro e olha para a frente dele, mais longe quanto mais rapido (como no
-- Death Rally). So o deslocamento para a frente e suavizado; o carro em si e seguido na hora.
local C = require "config"

local Camera = {}
Camera.__index = Camera

local sin, cos = math.sin, math.cos
local TELA_W, TELA_H = 480, 270

function Camera.nova(pista, carro)
  local cam = setmetatable({ pista = pista, alvo = carro, fx = 0, fy = 0 }, Camera)
  cam:atualizar(0)
  return cam
end

function Camera:atualizar(passo)
  local c, p = self.alvo, self.pista
  local f = c.v / c.vmax
  if f < 0 then f = 0 elseif f > 1 then f = 1 end
  local k = C.CAM_SEGUE * passo / 60
  if k > 1 then k = 1 end
  self.fx = self.fx + (sin(c.ang) * C.CAM_FRENTE_X * f - self.fx) * k
  self.fy = self.fy + (-cos(c.ang) * C.CAM_FRENTE_Y * f - self.fy) * k
  local x0 = (c.x + self.fx - TELA_W / 2) // 1
  local y0 = (c.y + self.fy - TELA_H / 2) // 1
  if x0 > p.largura - TELA_W then x0 = p.largura - TELA_W end
  if y0 > p.altura - TELA_H then y0 = p.altura - TELA_H end
  if x0 < 0 then x0 = 0 end
  if y0 < 0 then y0 = 0 end
  self.x0, self.y0 = x0, y0
end

return Camera
