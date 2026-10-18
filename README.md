# Apotegato

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

| Ação | Tecla |
| --- | --- |
| Mover | Setas ou WASD |
| Atacar | Espaço |
| Interagir | E |
| Menus | Mouse |

Mochila, diário e pausa ainda não têm tecla definida (a sugestão é I, J e Esc).

## Números que já estão fechados

- 7 corações. Se zerar, o gato desmaia e acorda na cabana com a mochila intacta.
- 3 golpes derrotam uma criatura.
- Luz: começa em 0,6, ganha 0,12 por criatura derrotada, teto de 1,8, e volta a 0,6 a cada andar novo.
- Mochila com 6 espaços e itens empilháveis. O que sobra da entrega vai para o estoque da apotecária ou cura 1 coração por item.
- 26 ingredientes e 10 condições, todos num CSV único com id estável.
- Save em JSON local, com campo de versão, gravado ao voltar para a cabana.

XP, moedas, upgrades e mochila que cresce estão em discussão e **não** fazem parte do escopo atual.

## Rodando o projeto

1. Instale o [Godot](https://godotengine.org/download) na versão estável mais recente da série 4.x (a versão padrão, não a .NET).
2. Clone o repositório:
   ```bash
   git clone https://github.com/gsaraiva2109/Apotegato.git
   ```
3. No Godot, clique em **Importar**, selecione o `project.godot` da pasta e abra.

O alvo é PC com Windows, incluindo máquinas com vídeo integrado.

## Organização

Trabalhamos em sprints de uma semana, de 19/10 até a primeira semana de dezembro. As tarefas ficam nas issues do GitHub e qualquer pessoa do grupo pode pegar uma. Os textos do diário também entram por issue.

Para mudar alguma coisa, crie uma branch a partir da `main`, abra um pull request e peça para alguém do grupo revisar antes de juntar.

## Equipe

- Arthur Soares Rebouças de Moura
- Davi Dias Vale (roteiro e mecânicas)
- Gabriel Saraiva Siqueira
- João Victor Martins Cid

Professor: Me. Thiago Narak Carvalho de Oliveira

## Créditos e aviso

Arte e áudio de terceiros vêm de pacotes gratuitos (de preferência CC0 ou CC BY). Autor, origem e licença de cada um ficam registrados e aparecem na tela **Fontes** do jogo.

O jogo se passa num mundo de fantasia. O que ele diz sobre os ingredientes faz parte da história e não é orientação médica; a própria apotecária sempre manda o paciente procurar um médico.
