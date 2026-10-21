-- Gerado por ferramentas/preparar_carros.py. Nao edite.
-- Tamanho de cada carro no jogo (px, apontando para cima) e o desenho: folhas de tiles
-- 40x40 com as direcoes 0-17 (img/car/<id>_<cor>) e 18-32 (<id>_<cor>2), de 64 direcoes.
DadosCarros = {
  quadro = 40, direcoes = 64, por_folha = 18,
  uno = { comprimento = 30, largura = 15 },
  ka = { comprimento = 30, largura = 14 },
  fusca = { comprimento = 31, largura = 14 },
  corsa = { comprimento = 32, largura = 16 },
  focus = { comprimento = 34, largura = 18 },
  monza = { comprimento = 34, largura = 16 },
  opala = { comprimento = 35, largura = 16 },
  puma = { comprimento = 32, largura = 16 },
}
return DadosCarros
