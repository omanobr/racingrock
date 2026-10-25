-- Racing Rock - corrida de combate vista de cima, no estilo do Death Rally (1996).
-- Ponto de entrada: o Lupi chama update() 60 vezes por segundo.
collectgarbage("generational")

require "palette"   -- gerado pela construcao (todas as cores do jogo)
require "sprites"   -- tabela Sprites com todas as imagens

-- Opcoes de teste vindas do simulador (o arquivo nao existe no console).
local ok, dev = pcall(require, "dev_config")
DEV = (ok and type(dev) == "table") and dev or {}

local C = require "config"
local Tempo = require "tempo"
local Diag = require "diagnostico"
local Lote = require "lote"

local TELAS = {
  titulo = require "telas.titulo",
  corrida = require "telas.corrida",
  resultado = require "telas.resultado",
  teste = require "telas.teste",
  rapida = require "telas.rapida",
  opcoes = require "telas.opcoes",
  historia = require "telas.historia",
  senha = require "telas.senha",
  garagem = require "telas.garagem",
  final = require "telas.final",
  abertura = require "telas.abertura",
  rodada = require "telas.rodada",
  cobranca = require "telas.cobranca",
}

Jogo = { tela = nil }

-- Fade (abertura): Jogo.brilho de 0 (preto) a 1 (normal); nil = normal. A paleta escurecida tem
-- 16 niveis, cada um montado na primeira vez que aparece (como no GearX).
local ESCURA = {}
local function paleta_escura(n)
  local t = ESCURA[n]
  if t then return t end
  t = { Palette[1] }   -- a cor 0 e a transparente: fica como esta
  for i = 2, #Palette do
    local c = Palette[i]   -- BGR555: vermelho nos 5 bits de baixo
    local r, g, b = (c & 31) * n // 16, ((c >> 5) & 31) * n // 16, ((c >> 10) & 31) * n // 16
    local v = r | (g << 5) | (b << 10)
    t[i] = v == 0 and 0x0421 or v   -- 0x0000 e transparente no console: o mais escuro e 1,1,1
  end
  ESCURA[n] = t
  return t
end

function Jogo.ir(nome, ...)
  Jogo.brilho = nil   -- a tela nova pode comecar escura (ela mesma acerta)
  Jogo.nome_tela = nome
  Jogo.tela = TELAS[nome].nova(...)
  collectgarbage("collect")
end

if DEV.cena == "corrida" then
  Jogo.ir("corrida", { pista = DEV.pista or 1, variante = DEV.variante, voltas = DEV.voltas or C.VOLTAS,
                       autopiloto = DEV.autopiloto, modelo = DEV.modelo })
else
  Jogo.ir(DEV.sem_abertura and "titulo" or "abertura")
end

-- medidor dos limites do aparelho (so no simulador, opcao "desempenho" do Modo de teste)
local Medidor = DEV.desempenho and require "medidor"
Diag.ligado = C.DIAGNOSTICO
Jogo.rodape = false

-- DEV.lento (so no simulador): o jogo anda 1 de cada N quadros, como o console quando o
-- quadro demora; nos outros so redesenha a mesma cena.
local pulados = 0
local palset = ui.palset

function update(frame)
  local anda = true
  if DEV.lento then
    pulados = (pulados + 1) % DEV.lento
    anda = pulados == 0
  end
  if anda then
    Tempo.atualizar(frame)
    if DEV.lento then Tempo.passo = DEV.lento end
  end
  if Medidor then Medidor.inicio() end

  -- a paleta inteira, TODO quadro: o console zera a paleta a cada quadro
  local paleta = Palette
  if Jogo.brilho and Jogo.brilho < 1 then paleta = paleta_escura(math.floor(Jogo.brilho * 16)) end
  for i = 1, #paleta do palset(i - 1, paleta[i]) end
  ui.camera()
  ui.clip()

  if anda then
    for _ = 1, DEV.turbo or 1 do Jogo.tela:atualizar() end
  end
  -- fora da corrida, os tiles de cada folha saem juntos no fim (lote.lua: cada troca de folha
  -- le a folha inteira do cartao)
  local lote = Jogo.nome_tela ~= "corrida"
  Lote.ligar(lote)
  Jogo.tela:desenhar()
  if lote then
    Lote.desenhar()
    Lote.ligar(false)
  end

  if Medidor then
    Medidor.fim()
    Medidor.desenhar()
  end
  Diag.quadro()
  if Jogo.rodape then Diag.desenhar() end
end
