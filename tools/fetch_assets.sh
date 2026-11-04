#!/usr/bin/env bash
# Baixa a arte de terceiros do repositório privado gsaraiva2109/ApotegatoAssets
# para assets/art/third_party/ (pasta ignorada pelo git).
#
# Uso local:  bash tools/fetch_assets.sh
#   Usa as credenciais que você já tem no git (gh auth login, gerenciador de
#   credenciais ou chave SSH com --ssh).
# Uso na CI:  defina ASSETS_TOKEN (token somente leitura); o script o usa no
#   cabeçalho HTTP, sem gravar o token na URL nem no .git/config.
#
# Opções:
#   --ssh   clona por SSH em vez de HTTPS
#
# Variáveis opcionais:
#   ASSETS_REPO  repositório de origem (padrão: gsaraiva2109/ApotegatoAssets)
#   ASSETS_REF   branch ou tag a baixar (padrão: main)
set -euo pipefail

REPO="${ASSETS_REPO:-gsaraiva2109/ApotegatoAssets}"
REF="${ASSETS_REF:-main}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/assets/art/third_party"

url="https://github.com/${REPO}.git"
if [[ ${1:-} == "--ssh" ]]; then
  url="git@github.com:${REPO}.git"
fi

git_args=()
if [[ -n ${ASSETS_TOKEN:-} ]]; then
  auth="$(printf 'x-access-token:%s' "$ASSETS_TOKEN" | base64 -w0)"
  echo "::add-mask::$auth" 2>/dev/null || true
  git_args+=(-c "http.https://github.com/.extraheader=AUTHORIZATION: basic $auth")
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Baixando $REPO@$REF ..."
if ! git "${git_args[@]}" clone --quiet --depth 1 --branch "$REF" "$url" "$tmp/repo"; then
  echo "Erro: não foi possível clonar $REPO." >&2
  echo "Confira se você tem acesso ao repositório privado (ou se ASSETS_TOKEN é válido)." >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"
rm -rf "$tmp/repo/.git"
cp -a "$tmp/repo/." "$DEST/"

echo "Arte de terceiros instalada em assets/art/third_party/"
echo "Abra o projeto no Godot (ou rode 'godot --headless --import') para importar."
