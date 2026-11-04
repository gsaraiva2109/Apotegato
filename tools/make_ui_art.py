"""Gera a arte provisória do tema da interface: painel e botões.

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


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    panel().save(OUT / "panel.png")
    pill((0x78, 0x55, 0x3B, 255), (0x55, 0x3A, 0x28, 255)).save(OUT / "button_normal.png")
    pill((0x6F, 0x42, 0x42, 255), (0x4A, 0x2C, 0x2C, 255)).save(OUT / "button_pressed.png")
    pill((0x8A, 0x70, 0x60, 255), (0x6B, 0x56, 0x4A, 255)).save(OUT / "button_disabled.png")


if __name__ == "__main__":
    main()
