-- Os modelos de carro, do mais fraco ao mais forte (arte em img/car/<id>_<cor>, feita por
-- ferramentas/preparar_carros.py a partir das imagens do Felipe). Por enquanto todos andam
-- igual: a potencia, o pneu e a blindagem de cada um vem com a loja.
local Carros = {
  { id = "uno", nome = "UNO" },
  { id = "ka", nome = "KA" },
  { id = "fusca", nome = "FUSCA" },
  { id = "corsa", nome = "CORSA" },
  { id = "focus", nome = "FOCUS" },
  { id = "monza", nome = "MONZA" },
  { id = "opala", nome = "OPALA" },
  { id = "puma", nome = "PUMA" },
}

function Carros.indice(id)
  for i, m in ipairs(Carros) do
    if m.id == id then return i end
  end
  return 1
end

return Carros
