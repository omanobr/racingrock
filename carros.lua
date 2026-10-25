-- Os modelos de carro, do mais fraco ao mais forte (arte em img/car/<id>_<cor>, feita por
-- ferramentas/preparar_carros.py a partir das imagens do Felipe).
--
-- Ficha (1 a 5; cada carro com uma ficha diferente, a pedido do Felipe): velocidade (final),
-- aceleracao (arranque), aderencia (o pneu escorrega menos) e tracao mudam a fisica (carro.lua,
-- numeros em config.lua: C.FICHA_*, C.TRACAO); arma = forca da metralhadora e blindagem = quanto
-- o carro aguenta, nas formulas do Death Rally (combate.lua). A saveiro faz o papel da picape do
-- Death Rally (o Dervish, logo depois do fusca).
--
-- v0.27: cada carro da lista e mais rapido que o anterior em todas as pistas (o Felipe ganhava
-- de um puma com o fusca). Com a IA nova, sozinhos no gramado, 3 voltas: fusca 74,0 s, uno 71,0,
-- ka 69,9, saveiro 68,6, corsa 67,3, focus 66,5, monza 65,2, opala 63,3, puma 61,5. Para isso
-- mudaram: fusca aderencia 2 -> 3, ka velocidade 1 -> 2, saveiro velocidade 2 -> 3 e aderencia
-- 1 -> 2, corsa velocidade 2 -> 3, opala velocidade 4 -> 5 e aderencia 2 -> 3 (e a tracao
-- traseira escorrega menos: C.TRACAO). As fichas continuam todas diferentes.
local Carros = {
  { id = "fusca", nome = "FUSCA", tracao = "traseira", aderencia = 3, aceleracao = 1, velocidade = 1, blindagem = 2, arma = 1 },
  { id = "uno", nome = "UNO", tracao = "dianteira", aderencia = 2, aceleracao = 2, velocidade = 2, blindagem = 1, arma = 1 },
  { id = "ka", nome = "KA", tracao = "dianteira", aderencia = 3, aceleracao = 2, velocidade = 2, blindagem = 2, arma = 1 },
  { id = "saveiro", nome = "SAVEIRO", tracao = "dianteira", aderencia = 2, aceleracao = 2, velocidade = 3, blindagem = 4, arma = 2 },
  { id = "corsa", nome = "CORSA", tracao = "dianteira", aderencia = 3, aceleracao = 3, velocidade = 3, blindagem = 2, arma = 2 },
  { id = "focus", nome = "FOCUS", tracao = "dianteira", aderencia = 4, aceleracao = 3, velocidade = 3, blindagem = 3, arma = 2 },
  { id = "monza", nome = "MONZA", tracao = "dianteira", aderencia = 3, aceleracao = 3, velocidade = 4, blindagem = 3, arma = 3 },
  { id = "opala", nome = "OPALA", tracao = "traseira", aderencia = 3, aceleracao = 4, velocidade = 5, blindagem = 5, arma = 4 },
  { id = "puma", nome = "PUMA", tracao = "traseira", aderencia = 5, aceleracao = 5, velocidade = 5, blindagem = 2, arma = 4 },
}

-- nota 1..5 da ficha -> valor entre faixa[1] (nota 1) e faixa[2] (nota 5)
function Carros.escala(nota, faixa)
  return faixa[1] + (faixa[2] - faixa[1]) * ((nota or 3) - 1) / 4
end

function Carros.indice(id)
  for i, m in ipairs(Carros) do
    if m.id == id then return i end
  end
  return 1
end

return Carros
