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

# Arte que substitui a provisória do jogo, com os mesmos nomes e tamanhos
# (overrides/art/ no repositório de assets vira assets/art/).
OVERRIDES="$DEST/overrides/art"
if [[ -d $OVERRIDES ]]; then
  cp -a "$OVERRIDES/." "$ROOT/assets/art/"
  # Esses arquivos são versionados com a arte provisória; marcamos como "não alterados"
  # para ninguém commitar a arte de terceiros por engano no repositório público.
  if git -C "$ROOT" rev-parse --git-dir > /dev/null 2>&1; then
    while IFS= read -r -d '' f; do
      git -C "$ROOT" update-index --skip-worktree "assets/art/${f#./}" 2> /dev/null || true
    done < <(cd "$OVERRIDES" && find . -type f -name '*.png' -print0)
  fi
  echo "Arte substituta aplicada sobre assets/art/ (cabana, regiões e Mingau)."
fi

# Músicas (audio/music/<id>.ogg no repositório de assets) vão para
# assets/audio/third_party/music/, também ignorada pelo git.
if [[ -d $DEST/audio ]]; then
  rm -rf "$ROOT/assets/audio/third_party"
  mkdir -p "$ROOT/assets/audio/third_party"
  cp -a "$DEST/audio/." "$ROOT/assets/audio/third_party/"
  echo "Áudio de terceiros instalado em assets/audio/third_party/"
fi

# Interface (UI Medieval Mega): o pacote vem numa sheet única, que o script de
# recorte divide nas peças do tema (assets/art/ui/). Sem Python/Pillow, o jogo
# segue com a arte provisória da interface.
UI_CROPS=(panel button_normal button_pressed button_disabled plank parchment bar_fill slider_grabber backpack_icon cursor heart_full heart_empty)
if [[ -f $DEST/toffeecraft-ui-medieval-mega/MedievalUiMega/medieval.png ]]; then
  PYTHON="$(command -v python3 || command -v python || true)"
  if [[ -n $PYTHON ]] && "$PYTHON" "$ROOT/tools/crop_ui_pack.py"; then
    # Arquivos versionados com a arte provisória: ninguém deve commitar o recorte.
    if git -C "$ROOT" rev-parse --git-dir > /dev/null 2>&1; then
      for name in "${UI_CROPS[@]}"; do
        git -C "$ROOT" update-index --skip-worktree "assets/art/ui/$name.png" 2> /dev/null || true
      done
    fi
  else
    echo "Aviso: não recortei a interface (precisa de Python 3 com Pillow); seguindo com a arte provisória." >&2
  fi
fi

echo "Arte de terceiros instalada em assets/art/third_party/"
echo "Abra o projeto no Godot (ou rode 'godot --headless --import') para importar."
