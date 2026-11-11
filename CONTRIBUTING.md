# Como contribuir

Guia rápido para o grupo. Se algo aqui estiver desatualizado, corrija no mesmo PR em que perceber.

## Preparando a máquina

1. **Godot 4.7.2**, versão padrão (não a .NET). Todo mundo na mesma versão evita que o editor reescreva arquivos à toa. É a mesma versão que o CI usa (`GODOT_VERSION` em `.github/workflows/`).
2. **Python 3.10 ou mais novo**, para as ferramentas de lint.
3. Na pasta do projeto:
   ```bash
   pip install -r requirements-dev.txt
   lefthook install
   ```
   Isso instala o `gdformat`, o `gdlint` e o `lefthook`, e ativa o hook de pre-commit. A partir daí, cada commit formata os `.gd` alterados e roda o lint neles. Se o `lefthook` não for encontrado no Windows, a pasta `Scripts` do Python não está no PATH; dá para rodar `python -m lefthook install`.

O hook é opcional, mas o CI roda as mesmas verificações. Sem ele, o erro só aparece no PR.

## Fluxo de trabalho

1. Pegue uma issue (ou crie uma) e se atribua.
2. Crie uma branch a partir da `main` atualizada, com um prefixo:

   | Prefixo | Para quê | Exemplo |
   | --- | --- | --- |
   | `feat/` | Funcionalidade nova, incluindo arte e áudio que entram no jogo | `feat/movimento-gato` |
   | `fix/` | Correção de bug | `fix/porta-andar-par` |
   | `docs/` | Documentação | `docs/diario-cerrado` |
   | `test/` | Só testes | `test/bfs-labirinto` |
   | `refactor/` | Mudança de código sem mudar comportamento | `refactor/mochila` |
   | `ci/` | Workflows, hooks, exportação | `ci/cache-godot` |
   | `chore/` | Manutenção geral | `chore/atualizar-gut` |

   Nomes em minúsculas, com hífen, sem acento. O nome nunca contém "claude", inclusive nas branches de agentes de IA.
3. Abra o PR para a `main` e preencha o template. Peça revisão de pelo menos uma pessoa do grupo.
4. O PR só entra com o check **CI OK** verde. Junte com **Squash and merge**, para cada PR virar um commit só na `main`.

## Estrutura de pastas

```
addons/            código de terceiros (GUT). Não edite.
autoload/          singletons registrados em Projeto > Configurações > Autoload
assets/
  art/
    characters/    Mingau, apotecária e pacientes
    creatures/
    regions/       uma subpasta por região, criada quando chegar o primeiro asset
    cabin/
    ingredients/   ícones, com o nome igual ao id do CSV (buriti.png)
    ui/
  audio/
    music/
    sfx/
  fonts/
data/              CSVs do jogo (ingredientes, créditos)
scenes/
  cabin/           a cabana (cabin.tscn)
  player/          o Mingau
  region/          andares, labirinto, porta, ingrediente no chão
  creatures/
  ui/              menu inicial (main_menu.tscn, a cena inicial do jogo), HUD, diário, mochila, estoque, tela Créditos
scripts/           lógica sem cena (BFS, gerador do labirinto, mochila, luz, save)
tests/             testes do GUT
tools/             scripts de linha de comando
```

- **O script de uma cena fica ao lado dela**, com o mesmo nome: `scenes/player/player.tscn` e `scenes/player/player.gd`. Uma cena que só serve a outra fica na mesma pasta.
- **`scripts/` é para regra que não depende de tela.** Se dá para testar sem instanciar uma cena, vai para lá. É o que permite cobrir BFS, mochila, luz e save com testes rápidos.
- **Autoload só para estado global de verdade**: dados carregados do CSV, estado da campanha e save. O arquivo fica em `autoload/` e o nome registrado é em PascalCase (`autoload/game_state.gd` vira `GameState`).
- **Assets ficam separados por tipo**, não por cena, porque vêm de pacotes de terceiros e cada um precisa ter a licença registrada.
- Pastas vazias levam um `.gitkeep`. Pode apagar quando a pasta ganhar o primeiro arquivo.

## Convenções de código

O código (pastas, arquivos, nós, classes, funções, variáveis, sinais) é em **inglês**. Comentários, documentação, mensagens de commit, PRs e todo texto que aparece no jogo são em **português**.

A exceção são os dados: as colunas e os ids do `data/ingredientes.csv` continuam como estão (`buriti`, `campos_rios`, `impar`). O código usa esses valores sem traduzir, e os ids de ingrediente, condição e região são sempre os mesmos do CSV.

| O quê | Padrão | Exemplo |
| --- | --- | --- |
| Pastas e arquivos | snake_case, sem acento | `scenes/region/floor_door.tscn` |
| Nós na cena | PascalCase | `Player`, `InteractionArea` |
| `class_name` e autoloads | PascalCase | `class_name Backpack`, `GameState` |
| Funções e variáveis | snake_case | `add_item()`, `current_light` |
| Funções e variáveis privadas | prefixo `_` | `_update_light()` |
| Constantes e valores de enum | UPPER_SNAKE_CASE | `const MAX_SLOTS := 6` |
| Sinais | snake_case, no passado | `item_collected`, `floor_cleared` |
| Testes | `test_` + nome do script testado | `tests/test_backpack.gd` |

Além disso:

- Siga o [guia de estilo do GDScript](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html). O `gdformat` e o `gdlint` já cobram a maior parte.
- Use tipagem estática: `var hearts: int = 7`, `func heal(amount: int) -> void`.
- Declare `class_name` só quando outro script precisar referenciar a classe.
- Um nó fala com os filhos chamando funções e com o pai emitindo sinais. Evite `get_parent()` e caminhos longos como `get_node("../../X")`.
- Números de balanceamento (luz, corações, espaços da mochila, golpes) ficam em constantes nomeadas ou `@export`, nunca soltos no código.

## Testes

Os testes ficam em `tests/` e usam o [GUT](https://github.com/bitwes/Gut) (já incluído em `addons/gut`). Arquivos começam com `test_` e estendem `GutTest`.

- **No editor:** painel GUT na parte de baixo, botão Run All.
- **Na linha de comando:**
  ```bash
  godot --headless --import
  godot --headless -s res://tools/check_project.gd
  godot --headless -s addons/gut/gut_cmdln.gd
  ```
  O `check_project.gd` abre todos os scripts e cenas e falha se algum tiver erro. O GUT só avisa quando um script de teste não compila e segue em frente, então essa verificação existe para pegar esse caso.

O que vale testar: tudo que é regra e não depende de tela. BFS, geração do labirinto, sorteio de pacientes e ingredientes, mochila, estoque, fórmula da luz e save.

## O CSV de ingredientes

`data/ingredientes.csv` é a fonte única dos ingredientes. Colunas:

| Coluna | Conteúdo |
| --- | --- |
| `id` | Identificador estável, em snake_case sem acento. Não mude depois que estiver em uso (o save guarda esse id). |
| `nome` | Nome que aparece no jogo |
| `regiao` | `amazonia`, `caatinga`, `campos_rios`, `cerrado`, `litoral` ou `mata_atlantica` |
| `paridade` | `impar` ou `par` |
| `condicoes` | Ids das condições separados por `\|`. O sufixo `:ou` marca alternativas: entre os ingredientes marcados assim na mesma condição, basta um (é o caso de camu-camu e acerola na anemia ferropriva). |

O jogo lê o CSV pelo autoload `IngredientData` (`autoload/ingredient_data.gd`), carregado uma vez na inicialização. Nenhum outro script deve abrir o arquivo. As consultas principais:

| Função | Devolve |
| --- | --- |
| `get_ingredient(id)` | O `Ingredient` com esse id, ou `null` |
| `get_ingredients_in(regiao, paridade)` | Ingredientes que aparecem nos andares dessa região e paridade |
| `get_ingredients_for(condicao)` | Todos os ingredientes que servem para a condição, alternativas incluídas |
| `get_requirements(condicao)` | Os requisitos da condição; cada um é um grupo de ids em que basta um |
| `is_condition_satisfied(condicao, ids)` | Se os ingredientes entregues cobrem a condição, aplicando a regra `:ou` |

O arquivo tem um `.import` com `importer="keep"`. Sem isso o Godot importaria o CSV como tabela de tradução. Não apague esse arquivo.

`tests/test_ingredients_csv.gd` confere o CSV contra o GDD: total de ingredientes, ids únicos, regiões e paridades válidas e quantidade de ingredientes por condição. Se o time mudar alguma dessas regras, atualize as constantes do teste junto.

## Versões e entregas

Cada sprint termina com uma tag de versão. Quando a `main` estiver pronta para a entrega:

```bash
git checkout main && git pull
git tag v0.1.0        # sprint 1 = v0.1.0, sprint 2 = v0.2.0, ...
git push origin v0.1.0
```

O workflow **Release** roda os testes, exporta o `.exe` para Windows e cria a release no GitHub com o `.zip` anexado e as notas geradas a partir dos PRs. Esse é o link que vai para o professor.

Para gerar um build sem criar release (para testar no Windows, por exemplo), vá em **Actions → Release → Run workflow**. O `.zip` fica disponível como artifact da execução por 14 dias.

## Assets de terceiros

Prefira licença CC0 ou CC BY. Para cada asset, registre nome, autor, origem, finalidade e licença em `data/creditos.csv` (colunas `nome`, `autor`, `origem`, `finalidade`, `licenca` e `tipo`, que é `arte` ou `audio`). O `tests/test_credits_csv.gd` confere que nenhum campo ficou vazio. Os créditos aparecem na tela Créditos.

### Onde fica a arte de terceiros

Vários pacotes de arte proíbem redistribuir os arquivos originais, e este repositório é público. Por isso a arte de terceiros **não vai no git**: ela fica no repositório privado [`ApotegatoAssets`](https://github.com/gsaraiva2109/ApotegatoAssets) e é baixada para `assets/art/third_party/`, pasta que o `.gitignore` ignora. A arte provisória feita por nós continua em `assets/art/` e o projeto abre sem erro mesmo sem a de terceiros.

Os derivados de arte de terceiros (como a onça, recolor do tigre do MasuOne) também ficam só no repositório privado. Packs CC0 ou CC BY sem cláusula de redistribuição podem ir no repositório público, com crédito na tela Créditos.

### Atalho: `tools/setup.sh`

`bash tools/setup.sh` faz tudo de uma vez: instala o `requirements-dev.txt` (inclui o Pillow, usado no recorte da interface), ativa o `lefthook` e baixa a arte. Você não precisa de token: o `ASSETS_READ_TOKEN` é só da CI, e localmente vale o seu acesso de colaborador ao `ApotegatoAssets`. Sem acesso, o script avisa e o jogo roda com a arte provisória. Depois de um `git pull` que mude algo, o hook `post-merge` do `lefthook` roda o `fetch_assets.sh` de novo.

### Baixando a arte localmente

1. Peça acesso de leitura ao `ApotegatoAssets` para o Gabriel.
2. Garanta que o git tem credenciais do GitHub (`gh auth login` ou o gerenciador de credenciais; ou use `--ssh` com sua chave).
3. Na raiz do projeto:
   ```bash
   bash tools/fetch_assets.sh        # HTTPS
   bash tools/fetch_assets.sh --ssh  # SSH
   ```
4. Abra o projeto no Godot, que importa os arquivos novos. Repita o comando quando a arte mudar no repositório privado.

No Windows, rode pelo Git Bash.

### Como adicionar ou trocar arte de terceiros

1. Faça o commit dos PNGs e dos `.import` no `ApotegatoAssets`, mantendo as pastas que o jogo espera dentro de `assets/art/third_party/`.
2. Registre nome, autor, origem e licença em `data/` (créditos) no PR do jogo que passa a usar a arte.
3. Nunca force o `git add` de algo dentro de `assets/art/third_party/` no repositório público.

### Arte substituta da cabana

**Trocar de branch.** Como a arte de terceiros fica com `skip-worktree`, o `git checkout` costuma falhar com "Your local changes to the following files would be overwritten" quando a outra branch mexe em arquivos de arte. Use `bash tools/trocar_branch.sh <branch>` no lugar do `git checkout`: ele desfaz as marcas, restaura a arte provisória, troca de branch, baixa a arte de novo e remarca.

O `ApotegatoAssets` tem uma pasta `overrides/art/` com recortes do Epic RPG World - House Interiors, com os mesmos nomes e tamanhos da arte provisória de `assets/art/cabin/`. O `tools/fetch_assets.sh` copia esses arquivos por cima da provisória, e a cabana passa a usar a arte definitiva sem mudar nenhuma cena. Como a arte de terceiros não pode ir para o git público, o script marca esses arquivos com `git update-index --skip-worktree`: eles não aparecem em `git status` e não entram em commits. Se você precisar restaurar a arte provisória (por exemplo, antes de um `git pull` que mexe nesses arquivos), rode `git update-index --no-skip-worktree assets/art/cabin/*.png` e depois `git checkout -- assets/art/cabin`. A porta continua provisória.

O mesmo mecanismo vale para os tilesets das regiões (`overrides/art/regions/<id>/tileset.png`, 128 x 32, montados com Forest Tilesets, RPG Beach Tileset e Pixel Trees 32x32) e para o sprite do Mingau (`overrides/art/characters/mingau_placeholder.png`, o gato do pacote da MasuOne). O tile de saída de cada região continua o provisório, na cor da Tabela 3. Quem rodar o jogo sem acesso ao repositório privado vê a arte provisória.

### Interface (UI Medieval Mega)

O pacote da ToffeeCraft é uma spritesheet única (`toffeecraft-ui-medieval-mega/MedievalUiMega/medieval.png` no `ApotegatoAssets`) e a licença proíbe redistribuir. O `tools/fetch_assets.sh` roda o `tools/crop_ui_pack.py` no fim, que recorta as peças do tema (painel, botões, tábua de madeira das placas, barra, mochila, cursor do mouse e corações do HUD) por coordenadas e as grava em `assets/art/ui/`, por cima da arte provisória de mesmo nome e tamanho (gerada por `tools/make_ui_art.py` e `tools/make_heart_art.py`). Os arquivos ficam com `skip-worktree`, como os da cabana, então o recorte nunca entra em commit. Para trocar uma peça, edite o dicionário `CROPS` do script. O tema `scenes/ui/game_theme.tres` usa 9-slice com margens que valem para a arte provisória e para a definitiva.

### Músicas

A trilha tem oito faixas em loop: `menu`, `cabana` e uma por região (`amazonia`, `caatinga`, `campos_rios`, `cerrado`, `litoral`, `mata_atlantica`). O autoload `Music` (`autoload/music.gd`) troca de faixa com fade, sem reiniciar se a faixa pedida já está tocando. As cenas pedem a música em `_ready` (`Music.play(MusicCatalog.CABIN)`, `Music.play_region(...)`).

Os arquivos ficam no `ApotegatoAssets`, em `audio/music/<id>.ogg` (por exemplo `audio/music/cerrado.ogg`), e o `tools/fetch_assets.sh` os copia para `assets/audio/third_party/music/`, pasta ignorada pelo git. Sem o arquivo, a faixa fica em silêncio e o jogo roda normalmente. Ao incluir uma faixa, registre nome, autor, origem e licença em `data/creditos.csv` (tipo `audio`) no mesmo PR.

### Na CI

Os workflows **CI** e **Release** rodam `tools/fetch_assets.sh` antes de importar o projeto, usando o secret `ASSETS_READ_TOKEN`. Na CI de PR o passo é pulado se o secret não existir (PRs de forks); na Release ele é obrigatório.

**Para quem administra o repositório: criar o token**

1. GitHub → Settings → Developer settings → Personal access tokens → **Fine-grained tokens** → Generate new token.
2. Resource owner: `gsaraiva2109`. Repository access: **Only select repositories** → `ApotegatoAssets`.
3. Permissions → Repository permissions → **Contents: Read-only** (o Metadata read-only vem junto). Nada mais.
4. Defina uma validade e anote a data para renovar.
5. No repositório público: Settings → Secrets and variables → Actions → **New repository secret**, nome `ASSETS_READ_TOKEN`, valor o token gerado.
