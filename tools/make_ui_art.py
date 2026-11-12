"""Gera a arte provisória do tema da interface: painel, botões, tábua, barra,
mochila, pergaminho do diário, cursor e cursor do slider.

Uso: python tools/make_ui_art.py

Os tamanhos e as margens batem com os recortes do UI Medieval Mega feitos por
tools/crop_ui_pack.py, porque o tema (scenes/ui/game_theme.tres) usa 9-slice
com essas margens. Quem tem acesso ao ApotegatoAssets vê o visual definitivo.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "ui"

FRAME = (0x8A, 0x5A, 0x3C, 255)
FRAME_EDGE = (0x1E, 0x12, 0x0E, 255)
PANEL_FILL = (0x4B, 0x29, 0x1D, 255)


def panel() -> Image.Image:
    img = Image.new("RGBA", (97, 96), FRAME_EDGE)
    d = ImageDraw.Draw(img)
    d.rectangle((1, 1, 95, 94), fill=FRAME)
    d.rectangle((8, 8, 88, 87), fill=FRAME_EDGE)
    d.rectangle((9, 9, 87, 86), fill=PANEL_FILL)
    return img


def pill(fill, edge) -> Image.Image:
    img = Image.new("RGBA", (48, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 47, 15), radius=7, fill=edge)
    d.rounded_rectangle((0, 0, 47, 13), radius=7, fill=fill)
    return img


def plank() -> Image.Image:
    img = Image.new("RGBA", (119, 51), FRAME_EDGE)
    d = ImageDraw.Draw(img)
    d.rectangle((1, 1, 117, 49), fill=(0xB8, 0x66, 0x24, 255))
    for x, y in ((7, 7), (111, 7), (7, 43), (111, 43)):
        d.rectangle((x, y, x + 1, y + 1), fill=(0xD8, 0xC0, 0x90, 255))
    return img


def backpack() -> Image.Image:
    img = Image.new("RGBA", (64, 79), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((2, 14, 56, 77), radius=8, fill=(0x5A, 0x32, 0x1C, 255), outline=FRAME_EDGE)
    d.rounded_rectangle((16, 2, 40, 22), radius=6, outline=FRAME_EDGE, width=3)
    d.rectangle((16, 40, 30, 54), fill=(0x8A, 0x5A, 0x3C, 255), outline=FRAME_EDGE)
    return img


def cursor() -> Image.Image:
    img = Image.new("RGBA", (11, 14), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon([(0, 0), (0, 12), (3, 9), (6, 13), (8, 12), (5, 8), (10, 8)], fill=(0xF3, 0xE6, 0xC4, 255), outline=FRAME_EDGE)
    return img


def grabber() -> Image.Image:
    img = Image.new("RGBA", (10, 10), (0, 0, 0, 0))
    ImageDraw.Draw(img).ellipse((0, 0, 9, 9), fill=(0xBD, 0x6D, 0x29, 255), outline=FRAME_EDGE)
    return img


def parchment() -> Image.Image:
    """Pergaminho com os dois rolos (9-slice: esquerda 14, direita 10, topo 26, base 29)."""
    edge = (0x0A, 0x00, 0x00, 255)
    paper = (0xE4, 0xCB, 0x9B, 255)
    shade = (0xC0, 0xAB, 0x82, 255)
    img = Image.new("RGBA", (150, 89), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # miolo, com o contorno escuro nas laterais e as duas faixas de sombra
    d.rectangle((4, 17, 142, 72), fill=edge)
    d.rectangle((6, 19, 140, 70), fill=paper)
    d.rectangle((6, 19, 140, 25), fill=shade)
    d.rectangle((6, 61, 140, 70), fill=shade)
    # rolos de cima e de baixo
    for y0, y1 in ((0, 17), (72, 88)):
        d.rounded_rectangle((2, y0, 149, y1), radius=6, fill=edge)
        d.rounded_rectangle((3, y0 + 1, 148, y1 - 1), radius=5, fill=paper)
        d.rectangle((6, y1 - 6, 145, y1 - 2), fill=shade)
    return img


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    panel().save(OUT / "panel.png")
    pill((0x78, 0x55, 0x3B, 255), (0x55, 0x3A, 0x28, 255)).save(OUT / "button_normal.png")
    pill((0x6F, 0x42, 0x42, 255), (0x4A, 0x2C, 0x2C, 255)).save(OUT / "button_pressed.png")
    pill((0x8A, 0x70, 0x60, 255), (0x6B, 0x56, 0x4A, 255)).save(OUT / "button_disabled.png")
    pill((0xBD, 0x6D, 0x29, 255), (0x8A, 0x4C, 0x1C, 255)).save(OUT / "bar_fill.png")
    plank().save(OUT / "plank.png")
    parchment().save(OUT / "parchment.png")
    backpack().save(OUT / "backpack_icon.png")
    cursor().save(OUT / "cursor.png")
    grabber().save(OUT / "slider_grabber.png")


if __name__ == "__main__":
    main()
