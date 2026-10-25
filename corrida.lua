-- Regras da corrida: largada, carros (jogador e computador), batidas entre carros, voltas,
-- classificacao e chegada. Nao desenha nada (isso e telas/corrida.lua).
local C = require "config"
local Carro = require "carro"
local IA = require "ia"
local Pista = require "pista"
local Entrada = require "entrada"
local Carros = require "carros"
local Combate = require "combate"

local Corrida = {}
Corrida.__index = Corrida

local sqrt, sin, cos = math.sqrt, math.sin, math.cos

local CORES = { "ver", "azu", "ama", "pra" }   -- o jogador e o vermelho

-- os modelos da corrida: o do jogador e, para o computador, outros sorteados (sem repetir)
local function modelos(do_jogador)
  local outros = {}
  for _, m in ipairs(Carros) do
    if m.id ~= do_jogador then outros[#outros + 1] = m end
  end
  for i = #outros, 2, -1 do
    local j = math.random(i)
    outros[i], outros[j] = outros[j], outros[i]
  end
  table.insert(outros, 1, Carros[Carros.indice(do_jogador)])
  return outros
end

-- opcoes: { pista = n, variante = n (Pista.VARIANTES), voltas = n, autopiloto = bool, modelo = id do carro do jogador,
--   nivel = 1..3 (C.NIVEIS: o computador), minas = do jogador, minas_rivais = de cada rival,
--   e no modo historia (campeonato.lua): rivais = { { nome, modelo, fator, blindagem, minas }, ... },
--   melhorias = { motor, pneus, blindagem } do jogador, dificuldade = "facil"..., campeonato }
-- As minas nao vem de fabrica (pedido do Felipe, como no Death Rally): so a metralhadora. No modo
-- historia o jogador compra antes da corrida.
function Corrida.nova(opcoes)
  local r = setmetatable({}, Corrida)
  r.pista = Pista.carregar(opcoes.pista or 1, opcoes.variante)
  IA.pista(r.pista)
  -- mapinha do painel (ferramentas/gerar_interface.py)
  local mapa = require("dados_interface").mapas[r.pista.id]
  if mapa and Sprites.img.mapa then
    r.mapa = { img = Sprites.img.mapa[r.pista.id], escala = mapa.escala, w = mapa.w, h = mapa.h,
               espelho = r.pista.espelho, largura = r.pista.largura }
  end
  r.voltas = opcoes.voltas or C.VOLTAS
  r.nivel = C.NIVEIS[opcoes.nivel or C.NIVEL] or C.NIVEIS[2]
  r.preco_minas = opcoes.preco_minas
  r.dificuldade = opcoes.dificuldade or "facil"
  r.campeonato = opcoes.campeonato
  r.estado = "contagem"
  r.tempo = 0          -- segundos desde a largada
  r.contagem = 3
  r.carros = {}
  r.chegada = {}       -- carros na ordem em que terminaram
  local p = r.pista
  -- o jogador larga por ultimo (como no Death Rally)
  local vagas = { 4, 1, 2, 3 }
  local lista = modelos(opcoes.modelo or C.MODELO)
  local rivais = opcoes.rivais
  if rivais then        -- modo historia: os rivais e os carros deles vem do ranking
    for i = 1, 3 do lista[i + 1] = Carros[Carros.indice(rivais[i].modelo)] end
  end
  local mel = opcoes.melhorias or {}
  for i = 1, C.CARROS do
    local g = p.grade[vagas[i]]
    local m = lista[i]
    local rival = rivais and rivais[i - 1]
    local fator = i == 1 and 1 + C.MELHORIA_MOTOR * (mel.motor or 0) or C.IA_FATOR_M[i - 1]
    if rival then fator = C.IA_FATOR_M[i - 1] * rival.fator end
    -- nivel do computador: a ficha inteira do carro dele x nivel.fator (a blindagem e a arma em
    -- combate.lua)
    local nivel = i == 1 and 1 or r.nivel.fator
    local ader = Carros.escala(m.aderencia, C.FICHA_ADERENCIA) / nivel
    if i == 1 then ader = math.max(0.1, ader - C.MELHORIA_PNEU * (mel.pneus or 0)) end
    local c = Carro.novo({
      x = g[1], y = g[2], ang = g[3],
      M = Carros.escala(m.velocidade, C.FICHA_M) * fator * nivel,
      arranque = Carros.escala(m.aceleracao, C.FICHA_ARRANQUE) * nivel,
      aderencia = ader,
      tracao = m.tracao,
      nome = i == 1 and "VOCE" or (rival and rival.nome or m.nome), humano = i == 1, modelo = m.id,
      img = Sprites.img.car[m.id .. "_" .. CORES[i]], img2 = Sprites.img.car[m.id .. "_" .. CORES[i] .. "2"],
    })
    c.modelo = m
    c.cor = CORES[i]
    c.nivel_blindagem = i == 1 and (mel.blindagem or 0) or (rival and rival.blindagem or 0)
    c.fator_nivel = nivel
    if i == 1 then c.minas_iniciais = opcoes.minas or 0
    else c.minas_iniciais = rival and rival.minas or opcoes.minas_rivais or 0 end
    c.idx = p:mais_perto(c.x, c.y)
    c.volta, c.meio = 0, true       -- 0 = ainda atras da linha de chegada
    c.progresso = c.idx - p.n
    c.posicao = i
    if not c.humano then IA.preparar(c, r.nivel); c.ia = true
    elseif opcoes.autopiloto then IA.preparar(c); c.ia = true end
    r.carros[i] = c
  end
  r.jogador = r.carros[1]
  r.combate = Combate.novo(r)
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
  c.atirando = Entrada.atira(0)
  c.soltar_mina = Entrada.mina(0)
end

-- batidas entre carros: cada carro e 2 circulos (frente e tras, da largura do carro); no par de
-- circulos mais encavalado, cada um recebe parte da diferenca de velocidade (empurrao) e eles sao
-- afastados devagar (tambem como empurrao, para o muro continuar valendo)
local function circulos(c)
  local q = c.comprimento / 4
  local fx, fy = sin(c.ang) * q, -cos(c.ang) * q
  c.c1x, c.c1y, c.c2x, c.c2y = c.x + fx, c.y + fy, c.x - fx, c.y - fy
  c.raio = c.largura / 2
end

function Corrida:batidas_entre_carros()
  local carros = self.carros
  for i = 1, #carros do circulos(carros[i]) end
  for i = 1, #carros - 1 do
    local a = carros[i]
    for j = i + 1, #carros do
      local b = carros[j]
      local soma = a.raio + b.raio
      local dx0, dy0 = b.x - a.x, b.y - a.y
      if dx0 * dx0 + dy0 * dy0 < (soma + (a.comprimento + b.comprimento) / 2) ^ 2 then   -- perto: confere os circulos
        local fundo, nx, ny = 0, 0, 0
        for ka = 1, 2 do
          local ax, ay = ka == 1 and a.c1x or a.c2x, ka == 1 and a.c1y or a.c2y
          for kb = 1, 2 do
            local bx, by = kb == 1 and b.c1x or b.c2x, kb == 1 and b.c1y or b.c2y
            local dx, dy = bx - ax, by - ay
            local d2 = dx * dx + dy * dy
            if d2 < soma * soma then
              local d = sqrt(d2)
              if d < 0.01 then dx, dy, d = 1, 0, 1 end
              if soma - d > fundo then fundo, nx, ny = soma - d, dx / d, dy / d end
            end
          end
        end
        if fundo > 0 then
          local aproxima = (b.vx + b.kx - a.vx - a.kx) * nx + (b.vy + b.ky - a.vy - a.ky) * ny
          local imp = 40 * fundo       -- afasta
          if aproxima < 0 then
            imp = imp - aproxima * C.EMPURRAO
            a.impacto_carro, b.impacto_carro = -aproxima, -aproxima   -- combate.lua tira vida
            a.batido_por, b.batido_por = b, a
          end
          a.kx, a.ky = a.kx - nx * imp, a.ky - ny * imp
          b.kx, b.ky = b.kx + nx * imp, b.ky + ny * imp
          a.v, b.v = a.v * 0.97, b.v * 0.97
          a.bateu_carro, b.bateu_carro = true, true
        end
      end
    end
  end
end

-- carro preso dentro do muro: volta para a linha central, parado, na direcao da pista
function Corrida:resgatar(c)
  local p = self.pista
  c.x, c.y, c.ang = p.linha.x[c.idx], p.linha.y[c.idx], p.linha.ang[c.idx]
  c.v, c.kx, c.ky, c.deslize, c.no_muro, c.tempo_travado = 0, 0, 0, 0, 0, 0
  c.segundos_parado, c.marca_x, c.marca_y = 0, c.x, c.y
  c.resgates = (c.resgates or 0) + 1
end

-- ultima garantia contra carro preso: a cada segundo ve quanto ele andou; parado muito tempo
-- com o pedal apertado (o computador sempre quer andar), volta para a pista
function Corrida:parado(c, dt)
  c.relogio_parado = (c.relogio_parado or 0) + dt
  if c.relogio_parado < 1 then return end
  c.relogio_parado = 0
  local x, y = c.marca_x or c.x, c.marca_y or c.y
  c.marca_x, c.marca_y = c.x, c.y
  if (c.acel or c.freio or c.ia) and (c.x - x) ^ 2 + (c.y - y) ^ 2 < 36 then
    c.segundos_parado = (c.segundos_parado or 0) + 1
    if c.segundos_parado >= C.RESGATE_PARADO then self:resgatar(c) end
  else
    c.segundos_parado = 0
  end
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
      if c.voltou_na_linha then
        -- tinha cruzado a linha de re: so voltou para a mesma volta (na v0.24 contava uma
        -- "melhor volta" de 0,2 s)
        c.voltou_na_linha = false
      else
        if c.volta > 1 then
          local t = self.tempo - (c.inicio_volta or 0)
          if not c.melhor_volta or t < c.melhor_volta then c.melhor_volta = t end
        end
        c.inicio_volta = self.tempo
      end
      if c.volta > self.voltas and not c.chegou then
        c.chegou = self.tempo
        self.chegada[#self.chegada + 1] = c
      end
    end
  elseif agora > antes + n // 2 then            -- voltou para tras da linha
    c.volta = c.volta - 1
    c.meio = true
    c.voltou_na_linha = true
  end
  if agora > n // 3 and agora < 2 * n // 3 then c.meio = true end
  c.idx = agora
  c.progresso = (c.volta - 1) * n + agora
end

function Corrida:classificar()
  local lista = self.classificacao
  -- quem chegou (pela ordem de chegada), depois quem esta correndo (pelo progresso) e por ultimo
  -- os destruidos (quem caiu depois fica na frente)
  table.sort(lista, function(a, b)
    if a.chegou and b.chegou then return a.chegou < b.chegou end
    if a.chegou or b.chegou then return a.chegou ~= nil end
    if a.destruido and b.destruido then return a.destruido > b.destruido end
    if a.destruido or b.destruido then return b.destruido ~= nil end
    return a.progresso > b.progresso
  end)
  for i = 1, #lista do lista[i].posicao = i end
end

-- elastico (como no Death Rally): o motor do computador fica mais forte quando ele esta atras do
-- jogador (carro.lua multiplica a potencia M), para a corrida nao ficar facil. Ate a v0.26 tambem
-- ficava 12% mais fraco quando estava longe na frente: um fusca alcancava um puma (o Felipe ganhou
-- de um puma com o fusca sem melhorias). Agora na frente ele corre com o carro que tem.
function Corrida:elastico()
  local E, j, longe = self.nivel.elastico, self.jogador, C.IA_ELASTICO_LONGE
  for i = 2, #self.carros do
    local c = self.carros[i]
    local d = c.progresso - j.progresso
    if d < -longe then c.elastico = E.atras_longe
    elseif d < 0 then c.elastico = E.atras
    else c.elastico = 1 end
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
    if c.destruido then
      c.acel, c.freio, c.turbo, c.volante, c.atirando = false, false, false, 0, false
    else
      if c.chegou and c.humano and not c.ia then       -- depois da chegada, o computador leva
        IA.preparar(c); c.ia = true
      end
      if c.ia then
        IA.pilotar(c, self, dt)
        IA.combate(c, self, dt)
      else
        comandos_do_jogador(c)
      end
    end
    c:atualizar(dt, p)
  end
  self:batidas_entre_carros()
  self.combate:atualizar(dt)
  for _, c in ipairs(self.carros) do
    if not c.destruido then
      self:acompanhar(c)
      self:parado(c, dt)
    end
  end
  if self.quadros % 6 == 0 then
    self:classificar()
    self:elastico()
  end
  if self.estado == "correndo" then
    local j = self.jogador
    -- so o jogador sobrou: vence na hora (e leva o bonus de sobrevivente, em premiar)
    if not j.destruido and not j.chegou then
      local vivos = 0
      for _, c in ipairs(self.carros) do
        if not c.destruido and not c.chegou then vivos = vivos + 1 end
      end
      if vivos == 1 and self.combate.destruidos == #self.carros - 1 then
        j.sobrevivente = true
        j.chegou = self.tempo
        self.chegada[#self.chegada + 1] = j
      end
    end
    if j.chegou or j.destruido then
      self.estado = "fim"
      self.fim_em = self.tempo
      self:classificar()
    end
  end
end

-- pontos (internos: o objetivo do computador e ganhar a corrida, atirando quando da; vao servir
-- para o ranking do campeonato) e o dinheiro do jogador, item por item (destruido nao leva o
-- premio da colocacao, como no Death Rally)
function Corrida:premiar()
  self:classificar()
  for i, c in ipairs(self.classificacao) do
    c.pontos = (c.destruido and 0 or (C.PONTOS_POSICAO[i] or 0)) + c.abates * C.PONTOS_ABATE
  end
  local j = self.jogador
  local P = C.PREMIOS[self.dificuldade] or C.PREMIOS.facil
  local linhas = {}
  local function linha(texto, valor)
    if valor > 0 then linhas[#linhas + 1] = { texto, valor } end
  end
  if not j.destruido then linha(string.format("PREMIO DO %do LUGAR", j.posicao), P.posicao[j.posicao] or 0) end
  linha(string.format("ABATES (%d)", j.abates), j.abates * P.abate)
  if j.sobrevivente then linha("ULTIMO SOBREVIVENTE", P.sobrevivente) end
  linha("DINHEIRO PEGO NA PISTA", j.dinheiro)
  local total = 0
  for _, l in ipairs(linhas) do total = total + l[2] end
  return linhas, total
end

return Corrida
