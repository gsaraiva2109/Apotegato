#!/usr/bin/env bash
# Prepara a máquina em um comando: ferramentas de lint, hooks do git e arte de
# terceiros. Pode rodar de novo quando quiser (por exemplo, depois de um pull
# que mudou o ApotegatoAssets).
#
# Uso: bash tools/setup.sh [--ssh]
#
# A arte baixa do repositório privado com as suas credenciais do GitHub
# (gh auth login ou chave SSH com --ssh), sem precisar de token. Sem acesso ao
# ApotegatoAssets, o jogo roda com a arte provisória.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PYTHON="$(command -v python3 || command -v python || true)"
if [[ -z $PYTHON ]]; then
  echo "Erro: Python 3.10 ou mais novo não encontrado." >&2
  exit 1
fi

echo "== Dependências de desenvolvimento =="
"$PYTHON" -m pip install -r requirements-dev.txt || echo "Aviso: falha ao instalar as dependências." >&2

echo "== Hooks do git =="
if command -v lefthook > /dev/null 2>&1; then
  lefthook install
else
  "$PYTHON" -m lefthook install || echo "Aviso: não consegui ativar o lefthook." >&2
fi

echo "== Arte de terceiros =="
if bash tools/fetch_assets.sh "$@"; then
  echo "Pronto. Abra o projeto no Godot."
else
  echo "Aviso: arte de terceiros não baixada. Peça acesso de leitura ao ApotegatoAssets para o Gabriel; até lá o jogo usa a arte provisória." >&2
fi
