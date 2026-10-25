-- Musica (v0.29, as musicas do Felipe): music/<nome>.mp3 (ferramentas/preparar_musicas.py),
-- tocadas com sfx.music, como no GearX e no le-pendu. Quem toca e o console (o servidor converte
-- o MP3), separado do Lua: o FPS do jogo nao muda a velocidade nem o tom da musica, e o console
-- repete a musica sozinho quando ela acaba. Trocar de musica = chamar sfx.music com outro arquivo
-- (so quando muda). No simulador nao tem som.
--   menu: abertura, titulo e menus; corrida1/corrida2: as corridas, alternando; chefe: o desafio
--   final contra O ADVERSARIO
local Som = {}

local atual

function Som.musica(nome)
  if nome == atual then return end
  atual = nome
  if not (sfx and sfx.music) then return end
  print("RROCK MUSICA " .. nome)
  -- pcall: se algo der errado no som, o jogo continua sem musica
  pcall(sfx.music, "music/" .. nome)
end

-- musica da corrida: o desafio final tem a sua; as outras alternam entre as duas
local corridas = 0
function Som.corrida(final)
  if final then return Som.musica("chefe") end
  corridas = corridas + 1
  Som.musica(corridas % 2 == 1 and "corrida1" or "corrida2")
end

return Som
