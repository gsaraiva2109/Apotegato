"""Gera o sprite provisório de um ingrediente caído no chão (32 x 32).

Uso: python tools/make_pickup_art.py

Todos os ingredientes usam este mesmo sprite até os ícones definitivos (um por
ingrediente, com o id do CSV como nome do arquivo, ex.: buriti.png). Para
trocar, basta sobrescrever o PNG com as mesmas dimensões.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = (
    Path(__file__).resolve().parent.parent
    / "assets"
    / "art"
    / "ingredients"
    / "pickup_placeholder.png"
)

OUTLINE = (0x2B, 0x1A, 0x10, 255)
LEAF = (0x6F, 0xC2, 0x5A, 255)
LEAF_LIGHT = (0xA8, 0xE0, 0x7C, 255)
LEAF_DARK = (0x3C, 0x82, 0x3A, 255)
STRING = (0xD9, 0xB5, 0x6E, 255)
SPARK = (0xFF, 0xF3, 0xB0, 255)


def main():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # sombra no chão
    d.ellipse([7, 23, 25, 28], fill=(0, 0, 0, 70))
    # trouxinha de ervas
    d.polygon([(16, 5), (24, 12), (22, 22), (10, 22), (8, 12)], fill=LEAF, outline=OUTLINE)
    d.polygon([(16, 7), (21, 12), (16, 19), (11, 12)], fill=LEAF_LIGHT)
    d.line([(16, 9), (16, 21)], fill=LEAF_DARK)
    d.rectangle([13, 20, 19, 23], fill=STRING, outline=OUTLINE)
    # brilho, para dar para achar no escuro
    for x, y in ((6, 6), (26, 8), (24, 4)):
        d.point((x, y), fill=SPARK)
        d.point((x + 1, y), fill=SPARK)
        d.point((x, y + 1), fill=SPARK)
        d.point((x - 1, y), fill=SPARK)
        d.point((x, y - 1), fill=SPARK)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)


if __name__ == "__main__":
    main()
