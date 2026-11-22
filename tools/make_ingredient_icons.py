"""Gera os 26 ícones de ingredientes (32 x 32), um por id do data/ingredientes.csv.

Uso: python tools/make_ingredient_icons.py

Arte própria do projeto, desenhada por código. Cada ícone é pintado em camadas
e recebe um contorno escuro automático de 1 px, no mesmo estilo dos bichos.
Os ingredientes se distinguem pela silhueta (fruta redonda, folha, flor, peixe,
frasco...), não só pela cor. Para retocar à mão (Aseprite), edite o PNG em
assets/art/ingredients/<id>.png; rodar o script de novo sobrescreve o arquivo.
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "art" / "ingredients"
OUTLINE = (0x2B, 0x1A, 0x10, 255)


def c(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


GREEN = c("5FAE4B")
GREEN_L = c("A6DB74")
GREEN_D = c("356B35")
BROWN = c("8A5A33")
BROWN_D = c("5A3820")
BROWN_L = c("C08A52")
RED = c("D63A33")
RED_D = c("8E2226")
RED_L = c("F0807A")
YELLOW = c("F2C94C")
YELLOW_L = c("FFF0A0")
ORANGE = c("E8842C")
ORANGE_D = c("B04F1E")
WHITE = c("F4F0E6")
GRAY = c("9AA3AD")
GRAY_D = c("5E6773")
GRAY_L = c("D3D9DF")
PURPLE = c("7E57B8")
PURPLE_D = c("48307A")
PURPLE_L = c("B79AE6")
PINK = c("EE7FA8")
PINK_L = c("F8C0D5")
BLUE = c("4A78B8")
BLUE_D = c("2E4A7A")
AMBER = c("E3A02B")
AMBER_L = c("FFD36A")
BLACK = c("2A2630")


def canvas():
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def outline(img):
    """Contorno de 1 px em volta de tudo o que foi pintado."""
    px = img.load()
    mark = []
    for y in range(32):
        for x in range(32):
            if px[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < 32 and 0 <= ny < 32 and px[nx, ny][3] != 0:
                    mark.append((x, y))
                    break
    for p in mark:
        px[p] = OUTLINE
    return img


def dots(d, color, pts):
    for p in pts:
        d.point(p, fill=color)


def leaf(d, x0, y0, x1, y1, color, vein=None):
    """Folha em losango alongado de (x0, y0) até a ponta (x1, y1)."""
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2
    dx, dy = x1 - x0, y1 - y0
    n = (dx * dx + dy * dy) ** 0.5 or 1
    px_, py_ = -dy / n * n * 0.28, dx / n * n * 0.28
    d.polygon([(x0, y0), (mx + px_, my + py_), (x1, y1), (mx - px_, my - py_)], fill=color)
    if vein:
        d.line([(x0, y0), (x1, y1)], fill=vein)


# --- Amazônia ---------------------------------------------------------------


def buriti():
    img, d = canvas()
    d.ellipse([7, 5, 25, 27], fill=ORANGE_D)
    d.ellipse([9, 7, 23, 25], fill=ORANGE)
    # escamas em losango da casca
    for y in range(9, 25, 4):
        for x in range(11 + (y // 4 % 2) * 2, 23, 4):
            d.polygon([(x, y - 1), (x + 1, y), (x, y + 1), (x - 1, y)], fill=ORANGE_D)
    d.ellipse([11, 8, 14, 11], fill=YELLOW)
    d.rectangle([15, 3, 17, 6], fill=BROWN_D)
    return outline(img)


def camu_camu():
    img, d = canvas()
    d.line([(16, 4), (16, 11)], fill=GREEN_D)
    leaf(d, 16, 6, 25, 4, GREEN)
    for cx, cy in ((10, 18), (22, 18), (16, 21)):
        d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=PURPLE_D)
        d.ellipse([cx - 4, cy - 4, cx + 3, cy + 3], fill=RED_D)
        d.point((cx - 2, cy - 2), fill=RED_L)
    d.rectangle([14, 10, 18, 12], fill=GREEN)
    return outline(img)


def resina_copaiba():
    img, d = canvas()
    # gota âmbar escorrendo de um pedaço de casca
    d.rectangle([4, 4, 27, 10], fill=BROWN)
    d.rectangle([4, 4, 27, 5], fill=BROWN_L)
    dots(d, BROWN_D, [(8, 8), (14, 7), (21, 8), (25, 6)])
    d.polygon([(16, 12), (22, 20), (22, 24), (19, 28), (13, 28), (10, 24), (10, 20)], fill=AMBER)
    d.polygon([(16, 15), (19, 20), (19, 24), (16, 26), (13, 24), (13, 20)], fill=AMBER_L)
    d.line([(12, 21), (12, 24)], fill=WHITE)
    d.rectangle([14, 10, 18, 14], fill=AMBER)
    return outline(img)


def unha_de_gato():
    img, d = canvas()
    d.line([(4, 26), (10, 18), (18, 14), (27, 6)], fill=GREEN_D, width=2)
    leaf(d, 9, 19, 5, 11, GREEN)
    leaf(d, 18, 14, 24, 21, GREEN)
    # os dois espinhos curvos, a "unha"
    d.polygon([(12, 17), (14, 23), (9, 27), (11, 21)], fill=BROWN_L)
    d.polygon([(20, 13), (25, 13), (28, 18), (23, 16)], fill=BROWN_L)
    d.line([(12, 18), (10, 26)], fill=BROWN_D)
    return outline(img)


# --- Caatinga ---------------------------------------------------------------


def castanha_caju():
    img, d = canvas()
    # fruta (o pedúnculo) vermelha com a castanha cinza pendurada
    d.ellipse([6, 8, 24, 28], fill=RED_D)
    d.ellipse([8, 9, 22, 26], fill=ORANGE)
    d.ellipse([9, 10, 16, 18], fill=YELLOW)
    d.polygon([(19, 4), (27, 6), (27, 11), (23, 14), (19, 10)], fill=GRAY_D)
    d.polygon([(20, 5), (26, 7), (26, 10), (22, 11)], fill=GRAY)
    return outline(img)


def alecrim_pimenta():
    img, d = canvas()
    d.line([(16, 29), (16, 3)], fill=GREEN_D, width=2)
    for y, w in ((7, 6), (11, 7), (15, 6), (19, 5)):
        d.line([(16, y), (16 - w, y - 3)], fill=GREEN, width=2)
        d.line([(17, y), (17 + w, y - 3)], fill=GREEN, width=2)
    d.polygon([(21, 20), (27, 21), (26, 28), (23, 26)], fill=RED)
    d.rectangle([20, 19, 22, 21], fill=GREEN_D)
    d.point((25, 23), fill=RED_L)
    return outline(img)


def acerola():
    img, d = canvas()
    d.line([(14, 8), (10, 3)], fill=GREEN_D)
    d.line([(20, 8), (24, 4)], fill=GREEN_D)
    leaf(d, 17, 5, 27, 8, GREEN)
    for cx, cy in ((10, 18), (22, 18)):
        d.ellipse([cx - 7, cy - 7, cx + 7, cy + 7], fill=RED_D)
        d.ellipse([cx - 6, cy - 6, cx + 5, cy + 5], fill=RED)
        d.rectangle([cx - 4, cy - 4, cx - 2, cy - 2], fill=RED_L)
        d.line([(cx, cy - 7), (cx, cy - 3)], fill=RED_D)  # sulco típico da acerola
    return outline(img)


def licuri():
    img, d = canvas()
    # três coquinhos ovais e pontudos em cacho
    for cx, cy in ((11, 11), (21, 12), (16, 21)):
        d.polygon([(cx, cy - 8), (cx + 5, cy - 3), (cx + 4, cy + 5), (cx, cy + 8), (cx - 4, cy + 5), (cx - 5, cy - 3)], fill=BROWN)
        d.polygon([(cx, cy - 6), (cx + 3, cy - 2), (cx + 2, cy + 3), (cx - 1, cy + 3), (cx - 3, cy - 2)], fill=BROWN_L)
        d.line([(cx, cy - 8), (cx, cy + 8)], fill=BROWN_D)
    return outline(img)


# --- Campos e Rios ----------------------------------------------------------


def pele_tilapia():
    img, d = canvas()
    d.polygon([(4, 8), (24, 6), (28, 11), (25, 17), (28, 23), (8, 26), (5, 18)], fill=GRAY)
    d.polygon([(6, 10), (22, 8), (25, 12), (6, 20)], fill=GRAY_L)
    for y in range(9, 26, 4):
        for x in range(8 + (y // 4 % 2) * 2, 26, 4):
            d.arc([x - 2, y - 2, x + 2, y + 2], 0, 180, fill=GRAY_D)
    d.line([(24, 6), (28, 11)], fill=PINK_L)
    return outline(img)


def banana_da_terra():
    img, d = canvas()
    d.polygon([(5, 6), (9, 4), (22, 12), (27, 22), (23, 27), (19, 17), (8, 11)], fill=GREEN_L)
    d.polygon([(7, 7), (9, 6), (21, 13), (25, 22), (23, 24), (19, 15)], fill=YELLOW)
    d.line([(10, 8), (22, 17)], fill=YELLOW_L)
    d.rectangle([3, 3, 7, 7], fill=BROWN_D)
    d.rectangle([22, 24, 26, 28], fill=BROWN_D)
    d.line([(13, 11), (21, 20)], fill=GREEN)  # quina da banana-da-terra
    return outline(img)


def figado_bovino():
    img, d = canvas()
    d.polygon([(4, 12), (9, 6), (18, 5), (28, 9), (27, 18), (21, 26), (11, 27), (5, 21)], fill=RED_D)
    d.polygon([(7, 12), (11, 8), (18, 8), (25, 11), (24, 17), (19, 23), (12, 24), (8, 20)], fill=c("A8363A"))
    d.line([(15, 8), (13, 21)], fill=RED_D)
    d.line([(21, 10), (19, 19)], fill=RED_D)
    dots(d, RED_L, [(10, 11), (11, 12), (22, 12)])
    d.polygon([(21, 4), (24, 3), (24, 8)], fill=GREEN_D)  # vesícula
    return outline(img)


def erva_cidreira():
    img, d = canvas()
    for x0, x1, col in ((16, 6, GREEN), (16, 12, GREEN_L), (16, 20, GREEN), (16, 26, GREEN_L), (16, 16, GREEN_D)):
        d.polygon([(x0 - 1, 26), (x0 + 1, 26), (x1, 3)], fill=col)
    d.rectangle([12, 19, 20, 22], fill=BROWN_L)
    d.line([(12, 20), (20, 20)], fill=BROWN_D)
    return outline(img)


def semente_chia():
    img, d = canvas()
    d.polygon([(5, 25), (9, 17), (16, 12), (23, 17), (27, 25)], fill=GRAY_D)
    d.polygon([(8, 24), (11, 19), (16, 15), (21, 19), (24, 24)], fill=BLACK)
    pts = [(10, 22), (13, 19), (16, 17), (19, 20), (22, 22), (14, 23), (18, 23), (12, 25), (20, 25)]
    for p in pts:
        d.point(p, fill=GRAY_L)
    # brotinho de chia saindo da pilha
    d.line([(16, 12), (16, 5)], fill=GREEN_D)
    d.ellipse([12, 2, 16, 5], fill=GREEN)
    d.ellipse([17, 3, 21, 6], fill=GREEN_L)
    return outline(img)


# --- Cerrado ----------------------------------------------------------------


def pequi():
    img, d = canvas()
    d.ellipse([4, 6, 21, 25], fill=GREEN_D)
    d.ellipse([5, 7, 19, 22], fill=GREEN)
    d.ellipse([6, 8, 11, 12], fill=GREEN_L)
    # metade aberta com polpa amarela e espinhos
    d.ellipse([14, 12, 28, 28], fill=YELLOW)
    d.ellipse([17, 15, 25, 25], fill=YELLOW_L)
    dots(d, BROWN_D, [(20, 17), (22, 20), (19, 21), (21, 23)])
    d.arc([14, 12, 28, 28], 200, 340, fill=GREEN_D)
    return outline(img)


def flor_assa_peixe():
    img, d = canvas()
    d.line([(16, 29), (16, 18)], fill=GREEN_D, width=2)
    leaf(d, 16, 26, 7, 22, GREEN)
    leaf(d, 16, 24, 25, 20, GREEN)
    # buquê esférico de florzinhas lilás
    for cx, cy in ((11, 13), (16, 9), (21, 13), (13, 17), (19, 17), (16, 13)):
        d.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=PURPLE_L)
        d.point((cx, cy), fill=WHITE)
    d.ellipse([8, 8, 11, 11], fill=PINK_L)
    return outline(img)


def mulungu():
    img, d = canvas()
    d.line([(6, 28), (14, 4)], fill=BROWN_D, width=2)
    # espiga de flores vermelhas em forma de chama
    for i, (x, y) in enumerate([(14, 6), (17, 9), (19, 13), (20, 17), (19, 21), (17, 25)]):
        d.polygon([(x - 2, y + 2), (x, y - 3), (x + 6, y + 1), (x + 3, y + 4)], fill=RED if i % 2 else ORANGE)
    dots(d, YELLOW_L, [(16, 8), (21, 15), (20, 22)])
    leaf(d, 8, 22, 2, 15, GREEN)
    return outline(img)


def arnica_brasileira():
    img, d = canvas()
    d.line([(16, 29), (16, 18)], fill=GREEN_D, width=2)
    leaf(d, 16, 26, 8, 22, GREEN)
    d.ellipse([4, 3, 28, 22], fill=YELLOW)
    for k in range(8):
        a = k * 45
        # pétalas alongadas em raio
        import math

        x = 16 + math.cos(math.radians(a)) * 9.5
        y = 12.5 + math.sin(math.radians(a)) * 8
        d.line([(16, 12), (x, y)], fill=AMBER, width=1)
    d.ellipse([11, 8, 21, 17], fill=ORANGE_D)
    d.ellipse([12, 9, 20, 16], fill=ORANGE)
    d.point((14, 11), fill=YELLOW_L)
    return outline(img)


# --- Litoral ----------------------------------------------------------------


def agua_coco():
    img, d = canvas()
    d.ellipse([5, 5, 27, 28], fill=GREEN_D)
    d.ellipse([6, 6, 25, 26], fill=GREEN)
    d.ellipse([8, 8, 14, 14], fill=GREEN_L)
    d.polygon([(11, 6), (21, 6), (19, 2), (13, 2)], fill=YELLOW_L)  # topo cortado
    d.rectangle([20, 1, 21, 14], fill=RED)  # canudo
    d.line([(21, 1), (26, 1)], fill=RED)
    return outline(img)


def sardinha():
    img, d = canvas()
    d.polygon([(3, 16), (9, 9), (20, 9), (25, 14), (29, 8), (29, 24), (25, 18), (20, 23), (9, 23)], fill=GRAY)
    d.polygon([(5, 16), (10, 10), (20, 10), (24, 14), (20, 16), (10, 16)], fill=BLUE)
    d.polygon([(10, 17), (20, 17), (22, 18), (20, 22), (10, 22), (5, 17)], fill=GRAY_L)
    d.ellipse([6, 13, 8, 15], fill=BLACK)
    d.line([(24, 14), (28, 10)], fill=GRAY_D)
    d.line([(24, 18), (28, 22)], fill=GRAY_D)
    d.line([(14, 10), (14, 22)], fill=GRAY_D)
    return outline(img)


def mel():
    img, d = canvas()
    # pote de mel com tampa e a colher de pau pingando
    d.rectangle([7, 12, 25, 28], fill=AMBER)
    d.rectangle([9, 14, 23, 26], fill=AMBER_L)
    d.rectangle([9, 14, 12, 26], fill=YELLOW_L)
    d.rectangle([6, 8, 26, 12], fill=BROWN_L)
    d.rectangle([6, 8, 26, 9], fill=YELLOW_L)
    d.rectangle([11, 18, 21, 23], fill=WHITE)
    # favo hexagonal no rótulo
    for x, y in ((14, 20), (18, 20), (16, 22)):
        d.rectangle([x - 1, y - 1, x + 1, y + 1], fill=AMBER)
    d.line([(26, 3), (20, 10)], fill=BROWN_D, width=2)
    return outline(img)


def aroeira_praia():
    img, d = canvas()
    d.line([(16, 28), (16, 12)], fill=BROWN_D, width=2)
    d.line([(16, 16), (6, 8)], fill=BROWN_D)
    d.line([(16, 16), (26, 8)], fill=BROWN_D)
    leaf(d, 16, 22, 6, 24, GREEN)
    leaf(d, 16, 22, 27, 24, GREEN)
    for cx, cy in ((6, 8), (26, 8), (16, 8), (11, 12), (21, 12), (16, 14), (9, 5), (23, 5)):
        d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=PINK)
        d.point((cx - 1, cy - 1), fill=PINK_L)
    return outline(img)


# --- Mata Atlântica ---------------------------------------------------------


def flor_maracuja():
    img, d = canvas()
    import math

    for k in range(10):
        a = math.radians(k * 36)
        x, y = 16 + math.cos(a) * 10, 16 + math.sin(a) * 10
        d.ellipse([x - 3.5, y - 3.5, x + 3.5, y + 3.5], fill=WHITE if k % 2 else PINK_L)
    d.ellipse([8, 8, 24, 24], fill=PURPLE)
    d.ellipse([10, 10, 22, 22], fill=BLUE)
    d.ellipse([12, 12, 20, 20], fill=PURPLE_L)
    d.ellipse([14, 14, 18, 18], fill=YELLOW)
    return outline(img)


def erva_baleeira():
    img, d = canvas()
    d.line([(16, 29), (16, 6)], fill=GREEN_D, width=2)
    # folhas arredondadas e serrilhadas em pares
    for y in (24, 17, 10):
        for sx in (-1, 1):
            cx = 16 + sx * 7
            d.ellipse([cx - 5, y - 4, cx + 5, y + 3], fill=GREEN)
            dots(d, GREEN_L, [(cx - 2 * sx, y - 2), (cx - 3 * sx, y - 1)])
            dots(d, GREEN_D, [(cx + 5 * sx, y - 1), (cx + 5 * sx, y + 1), (cx + 3 * sx, y + 3)])
    d.ellipse([14, 2, 18, 6], fill=WHITE)
    return outline(img)


def espinheira_santa():
    img, d = canvas()
    # folha escura, coriácea, com pontas espinhosas nas bordas
    d.polygon([(16, 2), (20, 7), (26, 8), (23, 13), (27, 18), (21, 20), (19, 26), (16, 29),
               (13, 26), (11, 20), (5, 18), (9, 13), (6, 8), (12, 7)], fill=GREEN_D)
    d.polygon([(16, 5), (19, 9), (22, 10), (20, 14), (22, 18), (18, 19), (16, 25),
               (14, 19), (10, 18), (12, 14), (10, 10), (13, 9)], fill=GREEN)
    d.line([(16, 5), (16, 27)], fill=GREEN_L)
    for y in (10, 15, 20):
        d.line([(16, y), (11, y - 3)], fill=GREEN_L)
        d.line([(16, y), (21, y - 3)], fill=GREEN_L)
    return outline(img)


def folha_goiabeira():
    img, d = canvas()
    d.ellipse([7, 3, 25, 28], fill=GREEN)
    d.ellipse([9, 5, 17, 14], fill=GREEN_L)
    d.line([(16, 2), (16, 30)], fill=GREEN_D, width=1)
    for y in range(7, 26, 4):  # nervuras bem marcadas, típicas da goiabeira
        d.line([(16, y + 2), (9, y - 1)], fill=GREEN_D)
        d.line([(16, y + 2), (23, y - 1)], fill=GREEN_D)
    return outline(img)


def folha_guaco():
    img, d = canvas()
    d.line([(4, 28), (10, 20), (18, 17), (28, 6)], fill=GREEN_D, width=2)
    # folhas em forma de coração ao longo do ramo
    for cx, cy in ((10, 11), (23, 22), (22, 9)):
        d.ellipse([cx - 6, cy - 5, cx, cy + 2], fill=GREEN)
        d.ellipse([cx, cy - 5, cx + 6, cy + 2], fill=GREEN)
        d.polygon([(cx - 6, cy), (cx + 6, cy), (cx, cy + 8)], fill=GREEN)
        d.line([(cx, cy - 3), (cx, cy + 6)], fill=GREEN_D)
        d.point((cx - 3, cy - 3), fill=GREEN_L)
    return outline(img)


ICONS = {
    "buriti": buriti,
    "camu_camu": camu_camu,
    "resina_copaiba": resina_copaiba,
    "unha_de_gato": unha_de_gato,
    "castanha_caju": castanha_caju,
    "alecrim_pimenta": alecrim_pimenta,
    "acerola": acerola,
    "licuri": licuri,
    "pele_tilapia": pele_tilapia,
    "banana_da_terra": banana_da_terra,
    "figado_bovino": figado_bovino,
    "erva_cidreira": erva_cidreira,
    "semente_chia": semente_chia,
    "pequi": pequi,
    "flor_assa_peixe": flor_assa_peixe,
    "mulungu": mulungu,
    "arnica_brasileira": arnica_brasileira,
    "agua_coco": agua_coco,
    "sardinha": sardinha,
    "mel": mel,
    "aroeira_praia": aroeira_praia,
    "flor_maracuja": flor_maracuja,
    "erva_baleeira": erva_baleeira,
    "espinheira_santa": espinheira_santa,
    "folha_goiabeira": folha_goiabeira,
    "folha_guaco": folha_guaco,
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, fn in ICONS.items():
        fn().save(OUT / f"{name}.png")


if __name__ == "__main__":
    main()
