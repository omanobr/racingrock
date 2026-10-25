-- Gerado por ferramentas/gerar_interface.py. Nao edite.
-- Letras grandes (img/ui/f2, f3): tile = inicio da cor + indice da letra (codigo Latin-1
-- ou nome do acento). Barras (img/ui/barras): tiles. Mapinhas (img/mapa/<id>): escala
-- (px do mapinha por px da pista) e tamanho; o mapinha tem 1 px de contorno em volta.
return {
  f2 = {
    w = 12, h = 16, avanco = 12, escala = 2,
    cores = { branco = 0, amarelo = 55, cinza = 110 },
    palheta = 165, zebrada = 166,
    letras = {
      [65] = 0, [66] = 1, [67] = 2, [68] = 3, [69] = 4, [70] = 5, [71] = 6, [72] = 7, [73] = 8,
      [74] = 9, [75] = 10, [76] = 11, [77] = 12, [78] = 13, [79] = 14, [80] = 15, [81] = 16, [82] = 17,
      [83] = 18, [84] = 19, [85] = 20, [86] = 21, [87] = 22, [88] = 23, [89] = 24, [90] = 25,
      [48] = 26, [49] = 27, [50] = 28, [51] = 29, [52] = 30, [53] = 31, [54] = 32, [55] = 33,
      [56] = 34, [57] = 35, [33] = 36, [63] = 37, [46] = 38, [44] = 39, [58] = 40, [45] = 41,
      [47] = 42, [39] = 43, [43] = 44, [36] = 45, [37] = 46, [40] = 47, [41] = 48, [186] = 49,
      agudo = 50, grave = 51, circ = 52, til = 53, cedilha = 54,
    },
  },
  f3 = {
    w = 17, h = 23, avanco = 17, escala = 3,
    cores = { amarelo = 0 },
    letras = {
      [65] = 0, [66] = 1, [67] = 2, [68] = 3, [69] = 4, [70] = 5, [71] = 6, [72] = 7, [73] = 8,
      [74] = 9, [75] = 10, [76] = 11, [77] = 12, [78] = 13, [79] = 14, [80] = 15, [81] = 16, [82] = 17,
      [83] = 18, [84] = 19, [85] = 20, [86] = 21, [87] = 22, [88] = 23, [89] = 24, [90] = 25,
      [48] = 26, [49] = 27, [50] = 28, [51] = 29, [52] = 30, [53] = 31, [54] = 32, [55] = 33,
      [56] = 34, [57] = 35, [33] = 36, [63] = 37, [46] = 38, [44] = 39, [58] = 40, [45] = 41,
      [47] = 42, [39] = 43, [43] = 44, [36] = 45, [37] = 46, [40] = 47, [41] = 48, [186] = 49,
      agudo = 50, grave = 51, circ = 52, til = 53, cedilha = 54,
    },
  },
  -- numeros do painel da corrida (img/ui/painel): f3 = algarismos grandes, f2 = pequenos
  painel = { f3 = 0, f2 = 10, barra = 20, ordinal = 21, avanco = 12 },
  barras = { velocidade = 0, velocidade_contorno = 1, vida = 2, municao = 3, turbo = 4,
             vel_x = 2, vel_leds = 34, vel_y = 1, vel_h = 12, barra_w = 100, barra_h = 7, leds = 24 },
  mapas = {
    p0 = { escala = 0.04934, w = 80, h = 62 },
    p1 = { escala = 0.05859, w = 92, h = 62 },
    p2 = { escala = 0.05769, w = 98, h = 55 },
    p3 = { escala = 0.06316, w = 98, h = 55 },
    p4 = { escala = 0.05128, w = 98, h = 56 },
    p5 = { escala = 0.05128, w = 98, h = 56 },
    p6 = { escala = 0.05405, w = 98, h = 55 },
    p7 = { escala = 0.06667, w = 98, h = 55 },
  },
}
