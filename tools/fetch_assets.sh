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
# A arte provisória (que o git não versiona) é gerada primeiro por
# tools/gerar_provisorios.sh; a arte do pacote é aplicada por cima. Nada disso fica no
# índice do git, então trocar de branch nunca conflita com ela.
#
# O download só acontece quando o ApotegatoAssets mudou desde a última vez (compara o
# commit remoto com o guardado em assets/art/third_party/.commit). Sem rede ou sem acesso,
# o script reaproveita a cópia que já está na máquina.
#
# Opções:
#   --ssh     clona por SSH em vez de HTTPS
#   --forcar  baixa de novo mesmo sem mudança
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

forcar=0
for arg in "$@"; do [[ $arg == "--forcar" ]] && forcar=1; done

# 1. Arte provisória (só precisa de Python + Pillow; sem isso o jogo não abre sem o pacote).
if ! bash "$ROOT/tools/gerar_provisorios.sh"; then
  echo "Aviso: não gerei a arte provisória (precisa de Python 3 com Pillow)." >&2
fi

# 2. Baixa o pacote só se mudou.
remoto="$(git "${git_args[@]}" ls-remote "$url" "refs/heads/$REF" "refs/tags/$REF" 2> /dev/null | awk 'NR==1 {print $1}' || true)"
local_commit="$(cat "$DEST/.commit" 2> /dev/null || true)"
if [[ $forcar -eq 0 && -n $remoto && $remoto == "$local_commit" && -d $DEST/overrides ]]; then
  echo "ApotegatoAssets já está atualizado (${remoto:0:7}); reaplicando a arte."
elif [[ -z $remoto && -d $DEST/overrides ]]; then
  echo "Aviso: não consegui consultar o ApotegatoAssets; reaplicando a cópia que já está aqui." >&2
else
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  echo "Baixando $REPO@$REF ..."
  if ! git "${git_args[@]}" clone --quiet --depth 1 --branch "$REF" "$url" "$tmp/repo"; then
    echo "Erro: não foi possível clonar $REPO." >&2
    echo "Confira se você tem acesso ao repositório privado (ou se ASSETS_TOKEN é válido)." >&2
    exit 1
  fi
  commit_baixado="$(git -C "$tmp/repo" rev-parse HEAD)"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  rm -rf "$tmp/repo/.git"
  cp -a "$tmp/repo/." "$DEST/"
  printf '%s\n' "$commit_baixado" > "$DEST/.commit"
fi

# 3. Arte que substitui a provisória do jogo, com os mesmos nomes e tamanhos
#    (overrides/art/ no repositório de assets vira assets/art/).
OVERRIDES="$DEST/overrides/art"
if [[ -d $OVERRIDES ]]; then
  cp -a "$OVERRIDES/." "$ROOT/assets/art/"
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
if [[ -f $DEST/toffeecraft-ui-medieval-mega/MedievalUiMega/medieval.png ]]; then
  PYTHON="$(command -v python3 || command -v python || true)"
  if [[ -n $PYTHON ]] && "$PYTHON" "$ROOT/tools/crop_ui_pack.py"; then
    :
  else
    echo "Aviso: não recortei a interface (precisa de Python 3 com Pillow); seguindo com a arte provisória." >&2
  fi
fi

echo "Arte de terceiros instalada em assets/art/third_party/"
echo "Abra o projeto no Godot (ou rode 'godot --headless --import') para importar."
