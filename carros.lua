-- Os modelos de carro, do mais fraco ao mais forte (arte em img/car/<id>_<cor>, feita por
-- ferramentas/preparar_carros.py a partir das imagens do Felipe).
--
-- Ficha (1 a 5, o chute inicial da tabela do LEIA-ME): arma = forca da metralhadora e
-- blindagem = quanto o carro aguenta, nas formulas do Death Rally (combate.lua). Aderencia,
-- aceleracao, velocidade e tracao ainda nao mudam nada: vem com os "carros com personalidade".
local Carros = {
  { id = "uno", nome = "UNO", tracao = "dianteira", aderencia = 2, aceleracao = 2, velocidade = 1, blindagem = 2, arma = 1 },
  { id = "ka", nome = "KA", tracao = "dianteira", aderencia = 3, aceleracao = 2, velocidade = 2, blindagem = 1, arma = 1 },
  { id = "fusca", nome = "FUSCA", tracao = "traseira", aderencia = 2, aceleracao = 1, velocidade = 2, blindagem = 4, arma = 2 },
  { id = "corsa", nome = "CORSA", tracao = "dianteira", aderencia = 3, aceleracao = 3, velocidade = 3, blindagem = 2, arma = 2 },
  { id = "focus", nome = "FOCUS", tracao = "dianteira", aderencia = 4, aceleracao = 3, velocidade = 3, blindagem = 3, arma = 3 },
  { id = "monza", nome = "MONZA", tracao = "dianteira", aderencia = 3, aceleracao = 3, velocidade = 4, blindagem = 3, arma = 3 },
  { id = "opala", nome = "OPALA", tracao = "traseira", aderencia = 2, aceleracao = 4, velocidade = 5, blindagem = 5, arma = 4 },
  { id = "puma", nome = "PUMA", tracao = "traseira", aderencia = 4, aceleracao = 5, velocidade = 5, blindagem = 2, arma = 4 },
}

function Carros.indice(id)
  for i, m in ipairs(Carros) do
    if m.id == id then return i end
  end
  return 1
end

return Carros
