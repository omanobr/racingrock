-- Lote (v0.34): nas telas de menu, os tiles de cada folha (letras f2/f3, retratos, icones) sao
-- guardados e desenhados juntos no fim do quadro (game.lua). No console, cada troca de folha le
-- a folha INTEIRA do cartao, e um retangulo ou texto no meio quebra o lote: o despejo que o
-- desenvolvedor mandou (corrida rapida, versao anterior) mostrou a fonte f2 lida 4 vezes num
-- quadro, e o ranking da rodada lia os retratos 20 vezes.
-- Regra: dentro do lote, os tiles ficam POR CIMA de todo retangulo e texto do quadro. O que
-- tem de cobrir letras (uma janela por cima de outra) chama Lote.desenhar() antes.
-- Na corrida o lote fica desligado (o painel ja desenha folha por folha) e Lote.tile = ui.tile.
local Lote = {}

local tile = ui.tile
local ligado = false
local folhas, n_folhas = {}, 0   -- folhas na ordem do primeiro uso no quadro
local filas, tam = {}, {}        -- folha -> { n, x, y, n, x, y... } e quantos numeros (reaproveitadas)

function Lote.ligar(sim) ligado = sim end

function Lote.tile(folha, n, x, y)
  if not ligado then return tile(folha, n, x, y) end
  local f, k = filas[folha], tam[folha]
  if not f then
    f = {}
    filas[folha] = f
  end
  if not k or k == 0 then
    k = 0
    n_folhas = n_folhas + 1
    folhas[n_folhas] = folha
  end
  f[k + 1], f[k + 2], f[k + 3] = n, x, y
  tam[folha] = k + 3
end

-- desenha o que foi guardado, uma folha de cada vez
function Lote.desenhar()
  for i = 1, n_folhas do
    local folha = folhas[i]
    local f = filas[folha]
    for j = 1, tam[folha], 3 do tile(folha, f[j], f[j + 1], f[j + 2]) end
    tam[folha], folhas[i] = 0, nil
  end
  n_folhas = 0
end

return Lote
