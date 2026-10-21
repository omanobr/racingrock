-- Numeros do jogo. A fisica imita o Death Rally (1996): os valores de la (70 quadros por
-- segundo, velocidade em pixels por quadro) estao convertidos para pixels por segundo.
local C = {}

C.VERSAO = "0.20"

C.VOLTAS = 3
C.CARROS = 4
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
C.MINAS = 3             -- minas por corrida
C.MINA_FREIA = -0.5     -- velocidade x isto (o Death Rally usa -0.7)
C.MINA_GIRO = math.rad(25)   -- gira ate isto para um lado
C.MINA_ARMA = 1.0       -- segundos ate a mina valer para quem soltou

-- Pontos e dinheiro (ideia do Felipe; so o jogador ganha o bonus de sobrevivente)
C.PONTOS_POSICAO = { 5, 3, 1, 0 }
C.PONTOS_ABATE = 2
C.PREMIO_POSICAO = { 750, 375, 187, 0 }   -- o Death Rally paga isso nas corridas faceis
C.PREMIO_ABATE = 300
C.PREMIO_SOBREVIVENTE = 1000
C.ABATE_ATE = 4         -- segundos: quem acertou o carro por ultimo nesse tempo leva o abate
C.ITENS_MAX = 4         -- itens na pista ao mesmo tempo
C.ITEM_INTERVALO = 3    -- segundos entre um item novo e outro
C.CONSERTO = 30         -- % de vida da chave
C.DINHEIRO_ITEM = 50
C.FUMACA_VIDA = 40      -- abaixo disso o carro solta fumaca
C.EFEITO_DURA = { explosao = 0.4, explosao_grande = 0.9, faisca = 0.15, fumaca = 0.8 }
C.IA_MINA_ESPERA = 5    -- segundos entre uma mina e outra do computador
C.IA_TIRO_INICIO = 4    -- o computador nao atira nos primeiros segundos (todos colados na largada)
C.IA_RAJADA = { 0.5, 1.0 }   -- o computador atira em rajadas de 0,5 a 1 s...
C.IA_PAUSA = { 0.6, 1.6 }    -- ...com pausas de 0,6 a 1,6 s
C.IA_ERRO_MIRA = math.rad(7) -- e mira com um erro sorteado a cada rajada (a 100 px: ate 12 px)

-- Carros do computador
C.IA_OLHAR = 3          -- pontos da linha central a frente (16 px cada), + 1 a cada IA_OLHAR_VEL px/s
C.IA_OLHAR_VEL = 60 * C.ESCALA
C.IA_CURVA = 0.40       -- na curva fechada a velocidade alvo cai 40%
C.IA_ZONA_MORTA = 0.06  -- radianos: nao mexe o volante se o erro for menor
C.IA_ELASTICO = {       -- potencia (M) x este fator conforme a distancia para o jogador (pontos de 16 px)
  atras_longe = 1.12, atras = 1.06, frente = 0.95, frente_longe = 0.88, longe = 40,
}
-- potencia (M) dos carros do computador e do jogador nesta versao de teste
C.M_JOGADOR = 3.0
C.M_IA = { 2.85, 2.95, 3.05 }
C.ADERENCIA = 0.3       -- "escorregamento" do pneu no Death Rally: 0.5 (pior) a 0.1 (melhor)

-- Camera: olha para onde o carro VAI (a velocidade, nao o bico: toques curtos no direcional
-- nao balancam a tela), ate CAM_FRENTE px, e chega la com uma mola suave
C.CAM_ANTECIPA = 0.55   -- segundos de caminho a frente (a 160 px/s: 88 px)
C.CAM_FRENTE_X = 110
C.CAM_FRENTE_Y = 60
C.CAM_SUAVE = 0.6       -- segundos para a camera chegar ao ponto (maior = mais suave)

C.DIAGNOSTICO = true    -- FPS no log do console uma vez por segundo

return C
