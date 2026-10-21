## Racing Rock

Corrida de combate vista de cima, no estilo do **Death Rally** (1996), para o console **Lupi**.

> Versão 0.19: 9 carros (fusca, uno, ka, saveiro, corsa, focus, monza, opala, puma), pista de treino, física no jeito do Death Rally (derrapagem, terra que segura o carro, muro em que o carro desliza), 3 pilotos do computador e combate: metralhadora, minas, vida, carros destruídos e itens na pista. Dinheiro pela colocação, por abate e por ser o último sobrevivente.

## Como jogar

| Controle | Na corrida | Nos menus |
|---|---|---|
| Direcional | Virar, inclusive parado (cima acelera, baixo freia) | Escolher |
| B | Acelerar | Confirmar |
| X | Frear e ré | |
| Y | Turbo (segure) | |
| A | Solta mina | Voltar |
| R | Metralhadora (segure) | |
| START | Pausa | |

## Código

Comece por `game.lua`. A corrida fica em `corrida.lua` (regras), `carro.lua` (física), `ia.lua` (pilotos do computador) e `telas/corrida.lua` (desenho). A pista é desenhada por `fundo.lua` a partir de `pistas/*.lua`, que são gerados por uma ferramenta a partir da imagem da pista. Os números do jogo ficam em `config.lua`.

> Documentação do Lupi: <https://lupi.api.br/docs>. Baseado no [primeiro-jogo](https://github.com/lupi-org-br/primeiro-jogo).

## Créditos

Ideia e direção: Felipe.
