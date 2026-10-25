-- Modo historia (campeonato), no jeito do Death Rally: voce comeca no fim de um ranking de 20
-- pilotos com um fusca velho e pouco dinheiro; a cada rodada escolhe uma de 3 corridas (facil,
-- media, dificil), ganha dinheiro e pontos, conserta o carro, compra melhorias e carros novos.
-- No 1o lugar do ranking, abre o desafio final contra O ADVERSARIO, o dono da liga.
--
-- O nivel dos rivais (facil, normal, dificil: C.NIVEIS) e escolhido no NOVO JOGO e vale o
-- campeonato inteiro (vai no password). A dificuldade de cada corrida so escolhe os carros que
-- entram (pedido do Felipe): na facil ate o corsa, na media ate o monza, na dificil monza, opala
-- e puma; o premio e os pontos sobem junto.
--
-- Os rivais tambem trocam de carro (ideia do Felipe: senao o do fusca anda de fusca para sempre):
-- cada um "compra" um carro melhor a cada RIVAL_PONTOS_CARRO pontos que ganha no campeonato. Como
-- os pontos deles saem da rodada, o carro tambem sai, e o password nao precisa guardar nada.
--
-- O console nao grava nada (desligou, perdeu): o progresso inteiro cabe num PASSWORD de 8
-- letras, estilo Super Nintendo (Rock n' Roll Racing, Biker Mice from Mars). Para caber, o
-- ranking dos outros 19 pilotos nao e guardado: os pontos deles dependem so da rodada (cada
-- um ganha um tanto por rodada, com um sorteio fixo), e o resto (carro, melhorias, dinheiro
-- em centenas, rodada e pontos) entra no password, com um digito verificador para pegar erro
-- de digitacao.
--
-- Nao desenha nada (telas/garagem.lua, telas/senha.lua, telas/resultado.lua).
local C = require "config"
local Carros = require "carros"

local floor = math.floor

local Campeonato = {}

-- os 19 rivais, do mais forte ao mais fraco: nome (ate 10 letras: cabe no painel da corrida),
-- carro, pontos no comeco e pontos por rodada
Campeonato.PILOTOS = {
  { "TROVAO", "puma", 40, 2.4 },
  { "COBRA", "opala", 37, 2.3 },
  { "BARAO", "monza", 34, 2.2 },
  { "PIRANHA", "puma", 31, 2.1 },
  { "LOBO MAU", "focus", 28, 2.0 },
  { "JACARE", "opala", 25, 1.9 },
  { "DONA GRAXA", "monza", 22, 1.8 },
  { "CAPITAO", "corsa", 20, 1.7 },
  { "FERRUGEM", "focus", 18, 1.6 },
  { "GASOLINA", "corsa", 16, 1.5 },
  { "ZE TURBO", "saveiro", 14, 1.4 },
  { "BIGODE", "saveiro", 12, 1.3 },
  { "CORUJA", "ka", 10, 1.2 },
  { "SUCATA", "uno", 8, 1.1 },
  { "FUMACA", "ka", 7, 1.0 },
  { "FAISCA", "uno", 5, 0.9 },
  { "TATU", "fusca", 4, 0.8 },
  { "RATO", "fusca", 2, 0.7 },
  { "MANCHA", "uno", 1, 0.6 },
}
-- o chefe: um puma com o motor um pouco acima do seu no nivel 3 da oficina (+12%), e pilota como
-- o nivel escolhido
Campeonato.CHEFE = { nome = "ADVERSARIO", modelo = "puma", fator = 1.15, blindagem = 3 }

-- rivais: da 13a a 19a posicao do ranking na facil, 7a-12a na media, 1a-6a na dificil. carros:
-- do pior ao melhor que pode entrar (indices em carros.lua: 1 fusca ... 5 corsa, 7 monza, 9 puma);
-- o carro do rival e puxado para dentro da faixa (com um melhor, ele vem com um emprestado)
Campeonato.DIFICULDADES = {
  { id = "facil", nome = "FACIL", rivais = { 13, 19 }, carros = { 1, 5 } },
  { id = "medio", nome = "MEDIA", rivais = { 7, 12 }, carros = { 4, 7 } },
  { id = "dificil", nome = "DIFICIL", rivais = { 1, 6 }, carros = { 7, 9 } },
}
local CARROS_FINAL = { 8, 9 }
local RIVAL_PONTOS_CARRO = 8

-- precos (multiplos de 100: o password guarda o dinheiro em centenas)
Campeonato.PRECO_CARRO = { fusca = 0, uno = 3000, ka = 4000, saveiro = 6000, corsa = 9000, focus = 13000,
                           monza = 18000, opala = 24000, puma = 32000 }
Campeonato.MELHORIAS = { "motor", "pneus", "blindagem" }
Campeonato.NOME_MELHORIA = { motor = "MOTOR", pneus = "PNEUS", blindagem = "BLINDAGEM" }
local PRECO_MELHORIA = { 800, 1600, 3200 }     -- nivel 1, 2, 3 no fusca; carros melhores pagam mais
Campeonato.MAX_NIVEL = 3
Campeonato.DINHEIRO_MAX = 1023 * 100

-- nivel: 1 a 3 (C.NIVEIS)
function Campeonato.novo(nivel)
  return { carro = 1, motor = 0, pneus = 0, blindagem = 0, dinheiro = 500, rodada = 0, pontos = 0, nivel = nivel or 2 }
end

function Campeonato.nivel(e) return C.NIVEIS[e.nivel or 2] or C.NIVEIS[2] end

function Campeonato.modelo(e) return Carros[e.carro] end

-- ---------------------------------------------------------------- sorteio fixo
-- o mesmo numero sempre que a semente for a mesma (a rodada vem do password, entao o ranking e
-- as corridas de cada rodada tem de sair iguais depois de digitar o password)
local function sorteio(a, b)
  local x = (a * 73856093 ~ b * 19349663 ~ 0x5bd1e995) & 0x7fffffff
  x = (x * 1103515245 + 12345) & 0x7fffffff
  x = (x * 1103515245 + 12345) & 0x7fffffff
  return x
end

-- ---------------------------------------------------------------- ranking
local function pontos_do_rival(i, rodada)
  local p = Campeonato.PILOTOS[i]
  return floor(p[3] + p[4] * rodada + (sorteio(i, rodada) % 100) / 100 * 2)
end

-- os 20 (19 rivais + voce), do 1o ao ultimo: { nome, pontos, carro (indice), rival (indice) ou
-- jogador = true }
function Campeonato.ranking(e)
  local lista = {}
  for i = 1, #Campeonato.PILOTOS do
    lista[#lista + 1] = { nome = Campeonato.PILOTOS[i][1], pontos = pontos_do_rival(i, e.rodada), rival = i,
                          carro = Campeonato.carro_do_rival(i, e.rodada) }
  end
  lista[#lista + 1] = { nome = "VOCE", pontos = e.pontos, jogador = true, carro = e.carro }
  -- empate: voce fica atras (tem de passar de verdade)
  table.sort(lista, function(a, b)
    if a.pontos ~= b.pontos then return a.pontos > b.pontos end
    if a.jogador or b.jogador then return b.jogador == true end
    return a.rival < b.rival
  end)
  return lista
end

function Campeonato.posicao(e)
  for i, l in ipairs(Campeonato.ranking(e)) do
    if l.jogador then return i end
  end
end

function Campeonato.desafio_aberto(e) return Campeonato.posicao(e) == 1 end

-- ---------------------------------------------------------------- corridas da rodada
-- pistas do campeonato: as de imagem (pistas/lista.lua, sem a de treino)
local function pistas()
  local Pista = require "pista"
  local l = {}
  for i = 2, Pista.quantas() do l[#l + 1] = i end
  return l
end

-- a estreia em pistas faceis de entender: gramado, deserto e porto (indices em pistas/lista.lua)
local PRIMEIRA_RODADA = { 2, 4, 3 }

-- o carro do rival i na rodada (indice em carros.lua): o do comeco, mais um a cada
-- RIVAL_PONTOS_CARRO pontos ganhos desde a 1a rodada
function Campeonato.carro_do_rival(i, rodada)
  local ganhos = pontos_do_rival(i, rodada) - pontos_do_rival(i, 0)
  local k = Carros.indice(Campeonato.PILOTOS[i][2]) + ganhos // RIVAL_PONTOS_CARRO
  return k > #Carros and #Carros or k
end

-- o carro (id) do rival i numa corrida que aceita os carros da faixa { pior, melhor }
local function carro_na_corrida(i, rodada, faixa)
  local k = Campeonato.carro_do_rival(i, rodada)
  if k < faixa[1] then k = faixa[1] elseif k > faixa[2] then k = faixa[2] end
  return Carros[k].id
end

-- as 3 corridas da rodada: { dificuldade, pista (indice no menu), variante (Pista.VARIANTES: a
-- pista inversa e/ou espelhada; a 1a rodada e normal), rivais = { indices dos rivais },
-- carros = { modelo de cada rival } }
function Campeonato.corridas(e)
  local rank = Campeonato.ranking(e)
  local rivais_por_posicao = {}
  for _, l in ipairs(rank) do
    if l.rival then rivais_por_posicao[#rivais_por_posicao + 1] = l.rival end
  end
  local ps = pistas()
  local lista = {}
  for d, dif in ipairs(Campeonato.DIFICULDADES) do
    local candidatos = {}
    for k = dif.rivais[1], dif.rivais[2] do candidatos[#candidatos + 1] = rivais_por_posicao[k] end
    local escolhidos = {}
    for k = 1, 3 do
      local j = sorteio(e.rodada * 7 + d, k) % #candidatos + 1
      escolhidos[k] = table.remove(candidatos, j)
    end
    local pista = ps[sorteio(e.rodada, d + 10) % #ps + 1]
    local variante = sorteio(e.rodada, d + 30) % 4 + 1
    if e.rodada == 0 then pista, variante = PRIMEIRA_RODADA[d], 1 end
    local carros = {}
    for k, i in ipairs(escolhidos) do carros[k] = carro_na_corrida(i, e.rodada, dif.carros) end
    lista[d] = { dificuldade = dif, pista = pista, variante = variante, rivais = escolhidos, carros = carros }
  end
  return lista
end

-- o desafio final: O ADVERSARIO e os 2 primeiros do ranking, na pista do porto
function Campeonato.desafio(e)
  local rank = Campeonato.ranking(e)
  local rivais, carros = {}, {}
  for _, l in ipairs(rank) do
    if l.rival and #rivais < 2 then
      rivais[#rivais + 1] = l.rival
      carros[#carros + 1] = carro_na_corrida(l.rival, e.rodada, CARROS_FINAL)
    end
  end
  return { dificuldade = { id = "final", nome = "DESAFIO FINAL" }, pista = 3, rivais = rivais, carros = carros,
           final = true }
end

-- opcoes para Corrida.nova (corrida.lua) a partir de uma das corridas acima. minas: true = o
-- jogador comprou o pacote (C.PRECO_MINAS, pago em Campeonato.aplicar). Os rivais com minas
-- (quantos: pelo nivel) saem do sorteio fixo da rodada.
function Campeonato.opcoes_da_corrida(e, corrida, minas)
  local Pista = require "pista"
  local nivel = Campeonato.nivel(e)
  local rivais = {}
  if corrida.final then
    local chefe = Campeonato.CHEFE
    rivais[1] = { nome = chefe.nome, modelo = chefe.modelo, fator = chefe.fator, blindagem = chefe.blindagem }
  end
  for k, i in ipairs(corrida.rivais) do
    rivais[#rivais + 1] = { nome = Campeonato.PILOTOS[i][1], modelo = corrida.carros[k], fator = 1 }
  end
  local com_minas = corrida.final and #rivais or nivel.minas
  local primeiro = sorteio(e.rodada, 77) % #rivais
  for k = 0, com_minas - 1 do rivais[(primeiro + k) % #rivais + 1].minas = C.MINAS end
  return {
    pista = corrida.pista, variante = corrida.variante, voltas = Pista.LISTA[corrida.pista].voltas,
    modelo = Campeonato.modelo(e).id, rivais = rivais, nivel = e.nivel or 2,
    minas = minas and C.MINAS or 0, preco_minas = minas and C.PRECO_MINAS or 0,
    melhorias = { motor = e.motor, pneus = e.pneus, blindagem = e.blindagem },
    dificuldade = corrida.dificuldade.id, campeonato = corrida,
  }
end

-- ---------------------------------------------------------------- loja
function Campeonato.preco_melhoria(e, qual)
  local nivel = e[qual] + 1
  if nivel > Campeonato.MAX_NIVEL then return nil end
  return floor(PRECO_MELHORIA[nivel] * (1 + (e.carro - 1) * 0.25) / 100 + 0.5) * 100
end

function Campeonato.comprar_melhoria(e, qual)
  local preco = Campeonato.preco_melhoria(e, qual)
  if not preco or preco > e.dinheiro then return false end
  e.dinheiro = e.dinheiro - preco
  e[qual] = e[qual] + 1
  return true
end

-- quanto o seu carro vale na troca (metade do preco; as melhorias nao voltam)
function Campeonato.valor_na_troca(e)
  return Campeonato.PRECO_CARRO[Campeonato.modelo(e).id] // 200 * 100
end

function Campeonato.preco_troca(e, indice)
  return Campeonato.PRECO_CARRO[Carros[indice].id] - Campeonato.valor_na_troca(e)
end

function Campeonato.comprar_carro(e, indice)
  if indice == e.carro then return false end
  local preco = Campeonato.preco_troca(e, indice)
  if preco > e.dinheiro then return false end
  e.dinheiro = e.dinheiro - preco
  if e.dinheiro > Campeonato.DINHEIRO_MAX then e.dinheiro = Campeonato.DINHEIRO_MAX end
  e.carro, e.motor, e.pneus, e.blindagem = indice, 0, 0, 0     -- carro novo vem de fabrica
  return true
end

-- ---------------------------------------------------------------- depois da corrida
-- r: a corrida terminada (corrida.lua). Devolve as linhas para a tela de resultado e aplica no
-- estado: dinheiro (premios - minas - conserto), pontos do ranking, rodada. As minas sao pagas
-- aqui (e nao na compra): saindo no meio da corrida, nada muda.
function Campeonato.aplicar(e, r, premio)
  local j = r.jogador
  local dif = r.dificuldade
  premio = floor(premio / 100) * 100
  local minas = r.preco_minas or 0
  if minas > e.dinheiro + premio then minas = e.dinheiro + premio end
  -- conserto: o carro volta inteiro para a proxima, e voce paga pelo estrago
  local dano = C.VIDA - j.vida
  local conserto = floor(dano * (C.CONSERTO_POR_PCT + e.carro - 1) / 100 + 0.99) * 100
  if conserto > e.dinheiro + premio - minas then conserto = e.dinheiro + premio - minas end
  e.dinheiro = floor(e.dinheiro + premio - minas - conserto)
  if e.dinheiro > Campeonato.DINHEIRO_MAX then e.dinheiro = Campeonato.DINHEIRO_MAX end
  -- pontos do ranking
  local tabela = C.PONTOS_RANKING[dif] or C.PONTOS_RANKING.facil
  local pontos = floor((j.destruido and 0 or (tabela[j.posicao] or 0)) + j.abates * C.PONTOS_RANKING_ABATE)
  e.pontos = e.pontos + pontos
  if e.pontos > 255 then e.pontos = 255 end
  if e.rodada < 63 then e.rodada = e.rodada + 1 end
  local venceu_final = r.campeonato and r.campeonato.final and j.posicao == 1 and not j.destruido
  return { conserto = conserto, minas = minas, pontos = pontos, premio = premio, venceu_final = venceu_final }
end

-- ---------------------------------------------------------------- password
-- 8 letras de um alfabeto de 32 (sem I, O, 0 e 1, que se confundem) = 40 bits. O estado vira um
-- numero so (base mista: carro 9 x motor 4 x pneus 4 x blindagem 4 x dinheiro/100 1024 x rodada
-- 64 x pontos 256 x nivel 3 = 2,9 x 10^10, cabe em 35 bits) + 5 bits de verificacao. Os 35 bits
-- sao embaralhados por uma mascara que depende da verificacao: mudar 1 dolar muda o password
-- inteiro, e um erro de digitacao quase sempre da "password invalido" (~97%). Ate a v0.26 eram
-- 34 bits (sem o nivel) + 6: os passwords antigos nao valem mais.
Campeonato.ALFABETO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
local ALFA = Campeonato.ALFABETO
local CHAVE = 0x9C5A3E71B4        -- 40 bits
local M35 = (1 << 35) - 1
-- os campos, do primeiro (mais alto) ao ultimo, e quantos valores cada um tem
local CAMPOS = { { "carro", 9 }, { "motor", 4 }, { "pneus", 4 }, { "blindagem", 4 }, { "centenas", 1024 },
                 { "rodada", 64 }, { "pontos", 256 }, { "niv", 3 } }
local TOTAL = 1
for _, c in ipairs(CAMPOS) do TOTAL = TOTAL * c[2] end

local function verificacao(v)
  local h = (v * 0x9E3779B97F4A7C15) & 0x7fffffffffffffff
  return (h >> 40) & 31
end

local function mascara(c)
  return ((c + 1) * 0x5DEECE66D + 0xB) * 0x2545F491 & M35
end

function Campeonato.senha(e)
  local valores = { carro = e.carro - 1, motor = e.motor, pneus = e.pneus, blindagem = e.blindagem,
                    centenas = floor(e.dinheiro / 100), rodada = e.rodada, pontos = e.pontos, niv = (e.nivel or 2) - 1 }
  local v = 0
  for _, c in ipairs(CAMPOS) do v = v * c[2] + valores[c[1]] end
  local c = verificacao(v)
  local w = ((v ~ mascara(c)) << 5 | c) ~ CHAVE
  local s = {}
  for i = 8, 1, -1 do
    local k = w & 31
    s[i] = ALFA:sub(k + 1, k + 1)
    w = w >> 5
  end
  return table.concat(s)
end

-- estado a partir do password (8 letras, sem espaco), ou nil se nao vale
function Campeonato.ler_senha(texto)
  if #texto ~= 8 then return nil end
  local w = 0
  for i = 1, 8 do
    local k = ALFA:find(texto:sub(i, i), 1, true)
    if not k then return nil end
    w = w << 5 | (k - 1)
  end
  w = w ~ CHAVE
  local c = w & 31
  local v = (w >> 5) ~ mascara(c)
  if verificacao(v) ~= c or v >= TOTAL then return nil end
  local valores = {}
  for i = #CAMPOS, 1, -1 do
    local base = CAMPOS[i][2]
    valores[CAMPOS[i][1]] = v % base
    v = v // base
  end
  return {
    carro = valores.carro + 1, motor = valores.motor, pneus = valores.pneus, blindagem = valores.blindagem,
    dinheiro = valores.centenas * 100, rodada = valores.rodada, pontos = valores.pontos, nivel = valores.niv + 1,
  }
end

-- "ABCD EFGH" (mais facil de anotar)
function Campeonato.senha_bonita(e)
  local s = Campeonato.senha(e)
  return s:sub(1, 4) .. " " .. s:sub(5, 8)
end

return Campeonato
