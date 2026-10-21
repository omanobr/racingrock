-- Teste de desempenho (para rodar NO APARELHO). Roda sozinho uma lista de testes de ~2,5 s e
-- mostra o FPS de cada um (ui.stat(7), medido pelo console). Cada teste escreve o nome no log
-- (cabo USB) ANTES de comecar: se o console travar, o ultimo nome do log e o culpado.
--
-- O que queremos descobrir: quanto custa ler folhas de tiles do cartao (cada folha diferente
-- desenhada no quadro e lida inteira: ~37 KB cada), e qual dos 3 jeitos de desenhar a pista
-- (fundo.lua) e o mais leve no console.
-- B: repete os testes. A: volta ao titulo.
local C = require "config"
local Pista = require "pista"
local Fundo = require "fundo"
local Entrada = require "entrada"
local Cores = require "cores"
local Diag = require "diagnostico"

local Tela = {}
Tela.__index = Tela

local AQUECE, MEDE = 30, 120
local TS = 16

local function folhas_teste()
  local l = {}
  for i = 0, 7 do l[#l + 1] = Sprites.img.tst["s" .. i] end
  l[#l + 1] = Sprites.img.p0.p0a
  l[#l + 1] = Sprites.img.p0.p0b
  return l
end

-- tela cheia de tiles (30 x 17) em N faixas verticais, cada faixa de uma folha diferente
local function folhas(n)
  local lista = folhas_teste()
  return function(t)
    local tile = ui.tile
    for k = 1, n do
      local img = lista[k]
      local c0, c1 = (k - 1) * 30 // n, k * 30 // n - 1
      for c = c0, c1 do
        local x = c * TS
        for r = 0, 16 do tile(img, (r * 7 + c + t) % 36, x, r * TS) end
      end
    end
  end
end

local function folhas_mapa(n)
  local lista = folhas_teste()
  local nomes = { "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "p0a", "p0b" }
  local camada = { metadata = { width = 30, height = 17, tile_size = TS }, tilesets = {} }
  for k = 1, n do camada[nomes[k]] = {}; camada.tilesets[nomes[k]] = nomes[k] end
  for r = 0, 16 do
    for c = 0, 29 do
      local k = c * n // 30 + 1
      camada[nomes[k]][r * 30 + c + 1] = (r * 7 + c) % 36
    end
  end
  return function() ui.map(camada, 0, 0) end, lista
end

local function lua(mil)
  return function()
    local x = 0
    for i = 1, mil * 250 do x = x + i * 3 end   -- ~4 instrucoes por volta
    return x
  end
end

local function carros()
  local imgs = { Sprites.img.car.t_ver, Sprites.img.car.t_azu, Sprites.img.car.t_ama, Sprites.img.car.t_pra }
  local sombra = Sprites.img.car.t_som
  return function(t)
    ui.cls(Cores.cinza_escuro)
    for i = 1, 4 do ui.tile(sombra, (t // 4 + i * 5) % 25, 80 + i * 70 + 3, 120 + 3) end
    for i = 1, 4 do ui.tile(imgs[i], (t // 4 + i * 5) % 25, 80 + i * 70, 120) end
  end
end

local function pista(modo)
  local p
  return function(t)
    p = p or Pista.carregar(1)
    local i = (t // 4) % p.n + 1
    local x0 = (p.linha.x[i] - 240) // 1
    local y0 = (p.linha.y[i] - 135) // 1
    if x0 < 0 then x0 = 0 elseif x0 > p.largura - 480 then x0 = p.largura - 480 end
    if y0 < 0 then y0 = 0 elseif y0 > p.altura - 270 then y0 = p.altura - 270 end
    Fundo.desenhar(p, x0, y0, modo)
  end
end

local function corrida(modo)
  local tela
  return function()
    if not tela then
      tela = require("telas.corrida").nova({ pista = 1, voltas = 99, autopiloto = true })
    end
    local antes = C.FUNDO
    C.FUNDO = modo
    tela:atualizar()
    tela:desenhar()
    C.FUNDO = antes
  end
end

local function lista_de_testes()
  return {
    { "LUA 20 MIL INSTRUCOES", lua(20) },
    { "4 CARROS + SOMBRAS", carros() },
    { "1 FOLHA (510 TILES)", folhas(1) },
    { "4 FOLHAS (~150 KB)", folhas(4) },
    { "8 FOLHAS (~300 KB)", folhas(8) },
    { "10 FOLHAS (~350 KB)", folhas(10) },
    { "PISTA: TILES", pista("tiles") },
    { "PISTA: VISAO (UI.MAP)", pista("visao") },
    { "PISTA: MAPA (UI.MAP)", pista("mapa") },
    { "8 FOLHAS EM UI.MAP", (folhas_mapa(8)) },
    { "CORRIDA: TILES", corrida("tiles") },
    { "CORRIDA: VISAO", corrida("visao") },
  }
end

function Tela.nova()
  local t = setmetatable({ testes = lista_de_testes(), atual = 1, quadro = 0, resultados = {} }, Tela)
  t:comecar()
  return t
end

function Tela:comecar()
  self.quadro, self.soma, self.n = 0, 0, 0
  local nome = self.testes[self.atual][1]
  print("RROCK TESTE " .. self.atual .. " " .. nome .. " ...")
end

function Tela:atualizar()
  if self.atual > #self.testes then
    if Entrada.confirmar() then
      self.atual, self.resultados = 1, {}
      self:comecar()
    elseif Entrada.voltar() then
      Jogo.ir("titulo")
    end
    return
  end
  self.quadro = self.quadro + 1
  if self.quadro > AQUECE then
    local fps = Diag.stat(7)
    if fps then self.soma, self.n = self.soma + fps, self.n + 1 end
  end
  if self.quadro >= AQUECE + MEDE then
    local media = self.n > 0 and self.soma / self.n or nil
    self.resultados[self.atual] = media or -1
    print(string.format("RROCK TESTE %d %s fps=%s", self.atual, self.testes[self.atual][1],
      media and string.format("%.1f", media) or "?"))
    self.atual = self.atual + 1
    if self.atual <= #self.testes then
      self:comecar()
    else
      print("RROCK TESTES FIM")
    end
  end
end

local function cor_do_fps(f)
  if f < 0 then return Cores.cinza_claro end
  if f >= 55 then return Cores.verde end
  if f >= 30 then return Cores.amarelo end
  return Cores.vermelho
end

function Tela:desenhar()
  if self.atual <= #self.testes then
    ui.cls(Cores.preto)
    self.testes[self.atual][2](self.quadro)
    ui.camera()
    ui.clip()
    ui.rectfill(0, 0, 479, 11, Cores.preto)
    ui.print(string.format("TESTE %d/%d: %s", self.atual, #self.testes, self.testes[self.atual][1]), 4, 2, Cores.amarelo)
    return
  end
  ui.cls(Cores.cinza_escuro)
  ui.print("TESTE DE DESEMPENHO (FPS MEDIDO PELO CONSOLE)", 8, 6, Cores.amarelo)
  for i, teste in ipairs(self.testes) do
    local f = self.resultados[i] or -1
    local y = 14 + i * 14
    ui.print(teste[1], 16, y, Cores.branco)
    ui.print(f >= 0 and string.format("%.1f", f) or "sem ui.stat", 300, y, cor_do_fps(f))
  end
  ui.print("Tire uma foto desta tela e mande.  " .. Entrada.NOME.confirmar .. ": repetir  "
    .. Entrada.NOME.voltar .. ": sair", 8, 254, Cores.cinza_claro)
end

return Tela
