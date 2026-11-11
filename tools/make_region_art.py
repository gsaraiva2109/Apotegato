"""Gera os tilesets provisórios das seis regiões (pixel art, tiles de 32 px).

Uso: python tools/make_region_art.py

Cada região ganha um PNG de 128 x 32 em assets/art/regions/<id>/tileset.png,
com quatro tiles lado a lado:

    0  chão
    1  parede da borda do andar
    2  barreira dentro do andar (fundo transparente)
    3  porta de saída (fundo transparente)

O chão (tile 0) é desenhado por baixo de todos os tiles, então barreira e porta
precisam de fundo transparente.

Campos e Rios e Litoral também ganham um `water.png` (128 x 128: quatro quadros
da água animada, em coluna, na coluna do tile de parede e/ou de barreira). Os
tiles que têm água nesse arquivo substituem os estáticos do tileset.

Cada região usa três cores (chão, parede e destaque). É só um quebra-galho até a
arte definitiva: para trocar, basta sobrescrever os PNGs com as mesmas dimensões
e a mesma ordem de tiles; o código não precisa mudar.
"""

import random
from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "regions"

TILE = 32
OUTLINE = (0x14, 0x10, 0x0C, 255)

# id da região (o mesmo do CSV) -> (chão, parede, destaque)
PALETTES = {
    "amazonia": ((0x2F, 0x6B, 0x3A), (0x16, 0x38, 0x20), (0xB4, 0xE0, 0x5A)),
    "caatinga": ((0xD9, 0xBF, 0x8C), (0x8A, 0x5A, 0x3C), (0x6E, 0x8F, 0x3E)),
    "campos_rios": ((0x7D, 0xB3, 0x6B), (0x2F, 0x6F, 0x8F), (0xE8, 0xD7, 0x6A)),
    "cerrado": ((0xB5, 0x79, 0x3A), (0x5C, 0x3A, 0x21), (0xD9, 0xA4, 0x41)),
    "litoral": ((0xE8, 0xD8, 0xA0), (0x3F, 0x8F, 0xB0), (0xF2, 0xF0, 0xE0)),
    "mata_atlantica": ((0x5E, 0x9C, 0x6B), (0x2D, 0x5F, 0x55), (0xE5, 0x8F, 0xB0)),
}


def shade(color, delta):
    return tuple(max(0, min(255, c + delta)) for c in color[:3]) + (255,)


def noisy(base, seed, amount=6):
    """Tile pintado com um ruído leve, para o chão não ficar chapado."""
    rng = random.Random(seed)
    tile = Image.new("RGBA", (TILE, TILE))
    px = tile.load()
    for y in range(TILE):
        for x in range(TILE):
            px[x, y] = shade(base, rng.randint(-amount, amount))
    return tile


def floor_tile(floor, accent, seed):
    tile = noisy(floor, seed, 5)
    d = ImageDraw.Draw(tile)
    rng = random.Random(seed + 100)
    for _ in range(5):
        x, y = rng.randint(2, TILE - 4), rng.randint(2, TILE - 4)
        d.point((x, y), fill=shade(floor, -22))
        d.point((x + 1, y), fill=shade(floor, -22))
    # um tufo de destaque por tile, bem discreto
    x, y = rng.randint(6, TILE - 8), rng.randint(6, TILE - 8)
    d.point((x, y), fill=shade(accent, -10))
    d.point((x, y - 1), fill=shade(accent, 10))
    return tile


def wall_tile(wall, accent, seed):
    tile = noisy(wall, seed, 6)
    d = ImageDraw.Draw(tile)
    d.rectangle([0, 0, TILE - 1, TILE - 1], outline=OUTLINE)
    # blocos de pedra/tronco
    for y in (10, 21):
        d.line([(1, y), (TILE - 2, y)], fill=shade(wall, -26))
    for x, y0 in ((11, 1), (22, 11), (8, 22)):
        d.line([(x, y0), (x, y0 + 8)], fill=shade(wall, -26))
    d.line([(1, 1), (TILE - 2, 1)], fill=shade(wall, 24))
    return tile


def barrier_tile(floor, wall, accent, seed):
    """Moita ou rocha com fundo transparente, para as barreiras internas.

    O chão normal é desenhado por baixo pelo `Room`, então a grama fica igual
    ao redor do obstáculo.
    """
    tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    d.ellipse([3, 6, 28, 29], fill=shade(wall, 10), outline=OUTLINE)
    d.ellipse([7, 9, 19, 17], fill=shade(wall, 34))
    d.point((22, 22), fill=shade(accent, 0))
    d.point((23, 22), fill=shade(accent, 0))
    d.point((12, 24), fill=shade(accent, 0))
    return tile


def door_tile(floor, wall, accent, seed):
    """Arco de passagem com fundo transparente e o destaque da região."""
    tile = Image.new("RGBA", (TILE, TILE), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    d.rectangle([4, 2, 27, 29], fill=shade(wall, -20), outline=OUTLINE)
    d.rectangle([8, 7, 23, 29], fill=shade(accent, -40), outline=OUTLINE)
    d.rectangle([11, 11, 20, 29], fill=shade(accent, 20))
    d.line([(12, 13), (12, 27)], fill=shade(accent, 70))
    d.line([(4, 2), (27, 2)], fill=shade(wall, 30))
    return tile


def make_tileset(region, palette):
    floor, wall, accent = palette
    img = Image.new("RGBA", (TILE * 4, TILE), (0, 0, 0, 0))
    seed = sum(ord(c) for c in region)
    tiles = (
        floor_tile(floor, accent, seed),
        wall_tile(wall, accent, seed + 1),
        barrier_tile(floor, wall, accent, seed + 2),
        door_tile(floor, wall, accent, seed + 3),
    )
    for i, tile in enumerate(tiles):
        img.paste(tile, (i * TILE, 0))
    folder = OUT / region
    folder.mkdir(parents=True, exist_ok=True)
    img.save(folder / "tileset.png")


# Água animada: região -> (cor da água rasa, cor da água funda, tiles que são água).
# Os tiles contam como na folha do tileset (1 = parede, 2 = barreira).
WATER = {
    "campos_rios": ((0x3F, 0x8F, 0xCF), (0x2A, 0x6A, 0xA8), (1, 2)),
    "litoral": ((0x4F, 0xA3, 0xD8), (0x2F, 0x78, 0xB5), (1,)),
}
WATER_FRAMES = 4


def water_frame(base, foam, frame):
    """Um quadro de água: cor lisa com riscos claros que correm para a direita.

    Os riscos se repetem a cada 16 px e andam 8 px por quadro, então a animação
    fecha em 4 quadros e emenda com os tiles vizinhos.
    """
    tile = Image.new("RGBA", (TILE, TILE), base + (255,))
    d = ImageDraw.Draw(tile)
    for row, y in enumerate((5, 15, 25)):
        shift = frame * 8 + row * 5
        for x0 in range(-16, TILE + 16, 16):
            x = x0 + shift % 16
            d.line([(x, y), (x + 6, y)], fill=foam + (255,))
    return tile


def make_water(region, shallow, deep, tiles):
    """water.png: 128 x (32 * quadros), com os quadros de cada tile em coluna.

    As colunas dos tiles que não são água ficam transparentes.
    """
    img = Image.new("RGBA", (TILE * 4, TILE * WATER_FRAMES), (0, 0, 0, 0))
    for column in tiles:
        base = deep if column == 1 else shallow
        foam = shade(base, 70)[:3]
        for frame in range(WATER_FRAMES):
            img.paste(water_frame(base, foam, frame), (column * TILE, frame * TILE))
    img.save(OUT / region / "water.png")


def main():
    for region, palette in PALETTES.items():
        make_tileset(region, palette)
    for region, (shallow, deep, tiles) in WATER.items():
        make_water(region, shallow, deep, tiles)


if __name__ == "__main__":
    main()
