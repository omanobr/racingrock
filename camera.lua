-- Camera: segue o carro e olha para a frente, para onde ele esta indo (a velocidade, e nao o
-- bico do carro: na v0.12 cada toque no direcional mexia a camera na hora e a tela balancava).
-- O deslocamento para a frente chega ao alvo com uma mola amortecida (sem tranco nem vai e
-- vem); o carro em si e seguido na hora.
local C = require "config"

local Camera = {}
Camera.__index = Camera

local TELA_W = 480

-- alto: altura da visao (270 = a tela inteira; 2 jogadores: meia tela, e o olhar para a frente
-- na vertical diminui na mesma proporcao)
function Camera.nova(pista, carro, alto)
  alto = alto or 270
  local cam = setmetatable({ pista = pista, alvo = carro, alto = alto, frente_y = C.CAM_FRENTE_Y * alto // 270,
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
  local c, p, alto, frente_y = self.alvo, self.pista, self.alto, self.frente_y
  local dt = passo / 60
  local tx, ty = c.vx * C.CAM_ANTECIPA, c.vy * C.CAM_ANTECIPA
  if tx > C.CAM_FRENTE_X then tx = C.CAM_FRENTE_X elseif tx < -C.CAM_FRENTE_X then tx = -C.CAM_FRENTE_X end
  if ty > frente_y then ty = frente_y elseif ty < -frente_y then ty = -frente_y end
  if dt > 0 then
    self.fx, self.vfx = mola(self.fx, tx, self.vfx, C.CAM_SUAVE, dt)
    self.fy, self.vfy = mola(self.fy, ty, self.vfy, C.CAM_SUAVE, dt)
  end
  -- a partir da posicao do carro ja arredondada (como ele e desenhado): assim o carro nao treme
  -- 1 px na tela quando a camera e ele arredondam diferente
  local x0 = c.x // 1 + (self.fx + 0.5) // 1 - TELA_W // 2
  local y0 = c.y // 1 + (self.fy + 0.5) // 1 - alto // 2
  if x0 > p.largura - TELA_W then x0 = p.largura - TELA_W end
  if y0 > p.altura - alto then y0 = p.altura - alto end
  if x0 < 0 then x0 = 0 end
  if y0 < 0 then y0 = 0 end
  self.x0, self.y0 = x0, y0
end

return Camera
