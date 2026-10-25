-- Pilotos do computador. Seguem a linha central da pista (pontos a cada 16 px, feitos por
-- ferramentas/preparar_pista.py) mirando num ponto a frente, deslocado para a linha de corrida
-- (por dentro das curvas) e para a "faixa" do piloto; miram para onde o carro VAI (com a
-- derrapagem), tiram o pe nas curvas, usam o turbo nas retas, desviam de quem esta logo a
-- frente, saem de perto do muro quando raspam e dao re quando ficam presos. O "elastico"
-- (corrida.lua) acelera quem ficou para tras.
--
-- v0.27 (o Felipe quase dava uma volta neles com o mesmo carro): ate a v0.26 miravam para onde
-- o bico apontava (derrapando, abriam a curva e raspavam no muro: o fusca batia ~200 vezes por
-- corrida no gramado), seguiam o meio da pista com uma faixa sorteada e nunca usavam o turbo.
-- Sozinhos na pista, nas 5 pistas, com fusca, corsa e puma: 1209 s -> 1013 s, quase sem bater.
-- O nivel (C.NIVEIS, c.nivel) muda quanto tiram o pe, quanto erram a linha e o turbo.
local C = require "config"

local IA = {}

local atan, abs, sin, cos, random = math.atan, math.abs, math.sin, math.cos, math.random
local PI, DOIS_PI = math.pi, 2 * math.pi

-- linha de corrida da pista (uma vez por pista, na largada): em cada ponto da linha central, um
-- deslocamento para o lado de dentro da curva (fracao da meia largura), sem chegar perto do muro
-- (livre_d/livre_e: espaco medido por ferramentas/preparar_pista.py)
function IA.pista(p)
  if p.ia_linha then return end
  local n, L = p.n, p.linha
  local ang, meia = L.ang, p.meia_largura
  local w = C.IA_LINHA_JANELA
  local bruto = {}
  for i = 1, n do
    local k = (ang[(i - 1 + w) % n + 1] - ang[(i - 1 - w) % n + 1] + PI) % DOIS_PI - PI
    local o = k * C.IA_LINHA
    if o > C.IA_LINHA_MAX then o = C.IA_LINHA_MAX elseif o < -C.IA_LINHA_MAX then o = -C.IA_LINHA_MAX end
    bruto[i] = o
  end
  local linha = {}
  for i = 1, n do
    local s = 0
    for d = -3, 3 do s = s + bruto[(i - 1 + d) % n + 1] end
    local o = s / 7 * meia
    local d, e = L.livre_d[i] - C.IA_MARGEM, L.livre_e[i] - C.IA_MARGEM
    if o > d then o = d elseif o < -e then o = -e end
    linha[i] = o / meia
  end
  p.ia_linha = linha
end

-- nivel: um de C.NIVEIS (o piloto automatico do jogador usa o normal)
function IA.preparar(c, nivel)
  c.nivel = nivel or C.NIVEIS[2]
  c.faixa = (random() - 0.5) * 2 * c.nivel.faixa   -- negativo = esquerda
  c.troca_faixa = 2 + random() * 3
  c.preso, c.re = 0, 0
  c.elastico = 1
  c.afasta = 0
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

  local N = c.nivel
  local v = c.v
  local olhar = C.IA_OLHAR + abs(v) // C.IA_OLHAR_VEL
  local j = (c.idx + olhar - 1) % n + 1
  local a = linha.ang[j]
  local lado = (c.faixa + c.afasta + p.ia_linha[j]) * p.meia_largura
  local tx, ty = linha.x[j] + cos(a) * lado, linha.y[j] + sin(a) * lado
  local rumo = c.ang
  if v > C.IA_RUMO_VEL then rumo = atan(c.vx, -c.vy) end   -- para onde o carro vai (com o deslize)
  local erro = (atan(tx - c.x, c.y - ty) - rumo + PI) % DOIS_PI - PI
  local zona = C.IA_ZONA_MORTA
  c.volante = erro > zona and 1 or (erro < -zona and -1 or 0)

  local curva = abs(linha.curva[j])
  if curva > PI / 2 then curva = PI / 2 end
  -- na curva tira o pe (pelo nivel); quanto pior o pneu (aderencia alta), mais
  local alvo = c.vmax * (1 - N.curva * (0.4 + 2 * c.aderencia) * curva / (PI / 2)) * c.elastico
  -- carro desalinhado com a pista (rodou, bateu): devagar ate se endireitar
  if erro > 1.2 or erro < -1.2 then alvo = alvo * 0.4 end
  c.acel = c.v < alvo
  c.freio = c.v > alvo * 1.25
  -- curva apertando (volante longe da direcao certa): tira o pe, como um piloto. Com a tracao da
  -- ficha, acelerar na curva faz a traseira sair ou o carro abrir a curva (carro.lua)
  local alivia = c.tracao.alivia
  if (erro > alivia or erro < -alivia) and c.v > C.TRACAO_VEL then c.acel = false end
  -- turbo na reta, com o carro alinhado
  c.turbo = c.turbo_carga > 0.05 and linha.reta[c.idx] >= N.turbo_reta and erro < 0.2 and erro > -0.2
    and v > 0.5 * c.vmax and corrida.tempo > 1

  -- raspou no muro: sai de perto dele por um tempo (sem isso, numa curva fechada por dentro
  -- ficava raspando a mureta a volta inteira)
  if c.batidas ~= c.batidas_vistas then
    c.batidas_vistas = c.batidas
    local k = c.idx
    local de_lado = (c.x - linha.x[k]) * cos(linha.ang[k]) + (c.y - linha.y[k]) * sin(linha.ang[k])
    c.afasta = de_lado > 0 and -C.IA_AFASTA or C.IA_AFASTA
  elseif c.afasta ~= 0 then
    c.afasta = c.afasta * (1 - 2 * dt)
  end

  -- troca de faixa de vez em quando, e para desviar de quem esta logo a frente
  c.troca_faixa = c.troca_faixa - dt
  if c.troca_faixa <= 0 then
    c.faixa = (random() - 0.5) * 2 * N.faixa
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

-- combate do computador (como no Death Rally): atira quando ha um carro na frente, no alcance da
-- metralhadora, e solta mina quando ha um carro colado atras
function IA.combate(c, corrida, dt)
  local fx, fy = sin(c.ang), -cos(c.ang)
  local atira, mina = false, false
  for _, o in ipairs(corrida.carros) do
    if o ~= c and not o.destruido then
      local dx, dy = o.x - c.x, o.y - c.y
      local adiante = dx * fx + dy * fy
      local lado = dx * -fy + dy * fx
      if adiante > 0 and adiante < C.ARMA_ALCANCE and lado < o.largura and lado > -o.largura then atira = true end
      if adiante < -c.comprimento and adiante > -c.comprimento - 50 and lado < 20 and lado > -20 then mina = true end
    end
  end
  -- rajadas com pausas (segurando o gatilho direto, todo mundo morria em segundos); o nivel muda
  -- o erro da mira e as pausas
  local N = c.nivel
  c.atirando = false
  c.rajada, c.pausa = (c.rajada or 0) - dt, (c.pausa or 0) - dt
  if atira and c.municao > 0 and corrida.tempo > C.ARMAS_INICIO then
    if c.rajada > 0 then
      c.atirando = true
    elseif c.pausa <= 0 then
      c.rajada = C.IA_RAJADA[1] + random() * (C.IA_RAJADA[2] - C.IA_RAJADA[1])
      c.mira_erro = (random() - 0.5) * 2 * N.mira   -- nao acerta sempre
      c.pausa = c.rajada + (C.IA_PAUSA[1] + random() * (C.IA_PAUSA[2] - C.IA_PAUSA[1])) * N.pausa
      c.atirando = true
    end
  end
  c.espera_mina = (c.espera_mina or C.IA_MINA_ESPERA) - dt
  if mina and c.minas > 0 and c.espera_mina <= 0 then
    c.soltar_mina = true
    c.espera_mina = C.IA_MINA_ESPERA
  end
end

return IA
