class_name CreatureSprites
extends RefCounted
## Arte das criaturas. Cada bicho tem uma pasta em `assets/art/creatures/<sprite>/`
## com duas folhas de células de 44 x 32, todas viradas para a esquerda:
##
##   andar.png  5 quadros de andar (o quadro 2 é o bicho em pé, parado)
##   golpe.png  3 quadros do ataque: aviso, golpe e volta
##
## A arte vem do repositório privado de assets (`tools/fetch_assets.sh`), então o
## arquivo pode não existir: o caminho é montado em tempo de execução e só
## carregado se existir, sem aviso no console. Sem arte, a criatura usa o
## sprite provisório da cena.
##
## É lógica pura: quem anima (a criatura) pergunta aqui qual quadro mostrar.

const ART_DIR := "res://assets/art/creatures/"
const WALK_SHEET := "andar.png"
const STRIKE_SHEET := "golpe.png"
const WALK_FRAMES := 5
const STRIKE_FRAMES := 3
## Largura e altura de cada célula das folhas, em pixels.
const CELL_SIZE := Vector2i(44, 32)
## Quadros por segundo do andar.
const WALK_FPS := 8.0
## Quadro do andar em que o bicho está em pé, para quando está parado.
const STAND_FRAME := 2


static func walk_path(sprite: String) -> String:
	return "%s%s/%s" % [ART_DIR, sprite, WALK_SHEET]


static func strike_path(sprite: String) -> String:
	return "%s%s/%s" % [ART_DIR, sprite, STRIKE_SHEET]


## Se as duas folhas do bicho estão instaladas.
static func has_art(sprite: String) -> bool:
	if sprite.is_empty():
		return false
	return ResourceLoader.exists(walk_path(sprite)) and ResourceLoader.exists(strike_path(sprite))


## Folha de andar, ou null se não estiver instalada.
static func load_walk(sprite: String) -> Texture2D:
	return _load_if_exists(walk_path(sprite)) if not sprite.is_empty() else null


## Folha de golpe, ou null se não estiver instalada.
static func load_strike(sprite: String) -> Texture2D:
	return _load_if_exists(strike_path(sprite)) if not sprite.is_empty() else null


## Quadro do andar para quem já andou `time` segundos.
static func walk_frame(time: float) -> int:
	return int(maxf(time, 0.0) * WALK_FPS) % WALK_FRAMES


## Quadro do golpe em cada estado: aviso, bote e descanso. Devolve -1 nos
## estados em que a criatura anda ou fica parada (usam a folha de andar).
static func strike_frame(state: CreatureBrain.State) -> int:
	match state:
		CreatureBrain.State.WARNING:
			return 0
		CreatureBrain.State.LUNGE:
			return 1
		CreatureBrain.State.REST:
			return 2
	return -1


static func _load_if_exists(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
