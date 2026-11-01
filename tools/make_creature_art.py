"""Gera o sprite provisório das criaturas (32 x 32).

Uso: python tools/make_creature_art.py

Uma criatura só para todas as regiões, sem sangue nem armas: um bicho de sombra
com olhos claros. Para trocar, basta sobrescrever o PNG com as mesmas
dimensões; a cena não precisa mudar.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = (
    Path(__file__).resolve().parent.parent
    / "assets"
    / "art"
    / "creatures"
    / "creature_placeholder.png"
)

OUTLINE = (0x14, 0x0C, 0x1C, 255)
BODY = (0x5B, 0x3F, 0x7A, 255)
BODY_LIGHT = (0x7C, 0x5C, 0xA0, 255)
BODY_DARK = (0x42, 0x2C, 0x5C, 255)
EYE = (0xFF, 0xF0, 0x9A, 255)
PUPIL = (0x20, 0x10, 0x28, 255)


def main():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 24, 26, 29], fill=(0, 0, 0, 70))
    # corpo redondo com duas pontinhas (orelhas) e pés
    d.ellipse([5, 7, 26, 27], fill=BODY, outline=OUTLINE)
    d.polygon([(7, 11), (8, 3), (13, 8)], fill=BODY, outline=OUTLINE)
    d.polygon([(24, 11), (23, 3), (18, 8)], fill=BODY, outline=OUTLINE)
    d.ellipse([9, 9, 17, 15], fill=BODY_LIGHT)
    d.rectangle([8, 24, 12, 27], fill=BODY_DARK, outline=OUTLINE)
    d.rectangle([19, 24, 23, 27], fill=BODY_DARK, outline=OUTLINE)
    # olhos
    for x in (10, 18):
        d.rectangle([x, 14, x + 4, 19], fill=EYE, outline=OUTLINE)
        d.rectangle([x + 2, 16, x + 3, 18], fill=PUPIL)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)


if __name__ == "__main__":
    main()
