extends Node
## Estado da campanha que sobrevive à troca de cena: região e andar atuais,
## a mochila, o estoque da apotecária e os pacientes já atendidos. Ir à cabana,
## voltar ou trocar de região não mexe na mochila, no estoque nem nos pacientes; só `new_game()` zera tudo.
##
## Registrado como autoload "GameState".

## Emitido quando o gato começa uma região (sempre no andar 1).
signal region_started(region: String)
## Emitido quando o gato sobe para outro andar da mesma região.
signal floor_climbed(floor_number: int)

const FIRST_FLOOR := 1
## Paridade do andar, com os mesmos valores da coluna "paridade" do CSV.
const PARITY_ODD := "impar"
const PARITY_EVEN := "par"

## Id da região atual (o mesmo do CSV). Vazio enquanto o gato está na cabana.
var current_region: String = ""
var current_floor: int = FIRST_FLOOR
var backpack := Backpack.new()
var stock := Stock.new()
## Quais condições já foram atendidas e o sorteio do próximo paciente.
var patients := PatientPicker.new()


## Começa uma região: sempre pelo andar 1. Mochila e estoque ficam como estão.
func start_region(region: String) -> void:
	current_region = region
	current_floor = FIRST_FLOOR
	region_started.emit(region)


## Sobe para o próximo andar da região atual. Não existe volta a andares
## anteriores.
func climb_floor() -> void:
	current_floor += 1
	floor_climbed.emit(current_floor)


## "impar" ou "par", conforme o andar atual. O andar 1 é ímpar.
func floor_parity() -> String:
	return PARITY_ODD if current_floor % 2 == 1 else PARITY_EVEN


## Deixa a região (o gato voltou à cabana). Mochila e estoque ficam como estão.
func leave_region() -> void:
	current_region = ""
	current_floor = FIRST_FLOOR


## Zera tudo para uma campanha nova.
func new_game() -> void:
	leave_region()
	backpack.clear()
	stock.clear()
	patients.reset()
