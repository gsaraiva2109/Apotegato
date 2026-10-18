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

   Nomes em minúsculas, com hífen, sem acento.
3. Abra o PR para a `main` e preencha o template. Peça revisão de pelo menos uma pessoa do grupo.
4. O PR só entra com o check **CI OK** verde. Junte com **Squash and merge**, para cada PR virar um commit só na `main`.

## Testes

Os testes ficam em `tests/` e usam o [GUT](https://github.com/bitwes/Gut) (já incluído em `addons/gut`). Arquivos começam com `test_` e estendem `GutTest`.

- **No editor:** painel GUT na parte de baixo, botão Run All.
- **Na linha de comando:**
  ```bash
  godot --headless --import
  godot --headless -s res://tools/checar_projeto.gd
  godot --headless -s addons/gut/gut_cmdln.gd
  ```
  O `checar_projeto.gd` abre todos os scripts e cenas e falha se algum tiver erro. O GUT só avisa quando um script de teste não compila e segue em frente, então essa verificação existe para pegar esse caso.

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

O arquivo tem um `.import` com `importer="keep"`. Sem isso o Godot importaria o CSV como tabela de tradução. Não apague esse arquivo.

`tests/test_ingredientes_csv.gd` confere o CSV contra o GDD: total de ingredientes, ids únicos, regiões e paridades válidas e quantidade de ingredientes por condição. Se o time mudar alguma dessas regras, atualize as constantes do teste junto.

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

Prefira licença CC0 ou CC BY. Para cada asset, registre nome, autor, origem, finalidade e licença. Os créditos aparecem na tela Fontes.
