-- Combate (como no Death Rally): vida, metralhadora, minas, itens na pista e os efeitos
-- (faisca, explosao, fumaca, fogo). A corrida chama Combate:atualizar depois de mover os carros;
-- telas/corrida.lua chama Combate:desenhar. Os comandos de cada carro (c.atirando, c.soltar_mina)
-- vem do jogador (corrida.lua) ou do computador (ia.lua).
local C = require "config"
local Cores = require "cores"
local Pista = require "pista"
local Efx = require "dados_efeitos"

local Combate = {}
Combate.__index = Combate

local sin, cos, random = math.sin, math.cos, math.random
local PAREDE, FORA = Pista.PAREDE, Pista.FORA
local ITENS = { "municao", "turbo", "dinheiro", "conserto" }
local CHANCE = { 30, 35, 15, 20 }                       -- em %, como no Death Rally (sem o cogumelo)

local escala = require("carros").escala

function Combate.novo(corrida)
  local cb = setmetatable({ corrida = corrida, minas = {}, itens = {}, efeitos = {}, proximo_item = 2,
    destruidos = 0 }, Combate)
  for _, c in ipairs(corrida.carros) do
    c.vida, c.municao, c.minas, c.dinheiro, c.fumaca = C.VIDA, C.MUNICAO, C.MINAS, 0, 0
    c.dano_por, c.abates, c.mira_erro = {}, 0, 0
    -- blindagem e arma pela ficha do modelo (carros.lua), como no Death Rally
    local b = escala(c.modelo.blindagem, C.BLINDAGEM_BASE) + C.BLINDAGEM_NIVEL + (c.humano and C.BLINDAGEM_JOGADOR or 0)
      + (c.nivel_blindagem or 0) * C.MELHORIA_BLINDAGEM      -- oficina do modo historia
    c.blindagem = b < C.BLINDAGEM_MAX and b or C.BLINDAGEM_MAX
    c.fator_arma = escala(c.modelo.arma, C.ARMA_FATOR)
  end
  cb.e16, cb.e32 = Sprites.img.efx.e16, Sprites.img.efx.e32
  return cb
end

function Combate:efeito(tipo, x, y, dx, dy)
  local e = self.efeitos
  e[#e + 1] = { tipo = tipo, x = x, y = y, t = 0, dx = dx or 0, dy = dy or 0 }
end

-- tira vida (em pontos do Death Rally: 1024 = 1%); em 0 o carro e destruido (para, pega fogo e
-- fica na pista como obstaculo). fonte: "tiro", "mina", "muro" ou "carro"; autor: o carro que
-- causou. Quem acertou por ultimo (ate ABATE_ATE s antes) leva o abate.
function Combate:dano(c, pontos, fonte, autor)
  if c.destruido or pontos <= 0 then return end
  local valor = pontos / 1024
  local agora = self.corrida.tempo
  c.dano_por[fonte] = (c.dano_por[fonte] or 0) + valor
  if autor and autor ~= c then c.agressor, c.agressor_em = autor, agora end
  c.vida = c.vida - valor
  if c.vida <= 0 then
    c.vida = 0
    self.destruidos = self.destruidos + 1
    c.destruido = self.destruidos                       -- ordem: quem cai depois fica na frente
    c.acel, c.freio, c.turbo, c.volante, c.atirando = false, false, false, 0, false
    self:efeito("explosao_grande", c.x, c.y)
    if c.agressor and agora - c.agressor_em <= C.ABATE_ATE and not c.agressor.destruido then
      c.agressor.abates = c.agressor.abates + 1
    end
  end
end

-- batida (muro ou carro) a "velocidade" px/s: (1024 - blindagem) x (px por quadro do Death Rally)^2
local function batida(c, velocidade)
  local k = velocidade / (C.QUADROS_DR * C.ESCALA)
  local p = (1024 - c.blindagem) * k * k
  return p < C.BATIDA_MAX and p or C.BATIDA_MAX
end

-- metralhadora: um raio de ARMA_ALCANCE px saindo do bico, ate o primeiro carro ou muro, com o
-- dano na hora (hitscan, como no Death Rally). O computador mira com erro (c.mira_erro, sorteado
-- a cada rajada em ia.lua): pode errar. Na tela (pedido do Felipe): so o clarao no bico de quem
-- atira e a faisca onde acertou (carro ou muro), nada no caminho (ate a v0.23, 3 pontos andavam
-- pelo raio e pareciam balas voando).
local function atirar(self, c, dt)
  local s, co = sin(c.ang + c.mira_erro), cos(c.ang + c.mira_erro)
  local fx, fy = s, -co                                 -- para a frente
  local bx, by = c.x + fx * c.comprimento / 2, c.y + fy * c.comprimento / 2
  local alcance, alvo = C.ARMA_ALCANCE, nil
  for _, o in ipairs(self.corrida.carros) do
    if o ~= c then
      local ox, oy = o.x - bx, o.y - by
      local t = ox * fx + oy * fy
      local lado = ox * co + oy * s
      if t > 0 and t < alcance and lado < o.largura / 2 + 3 and lado > -o.largura / 2 - 3 then
        alcance, alvo = t, o
      end
    end
  end
  local pista = self.corrida.pista
  local muro = false
  for d = 8, alcance, 8 do                              -- o muro segura o tiro
    local p = pista:piso(bx + fx * d, by + fy * d)
    if p == PAREDE or p == FORA then alcance, alvo, muro = d, nil, true break end
  end
  c.municao = c.municao - dt
  c.tiro_x, c.tiro_y = bx + fx * 3, by + fy * 3         -- o clarao, logo a frente do bico
  if alvo or muro then
    c.relogio_faisca = (c.relogio_faisca or 0) - dt
    if c.relogio_faisca <= 0 then
      c.relogio_faisca = 0.12
      self:efeito("faisca", bx + fx * alcance, by + fy * alcance)
    end
  end
  if alvo then self:dano(alvo, (1024 - alvo.blindagem) * c.fator_arma * C.QUADROS_DR * dt, "tiro", c) end
end

local function soltar_mina(self, c)
  local q = c.comprimento / 2 + 7
  local m = self.minas
  m[#m + 1] = { x = c.x - sin(c.ang) * q, y = c.y + cos(c.ang) * q, dono = c, t = 0 }
  c.minas = c.minas - 1
end

local function explodir_mina(self, mina, c)
  self:dano(c, C.MINA_FORCA * (1024 - c.blindagem), "mina", mina.dono)
  c.v = c.v * C.MINA_FREIA
  c.ang = (c.ang + (random() - 0.5) * 2 * C.MINA_GIRO) % (2 * math.pi)
  self:efeito("explosao", mina.x, mina.y)
end

local function sortear_item(self)
  local p = self.corrida.pista
  local r, soma, tipo = random(100), 0, ITENS[1]
  for i = 1, #ITENS do
    soma = soma + CHANCE[i]
    if r <= soma then tipo = ITENS[i] break end
  end
  for _ = 1, 8 do                                       -- longe dos carros e dos outros itens
    local i = random(p.n)
    local a = p.linha.ang[i]
    local lado = (random() - 0.5) * p.meia_largura
    local x, y = p.linha.x[i] + cos(a) * lado, p.linha.y[i] + sin(a) * lado
    local livre = true
    for _, c in ipairs(self.corrida.carros) do
      if (c.x - x) ^ 2 + (c.y - y) ^ 2 < 120 * 120 then livre = false break end
    end
    for _, it in ipairs(self.itens) do
      if (it.x - x) ^ 2 + (it.y - y) ^ 2 < 200 * 200 then livre = false break end
    end
    if livre then
      self.itens[#self.itens + 1] = { x = x, y = y, tipo = tipo }
      return
    end
  end
end

local function pegar_item(self, c, it)
  local t = it.tipo
  if t == "municao" then        -- no maximo o pente cheio (na v0.21 passava de 100%)
    c.municao = c.municao + C.MUNICAO_ITEM
    if c.municao > C.MUNICAO then c.municao = C.MUNICAO end
  elseif t == "turbo" then c.turbo_carga = 1
  elseif t == "dinheiro" then c.dinheiro = c.dinheiro + C.DINHEIRO_ITEM
  else c.vida = c.vida + C.CONSERTO; if c.vida > C.VIDA then c.vida = C.VIDA end end
  self:efeito("faisca", it.x, it.y)
end

function Combate:atualizar(dt)
  local carros = self.corrida.carros
  for _, c in ipairs(carros) do
    if not c.destruido then
      -- batidas (carro.lua e corrida.lua anotam a velocidade da batida)
      if c.impacto and c.impacto > C.BATIDA_MIN then self:dano(c, batida(c, c.impacto), "muro") end
      if c.impacto_carro and c.impacto_carro > C.BATIDA_MIN then
        self:dano(c, batida(c, c.impacto_carro), "carro", c.batido_por)
      end
      c.tiro_x = nil
      if c.atirando and c.municao > 0 and not c.destruido then atirar(self, c, dt) end
      if c.soltar_mina and c.minas > 0 and not c.destruido then soltar_mina(self, c) end
      -- fumaca de carro muito batido
      if c.vida < C.FUMACA_VIDA and not c.destruido then
        c.fumaca = c.fumaca - dt
        if c.fumaca <= 0 then
          c.fumaca = 0.15 + c.vida / 200
          self:efeito("fumaca", c.x, c.y, (random() - 0.5) * 20, -15)
        end
      end
    end
    c.impacto, c.impacto_carro, c.soltar_mina = nil, nil, false
  end

  -- minas: armam depois de MINA_ARMA s para quem soltou; explodem em quem passar por cima
  local minas = self.minas
  local k = 1
  while k <= #minas do
    local m = minas[k]
    m.t = m.t + dt
    local explodiu = false
    for _, c in ipairs(carros) do
      if not c.destruido and (c ~= m.dono or m.t > C.MINA_ARMA) then
        local r = 6 + c.largura / 2
        if (c.x - m.x) ^ 2 + (c.y - m.y) ^ 2 < r * r then
          explodir_mina(self, m, c)
          explodiu = true
          break
        end
      end
    end
    if explodiu then table.remove(minas, k) else k = k + 1 end
  end

  -- itens
  self.proximo_item = self.proximo_item - dt
  if self.proximo_item <= 0 then
    self.proximo_item = C.ITEM_INTERVALO
    if #self.itens < C.ITENS_MAX then sortear_item(self) end
  end
  local itens = self.itens
  k = 1
  while k <= #itens do
    local it, pego = itens[k], false
    for _, c in ipairs(carros) do
      if not c.destruido then
        local r = 8 + c.largura / 2
        if (c.x - it.x) ^ 2 + (c.y - it.y) ^ 2 < r * r then
          pegar_item(self, c, it)
          pego = true
          break
        end
      end
    end
    if pego then table.remove(itens, k) else k = k + 1 end
  end

  -- efeitos
  local ef = self.efeitos
  k = 1
  while k <= #ef do
    local e = ef[k]
    e.t = e.t + dt
    e.x, e.y = e.x + e.dx * dt, e.y + e.dy * dt
    if e.t >= C.EFEITO_DURA[e.tipo] then table.remove(ef, k) else k = k + 1 end
  end
end

-- ---------------------------------------------------------------- desenho
local TELA_W, TELA_H = 480, 270

-- tile de efeito (16 ou 32 px) centrado em (x, y) do mundo, so se couber inteiro na largura
local function efeito_na_tela(img, tamanho, n, x, y, x0, y0)
  local sx, sy = (x - x0) // 1 - tamanho // 2, (y - y0) // 1 - tamanho // 2
  if sx >= 0 and sx + tamanho <= TELA_W and sy > -tamanho and sy < TELA_H then ui.tile(img, n, sx, sy) end
end

-- no chao (antes dos carros): minas e itens
function Combate:desenhar_chao(x0, y0, quadro)
  local e16 = self.e16
  local pisca = (quadro // 20) % 2
  for _, m in ipairs(self.minas) do efeito_na_tela(e16, 16, Efx.mina[1] + pisca, m.x, m.y, x0, y0) end
  for _, it in ipairs(self.itens) do efeito_na_tela(e16, 16, Efx[it.tipo][1], it.x, it.y, x0, y0) end
end

local function quadro_do_efeito(e)
  local info = Efx[e.tipo]
  local n = (e.t / C.EFEITO_DURA[e.tipo] * info[2]) // 1
  if n >= info[2] then n = info[2] - 1 end
  return info[1] + n
end

-- por cima dos carros: tiros, fogo dos destruidos, efeitos
function Combate:desenhar_cima(x0, y0, quadro, cor_tiro)
  local e16, e32 = self.e16, self.e32
  local min_x, max_x = 16, TELA_W - 17                 -- dentro das faixas pretas
  for _, c in ipairs(self.corrida.carros) do
    if c.tiro_x then                                   -- clarao no bico: pisca (3x3 e 2x2)
      local r = (quadro % 3 == 0) and 1 or 0
      local px, py = (c.tiro_x - x0) // 1, (c.tiro_y - y0) // 1
      if px - r >= min_x and px + 1 + r <= max_x and py - r >= 0 and py + 1 + r < TELA_H then
        ui.rectfill(px - r, py - r, px + 1 + r, py + 1 + r, cor_tiro)
        if r == 1 then ui.rectfill(px, py, px + 1, py + 1, Cores.branco) end
      end
    end
    if c.destruido then
      efeito_na_tela(e16, 16, Efx.fogo[1] + (quadro // 6) % Efx.fogo[2], c.x, c.y - 4, x0, y0)
    end
  end
  for _, e in ipairs(self.efeitos) do
    if e.tipo == "explosao_grande" then
      efeito_na_tela(e32, 32, quadro_do_efeito(e), e.x, e.y, x0, y0)
    else
      efeito_na_tela(e16, 16, quadro_do_efeito(e), e.x, e.y, x0, y0)
    end
  end
end

return Combate
