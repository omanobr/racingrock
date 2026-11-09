-- Camera: segue o carro e olha para a frente, para onde ele esta indo (a velocidade, e nao o
-- bico do carro: na v0.12 cada toque no direcional mexia a camera na hora e a tela balancava).
-- O deslocamento para a frente chega ao alvo com uma mola amortecida (sem tranco nem vai e
-- vem); o carro em si e seguido na hora.
local C = require "config"

local Camera = {}
Camera.__index = Camera

local TELA_H = 270

-- largo: largura da visao (480 = a tela inteira; 2 jogadores: 240, e o olhar para a frente na
-- horizontal diminui na mesma proporcao)
function Camera.nova(pista, carro, largo)
  largo = largo or 480
  local cam = setmetatable({ pista = pista, alvo = carro, largo = largo, frente_x = C.CAM_FRENTE_X * largo // 480,
                             fx = 0, fy = 0, vfx = 0, vfy = 0 }, Camera)
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
  local c, p, largo, frente_x = self.alvo, self.pista, self.largo, self.frente_x
  local dt = passo / 60
  local tx, ty = c.vx * C.CAM_ANTECIPA, c.vy * C.CAM_ANTECIPA
  if tx > frente_x then tx = frente_x elseif tx < -frente_x then tx = -frente_x end
  if ty > C.CAM_FRENTE_Y then ty = C.CAM_FRENTE_Y elseif ty < -C.CAM_FRENTE_Y then ty = -C.CAM_FRENTE_Y end
  if dt > 0 then
    self.fx, self.vfx = mola(self.fx, tx, self.vfx, C.CAM_SUAVE, dt)
    self.fy, self.vfy = mola(self.fy, ty, self.vfy, C.CAM_SUAVE, dt)
  end
  -- a partir da posicao do carro ja arredondada (como ele e desenhado): assim o carro nao treme
  -- 1 px na tela quando a camera e ele arredondam diferente
  local x0 = c.x // 1 + (self.fx + 0.5) // 1 - largo // 2
  local y0 = c.y // 1 + (self.fy + 0.5) // 1 - TELA_H // 2
  if x0 > p.largura - largo then x0 = p.largura - largo end
  if y0 > p.altura - TELA_H then y0 = p.altura - TELA_H end
  if x0 < 0 then x0 = 0 end
  if y0 < 0 then y0 = 0 end
  self.x0, self.y0 = x0, y0
end

return Camera
