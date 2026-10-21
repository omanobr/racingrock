-- Regras da corrida: largada, carros (jogador e computador), batidas entre carros, voltas,
-- classificacao e chegada. Nao desenha nada (isso e telas/corrida.lua).
local C = require "config"
local Carro = require "carro"
local IA = require "ia"
local Pista = require "pista"
local Entrada = require "entrada"

local Corrida = {}
Corrida.__index = Corrida

local sqrt = math.sqrt

local CORES = { "ver", "azu", "ama", "pra" }
local NOMES = { "VOCE", "AZUL", "AMARELO", "PRATA" }

-- opcoes: { pista = n, voltas = n, autopiloto = bool }
function Corrida.nova(opcoes)
  local r = setmetatable({}, Corrida)
  r.pista = Pista.carregar(opcoes.pista or 1)
  r.voltas = opcoes.voltas or C.VOLTAS
  r.estado = "contagem"
  r.tempo = 0          -- segundos desde a largada
  r.contagem = 3
  r.carros = {}
  r.chegada = {}       -- carros na ordem em que terminaram
  local p = r.pista
  -- o jogador larga por ultimo (como no Death Rally)
  local vagas = { 4, 1, 2, 3 }
  for i = 1, C.CARROS do
    local g = p.grade[vagas[i]]
    local c = Carro.novo({
      x = g[1], y = g[2], ang = g[3],
      M = i == 1 and C.M_JOGADOR or C.M_IA[i - 1],
      nome = NOMES[i], img = Sprites.img.car["t_" .. CORES[i]], humano = i == 1,
    })
    c.idx = p:mais_perto(c.x, c.y)
    c.volta, c.meio = 0, true       -- 0 = ainda atras da linha de chegada
    c.progresso = c.idx - p.n
    c.posicao = i
    if not c.humano or opcoes.autopiloto then IA.preparar(c); c.ia = true end
    r.carros[i] = c
  end
  r.jogador = r.carros[1]
  r.classificacao = {}
  for i = 1, #r.carros do r.classificacao[i] = r.carros[i] end
  r:classificar()
  r.quadros = 0
  return r
end

local function comandos_do_jogador(c)
  c.acel = Entrada.acelera(0)
  c.freio = Entrada.freia(0)
  c.turbo = Entrada.turbo(0)
  c.volante = (Entrada.direita(0) and 1 or 0) - (Entrada.esquerda(0) and 1 or 0)
end

-- batidas entre carros: circulos; cada um recebe parte da diferenca de velocidade (empurrao)
-- e eles sao afastados devagar (tambem como empurrao, para o muro continuar valendo)
function Corrida:batidas_entre_carros()
  local carros, R2 = self.carros, (2 * C.RAIO_CARRO) ^ 2
  for i = 1, #carros - 1 do
    local a = carros[i]
    for j = i + 1, #carros do
      local b = carros[j]
      local dx, dy = b.x - a.x, b.y - a.y
      local d2 = dx * dx + dy * dy
      if d2 < R2 then
        local d = sqrt(d2)
        if d < 0.01 then dx, dy, d = 1, 0, 1 end
        local nx, ny = dx / d, dy / d
        local aproxima = (b.vx + b.kx - a.vx - a.kx) * nx + (b.vy + b.ky - a.vy - a.ky) * ny
        local imp = 40 * (2 * C.RAIO_CARRO - d)       -- afasta
        if aproxima < 0 then imp = imp - aproxima * C.EMPURRAO end
        a.kx, a.ky = a.kx - nx * imp, a.ky - ny * imp
        b.kx, b.ky = b.kx + nx * imp, b.ky + ny * imp
        a.v, b.v = a.v * 0.97, b.v * 0.97
        a.bateu_carro, b.bateu_carro = true, true
      end
    end
  end
end

-- carro preso dentro do muro: volta para a linha central, parado, na direcao da pista
function Corrida:resgatar(c)
  local p = self.pista
  c.x, c.y, c.ang = p.linha.x[c.idx], p.linha.y[c.idx], p.linha.ang[c.idx]
  c.v, c.kx, c.ky, c.deslize, c.no_muro, c.tempo_travado = 0, 0, 0, 0, 0, 0
  c.resgates = (c.resgates or 0) + 1
end

-- indice na linha central, voltas e "progresso" (voltas x pontos + ponto: maior = na frente)
function Corrida:acompanhar(c)
  if c.no_muro > C.RESGATE or c.tempo_travado > C.RESGATE_TRAVADO then self:resgatar(c) end
  local p = self.pista
  local n = p.n
  local antes = c.idx
  local agora = p:seguir(antes, c.x, c.y)
  if agora < antes - n // 2 then                -- passou pela linha de chegada para a frente
    if c.meio then
      c.volta = c.volta + 1
      c.meio = false
      if c.volta > 1 then
        local t = self.tempo - (c.inicio_volta or 0)
        if not c.melhor_volta or t < c.melhor_volta then c.melhor_volta = t end
      end
      c.inicio_volta = self.tempo
      if c.volta > self.voltas and not c.chegou then
        c.chegou = self.tempo
        self.chegada[#self.chegada + 1] = c
      end
    end
  elseif agora > antes + n // 2 then            -- voltou para tras da linha
    c.volta = c.volta - 1
    c.meio = true
  end
  if agora > n // 3 and agora < 2 * n // 3 then c.meio = true end
  c.idx = agora
  c.progresso = (c.volta - 1) * n + agora
end

function Corrida:classificar()
  local lista = self.classificacao
  table.sort(lista, function(a, b)
    if a.chegou and b.chegou then return a.chegou < b.chegou end
    if a.chegou or b.chegou then return a.chegou ~= nil end
    return a.progresso > b.progresso
  end)
  for i = 1, #lista do lista[i].posicao = i end
end

-- elastico (como no Death Rally): o computador acelera um pouco quando esta atras do jogador
-- e alivia quando esta muito na frente
function Corrida:elastico()
  local E, j = C.IA_ELASTICO, self.jogador
  for i = 2, #self.carros do
    local c = self.carros[i]
    local d = c.progresso - j.progresso
    if d < -E.longe then c.elastico = E.atras_longe
    elseif d < 0 then c.elastico = E.atras
    elseif d > E.longe then c.elastico = E.frente_longe
    else c.elastico = E.frente end
  end
end

-- passo: quantos 1/60 s andar (Tempo.passo)
function Corrida:atualizar(passo)
  local dt = passo / 60
  self.quadros = self.quadros + 1
  if self.estado == "contagem" then
    self.contagem = self.contagem - dt
    if self.contagem <= 0 then self.estado = "correndo" end
    return
  end
  self.tempo = self.tempo + dt
  local p = self.pista
  for _, c in ipairs(self.carros) do
    c.bateu, c.bateu_carro = false, false
    if c.ia then IA.pilotar(c, self, dt) else comandos_do_jogador(c) end
    if c.chegou and c.humano and not c.ia then         -- depois da chegada, o computador leva
      IA.preparar(c); c.ia = true
    end
    c:atualizar(dt, p)
  end
  self:batidas_entre_carros()
  for _, c in ipairs(self.carros) do self:acompanhar(c) end
  if self.quadros % 6 == 0 then
    self:classificar()
    self:elastico()
  end
  if self.estado == "correndo" and self.jogador.chegou then
    self.estado = "fim"
    self.fim_em = self.tempo
  end
end

return Corrida
