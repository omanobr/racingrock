-- Pilotos do computador. Seguem a linha central da pista (pontos a cada 16 px, feitos por
-- ferramentas/preparar_pista.py) mirando num ponto a frente, deslocado para a "faixa" do
-- piloto; tiram o pe nas curvas fechadas, desviam de quem esta logo a frente e dao re
-- quando ficam presos. O "elastico" (corrida.lua) acelera quem ficou para tras.
local C = require "config"

local IA = {}

local atan, abs, sin, cos, random = math.atan, math.abs, math.sin, math.cos, math.random
local PI, DOIS_PI = math.pi, 2 * math.pi

function IA.preparar(c)
  c.faixa = (random() - 0.5) * 0.8      -- -0.4 a 0.4 da meia largura (negativo = esquerda)
  c.troca_faixa = 2 + random() * 3
  c.preso, c.re = 0, 0
  c.elastico = 1
end

local function angulo_ate(c, x, y)
  return (atan(x - c.x, c.y - y) - c.ang + PI) % DOIS_PI - PI
end

function IA.pilotar(c, corrida, dt)
  local p = corrida.pista
  local n, linha = p.n, p.linha

  -- de re por um tempo (estava preso no muro ou em outro carro)
  if c.re > 0 then
    c.re = c.re - dt
    c.acel, c.freio, c.turbo = false, true, false
    c.volante = -c.volante_re
    return
  end

  local olhar = C.IA_OLHAR + abs(c.v) // C.IA_OLHAR_VEL
  local j = (c.idx + olhar - 1) % n + 1
  local a = linha.ang[j]
  local lado = c.faixa * p.meia_largura
  local erro = angulo_ate(c, linha.x[j] + cos(a) * lado, linha.y[j] + sin(a) * lado)
  local zona = C.IA_ZONA_MORTA
  c.volante = erro > zona and 1 or (erro < -zona and -1 or 0)

  local curva = abs(linha.curva[j])
  if curva > PI / 2 then curva = PI / 2 end
  local alvo = c.vmax * (1 - C.IA_CURVA * curva / (PI / 2)) * c.elastico
  -- carro desalinhado com a pista (rodou, bateu): devagar ate se endireitar
  if erro > 1.2 or erro < -1.2 then alvo = alvo * 0.4 end
  c.acel = c.v < alvo
  c.freio = c.v > alvo * 1.25
  c.turbo = false

  -- troca de faixa de vez em quando, e para desviar de quem esta logo a frente
  c.troca_faixa = c.troca_faixa - dt
  if c.troca_faixa <= 0 then
    c.faixa = (random() - 0.5) * 0.8
    c.troca_faixa = 2 + random() * 3
  end
  local frente_x, frente_y = sin(c.ang), -cos(c.ang)
  for _, o in ipairs(corrida.carros) do
    if o ~= c then
      local dx, dy = o.x - c.x, o.y - c.y
      local adiante = dx * frente_x + dy * frente_y
      if adiante > 0 and adiante < 1.5 * c.comprimento then
        local de_lado = dx * -frente_y + dy * frente_x   -- positivo: o outro esta a direita
        if de_lado < c.largura and de_lado > -c.largura then
          c.faixa = de_lado > 0 and -0.45 or 0.45
          c.troca_faixa = 1.5
        end
      end
    end
  end

  -- preso: acelerando sem sair do lugar
  if c.acel and abs(c.v) < 15 then c.preso = c.preso + dt else c.preso = 0 end
  if c.preso > 1.0 then
    c.preso = 0
    c.re = 0.9
    c.volante_re = c.volante ~= 0 and c.volante or 1
  end
end

return IA
