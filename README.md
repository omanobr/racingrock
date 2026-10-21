## Racing Rock

Corrida de combate vista de cima, no estilo do **Death Rally** (1996), para o console **Lupi**.

> Versão 0.1: protótipo. Pista de treino e carros provisórios (a arte de verdade vem depois), física no jeito do Death Rally (derrapagem, terra que segura o carro, muros), 3 pilotos do computador, voltas e classificação. O menu também tem um teste de botões e um teste de desempenho para rodar no aparelho.

## Como jogar

| Controle | Na corrida | Nos menus |
|---|---|---|
| Direcional | Virar (cima acelera, baixo freia) | Escolher |
| B | Acelerar | Confirmar |
| A | Frear / ré | Voltar |
| X | Turbo (segure) | |
| START | Pausa | |

## Código

Comece por `game.lua`. A corrida fica em `corrida.lua` (regras), `carro.lua` (física), `ia.lua` (pilotos do computador) e `telas/corrida.lua` (desenho). A pista é desenhada por `fundo.lua` a partir de `pistas/*.lua`, que são gerados por uma ferramenta a partir da imagem da pista. Os números do jogo ficam em `config.lua`.

> Documentação do Lupi: <https://lupi.api.br/docs>. Baseado no [primeiro-jogo](https://github.com/lupi-org-br/primeiro-jogo).

## Créditos

Ideia e direção: Felipe.
