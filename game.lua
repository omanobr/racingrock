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

local TELAS = {
  titulo = require "telas.titulo",
  corrida = require "telas.corrida",
  resultado = require "telas.resultado",
  teste = require "telas.teste",
}

Jogo = { tela = nil }

function Jogo.ir(nome, ...)
  Jogo.nome_tela = nome
  Jogo.tela = TELAS[nome].nova(...)
  collectgarbage("collect")
end

if DEV.cena == "corrida" then
  Jogo.ir("corrida", { pista = DEV.pista or 1, voltas = DEV.voltas or C.VOLTAS, autopiloto = DEV.autopiloto,
                       modelo = DEV.modelo })
else
  Jogo.ir("titulo")
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
  for i = 1, #paleta do palset(i - 1, paleta[i]) end
  ui.camera()
  ui.clip()

  if anda then
    for _ = 1, DEV.turbo or 1 do Jogo.tela:atualizar() end
  end
  Jogo.tela:desenhar()

  if Medidor then
    Medidor.fim()
    Medidor.desenhar()
  end
  Diag.quadro()
  if Jogo.rodape then Diag.desenhar() end
end
