-- Numeros do jogo. A fisica imita o Death Rally (1996): os valores de la (70 quadros por
-- segundo, velocidade em pixels por quadro) estao convertidos para pixels por segundo.
local C = {}

C.VERSAO = "0.31"

C.VOLTAS = 3            -- so para testes: cada pista tem as suas (pistas/lista.lua)
C.CARROS = 4
C.PISTA = 2             -- pista do comeco (pista.lua; o menu troca)
C.VARIANTE = 1          -- 1 normal, 2 inversa, 3 espelhada, 4 espelhada e inversa (Pista.VARIANTES)
C.MODELO = "fusca"      -- carro do jogador no comeco (carros.lua; o menu troca)

-- Carro. M e a "potencia" do Death Rally (2.55 no carro mais fraco, 4.3 no mais forte).
-- Com o acelerador apertado o carro chega a ~54*M px/s; com turbo, ~88*M px/s (vezes ESCALA).
-- ESCALA: os carros tem 30-35 px (no Death Rally, 27-31); as velocidades crescem junto, senao
-- tudo parece mais lento.
C.ESCALA = 1.3
C.ACEL = 130.7 * C.ESCALA         -- x M px/s2
C.ACEL_TURBO = 212 * C.ESCALA     -- x M px/s2
C.FREIO = 54.4 * C.ESCALA         -- x M px/s2
C.ARRASTO = 1.414       -- por segundo, sempre (o 0.98 por quadro do Death Rally)
C.ARRASTO_ACEL = 0.987  -- por segundo, a mais com o acelerador (o 0.986)
C.RE_MAX = 0.35         -- velocidade maxima de re (fracao da maxima)
C.GIRO_BASE = 1.70      -- giro = 3.75 graus / (GIRO_BASE - 0.05 x motor) por quadro a 70 FPS
C.GIRO_VEL = 40 * C.ESCALA   -- abaixo desta velocidade (px/s) o carro vira menos
C.GIRO_PARADO = 0.5     -- parado, gira a esta fracao do giro normal
-- derrapagem: o "angulo de deslize" sobe enquanto vira e desce sozinho; quanto maior a
-- aderencia (pneu ruim = numero alto), mais o carro escorrega de lado
C.DESLIZE_SOBE = 140    -- por segundo
C.DESLIZE_DESCE = 70    -- por segundo
C.DESLIZE_MAX = 36
C.DESLIZE_FREIA = 20    -- acima disso o carro perde velocidade (o 0.98 extra)

-- Terreno (letra do mapa de terreno -> arrasto extra por segundo)
C.ARRASTO_TERRA = 2.03  -- 34/35 por quadro: na terra o carro anda a ~metade
C.TERRA_ESCORREGA = 1.6 -- multiplica a aderencia na terra

-- Batidas
C.MURO_DE_FRENTE = 0.9  -- batida "de frente" (cosseno do angulo com o muro): volta
C.MURO_PERDA = 0.8      -- de raspao: perde 80% da parte da velocidade que ia contra o muro
C.MURO_GIRO = math.rad(25)   -- de raspao: gira ate isso para ficar paralelo ao muro
C.MURO_SEPARA = 0.25    -- de raspao: empurrao para fora do muro (fracao da velocidade)
C.MURO_ARRASTA = 0.3    -- arrastando encostado no muro, a velocidade cai para 30% em 1 s
C.MURO_VOLTA = -0.3     -- bateu de frente: volta com 30% da velocidade
-- colisao entre carros: 2 circulos por carro (frente e tras), do tamanho de cada modelo
C.EMPURRAO = 0.7        -- quanto da diferenca de velocidade passa de um carro para o outro
C.EMPURRAO_FIM = 9.78   -- o empurrao some (1.15 por quadro)
C.RESGATE = 0.4         -- segundos com o meio do carro no muro (0,1 s fora da pista): volta para a pista
C.RESGATE_TRAVADO = 1.5 -- segundos encostado no muro sem conseguir sair: idem
C.RESGATE_PARADO = 4    -- segundos sem sair do lugar (menos de 6 px por segundo) com o pedal apertado: idem

-- Combate, com as formulas do Death Rally (vida cheia = 1024 x 100; tudo depende da blindagem
-- de quem leva, de 0 a 1024; cada % de vida = 1024):
--   metralhadora: (1024 - blindagem) x fator da arma de quem atira, por quadro a 70 por segundo
--   mina: 20 x (1024 - blindagem); batida: (1024 - blindagem) x (velocidade em px/quadro)^2, ate 10000
--   blindagem = base do carro (120 a 350) + nivel comprado (360 a 600) + 100 do jogador, ate 900
C.VIDA = 100
C.DANO = 2.5            -- multiplica todo dano (tiro, mina, batida). v0.29: o Felipe achou os carros
                        -- "tanques" (com 1: 0 a 0,3 rivais destruidos por corrida, ele nunca);
                        -- com 2,5: ~1 rival por corrida, voce de vez em quando, dano medio ~50%
C.KMH = 0.7             -- velocimetro: km/h por px/s (fusca ~136, puma ~161, com turbo ~260)
C.ARMA_ALCANCE = 170    -- px (130 no Death Rally, x ESCALA)
C.ARMA_FATOR = { 0.2, 0.95 }       -- arma 1 a 5 da ficha (carros.lua): 0,2 + 0,15 x tipo (0 a 5)
C.BLINDAGEM_BASE = { 120, 350 }    -- blindagem 1 a 5 da ficha
C.BLINDAGEM_NIVEL = 360            -- o 1o nivel (a loja vai vender os outros, ate 600)
C.BLINDAGEM_JOGADOR = 100
C.BLINDAGEM_MAX = 900
C.QUADROS_DR = 70       -- o Death Rally roda a 70 quadros por segundo
C.MINA_FORCA = 20
C.BATIDA_MAX = 10000
C.BATIDA_MIN = 40       -- batida mais devagar que isso (px/s) nao tira vida
C.MUNICAO = 6           -- segundos de tiro no comeco da corrida (5,6 s no Death Rally)
C.MUNICAO_ITEM = 4      -- segundos a mais por caixa de municao
C.MINAS = 3             -- minas de um pacote (modo historia: compradas no mercado negro)
-- Mercado negro (modo historia, v0.29, como no Death Rally): compras que valem so para a proxima
-- corrida, pagas no fim dela (saindo no meio, nada e cobrado)
C.MERCADO = {
  minas = 400,          -- um pacote de C.MINAS
  espinhos = 600,       -- batida do seu para-choque tira ESPINHOS x mais dos outros (e a metade de voce)
  foguete = 500,        -- combustivel de foguete: o turbo larga com FOGUETE tanques
  sabotagem = 900,      -- um rival larga com SABOTAGEM_VIDA % de vida
}
C.ESPINHOS = 3
C.FOGUETE = 2
C.SABOTAGEM_VIDA = 55
-- Recompensa (proposta antes da corrida, como no Death Rally): destruir um rival nesta corrida.
-- Chance de aparecer ao escolher uma corrida; valor = RECOMPENSA_ABATES x o premio por abate da
-- corrida; se ele escapar, voce paga a MULTA (fracao do valor). Avisado na proposta.
C.RECOMPENSA_CHANCE = 25   -- %
C.RECOMPENSA_ABATES = 3
C.RECOMPENSA_MULTA = 0.5
-- Agiota: empresta, cobra JUROS em PRAZO rodadas; se nao pagar, leva o dinheiro e as melhorias
C.AGIOTA_EMPRESTIMOS = { 5000, 10000, 20000 }
C.AGIOTA_JUROS = 1.5
C.AGIOTA_PRAZO = 5
C.MINA_FREIA = -0.5     -- velocidade x isto (o Death Rally usa -0.7)
C.MINA_GIRO = math.rad(25)   -- gira ate isto para um lado
C.MINA_ARMA = 1.0       -- segundos ate a mina valer para quem soltou

-- Pontos e dinheiro (ideia do Felipe; so o jogador ganha o bonus de sobrevivente)
C.PONTOS_POSICAO = { 5, 3, 1, 0 }
C.PONTOS_ABATE = 2
-- dinheiro do jogador por corrida, pela dificuldade (o Death Rally paga ~750/375/187 nas faceis;
-- aqui tudo multiplo de 100: o password guarda o dinheiro em centenas). A corrida rapida paga
-- como a facil.
-- v0.29: x2,2 e o 4o lugar ganha metade do 3o (campeonato simulado: ferramentas/medir_campanha.py)
C.PREMIOS = {
  facil = { posicao = { 1800, 900, 400, 200 }, abate = 700, sobrevivente = 2000 },
  medio = { posicao = { 3500, 1800, 900, 400 }, abate = 1100, sobrevivente = 4000 },
  dificil = { posicao = { 7000, 3500, 1800, 900 }, abate = 1800, sobrevivente = 6000 },
  final = { posicao = { 22000, 0, 0, 0 }, abate = 2200, sobrevivente = 10000 },
}
-- modo historia (campeonato.lua): pontos do ranking por colocacao (+1 por abate), conserto por %
-- de estrago (+1 a cada carro melhor) e o efeito das melhorias da oficina (por nivel, ate 3). A
-- dificuldade da corrida (facil, media, dificil) so muda os carros que entram (Campeonato.
-- DIFICULDADES), o premio e os pontos: a pilotagem e a ficha dos rivais vem do nivel (C.NIVEIS).
C.PONTOS_RANKING = { facil = { 3, 2, 1, 0 }, medio = { 5, 3, 2, 0 }, dificil = { 8, 5, 3, 1 }, final = { 0, 0, 0, 0 } }
C.PONTOS_RANKING_ABATE = 1
C.CONSERTO_POR_PCT = 6
C.MELHORIA_MOTOR = 0.04        -- potencia +4% por nivel
C.MELHORIA_PNEU = 0.035        -- escorregamento -0,035 por nivel
C.MELHORIA_BLINDAGEM = 80      -- blindagem +80 por nivel (360 -> 600, como na loja do Death Rally)
C.ABATE_ATE = 4         -- segundos: quem acertou o carro por ultimo nesse tempo leva o abate
C.ITENS_MAX = 4         -- itens na pista ao mesmo tempo
C.ITEM_INTERVALO = 3    -- segundos entre um item novo e outro
C.CONSERTO = 15         -- % de vida da chave (30 na v0.21: o Felipe achou que curava demais)
C.DINHEIRO_ITEM = 100
C.FUMACA_VIDA = 40      -- abaixo disso o carro solta fumaca
C.FAISCA_VEL = 60       -- raspando no muro mais rapido que isso (px/s), solta faiscas
C.EFEITO_DURA = { explosao = 0.4, explosao_grande = 0.9, faisca = 0.15, fumaca = 0.8 }
C.IA_MINA_ESPERA = 5    -- segundos entre uma mina e outra do computador
C.IA_TIRO_INICIO = 4    -- o computador nao atira nos primeiros segundos (todos colados na largada)
C.IA_RAJADA = { 0.5, 1.0 }   -- o computador atira em rajadas de 0,5 a 1 s...
C.IA_PAUSA = { 0.6, 1.6 }    -- ...com pausas de 0,6 a 1,6 s
-- e mira com um erro sorteado a cada rajada, ate o "mira" do nivel (C.NIVEIS)

-- Carros do computador (ia.lua)
C.IA_OLHAR = 3          -- pontos da linha central a frente (16 px cada), + 1 a cada IA_OLHAR_VEL px/s
C.IA_OLHAR_VEL = 60 * C.ESCALA
C.IA_ZONA_MORTA = 0.06  -- radianos: nao mexe o volante se o erro for menor
C.IA_RUMO_VEL = 40      -- acima disso (px/s) mira pela direcao em que o carro anda, nao pelo bico
-- linha de corrida: por dentro das curvas, IA_LINHA x o quanto a pista vira em +-IA_LINHA_JANELA
-- pontos (fracao da meia largura, ate IA_LINHA_MAX), a IA_MARGEM px do muro, no minimo
C.IA_LINHA = 0.8
C.IA_LINHA_MAX = 0.6
C.IA_LINHA_JANELA = 4
C.IA_MARGEM = 14
C.IA_AFASTA = 0.3       -- raspou no muro: vai para o outro lado (fracao da meia largura), sumindo em ~1 s
C.IA_ELASTICO_LONGE = 40   -- elastico: a mais de 40 pontos (640 px) do jogador e "longe"
-- Nivel dos pilotos do computador (escolhido no comeco do modo historia, para o campeonato
-- inteiro, e na corrida rapida; ideia do Felipe).
--   fator: multiplica TODA a ficha do carro deles (velocidade, arranque, aderencia, blindagem e
--     arma); no DIFICIL o fusca deles chega a ~137 km/h e o seu a ~130
--   mira: erro maximo do tiro, sorteado a cada rajada (a 100 px, 7 graus = 12 px: erra metade
--     dos tiros de longe); pausa: x as pausas entre as rajadas (no DIFICIL quase nao erra, mas
--     atira com pausas maiores: com 0,7 o jogador explodia em metade das corridas)
--   curva: quanto tiram o pe nas curvas (0 = nada); faixa: quanto se afastam da linha de corrida
--   turbo_reta: pontos de reta (16 px) que esperam ter pela frente para usar o turbo
--   elastico: potencia x isto quando o computador esta atras do jogador (longe: a mais de
--     IA_ELASTICO_LONGE pontos). So ajuda quem esta atras (pedido do Felipe): na frente nao perde
--     nada, senao um fusca alcanca um puma
--   minas: quantos dos 3 rivais do modo historia levam um pacote de minas
--   premio: x os premios do modo historia ("taxa de ganho proporcional", pedido do Felipe). Medido
--     com ferramentas/medir_campanha.py (o piloto automatico jogando o campeonato inteiro): no
--     FACIL ~22 rodadas; no MEDIO, quem pilota um pouco melhor que a IA termina em ~30; no DIFICIL,
--     so quem pilota bem melhor (31 rodadas; ou 2o lugar na 40a)
C.NIVEIS = {
  { id = "facil", nome = "F\xC1CIL", fator = 0.95, curva = 0.3, faixa = 0.3, turbo_reta = 16,
    elastico = { atras = 1.0, atras_longe = 1.03 }, minas = 0, mira = math.rad(12), pausa = 1.3, premio = 0.8 },
  { id = "medio", nome = "M\xC9DIO", fator = 1.0, curva = 0.1, faixa = 0.15, turbo_reta = 12,
    elastico = { atras = 1.02, atras_longe = 1.05 }, minas = 1, mira = math.rad(6), pausa = 1.0, premio = 1.0 },
  { id = "dificil", nome = "DIF\xCDCIL", fator = 1.05, curva = 0.0, faixa = 0.1, turbo_reta = 10,
    elastico = { atras = 1.03, atras_longe = 1.07 }, minas = 2, mira = math.rad(3), pausa = 1.3, premio = 1.4 },
}
C.NIVEL = 2             -- nivel da corrida rapida (o menu troca)
-- Carros com personalidade (ideia do Felipe): a ficha de cada modelo (carros.lua, notas 1 a 5)
-- vira os numeros da fisica. Nota 1 -> o primeiro valor, nota 5 -> o segundo.
C.FICHA_M = { 2.75, 3.25 }          -- velocidade: potencia M (velocidade final ~54*M px/s)
C.FICHA_ARRANQUE = { 0.8, 1.3 }     -- aceleracao: forca parado (perto da velocidade final vale 1:
                                    -- muda o quanto demora para chegar la, nao a final)
C.FICHA_ADERENCIA = { 0.42, 0.18 }  -- aderencia: escorregamento do pneu (Death Rally: 0.5 o pior, 0.1 o melhor)
C.IA_FATOR_M = { 0.97, 0.99, 1.01 } -- os 3 do computador: potencia do modelo x isto (variedade)
C.ADERENCIA = 0.3       -- escorregamento de quem nao tem ficha
-- tracao, acelerando com o volante virado (acima de TRACAO_VEL px/s):
--   traseira: a traseira sai (gira mais e escorrega mais: da para fazer drift no acelerador)
--   dianteira: sai de frente (gira menos, abre a curva); tirando o pe, fecha a curva
--   integral: no meio termo, escorrega menos acelerando
-- arranque: multiplica o arranque da ficha. A traseira escorrega mais, mas arranca melhor (o peso
-- vai para as rodas de tras): ganha na saida da curva (pedido do Felipe: o que atrapalha de um
-- lado tem de compensar do outro)
-- alivia: o computador tira o pe quando o volante esta mais longe que isso (radianos) da direcao
-- certa (de traseira, mais cedo, senao roda)
C.TRACAO_VEL = 60 * C.ESCALA
C.TRACAO = {
  traseira = { giro = 1.1, deslize = 1.1, deslize_max = 1.05, giro_solto = 1.0, alivia = 0.2, arranque = 1.15 },
  dianteira = { giro = 0.85, deslize = 0.8, deslize_max = 1.0, giro_solto = 1.08, alivia = 0.3, arranque = 1.0 },
  integral = { giro = 1.0, deslize = 0.8, deslize_max = 0.9, giro_solto = 1.0, alivia = 0.3, arranque = 1.1 },
}

-- Camera: olha para onde o carro VAI (a velocidade, nao o bico: toques curtos no direcional
-- nao balancam a tela), ate CAM_FRENTE px, e chega la com uma mola suave
C.CAM_ANTECIPA = 0.55   -- segundos de caminho a frente (a 160 px/s: 88 px)
C.CAM_FRENTE_X = 110
C.CAM_FRENTE_Y = 60
C.CAM_SUAVE = 0.6       -- segundos para a camera chegar ao ponto (maior = mais suave)

C.DIAGNOSTICO = true    -- FPS no log do console uma vez por segundo

return C
