-- Modo historia (campeonato), no jeito do Death Rally: voce comeca no fim de um ranking de 20
-- pilotos com um fusca velho e pouco dinheiro; a cada rodada escolhe uma de 3 corridas (facil,
-- media, dificil), ganha dinheiro e pontos, conserta o carro, compra melhorias e carros novos.
-- No 1o lugar do ranking, abre o desafio final contra O ADVERSARIO, o dono da liga.
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
Campeonato.CHEFE = { nome = "ADVERSARIO", modelo = "puma", fator = 1.2, blindagem = 3 }

Campeonato.DIFICULDADES = {
  { id = "facil", nome = "FACIL", rivais = { 13, 19 } },     -- rivais da 13a a 19a posicao do ranking
  { id = "medio", nome = "MEDIA", rivais = { 7, 12 } },
  { id = "dificil", nome = "DIFICIL", rivais = { 1, 6 } },
}

-- precos (multiplos de 100: o password guarda o dinheiro em centenas)
Campeonato.PRECO_CARRO = { fusca = 0, uno = 3000, ka = 4000, saveiro = 6000, corsa = 9000, focus = 13000,
                           monza = 18000, opala = 24000, puma = 32000 }
Campeonato.MELHORIAS = { "motor", "pneus", "blindagem" }
Campeonato.NOME_MELHORIA = { motor = "MOTOR", pneus = "PNEUS", blindagem = "BLINDAGEM" }
local PRECO_MELHORIA = { 800, 1600, 3200 }     -- nivel 1, 2, 3 no fusca; carros melhores pagam mais
Campeonato.MAX_NIVEL = 3
Campeonato.DINHEIRO_MAX = 1023 * 100

function Campeonato.novo()
  return { carro = 1, motor = 0, pneus = 0, blindagem = 0, dinheiro = 500, rodada = 0, pontos = 0 }
end

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

-- os 20 (19 rivais + voce), do 1o ao ultimo: { nome, pontos, rival (indice) ou jogador = true }
function Campeonato.ranking(e)
  local lista = {}
  for i = 1, #Campeonato.PILOTOS do
    lista[#lista + 1] = { nome = Campeonato.PILOTOS[i][1], pontos = pontos_do_rival(i, e.rodada), rival = i }
  end
  lista[#lista + 1] = { nome = "VOCE", pontos = e.pontos, jogador = true }
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

-- as 3 corridas da rodada: { dificuldade, pista (indice no menu), rivais = { indices dos rivais } }
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
    if e.rodada == 0 then pista = PRIMEIRA_RODADA[d] end
    lista[d] = { dificuldade = dif, pista = pista, rivais = escolhidos }
  end
  return lista
end

-- o desafio final: O ADVERSARIO e os 2 primeiros do ranking, na pista do porto
function Campeonato.desafio(e)
  local rank = Campeonato.ranking(e)
  local rivais = {}
  for _, l in ipairs(rank) do
    if l.rival and #rivais < 2 then rivais[#rivais + 1] = l.rival end
  end
  return { dificuldade = { id = "final", nome = "DESAFIO FINAL" }, pista = 3, rivais = rivais, final = true }
end

-- opcoes para Corrida.nova (corrida.lua) a partir de uma das corridas acima
function Campeonato.opcoes_da_corrida(e, corrida)
  local Pista = require "pista"
  local fator = C.CAMPEONATO_FATOR[corrida.dificuldade.id]
  local rivais = {}
  if corrida.final then
    local chefe = Campeonato.CHEFE
    rivais[1] = { nome = chefe.nome, modelo = chefe.modelo, fator = chefe.fator, blindagem = chefe.blindagem }
  end
  for _, i in ipairs(corrida.rivais) do
    local p = Campeonato.PILOTOS[i]
    rivais[#rivais + 1] = { nome = p[1], modelo = p[2], fator = fator }
  end
  return {
    pista = corrida.pista, voltas = Pista.LISTA[corrida.pista].voltas,
    modelo = Campeonato.modelo(e).id, rivais = rivais,
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
-- estado: dinheiro (premios - conserto), pontos do ranking, rodada.
function Campeonato.aplicar(e, r, premio)
  local j = r.jogador
  local dif = r.dificuldade
  local linhas = {}
  -- conserto: o carro volta inteiro para a proxima, e voce paga pelo estrago
  local dano = C.VIDA - j.vida
  local conserto = floor(dano * (C.CONSERTO_POR_PCT + e.carro - 1) / 100 + 0.99) * 100
  premio = floor(premio / 100) * 100
  if conserto > e.dinheiro + premio then conserto = e.dinheiro + premio end
  e.dinheiro = floor(e.dinheiro + premio - conserto)
  if e.dinheiro > Campeonato.DINHEIRO_MAX then e.dinheiro = Campeonato.DINHEIRO_MAX end
  -- pontos do ranking
  local tabela = C.PONTOS_RANKING[dif] or C.PONTOS_RANKING.facil
  local pontos = floor((j.destruido and 0 or (tabela[j.posicao] or 0)) + j.abates * C.PONTOS_RANKING_ABATE)
  e.pontos = e.pontos + pontos
  if e.pontos > 255 then e.pontos = 255 end
  if e.rodada < 63 then e.rodada = e.rodada + 1 end
  local venceu_final = r.campeonato and r.campeonato.final and j.posicao == 1 and not j.destruido
  return { conserto = conserto, pontos = pontos, premio = premio, venceu_final = venceu_final }
end

-- ---------------------------------------------------------------- password
-- 8 letras de um alfabeto de 32 (sem I, O, 0 e 1, que se confundem) = 40 bits:
--   carro 4 + motor 2 + pneus 2 + blindagem 2 + dinheiro/100 10 + rodada 6 + pontos 8 = 34 bits
--   + 6 bits de verificacao. Os 34 bits sao embaralhados por uma mascara que depende da
--   verificacao: mudar 1 dolar muda o password inteiro, e um erro de digitacao quase sempre da
--   "password invalido" (1 em 64 passaria).
Campeonato.ALFABETO = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
local ALFA = Campeonato.ALFABETO
local CHAVE = 0x9C5A3E71B4        -- 40 bits
local M34 = (1 << 34) - 1

local function verificacao(v)
  local h = (v * 0x9E3779B97F4A7C15) & 0x7fffffffffffffff
  return (h >> 40) & 63
end

local function mascara(c)
  return ((c + 1) * 0x5DEECE66D + 0xB) * 0x2545F491 & M34
end

function Campeonato.senha(e)
  local v = (e.carro - 1) | e.motor << 4 | e.pneus << 6 | e.blindagem << 8
    | floor(e.dinheiro / 100) << 10 | e.rodada << 20 | e.pontos << 26
  local c = verificacao(v)
  local w = ((v ~ mascara(c)) << 6 | c) ~ CHAVE
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
  local c = w & 63
  local v = (w >> 6) ~ mascara(c)
  if verificacao(v) ~= c then return nil end
  local e = {
    carro = (v & 15) + 1, motor = v >> 4 & 3, pneus = v >> 6 & 3, blindagem = v >> 8 & 3,
    dinheiro = (v >> 10 & 1023) * 100, rodada = v >> 20 & 63, pontos = v >> 26 & 255,
  }
  if e.carro > #Carros then return nil end
  return e
end

-- "ABCD EFGH" (mais facil de anotar)
function Campeonato.senha_bonita(e)
  local s = Campeonato.senha(e)
  return s:sub(1, 4) .. " " .. s:sub(5, 8)
end

return Campeonato
