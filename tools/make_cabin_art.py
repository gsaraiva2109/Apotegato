"""Gera a arte provisória da cabana (pixel art, tiles de 32 px) em assets/art/cabin/.

Uso: python tools/make_cabin_art.py

É só um quebra-galho até a arte definitiva. Para trocar, basta sobrescrever os
PNGs com o mesmo nome e as mesmas dimensões; as cenas não precisam mudar.
"""

import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "cabin"

# Paleta da cabana: madeira quente e frascos coloridos.
OUTLINE = (0x2B, 0x1A, 0x10, 255)
WOOD_DARK = (0x5A, 0x3B, 0x26, 255)
WOOD = (0x7B, 0x53, 0x34, 255)
WOOD_LIGHT = (0x9C, 0x6E, 0x44, 255)
FLOOR = (0xC9, 0xA1, 0x6B, 255)
FLOOR_DARK = (0xB8, 0x8F, 0x5B, 255)
FLOOR_LIGHT = (0xD6, 0xB2, 0x7C, 255)
CREAM = (0xF3, 0xE6, 0xC4, 255)
GLASS = [
    (0x6F, 0xB3, 0x6A, 255),
    (0xE0, 0xA3, 0x3A, 255),
    (0xC9, 0x4F, 0x4F, 255),
    (0x5B, 0x8F, 0xC9, 255),
    (0x9A, 0x6B, 0xB5, 255),
]
CORK = (0xB0, 0x82, 0x4F, 255)
LEAF = (0x4E, 0x9A, 0x4A, 255)
LEAF_DARK = (0x36, 0x70, 0x38, 255)
LEAF_LIGHT = (0x7C, 0xC4, 0x5E, 255)
CLAY = (0xC0, 0x6A, 0x42, 255)
CLAY_DARK = (0x94, 0x4B, 0x2D, 255)


def shade(color, delta):
    return tuple(max(0, min(255, c + delta)) for c in color[:3]) + (255,)


def noisy(img, base, seed, amount=6):
    """Pinta o fundo com um ruído leve, para a madeira não ficar chapada."""
    rng = random.Random(seed)
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            px[x, y] = shade(base, rng.randint(-amount, amount))


def tileset():
    img = Image.new("RGBA", (32 * 5, 32), (0, 0, 0, 0))

    def tile(i):
        t = Image.new("RGBA", (32, 32))
        return t, ImageDraw.Draw(t), i * 32

    # 0 e 1: piso de tábuas
    for i, seed in ((0, 1), (1, 2)):
        t, d, ox = tile(i)
        noisy(t, FLOOR, seed, 4)
        d = ImageDraw.Draw(t)
        for y in (0, 16):
            d.line([(0, y), (31, y)], fill=FLOOR_DARK)
        d.line([(0, 1), (31, 1)], fill=FLOOR_LIGHT)
        d.line([(0, 17), (31, 17)], fill=FLOOR_LIGHT)
        for x, y0 in ((8 + i * 12, 0), (22 - i * 10, 16)):
            d.line([(x, y0), (x, y0 + 15)], fill=FLOOR_DARK)
        img.paste(t, (ox, 0))
    # 2: topo da parede (viga escura)
    t, d, ox = tile(2)
    noisy(t, WOOD_DARK, 3, 4)
    d = ImageDraw.Draw(t)
    d.line([(0, 0), (31, 0)], fill=shade(WOOD_DARK, 14))
    d.line([(0, 31), (31, 31)], fill=OUTLINE)
    for x in (0, 16):
        d.line([(x, 0), (x, 31)], fill=shade(WOOD_DARK, -14))
    img.paste(t, (ox, 0))
    # 3: face da parede (tábuas verticais)
    t, d, ox = tile(3)
    noisy(t, WOOD, 4, 5)
    d = ImageDraw.Draw(t)
    for x in (0, 10, 21):
        d.line([(x, 0), (x, 31)], fill=shade(WOOD, -26))
        d.line([(x + 1, 0), (x + 1, 31)], fill=shade(WOOD, 12))
    d.line([(0, 30), (31, 30)], fill=shade(WOOD, -34))
    d.line([(0, 31), (31, 31)], fill=OUTLINE)
    img.paste(t, (ox, 0))
    # 4: piso escurecido junto da parede (sombra)
    t, d, ox = tile(4)
    noisy(t, FLOOR_DARK, 5, 4)
    d = ImageDraw.Draw(t)
    d.line([(0, 16), (31, 16)], fill=shade(FLOOR_DARK, -14))
    img.paste(t, (ox, 0))
    img.save(OUT / "cabin_tileset.png")


def outline_box(d, box, fill, edge=OUTLINE):
    d.rectangle(box, fill=fill, outline=edge)


def jar(d, x, y, color, h=14):
    """Frasco de vidro com tampa de cortiça e rótulo."""
    d.rectangle([x + 1, y + 3, x + 8, y + h], fill=color, outline=OUTLINE)
    d.rectangle([x + 3, y, x + 6, y + 3], fill=CORK, outline=OUTLINE)
    d.rectangle([x + 3, y + 7, x + 6, y + 10], fill=CREAM)
    d.point((x + 2, y + 5), fill=shade(color, 60))


def shelf():
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    outline_box(d, [2, 2, 93, 63], WOOD_DARK)
    outline_box(d, [5, 5, 90, 60], shade(WOOD_DARK, -20))
    for y in (24, 44):
        outline_box(d, [4, y, 91, y + 3], WOOD_LIGHT)
    for row, y in enumerate((9, 28, 48)):
        for i in range(7):
            jar(d, 8 + i * 12, y if row else y, GLASS[(i + row * 2) % 5], 14 if row == 0 else 12)
    # ervas penduradas no topo
    for x in (20, 60):
        d.line([(x, 0), (x, 5)], fill=LEAF_DARK)
        d.polygon([(x - 3, 3), (x + 3, 3), (x, 9)], fill=LEAF)
    img.save(OUT / "shelf.png")


def table():
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # pernas
    for x in (6, 84):
        outline_box(d, [x, 40, x + 5, 62], WOOD_DARK)
    # tampo (face de cima e frente)
    outline_box(d, [2, 8, 93, 38], WOOD_LIGHT)
    outline_box(d, [2, 38, 93, 46], WOOD)
    for x in (20, 44, 70):
        d.line([(x, 10), (x, 36)], fill=shade(WOOD_LIGHT, -16))
    # diário aberto
    outline_box(d, [24, 14, 70, 34], (0x8E, 0x2F, 0x34, 255))
    outline_box(d, [27, 16, 47, 32], CREAM)
    outline_box(d, [48, 16, 67, 32], CREAM)
    for y in (20, 24, 28):
        d.line([(30, y), (44, y)], fill=(0x9A, 0x8A, 0x66, 255))
        d.line([(51, y), (64, y)], fill=(0x9A, 0x8A, 0x66, 255))
    # pena e tinteiro
    d.line([(76, 12), (84, 22)], fill=CREAM)
    outline_box(d, [74, 24, 80, 32], (0x2F, 0x3B, 0x6B, 255))
    img.save(OUT / "table.png")


def bed():
    img = Image.new("RGBA", (96, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for x in (6, 86):
        outline_box(d, [x, 52, x + 4, 62], WOOD_DARK)
    outline_box(d, [2, 8, 93, 56], WOOD)  # estrado
    outline_box(d, [2, 4, 12, 58], WOOD_DARK)  # cabeceira
    outline_box(d, [14, 12, 34, 50], CREAM)  # travesseiro
    d.line([(16, 16), (32, 16)], fill=shade(CREAM, -20))
    outline_box(d, [32, 12, 91, 52], (0x4A, 0x8F, 0x86, 255))  # manta
    for x in range(40, 90, 12):
        d.line([(x, 14), (x, 50)], fill=(0x3A, 0x73, 0x6C, 255))
    for y in (24, 38):
        d.line([(33, y), (90, y)], fill=(0x6A, 0xB0, 0xA6, 255))
    img.save(OUT / "bed.png")


def plant():
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for pts, color in (
        ([(16, 30), (4, 12), (14, 24)], LEAF_DARK),
        ([(16, 30), (28, 10), (18, 24)], LEAF_DARK),
        ([(16, 30), (10, 2), (19, 22)], LEAF),
        ([(16, 30), (22, 4), (14, 22)], LEAF),
        ([(16, 30), (16, 8), (18, 26)], LEAF_LIGHT),
    ):
        d.polygon(pts, fill=color, outline=OUTLINE)
    d.polygon([(7, 32), (25, 32), (22, 46), (10, 46)], fill=CLAY, outline=OUTLINE)
    outline_box(d, [5, 30, 26, 34], CLAY_DARK)
    img.save(OUT / "plant.png")


def door():
    img = Image.new("RGBA", (32, 64), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    outline_box(d, [0, 0, 31, 63], WOOD_DARK)
    outline_box(d, [3, 4, 28, 63], WOOD_LIGHT)
    for x in (10, 18):
        d.line([(x, 5), (x, 62)], fill=shade(WOOD_LIGHT, -26))
    for y in (16, 46):
        d.line([(3, y), (28, y)], fill=(0x3A, 0x3A, 0x3A, 255))
    d.ellipse([22, 32, 26, 36], fill=(0xE0, 0xC0, 0x5A, 255), outline=OUTLINE)
    img.save(OUT / "door.png")


def rug():
    img = Image.new("RGBA", (128, 96), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, 127, 95], 10, fill=(0x8E, 0x2F, 0x34, 255), outline=OUTLINE)
    d.rounded_rectangle([6, 6, 121, 89], 6, fill=CREAM)
    d.rounded_rectangle([10, 10, 117, 85], 4, fill=(0x4A, 0x8F, 0x86, 255))
    d.polygon([(64, 18), (100, 48), (64, 78), (28, 48)], fill=(0xE0, 0xA3, 0x3A, 255), outline=OUTLINE)
    d.polygon([(64, 30), (86, 48), (64, 66), (42, 48)], fill=(0x8E, 0x2F, 0x34, 255))
    img.save(OUT / "rug.png")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    for make in (tileset, shelf, table, bed, plant, door, rug):
        make()
    print("Arte provisória gerada em", OUT)
