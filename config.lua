-- Numeros do jogo. A fisica imita o Death Rally (1996): os valores de la (70 quadros por
-- segundo, velocidade em pixels por quadro) estao convertidos para pixels por segundo.
local C = {}

C.VERSAO = "0.1"

-- Fundo da pista: "tiles" (ui.tile, um por tile, agrupados por folha), "mapa" (ui.map em
-- blocos fixos de 16x16 tiles) ou "visao" (ui.map numa tabela do tamanho da tela, refeita
-- quando a camera passa de um tile). O teste de desempenho compara os tres no aparelho.
C.FUNDO = "tiles"

C.VOLTAS = 3
C.CARROS = 4

-- Carro. M e a "potencia" do Death Rally (2.55 no carro mais fraco, 4.3 no mais forte).
-- Com o acelerador apertado o carro chega a ~54*M px/s; com turbo, ~88*M px/s.
C.ACEL = 130.7          -- x M px/s2
C.ACEL_TURBO = 212      -- x M px/s2
C.FREIO = 54.4          -- x M px/s2
C.ARRASTO = 1.414       -- por segundo, sempre (o 0.98 por quadro do Death Rally)
C.ARRASTO_ACEL = 0.987  -- por segundo, a mais com o acelerador (o 0.986)
C.RE_MAX = 0.35         -- velocidade maxima de re (fracao da maxima)
C.GIRO_BASE = 1.70      -- giro = 3.75 graus / (GIRO_BASE - 0.05 x motor) por quadro a 70 FPS
C.GIRO_VEL = 40         -- abaixo desta velocidade (px/s) o carro vira menos
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
C.MURO_PERDA = 0.875    -- raspou no muro: velocidade x 7/8 e vira 20 graus
C.MURO_GIRO = math.rad(20)
C.MURO_VOLTA = -0.3     -- bateu de frente: volta com 30% da velocidade
C.RAIO_CARRO = 8        -- colisao entre carros (circulo)
C.EMPURRAO = 0.7        -- quanto da diferenca de velocidade passa de um carro para o outro
C.EMPURRAO_FIM = 9.78   -- o empurrao some (1.15 por quadro)

-- Carros do computador
C.IA_OLHAR = 3          -- pontos da linha central a frente (16 px cada), + 1 a cada IA_OLHAR_VEL px/s
C.IA_OLHAR_VEL = 60
C.IA_CURVA = 0.40       -- na curva fechada a velocidade alvo cai 40%
C.IA_ZONA_MORTA = 0.06  -- radianos: nao mexe o volante se o erro for menor
C.IA_ELASTICO = {       -- velocidade alvo x este fator conforme a distancia para o jogador (pontos)
  atras_longe = 1.12, atras = 1.06, frente = 0.95, frente_longe = 0.88, longe = 40,
}
-- potencia (M) dos carros do computador e do jogador nesta versao de teste
C.M_JOGADOR = 3.0
C.M_IA = { 2.85, 2.95, 3.05 }
C.ADERENCIA = 0.3       -- "escorregamento" do pneu no Death Rally: 0.5 (pior) a 0.1 (melhor)

-- Camera: olha para a frente do carro, mais longe quanto mais rapido (como no Death Rally)
C.CAM_FRENTE_X = 110
C.CAM_FRENTE_Y = 60
C.CAM_SEGUE = 6         -- por segundo (quanto maior, mais grudada)

C.DIAGNOSTICO = true    -- FPS no log do console uma vez por segundo

return C
