"""Gera os sprites provisórios da apotecária e do paciente.

Uso: python tools/make_character_art.py

- apothecary_placeholder.png (32 x 48): senhora baixinha de xale verde-musgo,
  avental claro e coque grisalho.
- patient_placeholder.png (32 x 48): visitante genérico de capa marrom, usado por
  todos os pacientes até a arte final (#48).

Para trocar, basta sobrescrever os PNGs com as mesmas dimensões; a cabana não
precisa mudar.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "art" / "characters"

OUTLINE = (0x24, 0x16, 0x10, 255)
SKIN = (0xE8, 0xB8, 0x8C, 255)
SHADOW = (0, 0, 0, 70)
EYE = (0x24, 0x16, 0x10, 255)


def _head(d, hair, hair_dark):
    d.ellipse([10, 6, 21, 17], fill=SKIN, outline=OUTLINE)
    d.rectangle([13, 11, 14, 12], fill=EYE)
    d.rectangle([17, 11, 18, 12], fill=EYE)
    d.arc([10, 4, 21, 13], 180, 360, fill=hair_dark)
    d.chord([10, 4, 21, 12], 180, 360, fill=hair, outline=OUTLINE)
    return d


def make_apothecary():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 42, 26, 47], fill=SHADOW)
    # vestido e xale
    d.polygon([(9, 20), (23, 20), (26, 44), (6, 44)], fill=(0x5A, 0x3A, 0x5E, 255), outline=OUTLINE)
    d.polygon([(8, 19), (24, 19), (22, 30), (10, 30)], fill=(0x4E, 0x6B, 0x3A, 255), outline=OUTLINE)
    # avental
    d.rectangle([12, 27, 20, 42], fill=(0xEE, 0xE4, 0xCC, 255), outline=OUTLINE)
    d.rectangle([14, 33, 18, 36], outline=(0xB8, 0xA8, 0x88, 255))
    # coque grisalho
    d.ellipse([12, 1, 19, 7], fill=(0xC8, 0xC8, 0xC8, 255), outline=OUTLINE)
    _head(d, (0xC8, 0xC8, 0xC8, 255), (0x9A, 0x9A, 0x9A, 255))
    # óculos redondos
    d.ellipse([12, 10, 15, 13], outline=(0x6A, 0x4A, 0x20, 255))
    d.ellipse([16, 10, 19, 13], outline=(0x6A, 0x4A, 0x20, 255))
    return img


def make_patient():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.ellipse([6, 42, 26, 47], fill=SHADOW)
    # capa e pernas
    d.rectangle([11, 38, 14, 44], fill=(0x4A, 0x36, 0x28, 255), outline=OUTLINE)
    d.rectangle([17, 38, 20, 44], fill=(0x4A, 0x36, 0x28, 255), outline=OUTLINE)
    d.polygon([(10, 19), (22, 19), (25, 40), (7, 40)], fill=(0x8A, 0x5A, 0x34, 255), outline=OUTLINE)
    d.line([(16, 20), (16, 39)], fill=(0x6E, 0x46, 0x28, 255))
    _head(d, (0x5A, 0x3A, 0x22, 255), (0x3E, 0x28, 0x18, 255))
    return img


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    make_apothecary().save(OUT_DIR / "apothecary_placeholder.png")
    make_patient().save(OUT_DIR / "patient_placeholder.png")


if __name__ == "__main__":
    main()
