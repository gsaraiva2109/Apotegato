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


CREAM = (0xF3, 0xE6, 0xC4, 255)
GREEN = (0x6E, 0xA8, 0x4A, 255)
GREEN_EDGE = (0x2F, 0x5A, 0x22, 255)
RED = (0xA8, 0x46, 0x3C, 255)
RED_EDGE = (0x5A, 0x22, 0x1E, 255)


def switch(on: bool) -> Image.Image:
    """Interruptor 60 x 26. Ligado: trilha verde, botão à direita e marca de
    visto. Desligado: trilha vermelha, botão à esquerda e um X. O estado se vê
    pela posição e pelo símbolo, não só pela cor."""
    fill, edge = (GREEN, GREEN_EDGE) if on else (RED, RED_EDGE)
    img = Image.new("RGBA", (60, 26), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((0, 0, 59, 25), radius=12, fill=edge)
    d.rounded_rectangle((2, 2, 57, 23), radius=10, fill=fill)
    knob_x = 37 if on else 3
    d.ellipse((knob_x, 3, knob_x + 19, 22), fill=FRAME_EDGE)
    d.ellipse((knob_x + 1, 4, knob_x + 18, 21), fill=CREAM)
    d.ellipse((knob_x + 5, 8, knob_x + 14, 17), fill=(0xD8, 0xC0, 0x90, 255))
    if on:
        for i in range(4):
            d.rectangle((11 + i, 12 + i, 12 + i, 13 + i), fill=CREAM)
        for i in range(7):
            d.rectangle((15 + i, 15 - i, 16 + i, 16 - i), fill=CREAM)
    else:
        for i in range(8):
            d.rectangle((34 + i, 9 + i, 35 + i, 10 + i), fill=CREAM)
            d.rectangle((41 - i, 9 + i, 42 - i, 10 + i), fill=CREAM)
    return img


def icon(draw) -> Image.Image:
    """Ícone 28 x 28: miolo creme com contorno escuro, para botões de ícone."""
    big = Image.new("RGBA", (24, 24), (0, 0, 0, 0))
    mask = Image.new("L", (24, 24), 0)
    draw(ImageDraw.Draw(mask))
    # contorno de 1 pixel em volta da forma
    outline = Image.new("L", (24, 24), 0)
    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            outline.paste(255, (dx, dy), mask)
    big.paste(Image.new("RGBA", (24, 24), FRAME_EDGE), (0, 0), outline)
    big.paste(Image.new("RGBA", (24, 24), CREAM), (0, 0), mask)
    framed = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
    framed.paste(big, (2, 2))
    return framed


def draw_close(d) -> None:
    d.line((5, 5, 18, 18), fill=255, width=3)
    d.line((18, 5, 5, 18), fill=255, width=3)


def draw_gear(d) -> None:
    d.ellipse((6, 6, 17, 17), fill=255)
    for box in ((10, 2, 13, 21), (2, 10, 21, 13)):
        d.rectangle(box, fill=255)
    d.line((4, 4, 19, 19), fill=255, width=3)
    d.line((19, 4, 4, 19), fill=255, width=3)
    d.ellipse((9, 9, 14, 14), fill=0)


def draw_speaker(d) -> None:
    d.rectangle((3, 9, 7, 14), fill=255)
    d.polygon([(7, 9), (13, 4), (13, 19), (7, 14)], fill=255)


def draw_sound(d) -> None:
    draw_speaker(d)
    d.arc((9, 6, 17, 17), -50, 50, fill=255, width=2)
    d.arc((9, 2, 21, 21), -50, 50, fill=255, width=2)


def draw_mute(d) -> None:
    draw_speaker(d)
    d.line((15, 8, 22, 15), fill=255, width=2)
    d.line((22, 8, 15, 15), fill=255, width=2)


def draw_home(d) -> None:
    d.polygon([(12, 3), (22, 12), (19, 12), (19, 21), (5, 21), (5, 12), (2, 12)], fill=255)
    d.rectangle((10, 14, 14, 21), fill=0)


def draw_play(d) -> None:
    d.polygon([(7, 3), (21, 12), (7, 21)], fill=255)


ICONS = {
    "icon_close.png": draw_close,
    "icon_gear.png": draw_gear,
    "icon_sound.png": draw_sound,
    "icon_mute.png": draw_mute,
    "icon_home.png": draw_home,
    "icon_play.png": draw_play,
}


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
    switch(True).save(OUT / "switch_on.png")
    switch(False).save(OUT / "switch_off.png")
    for name, draw in ICONS.items():
        icon(draw).save(OUT / name)


if __name__ == "__main__":
    main()
