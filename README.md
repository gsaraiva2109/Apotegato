# Apotegato

[![CI](https://github.com/gsaraiva2109/Apotegato/actions/workflows/ci.yml/badge.svg)](https://github.com/gsaraiva2109/Apotegato/actions/workflows/ci.yml)

Jogo 2D top-down em pixel art feito em Godot 4 para a disciplina da Unifor. Você joga com o Mingau, um gato que tirava um cochilo na Unifor, foi engolido por um portal e caiu na cabana de uma apotecária. Ela machucou as costelas e não consegue mais sair para buscar ingredientes, então quem vai é ele.

## Como funciona

1. Um paciente chega à cabana e conta o que está sentindo.
2. A apotecária diz quais ingredientes precisa (três, ou quatro no caso de xeroftalmia e resfriado).
3. O Mingau consulta o diário, escolhe uma das seis regiões (Amazônia, Caatinga, Campos e Rios, Cerrado, Litoral e Mata Atlântica) e desce para os labirintos.
4. Cada andar é gerado na hora e fica no escuro: só dá para ver um círculo de luz em volta do gato. Cada ingrediente aparece só nos andares pares ou só nos ímpares da sua região.
5. Com tudo na mochila, ele volta para a cabana e entrega.

Depois de 10 pacientes, o jogador decide se volta para a Unifor (fim da história) ou se continua ajudando, num modo sem fim.

Pelo caminho tem criaturas. O combate é sem armas e sem sangue, e é opcional: dá para pegar os itens e subir de andar sem derrotar ninguém. Cada criatura derrotada aumenta a luz naquele andar.

## Controles

| Ação | Tecla | Nome no Input Map |
| --- | --- | --- |
| Mover | Setas ou WASD | `move_up`, `move_down`, `move_left`, `move_right` |
| Atacar | Espaço | `attack` |
| Interagir | E | `interact` |
| Abrir a mochila | I | `backpack` |
| Abrir o diário | J | `journal` |
| Pausar (menu com Continuar, Opções e Voltar ao menu inicial) | Esc | `pause` |
| Tela cheia | F11 | `toggle_fullscreen` |
| Pixel perfeito ou preencher a tela | F10 | `toggle_scale_mode` |
| Menus | Mouse | |

As teclas são físicas: WASD fica no mesmo lugar em qualquer layout de teclado. O jogador pode trocar as teclas em Opções > Teclas. O código usa sempre o nome da ação (`Input.is_action_pressed("attack")`), nunca a tecla. Para mudar uma tecla, edite em Projeto > Configurações do Projeto > Mapa de Entrada e atualize `tests/test_input_map.gd`.

### Opções

A tela de opções abre pelo menu inicial e pelo menu de pausa. Tem volume da música e dos efeitos (0 a 100%, de 5 em 5), um interruptor de mudo para cada um, tela cheia, pixel perfeito ou preencher, a troca das teclas (andar, arranhar, interagir, mochila e diário, cada uma com tecla principal e alternativa; Esc, F10 e F11 são fixas e uma tecla só serve a uma ação), "Reduzir efeitos visuais", que troca as piscadas (a do Mingau ao levar dano e o aviso das criaturas) por versões estáticas, e "Texto grande", que aumenta os textos em 25%. Funciona com mouse e teclado, e tudo fica salvo em `user://settings.cfg`. "Restaurar padrões" volta tudo ao original.

### Tamanho da janela

O jogo é desenhado em 960 x 544 e ampliado para o monitor de quem joga, em qualquer resolução. Ao abrir, a janela ganha o maior tamanho que cabe na tela. No modo **pixel perfeito** (padrão) a ampliação é sempre inteira (2x, 3x...), sem deformar os pixels, e pode sobrar borda preta; no modo **preencher a tela** (F10) a imagem ocupa o máximo possível, com uma leve irregularidade nos pixels. Em telas menores que 960 x 544 a imagem é reduzida até caber. A tela cheia (F11) e o modo ficam salvos em `user://settings.cfg`.

## Números que já estão fechados

- 7 corações, contados em meios (14 meios). Se zerar, o gato desmaia e acorda na cabana com a mochila intacta e a vida cheia. Criaturas não atacam um gato desmaiado.
- Cada região tem uma criatura fraca (tira meio coração, 3 arranhões, 70 px/s, desde o andar 1) e uma forte (tira um coração, 4 arranhões, 80 px/s, a partir do andar 3). Os valores e o bicho de cada criatura (coluna `sprite`) ficam em `data/criaturas.csv`: tucano e onça-pintada na Amazônia, cascavel e onça-parda na Caatinga, seriema e capivara nos Campos e Rios, lobo-guará e tamanduá no Cerrado, caranguejo e jacaré no Litoral, macaco-prego e mico-leão na Mata Atlântica.
- A criatura só machuca no bote: com o gato a 24 px ela para e avisa por 0,4 s, dá o bote por 0,12 s e descansa 0,7 s. Arranhar durante o aviso cancela o bote. Encostar nela não machuca. Quem leva o golpe fica 1 s invencível e é empurrado.
- Cura: meio coração a cada 5 s sem levar dano nem arranhar. Cada sobra de ingrediente cura 1 coração (ou meio, se falta só isso); com a vida cheia nada é gasto.
- Luz: começa em 0,6, ganha 0,12 por criatura derrotada, teto de 1,8, e volta a 0,6 a cada andar novo.
- Mochila com 6 espaços e itens empilháveis. O que sobra da entrega vai para o estoque da apotecária ou cura vida (1 coração por item).
- 26 ingredientes e 10 condições, todos num CSV único com id estável.
- Save em JSON local, com campo de versão, gravado ao voltar para a cabana.

XP, moedas, upgrades e mochila que cresce estão em discussão e **não** fazem parte do escopo atual.

## Rodando o projeto

1. Instale o [Godot 4.7.2](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) (a versão padrão, não a .NET).
2. Clone o repositório:
   ```bash
   git clone https://github.com/gsaraiva2109/Apotegato.git
   ```
3. No Godot, clique em **Importar**, selecione o `project.godot` da pasta e abra.

O alvo é PC com Windows, incluindo máquinas com vídeo integrado, por isso o projeto usa o renderizador Compatibility.

A versão jogável de cada sprint fica em [Releases](https://github.com/gsaraiva2109/Apotegato/releases).

## Organização

Trabalhamos em sprints de uma semana, de 19/10 até a primeira semana de dezembro. As tarefas ficam nas issues do GitHub e qualquer pessoa do grupo pode pegar uma. Os textos do diário também entram por issue.

Para mudar alguma coisa, crie uma branch a partir da `main`, abra um pull request e peça para alguém do grupo revisar antes de juntar. O passo a passo (ferramentas, nomes de branch, testes e como gerar uma versão) está no [CONTRIBUTING.md](CONTRIBUTING.md).

## Equipe

- Arthur Soares Rebouças de Moura
- Davi Dias Vale (roteiro e mecânicas)
- Gabriel Saraiva Siqueira
- João Victor Martins Cid

Professor: Me. Thiago Narak Carvalho de Oliveira

## Créditos e aviso

Arte e áudio de terceiros vêm de pacotes gratuitos (de preferência CC0 ou CC BY). Autor, origem e licença de cada um ficam registrados e aparecem na tela **Créditos** do jogo.

O jogo se passa num mundo de fantasia. O que ele diz sobre os ingredientes faz parte da história e não é orientação médica; a própria apotecária sempre manda o paciente procurar um médico.
