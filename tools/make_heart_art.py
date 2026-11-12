"""Gera os corações provisórios do HUD (18 x 15): cheio, meio e vazio.

Uso: python tools/make_heart_art.py

Para trocar, basta sobrescrever os PNGs com as mesmas dimensões e nomes.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "ui"

OUTLINE = (0x2B, 0x10, 0x14, 255)
FULL = (0xD9, 0x3A, 0x4A, 255)
FULL_LIGHT = (0xFF, 0x8A, 0x92, 255)
EMPTY = (0x4A, 0x32, 0x36, 255)
EMPTY_EDGE = (0x7A, 0x5C, 0x60, 255)

# silhueta do coração, linha a linha (# = pixel do coração)
SHAPE = [
    "..####..####..",
    ".############.",
    "##############",
    "##############",
    "##############",
    ".############.",
    "..##########..",
    "...########...",
    "....######....",
    ".....####.....",
    "......##......",
]


def heart(fill, edge, light=None):
    img = Image.new("RGBA", (18, 15), (0, 0, 0, 0))
    px = img.load()
    ox, oy = 2, 2
    cells = {(x, y) for y, row in enumerate(SHAPE) for x, c in enumerate(row) if c == "#"}
    for x, y in cells:
        border = any((x + dx, y + dy) not in cells for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        px[x + ox, y + oy] = edge if border else fill
    if light:
        d = ImageDraw.Draw(img)
        d.point((ox + 2, oy + 2), fill=light)
        d.point((ox + 3, oy + 2), fill=light)
        d.point((ox + 2, oy + 3), fill=light)
    return img


def half_heart():
    """Meio coração: a metade esquerda cheia e a direita vazia, com o mesmo contorno."""
    img = Image.new("RGBA", (18, 15), (0, 0, 0, 0))
    full = heart(FULL, OUTLINE, FULL_LIGHT)
    empty = heart(EMPTY, EMPTY_EDGE)
    img.paste(empty.crop((9, 0, 18, 15)), (9, 0))
    img.paste(full.crop((0, 0, 9, 15)), (0, 0))
    return img


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    heart(FULL, OUTLINE, FULL_LIGHT).save(OUT / "heart_full.png")
    half_heart().save(OUT / "heart_half.png")
    heart(EMPTY, EMPTY_EDGE).save(OUT / "heart_empty.png")


if __name__ == "__main__":
    main()
