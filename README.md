## Racing Rock

Corrida de combate vista de cima, no estilo do **Death Rally** (1996), para o console **Lupi**.

> Versão 0.34: armas travadas nos primeiros 4 segundos para todos, e menus mais leves para o console. Versão 0.33: telas com arte para o mercado negro, o agiota e a cobrança, e a neve sem as "zebras". Versão 0.32: dano x1,9 (os carros aguentam mais) e prêmios 15% maiores. Versão 0.31: as músicas numa trilha só (trocar de música prendia memória do console). Versão 0.30: duas pistas novas, a fazenda e a pedreira (cada uma em 4 variações). Versão 0.29: abertura da Lian Games, músicas, mercado negro (minas, espinhos, foguete, sabotagem), agiota, recompensas, ranking da rodada animado, carros menos "tanques", economia do modo história refeita, marcas de pneu e demonstração no título. Versão 0.28: arte da interface (título com "aperte start", garagem, concessionária, mural das corridas, retratos dos 22 pilotos, ícones da oficina, final) e pistas inversas e espelhadas (cada pista vale por 4). Versão 0.27: corrida mais leve (fundo em tiras), computador muito melhor (linha de corrida, turbo, mira por nível), nível dos rivais no modo história, minas compradas antes da corrida e rivais que trocam de carro. Versão 0.26: painel da corrida e menus novos (velocímetro, mapinha, letras grandes com acento, carros em 3/4). Versão 0.25: **modo história** (campeonato com ranking de 20 pilotos, oficina, concessionária, desafio final e password de 8 letras para continuar depois), corrida rápida, 6 pistas, 9 carros com personalidade (velocidade, aceleração, aderência e tração), física no jeito do Death Rally e combate: metralhadora, minas, vida, carros destruídos e itens na pista.

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

## Modo história

Você começa no último lugar de um ranking de 20 pilotos, com um fusca velho e $500. A cada rodada escolhe uma corrida (fácil, média ou difícil), ganha dinheiro e pontos, paga o conserto, compra melhorias (motor, pneus, blindagem) e carros melhores. No 1º lugar do ranking abre o desafio final contra O ADVERSÁRIO.

O console não guarda o jogo: a garagem mostra um **password de 8 letras** com todo o progresso. Para continuar outro dia: MODO HISTÓRIA → PASSWORD.

## Código

Comece por `game.lua`. A corrida fica em `corrida.lua` (regras), `carro.lua` (física), `ia.lua` (pilotos do computador) e `telas/corrida.lua` (desenho). A pista é desenhada por `fundo.lua` a partir de `pistas/*.lua`, que são gerados por uma ferramenta a partir da imagem da pista. Os números do jogo ficam em `config.lua`.

> Documentação do Lupi: <https://lupi.api.br/docs>. Baseado no [primeiro-jogo](https://github.com/lupi-org-br/primeiro-jogo).

## Créditos

Ideia e direção: Felipe.
