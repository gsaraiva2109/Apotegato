"""Recorta do UI Medieval Mega (ToffeeCraft) as peças usadas pelo tema do jogo.

O pacote vem numa spritesheet única e a licença proíbe redistribuir, então a
sheet fica só no repositório privado ApotegatoAssets (baixada para
assets/art/third_party/ pelo tools/fetch_assets.sh, que roda este script no
final). Aqui ficam apenas as coordenadas dos recortes, nunca a arte.

Cada recorte sobrescreve a arte provisória de assets/art/ui/ que tem o mesmo
nome e o mesmo tamanho (gerada por tools/make_ui_art.py e make_heart_art.py).
Se a sheet não existir ou não tiver o formato esperado, nada é gravado e o
jogo segue com a arte provisória.

Uso: python tools/crop_ui_pack.py [caminho/da/sheet.png]
Requer: Pillow.
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow não instalado: seguindo com a arte provisória da interface.")
    sys.exit(0)

ROOT = Path(__file__).resolve().parent.parent
SHEET = (
    ROOT
    / "assets"
    / "art"
    / "third_party"
    / "toffeecraft-ui-medieval-mega"
    / "MedievalUiMega"
    / "medieval.png"
)
OUT = ROOT / "assets" / "art" / "ui"
SHEET_SIZE = (1024, 1024)

# nome do arquivo -> (x, y, largura, altura) na sheet
CROPS = {
    # painel: moldura de madeira com miolo escuro (9-slice com margem 9)
    "panel.png": (864, 704, 97, 96),
    # botões (9-slice com margem 8 nas laterais e 7 em cima e embaixo)
    "button_normal.png": (256, 336, 48, 16),
    "button_pressed.png": (256, 272, 48, 16),
    "button_disabled.png": (384, 304, 48, 16),
    # corações do HUD
    "heart_full.png": (903, 8, 18, 15),
    "heart_empty.png": (967, 8, 18, 15),
}


def main() -> int:
    sheet_path = Path(sys.argv[1]) if len(sys.argv) > 1 else SHEET
    if not sheet_path.is_file():
        print(f"Sheet do UI Mega não encontrada em {sheet_path}; mantendo a arte provisória.")
        return 0
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.size != SHEET_SIZE:
        print(f"Erro: a sheet tem {sheet.size}, esperado {SHEET_SIZE}.", file=sys.stderr)
        return 1

    crops = {}
    for name, (x, y, w, h) in CROPS.items():
        current = Image.open(OUT / name)
        if current.size != (w, h):
            print(f"Erro: {name} provisório tem {current.size}, o recorte {(w, h)}.", file=sys.stderr)
            return 1
        piece = sheet.crop((x, y, x + w, y + h))
        if piece.getchannel("A").getbbox() is None:
            print(f"Erro: o recorte {name} saiu vazio; confira as coordenadas.", file=sys.stderr)
            return 1
        crops[name] = piece

    for name, piece in crops.items():
        piece.save(OUT / name)
        print(f"  {name}")
    print("Interface do UI Mega aplicada sobre assets/art/ui/.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
