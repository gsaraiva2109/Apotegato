#!/usr/bin/env bash
# Troca de branch sem o erro "Your local changes ... would be overwritten".
#
# A arte de terceiros que o tools/fetch_assets.sh coloca por cima da arte provisória fica
# marcada com `git update-index --skip-worktree`, e o git recusa trocar de branch quando a
# outra branch mexe nesses arquivos. Este script desfaz as marcas, restaura a arte provisória,
# troca de branch, baixa a arte de novo e remarca.
#
# Uso:  bash tools/trocar_branch.sh <branch>        (aceita também origin/<branch>)
# Trabalho seu em arquivos que NÃO são arte continua intacto; se houver mudança sua em
# arquivo de arte marcado, ela é descartada (a arte de terceiros é refeita pelo fetch).
set -euo pipefail

ALVO="${1:?uso: bash tools/trocar_branch.sh <branch>}"
ALVO="${ALVO#origin/}"
RAIZ="$(git rev-parse --show-toplevel)"
cd "$RAIZ"

echo "Buscando $ALVO ..."
git fetch --quiet origin "$ALVO"

# 1. Restaura a arte provisória nos arquivos marcados com skip-worktree.
mapfile -t marcados < <(git ls-files -v | sed -n 's/^S //p')
if ((${#marcados[@]} > 0)); then
  git update-index --no-skip-worktree -- "${marcados[@]}"
  git checkout -- "${marcados[@]}"
fi

# 2. Arquivos novos de arte que a branch de destino também versiona (ex.: water.png) e que
#    o fetch_assets copiou antes de existirem no git: o git recusaria sobrescrevê-los.
while IFS= read -r arquivo; do
  if git cat-file -e "origin/$ALVO:$arquivo" 2> /dev/null; then rm -f -- "$arquivo"; fi
done < <(git ls-files --others --exclude-standard -- assets/art assets/audio)

# 3. Troca de branch (cria a local acompanhando a remota se ainda não existir).
if git show-ref --verify --quiet "refs/heads/$ALVO"; then
  git checkout "$ALVO"
  git merge --ff-only "origin/$ALVO" || echo "Aviso: a branch local divergiu de origin/$ALVO; nada foi mesclado."
else
  git checkout -b "$ALVO" "origin/$ALVO"
fi

# 4. Traz a arte de terceiros de novo (e remarca os arquivos).
bash tools/fetch_assets.sh || echo "Aviso: não consegui baixar a arte; o jogo roda com a provisória."
echo "Pronto: você está em $ALVO."
