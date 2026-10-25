-- Musica: UMA trilha so (music/trilha.mp3, as 4 musicas do Felipe em sequencia, feita por
-- ferramentas/preparar_musicas.py), tocada com sfx.music uma vez, quando o jogo abre; o console a
-- repete sozinho. Quem toca e o console, separado do Lua: o FPS do jogo nao muda a musica.
--
-- Por que nao troca de musica (v0.31): no aparelho, cada sfx.music com outro arquivo prende memoria
-- do console e nao solta a da anterior. Na v0.29 a musica trocava a cada corrida (e na demonstracao
-- do titulo): depois de ~10 trocas o log encheu de "No RAM left for sample load", a musica falhou,
-- e nem reabrir o jogo resolveu (so desligando o console). Por isso Som.musica so toca na primeira
-- vez; os pedidos seguintes (menu, corrida, desafio) sao ignorados.
local Musica = require "dados_musica"

local Som = {}

local tocando = false

function Som.musica()
  if tocando then return end
  tocando = true
  if not (sfx and sfx.music) then return end
  print("RROCK MUSICA " .. Musica.arquivo)
  -- pcall: se algo der errado no som, o jogo continua sem musica
  pcall(sfx.music, Musica.arquivo)
end

return Som
