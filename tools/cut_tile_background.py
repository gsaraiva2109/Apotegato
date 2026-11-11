"""Recorta o fundo de um tile de barreira (ou de saída) de um tileset de região.

Uso:
    python tools/cut_tile_background.py assets/art/regions/amazonia/tileset.png
    python tools/cut_tile_background.py ENTRADA.png [-o SAIDA.png] [--tile 2] [--tolerance 28]

Serve para arte de terceiros em que a árvore vem pintada em cima de uma grama
própria, de cor diferente do chão normal. O `Room` desenha o tile de chão por
baixo das barreiras, então o tile da árvore precisa ter fundo transparente.

Como funciona: a partir das bordas do tile, apaga (deixa transparente) todos os
pixels ligados à borda cuja cor seja parecida com a do fundo. As cores de fundo
são as dos cantos do tile. O contorno escuro da árvore fecha a silhueta e
impede que o apagamento entre nela. Confira o resultado com `--preview`.

A ferramenta só altera o arquivo que você indicar; a arte de terceiros continua
somente no repositório privado, nunca neste.
"""

import argparse
from collections import Counter, deque
from pathlib import Path

from PIL import Image

TILE = 32


def distance(a, b):
    """Maior diferença entre canais RGB de duas cores."""
    return max(abs(a[i] - b[i]) for i in range(3))


def background_colors(tile, corner=3):
    """Cores mais comuns nos blocos corner x corner de cada canto do tile."""
    w, h = tile.size
    px = tile.load()
    colors = Counter()
    for x0 in (0, w - corner):
        for y0 in (0, h - corner):
            for x in range(x0, x0 + corner):
                for y in range(y0, y0 + corner):
                    if px[x, y][3] > 0:
                        colors[px[x, y][:3]] += 1
    return list(colors)


def cut_background(tile, tolerance=28):
    """Devolve uma cópia do tile com o fundo ligado às bordas transparente."""
    tile = tile.convert("RGBA")
    w, h = tile.size
    px = tile.load()
    bg = background_colors(tile)
    if not bg:
        return tile

    def is_bg(x, y):
        pixel = px[x, y]
        return pixel[3] > 0 and any(distance(pixel, c) <= tolerance for c in bg)

    seen = set()
    queue = deque()
    for x in range(w):
        for y in (0, h - 1):
            queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            queue.append((x, y))
    while queue:
        x, y = queue.popleft()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h) or not is_bg(x, y):
            continue
        seen.add((x, y))
        queue.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    for x, y in seen:
        px[x, y] = (0, 0, 0, 0)
    return tile


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("entrada", type=Path, help="tileset de 128 x 32")
    parser.add_argument("-o", "--saida", type=Path, help="padrão: sobrescreve a entrada")
    parser.add_argument(
        "--tile",
        type=int,
        action="append",
        help="índice do tile a recortar (0 a 3); pode repetir. Padrão: 2 (barreira)",
    )
    parser.add_argument("--tolerance", type=int, default=28, help="diferença de cor aceita (0 a 255)")
    parser.add_argument("--preview", action="store_true", help="grava também SAIDA_preview.png sobre o chão")
    args = parser.parse_args()

    tiles = args.tile or [2]
    sheet = Image.open(args.entrada).convert("RGBA")
    if sheet.size[1] != TILE or sheet.size[0] % TILE:
        raise SystemExit(f"tileset deve ter {TILE} px de altura e largura múltipla de {TILE}")
    for index in tiles:
        box = (index * TILE, 0, (index + 1) * TILE, TILE)
        if box[2] > sheet.size[0]:
            raise SystemExit(f"o tileset não tem o tile {index}")
        sheet.paste(cut_background(sheet.crop(box), args.tolerance), box)

    saida = args.saida or args.entrada
    sheet.save(saida)
    print(f"Gravado {saida}")

    if args.preview:
        floor = sheet.crop((0, 0, TILE, TILE))
        preview = Image.new("RGBA", (TILE * len(tiles), TILE))
        for n, index in enumerate(tiles):
            preview.paste(floor, (n * TILE, 0))
            tile = sheet.crop((index * TILE, 0, (index + 1) * TILE, TILE))
            preview.alpha_composite(tile, (n * TILE, 0))
        out = saida.with_name(saida.stem + "_preview.png")
        preview.resize((preview.width * 8, preview.height * 8), Image.NEAREST).save(out)
        print(f"Prévia em {out}")


if __name__ == "__main__":
    main()
