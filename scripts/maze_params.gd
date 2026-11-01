class_name MazeParams
extends Resource
## Parâmetros da geração de um andar. Cada valor tem um limite máximo (e mínimo)
## para a geração nunca ficar pesada nem gerar um mapa impossível; quem
## atribuir um valor fora do intervalo recebe o valor limitado.

const MIN_WIDTH := 10
const MAX_WIDTH := 60
const MIN_HEIGHT := 8
const MAX_HEIGHT := 34
const MAX_OBSTACLES := 80
const MAX_ENTITIES := 12
const MAX_ITEMS := 8

## Largura da grade, em células.
@export_range(MIN_WIDTH, MAX_WIDTH) var width: int = 30:
	set(value):
		width = clampi(value, MIN_WIDTH, MAX_WIDTH)

## Altura da grade, em células.
@export_range(MIN_HEIGHT, MAX_HEIGHT) var height: int = 17:
	set(value):
		height = clampi(value, MIN_HEIGHT, MAX_HEIGHT)

## Quantas barreiras (trechos de parede de 2 a 6 células) espalhar pelo andar.
@export_range(0, MAX_OBSTACLES) var obstacles: int = 16:
	set(value):
		obstacles = clampi(value, 0, MAX_OBSTACLES)

## Quantas posições de criatura reservar. O gerador pode entregar menos se não
## houver lugar que respeite as distâncias mínimas.
@export_range(0, MAX_ENTITIES) var entities: int = 4:
	set(value):
		entities = clampi(value, 0, MAX_ENTITIES)

## Quantas posições de ingrediente reservar.
@export_range(0, MAX_ITEMS) var items: int = 3:
	set(value):
		items = clampi(value, 0, MAX_ITEMS)
