-- Gerado por ferramentas/preparar_interface.py. Nao edite.
-- Telas cheias: img/tela/<nome>1..3 (faixas de 480x90, de cima para baixo).
-- Retratos (img/ui/ret36 e ret16): 1-19 os rivais na ordem de campeonato.lua, mais jogador,
-- adversario e mecanica (o tile e o numero - 1).
return {
  faixa_h = 90,
  logo = { w = 200, h = 122 },
  adversario = { w = 96, h = 96 },
  retrato = { jogador = 19, adversario = 20, mecanica = 21 },
  oficina = { motor = 0, pneus = 1, blindagem = 2, lado = 48 },
  itens = { minas = 0, espinhos = 1, foguete = 2, sabotagem = 3, lado = 32 },   -- img/ui/itens (mercado negro)
}
