-- Camera: segue o carro e olha para a frente, para onde ele esta indo (a velocidade, e nao o
-- bico do carro: na v0.12 cada toque no direcional mexia a camera na hora e a tela balancava).
-- O deslocamento para a frente chega ao alvo com uma mola amortecida (sem tranco nem vai e
-- vem); o carro em si e seguido na hora.
local C = require "config"

local Camera = {}
Camera.__index = Camera

local TELA_W, TELA_H = 480, 270

function Camera.nova(pista, carro)
  local cam = setmetatable({ pista = pista, alvo = carro, fx = 0, fy = 0, vfx = 0, vfy = 0 }, Camera)
  cam:atualizar(0)
  return cam
end

-- mola criticamente amortecida (o "SmoothDamp" dos motores de jogo): devolve posicao e velocidade
local function mola(atual, alvo, vel, tempo, dt)
  local w = 2 / tempo
  local x = w * dt
  local e = 1 / (1 + x + 0.48 * x * x + 0.235 * x * x * x)
  local dif = atual - alvo
  local t = (vel + w * dif) * dt
  return alvo + (dif + t) * e, (vel - w * t) * e
end

function Camera:atualizar(passo)
  local c, p = self.alvo, self.pista
  local dt = passo / 60
  local tx, ty = c.vx * C.CAM_ANTECIPA, c.vy * C.CAM_ANTECIPA
  if tx > C.CAM_FRENTE_X then tx = C.CAM_FRENTE_X elseif tx < -C.CAM_FRENTE_X then tx = -C.CAM_FRENTE_X end
  if ty > C.CAM_FRENTE_Y then ty = C.CAM_FRENTE_Y elseif ty < -C.CAM_FRENTE_Y then ty = -C.CAM_FRENTE_Y end
  if dt > 0 then
    self.fx, self.vfx = mola(self.fx, tx, self.vfx, C.CAM_SUAVE, dt)
    self.fy, self.vfy = mola(self.fy, ty, self.vfy, C.CAM_SUAVE, dt)
  end
  -- a partir da posicao do carro ja arredondada (como ele e desenhado): assim o carro nao treme
  -- 1 px na tela quando a camera e ele arredondam diferente
  local x0 = c.x // 1 + (self.fx + 0.5) // 1 - TELA_W // 2
  local y0 = c.y // 1 + (self.fy + 0.5) // 1 - TELA_H // 2
  if x0 > p.largura - TELA_W then x0 = p.largura - TELA_W end
  if y0 > p.altura - TELA_H then y0 = p.altura - TELA_H end
  if x0 < 0 then x0 = 0 end
  if y0 < 0 then y0 = 0 end
  self.x0, self.y0 = x0, y0
end

return Camera
