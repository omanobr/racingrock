-- Teste de desempenho (OPCOES > TESTE DE DESEMPENHO), para rodar NO APARELHO, como o do GearX.
-- Roda sozinho uma lista de testes de 4 s e mede, em cada um, o FPS que o console informa
-- (ui.stat(7)): a media e o pior segundo. No fim mostra uma tabela: tire uma foto e mande. Cada
-- teste escreve o nome no log (cabo USB) ANTES de comecar (se o console travar, o ultimo nome do
-- log e o culpado) e o resultado no fim, com o ui.stat(1) ("uso do processador" na documentacao
-- do firmware 0.6.8; na 1a rodada, v0.38, ficou em 32-33% em todos os testes, ate no Lua de 60
-- mil instrucoes: nao mede o Lua do jogo).
--
-- Medir no aparelho (1a rodada, v0.38): o ui.stat(7) e a contagem do segundo anterior e chega
-- 1-2 s atrasado, entao os 2 primeiros segundos de cada teste nao contam; ler o pistas/<id>.lua
-- de uma pista trava o console ~0,5 s (as pistas sao lidas todas antes do 1o teste); e o
-- contador de quadros do update(frame) nao conta os quadros pulados (dframe sempre 1).
--
-- O que cada grupo quer descobrir:
--   LUA      quantas instrucoes o console faz por quadro (o firmware 0.6.8 deixou o GearX ~2x
--            mais rapido); o testar_console.py conta as instrucoes de cada teste no PC
--   LETRAS   quanto custa quebrar o lote (v0.34): as mesmas 288 letras e 24 quadradinhos, com
--            a folha da fonte lida 1 vez ou 24 vezes no quadro
--   PISTA    quanto custa ler folhas do cartao: cada folha desenhada no quadro e lida inteira
--   CORRIDA  o gramado (a pista mais pesada no aparelho) com uma parte desligada de cada vez
--            (Tela.sem de telas/corrida.lua), so as contas, so o desenho, com 2 jogadores (tela
--            dividida, v0.40: com 2 rivais e sem rivais), e as outras pistas
-- Filmar em camera lenta (v0.41): o FPS acima e o do chip que roda o Lua; o chip de video le do
-- cartao cada imagem desenhada e, se nao der conta, pode mostrar menos quadros sem o Lua saber
-- (no GearX, 300 trocas de imagem travaram o video e o Lua seguiu). Por isso cada teste mostra um
-- contador (0 a 99, sobe 1 a cada quadro do Lua) e um quadradinho que anda 8 px por quadro: num
-- video em camera lenta do celular, um numero que falta e um quadro que o video nao mostrou.
-- B: repete os testes. A: volta para as opcoes.
local C = require "config"
local Cores = require "cores"
local Entrada = require "entrada"
local Diag = require "diagnostico"
local Pista = require "pista"
local Texto = require "texto"
local P = require("dados_interface").painel
local TelaCorrida = require "telas.corrida"

local Tela = {}
Tela.__index = Tela

local AQUECE, MEDE = 120, 120  -- quadros de cada teste: os 2 primeiros segundos nao contam
local GRAMADO = 2              -- em pistas/lista.lua (a 1a e a de treino)
local OPCOES = {}              -- o 3o campo de cada teste (abaixo)

local function fundo()
  ui.rectfill(0, 0, 479, 269, Cores.preto)
end

local function lua(mil)
  local voltas = mil * 1000 // 3
  return function()
    fundo()
    local s = 0
    for i = 1, voltas do s = s + i * 2 end   -- 3 instrucoes por volta
    return s
  end
end

-- 24 linhas de 12 letras (f2) em 2 colunas e um quadradinho no fim de cada linha. Num lote: os
-- quadradinhos primeiro e as letras todas depois (1 leitura da fonte). Quebrado: cada linha e
-- o quadradinho dela (o retangulo quebra o lote: a fonte e lida 24 vezes).
local LINHA = "ABCDEFGHIJKL"
local function letras(quebrado)
  return function()
    fundo()
    for k = 0, 23 do
      local x, y = 40 + (k // 12) * 220, 30 + (k % 12) * 18
      if quebrado then Texto.escrever("f2", LINHA, x, y, "branco") end
      ui.rectfill(x + 160, y + 4, x + 167, y + 11, Cores.amarelo)
    end
    if not quebrado then
      for k = 0, 23 do Texto.escrever("f2", LINHA, 40 + (k // 12) * 220, 30 + (k % 12) * 18, "branco") end
    end
  end
end

-- a tela cheia de tiras do gramado (30 colunas de 16 x 63 px) em n faixas, cada faixa de uma
-- folha diferente (os tiles de cada folha saem das regioes da pista: todos existem)
local function folhas(n)
  return function(self)
    local tile, lista = ui.tile, self.folhas
    for k = 1, n do
      local f = lista[k]
      local img, t = f.img, f.tiles
      for c = (k - 1) * 30 // n, k * 30 // n - 1 do
        for r = 0, 4 do tile(img, t[(r * 7 + c) % #t + 1], c * 16, r * 63) end
      end
    end
  end
end

local function corrida(self)
  local op = OPCOES[self.atual]
  if op.so == "contas" or op.sem and op.sem.pista then fundo() end
  if op.so ~= "contas" then self.cv:desenhar() end
end

-- { nome (ate 36 letras), desenho, opcoes: corrida = pista, sem = partes, so = "contas"/"desenho",
--   jogadores, carros (Corrida.nova) }
local TESTES = {
  { "VAZIO (SO A PALETA)", fundo },
  { "LUA: 20 MIL INSTRUCOES", lua(20) },
  { "LUA: 40 MIL INSTRUCOES", lua(40) },
  { "LUA: 60 MIL INSTRUCOES", lua(60) },
  { "300 RETANGULOS", function()
    fundo()
    for k = 0, 299 do
      local x, y = (k % 30) * 16, 20 + (k // 30) * 24
      ui.rectfill(x, y, x + 11, y + 15, k % 2 == 0 and Cores.amarelo or Cores.azul)
    end
  end },
  { "LETRAS: NUM LOTE (1 LEITURA)", letras(false) },
  { "LETRAS: LOTE QUEBRADO (24 LEITURAS)", letras(true) },
  { "PISTA: 1 FOLHA", folhas(1) },
  { "PISTA: 8 FOLHAS", folhas(8) },
  { "PISTA: 16 FOLHAS", folhas(16) },
  { "PISTA: 24 FOLHAS", folhas(24) },
  { "GRAMADO: CORRIDA COMPLETA", corrida, { corrida = GRAMADO } },
  { "GRAMADO: SEM O PAINEL", corrida, { corrida = GRAMADO, sem = { painel = true } } },
  { "GRAMADO: SEM A PISTA", corrida, { corrida = GRAMADO, sem = { pista = true } } },
  { "GRAMADO: SEM OS CARROS", corrida, { corrida = GRAMADO, sem = { carros = true } } },
  { "GRAMADO: SEM RASTROS, TIROS E ITENS", corrida, { corrida = GRAMADO, sem = { efeitos = true } } },
  { "GRAMADO: SO O DESENHO (PARADA)", corrida, { corrida = GRAMADO, so = "desenho" } },
  { "GRAMADO: SO AS CONTAS (SEM DESENHO)", corrida, { corrida = GRAMADO, so = "contas" } },
  { "GRAMADO: 2 JOGADORES, 4 CARROS", corrida, { corrida = GRAMADO, jogadores = 2 } },
  { "GRAMADO: 2 JOGADORES, SEM RIVAIS", corrida, { corrida = GRAMADO, jogadores = 2, carros = 2 } },
}
for i = 3, Pista.quantas() do
  TESTES[#TESTES + 1] = { "CORRIDA: " .. Pista.LISTA[i].nome, corrida, { corrida = i } }
end
for i, t in ipairs(TESTES) do
  OPCOES[i] = t[3] or {}
  t.rotulo = string.format("%2d %s", i, t[1])
end

-- as folhas do gramado e os tiles de cada uma
local function folhas_do_gramado()
  local p = Pista.carregar(GRAMADO)
  local tiles = {}
  for _, linha in ipairs(p.regioes) do
    for _, r in ipairs(linha) do
      local t = tiles[r[1]] or {}
      tiles[r[1]] = t
      for k = 2, #r do
        for _, n in ipairs(r[k]) do t[#t + 1] = n end
      end
    end
  end
  local lista = {}
  for i, img in ipairs(p.imagens) do
    if tiles[i] then lista[#lista + 1] = { img = img, tiles = tiles[i] } end
  end
  return lista
end

-- o 1o quadro mostra "CARREGANDO"; no 2o as pistas sao lidas (atual = 0 ate la)
function Tela.nova()
  return setmetatable({ atual = 0, espera = 1, resultados = {} }, Tela)
end

function Tela:carregar()
  for i = 2, Pista.quantas() do require("pistas." .. Pista.LISTA[i].id) end
  self.folhas = folhas_do_gramado()
  print("RROCK TESTE DE DESEMPENHO v" .. C.VERSAO .. ": " .. #TESTES .. " testes")
  self.atual = 1
  self:comecar()
end

-- corrida de 4 no piloto automatico, todos com minas, ja correndo (sem a contagem) e com as
-- armas liberadas
function Tela:nova_corrida(op)
  self.cv = TelaCorrida.nova({ pista = op.corrida, voltas = 99, autopiloto = true, minas = 3, minas_rivais = 3,
                               jogadores = op.jogadores, carros = op.carros, autopiloto2 = true })
  local r = self.cv.corrida
  r.estado, r.tempo = "correndo", C.ARMAS_INICIO
  self.cv_op = op
end

function Tela:comecar()
  self.quadro, self.medindo = 0, false
  self.soma7, self.n7, self.min7, self.soma1, self.n1 = 0, 0, nil, 0, 0
  TelaCorrida.sem = {}
  local op = OPCOES[self.atual]
  if not op then
    self.cv = nil
    collectgarbage("collect")
    return
  end
  if op.corrida then
    local antes = self.cv_op
    if not antes or antes.corrida ~= op.corrida or antes.jogadores ~= op.jogadores or antes.carros ~= op.carros then
      self.cv = nil
      collectgarbage("collect")
      self:nova_corrida(op)
    end
    TelaCorrida.sem = op.sem or {}
  else
    self.cv, self.cv_op = nil, nil
  end
  self.titulo = string.format("TESTE %d DE %d: %s", self.atual, #TESTES, TESTES[self.atual][1])
  print("RROCK TESTE " .. self.atual .. " " .. TESTES[self.atual][1] .. " ...")
end

local function numero(v, formato)
  return v and string.format(formato, v) or "?"
end

function Tela:terminar()
  local r = {}
  r.fps7 = self.n7 > 0 and self.soma7 / self.n7 or nil
  r.cpu = self.n1 > 0 and self.soma1 / self.n1 or nil
  local seg = self.relogio0 and Diag.relogio() - self.relogio0
  r.fps = r.fps7 or (seg and seg > 0 and MEDE / seg) or nil   -- simulador: pelo relogio
  r.texto = string.format("%5s %5s", numero(r.fps, "%.1f"), numero(self.min7, "%.0f"))
  self.resultados[self.atual] = r
  print(string.format("RROCK TESTE %d %s: fps=%s pior=%s cpu=%s", self.atual, TESTES[self.atual][1],
    numero(r.fps, "%.1f"), numero(self.min7, "%.0f"), numero(r.cpu, "%.0f")))
  self.atual = self.atual + 1
  if self.atual > #TESTES then print("RROCK TESTES FIM") end
  self:comecar()
end

function Tela:atualizar()
  if Entrada.voltar() then
    TelaCorrida.sem = {}
    Jogo.ir("opcoes")
    return
  end
  self.contador = (self.contador or 0) + 1
  if self.atual == 0 then
    if self.espera > 0 then self.espera = self.espera - 1 else self:carregar() end
    return
  end
  if self.atual > #TESTES then
    if Entrada.confirmar() then
      self.atual, self.resultados = 1, {}
      self:comecar()
    end
    return
  end
  local cv = self.cv
  if cv and OPCOES[self.atual].so ~= "desenho" then
    cv:atualizar()
    -- o seu carro chegou ou foi destruido: outra corrida (a tela da corrida iria para o resultado)
    if cv.corrida.estado == "fim" then self:nova_corrida(self.cv_op) end
  end
  self.quadro = self.quadro + 1
  if self.quadro == AQUECE then
    self.medindo, self.relogio0 = true, Diag.relogio and Diag.relogio()
  elseif self.medindo then
    local fps, cpu = Diag.stat(7), Diag.stat(1)
    if fps then
      self.soma7, self.n7 = self.soma7 + fps, self.n7 + 1
      if not self.min7 or fps < self.min7 then self.min7 = fps end
    end
    if cpu then self.soma1, self.n1 = self.soma1 + cpu, self.n1 + 1 end
  end
  if self.quadro >= AQUECE + MEDE then self:terminar() end
end

local function cor_do_fps(f)
  if not f then return Cores.cinza_claro end
  if f >= 57 then return Cores.verde end
  if f >= 45 then return Cores.amarelo end
  return Cores.vermelho
end

function Tela:tabela()
  fundo()
  ui.print("TESTE DE DESEMPENHO v" .. C.VERSAO .. ": TIRE UMA FOTO DESTA TELA E MANDE", 8, 4, Cores.amarelo)
  ui.print("TESTE", 8, 15, Cores.cinza)
  ui.print("  FPS  PIOR", 300, 15, Cores.cinza)
  for i, teste in ipairs(TESTES) do
    local r = self.resultados[i]
    local y = 25 + (i - 1) * 9
    ui.print(teste.rotulo, 8, y, Cores.branco)
    if r then ui.print(r.texto, 300, y, cor_do_fps(r.fps)) end
  end
  ui.print(Entrada.NOME.confirmar .. ": REPETIR   " .. Entrada.NOME.voltar .. ": SAIR", 8, 261, Cores.cinza_claro)
end

function Tela:desenhar()
  if self.atual == 0 then
    fundo()
    ui.print("CARREGANDO AS PISTAS...", 171, 131, Cores.amarelo)
    return
  end
  local teste = TESTES[self.atual]
  if not teste then return self:tabela() end
  teste[2](self)
  ui.rectfill(0, 0, 479, 11, Cores.preto)
  ui.print(self.titulo, 4, 2, Cores.amarelo)
  ui.rectfill(0, 10, 479 * self.quadro // (AQUECE + MEDE), 11, Cores.amarelo)
  -- contador e quadradinho para filmar em camera lenta (no comeco do arquivo)
  local c = self.contador
  local x = 16 + (c * 8) % 440
  ui.rectfill(x, 13, x + 7, 18, Cores.branco)
  ui.rectfill(422, 232, 467, 262, Cores.preto)
  local pn = Sprites.img.ui.painel
  ui.tile(pn, P.f3 + c // 10 % 10, 428, 236)
  ui.tile(pn, P.f3 + c % 10, 445, 236)
end

return Tela
