class_name MingauSprites
extends RefCounted
## Arte do Mingau. Uma única folha, `assets/art/characters/mingau_sheet.png`, com
## uma linha por direção (8, vistas de cima em perspectiva) e uma coluna por quadro,
## em células de 44 x 40:
##
##   linhas   sul, sudeste, leste, nordeste, norte, noroeste, oeste, sudoeste
##   colunas  0 parado, 1 a 4 andar, 5 aviso do arranhão, 6 golpe, 7 volta
##
## A folha já traz as direções para a direita (nada de espelhar). Ela vem do
## repositório privado de assets (`tools/fetch_assets.sh`), então pode não existir:
## o caminho é carregado só se existir, sem aviso no console, e sem a folha o
## gato usa o sprite provisório.
##
## É lógica pura: quem anima (o jogador) pergunta aqui qual quadro mostrar.

const SHEET_PATH := "res://assets/art/characters/mingau_sheet.png"
const COLUMNS := 8
const ROWS := 8
const CELL_SIZE := Vector2i(44, 40)
const IDLE_FRAME := 0
const WALK_FIRST := 1
const WALK_FRAMES := 4
const WINDUP_FRAME := 5
const HIT_FRAME := 6
const RECOVER_FRAME := 7
## Quadros por segundo do andar.
const WALK_FPS := 8.0
## Duração de cada quadro do arranhão, em segundos (três quadros: 0,24 s).
const SCRATCH_FRAME_SECONDS := 0.08

## As oito direções, na ordem das linhas da folha. As diagonais já são unitárias.
const DIRECTIONS: Array[Vector2] = [
	Vector2(0, 1),
	Vector2(0.70710678, 0.70710678),
	Vector2(1, 0),
	Vector2(0.70710678, -0.70710678),
	Vector2(0, -1),
	Vector2(-0.70710678, -0.70710678),
	Vector2(-1, 0),
	Vector2(-0.70710678, 0.70710678),
]


static func is_installed() -> bool:
	return ResourceLoader.exists(SHEET_PATH)


## A folha, ou null se não estiver instalada.
static func load_sheet() -> Texture2D:
	if not is_installed():
		return null
	return load(SHEET_PATH) as Texture2D


## Linha da folha (0 a 7) da direção mais próxima de `direction`.
static func direction_index(direction: Vector2) -> int:
	if direction.is_zero_approx():
		return 0
	# a linha 0 é o sul (ângulo de 90 graus no sentido do Godot, y para baixo)
	var steps := roundi((PI / 2.0 - direction.angle()) / (PI / 4.0))
	return posmod(steps, ROWS)


## A direção das oito (unitária) mais próxima de `direction`. Sem entrada, devolve
## `current`.
static func snap(direction: Vector2, current: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return current
	return DIRECTIONS[direction_index(direction)]


## Quadro do andar para quem já andou `time` segundos.
static func walk_frame(time: float) -> int:
	return WALK_FIRST + int(maxf(time, 0.0) * WALK_FPS) % WALK_FRAMES


## Quadro do arranhão para `elapsed` segundos desde o início do golpe. Depois do
## último quadro, devolve -1 (o golpe acabou).
static func scratch_frame(elapsed: float) -> int:
	if elapsed < 0.0:
		return -1
	var step := int(elapsed / SCRATCH_FRAME_SECONDS)
	if step > 2:
		return -1
	return WINDUP_FRAME + step


static func total_scratch_seconds() -> float:
	return SCRATCH_FRAME_SECONDS * 3.0
