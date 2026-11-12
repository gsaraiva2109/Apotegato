#!/usr/bin/env bash
# Gera a arte provisória que o git não versiona (cabana, regiões, interface, o Mingau,
# a apotecária e o paciente),
# para o jogo abrir sem a arte de terceiros. O tools/fetch_assets.sh roda este script antes
# de aplicar a arte do pacote por cima.
#
# Uso:  bash tools/gerar_provisorios.sh
# Precisa de Python 3 com Pillow (pip install -r requirements-dev.txt). É rápido (< 1 s) e
# idempotente: pode rodar quantas vezes quiser. Sobrescreve a arte aplicada; rode o
# fetch_assets.sh depois para reaplicar a do pacote.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PYTHON="$(command -v python3 || command -v python || true)"
if [[ -z $PYTHON ]]; then
  echo "Erro: Python 3 com Pillow é necessário para gerar a arte provisória." >&2
  exit 1
fi

for script in make_cabin_art make_region_art make_ui_art make_heart_art make_character_art; do
  "$PYTHON" "tools/$script.py" > /dev/null
done
mkdir -p assets/art/characters
cp tools/provisorio/mingau_placeholder.png assets/art/characters/mingau_placeholder.png
echo "Arte provisória gerada em assets/art/."
