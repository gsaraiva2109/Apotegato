class_name Cabin
extends Node2D
## A cabana da apotecária: sala de 30 x 17 tiles onde o Mingau anda e onde
## acontece o atendimento dos pacientes, seguindo o roteiro (Roteiro_Mingau).
##
## - Na primeira vez, a conversa introdutória começa sozinha e, ao terminar, o
##   primeiro paciente entra.
## - O Mingau conversa com o paciente (queixa) e com a apotecária (lembrete,
##   pedido dos ingredientes e, depois do pedido, a entrega pela mochila).
## - Depois da orientação e do agradecimento, o atendimento é concluído, o
##   paciente sai pela porta e só então o próximo entra.
## - Depois do último atendimento da campanha, toca o encerramento com a escolha
##   entre voltar para a Unifor e continuar ajudando.
##
## Em que ponto o atendimento está fica em `GameState.attendance`; aqui só se
## mostra. Toda conversa, menu e entrega passa pela máquina de estados
## (`GameState.flow`), que congela o jogo fora da exploração.

## Emitido quando o Mingau interage com um ponto da cabana (`door`,
## `apothecary`, `stock` ou `patient`).
signal interacted(id: StringName)
## Emitido quando a entrega de ingredientes cobre a condição do paciente.
signal delivery_completed(condition: String)
## Emitido quando um paciente termina de entrar e fica esperando no lugar dele.
signal patient_arrived(condition: String)
## Emitido quando o paciente atendido termina de sair pela porta.
signal patient_left(condition: String)

## Tamanho da cabana em pixels (30 x 17 tiles de 32 px).
const ROOM := Rect2i(0, 0, 960, 544)
## Caminho do paciente da porta até o lugar dele, ao lado da cama. Na saída ele
## faz o caminho ao contrário.
const PATIENT_PATH: Array[Vector2] = [
	Vector2(464, 72), Vector2(464, 200), Vector2(192, 200), Vector2(192, 336)
]
## Velocidade do paciente andando, em pixels por segundo.
const PATIENT_SPEED := 120.0
## Mostra o paciente entrando e saindo andando. Os testes desligam para não
## esperar a caminhada.
@export var animate_patient := true
## Segundos entre a despedida (voltar para a Unifor) e o menu inicial.
@export var ending_seconds := 1.5

## Condição do paciente que pode receber a entrega agora (id do CSV): a do
## atendimento em andamento, só depois que a apotecária pediu os ingredientes.
var current_condition: String:
	get:
		return GameState.attendance.delivery_condition()

var _rng := RandomNumberGenerator.new()
## O que fazer quando a conversa atual terminar (recebe o id da escolha).
var _after_dialogue := Callable()
## Se a última entrega deixou sobras na mochila (para decidir depois da conversa).
var _surplus_left := false
var _patient_tween: Tween = null

@onready var _player: Player = $World/Player
@onready var _patient: Node2D = $World/Patient
@onready var _patient_point: InteractionArea = $Interactions/Patient
@onready var _region_menu: RegionMenu = $RegionMenu
@onready var _stock_menu: StockMenu = $StockMenu
@onready var _backpack_menu: BackpackMenu = $BackpackMenu
@onready var _dialogue_box: DialogueBox = $DialogueBox


func _ready() -> void:
	_rng.randomize()
	# A cabana sempre abre explorando, mesmo que a cena anterior tenha saído
	# com um menu aberto.
	GameState.flow.reset()
	Music.play(Music.CABIN)
	_player.set_camera_limits(ROOM)
	for area: InteractionArea in $Interactions.get_children():
		area.interacted.connect(_on_interacted)
	_region_menu.region_selected.connect(_on_region_selected)
	_region_menu.closed.connect(_close_menu)
	_stock_menu.closed.connect(_close_menu)
	_backpack_menu.hearts = _player.hearts
	_backpack_menu.show_messages = false
	_backpack_menu.closed.connect(_on_backpack_menu_closed)
	_backpack_menu.delivered.connect(_on_delivered)
	_backpack_menu.delivery_completed.connect(_on_delivery_completed)
	_dialogue_box.finished.connect(_on_dialogue_finished)
	_restore_patient()
	if GameState.attendance.needs_intro():
		_play([Attendance.INTRO], _on_intro_finished)
	else:
		_call_next_patient()


## Ao sair da cena (troca de cena), o jogo volta a explorar: a próxima cena não
## herda um diálogo ou menu que ficou aberto.
func _exit_tree() -> void:
	GameState.flow.reset()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("backpack") and GameState.flow.can_player_act():
		open_backpack()
		get_viewport().set_input_as_handled()


## Se há uma conversa na tela.
func is_in_dialogue() -> bool:
	return _dialogue_box.is_open()


## O paciente (o nó que aparece na cabana), para os testes.
func get_patient() -> Node2D:
	return _patient


## Abre a mochila. Depois que a apotecária pediu os ingredientes, ela também
## entrega (estado de entrega); antes disso, só mostra o conteúdo (menu).
func open_backpack() -> void:
	var condition := current_condition
	var state := GameFlow.State.DELIVERY if not condition.is_empty() else GameFlow.State.MENU
	if not GameState.flow.request(state):
		return
	_backpack_menu.open(condition)


func _on_interacted(id: StringName) -> void:
	interacted.emit(id)
	match id:
		&"door":
			if GameState.flow.open_menu():
				_region_menu.open()
		&"stock":
			if GameState.flow.open_menu():
				_stock_menu.open()
		&"apothecary":
			_talk_to_apothecary()
		&"patient":
			_play(GameState.attendance.talk_to_patient(), _back_to_exploration)


func _talk_to_apothecary() -> void:
	if GameState.attendance.can_deliver():
		open_backpack()
	else:
		_play(GameState.attendance.talk_to_apothecary(), _back_to_exploration)


## A região escolhida sempre começa no andar 1. A mochila e o estoque seguem
## como estavam.
func _on_region_selected(region: String) -> void:
	GameState.start_region(region)
	get_tree().change_scene_to_file(ScenePaths.FLOOR)


func _close_menu() -> void:
	GameState.flow.close_menu()


func _on_backpack_menu_closed() -> void:
	if GameState.flow.is_in(GameFlow.State.DELIVERY):
		GameState.flow.request(GameFlow.State.EXPLORATION)
	else:
		GameState.flow.close_menu()


## Cada entrega vira conversa: mochila vazia, sobras, o que ainda falta ou, com
## tudo entregue, a orientação e o agradecimento. A mochila fica aberta embaixo
## e volta a responder quando a conversa termina.
func _on_delivered(result: DeliveryResult) -> void:
	var attendance := GameState.attendance
	var topics := attendance.delivery_topics(
		result.outcome, not result.stored.is_empty(), not result.surplus.is_empty()
	)
	var values := {"missing": result.missing_text()}
	_surplus_left = not result.surplus.is_empty()
	if result.outcome == Delivery.Outcome.COMPLETE:
		_play(topics, _on_attendance_concluded, values)
	else:
		_play(topics, _back_to_delivery, values)


## A entrega cobriu a condição. Quem marca o atendimento como concluído é o fim
## do agradecimento (`_on_attendance_concluded`).
func _on_delivery_completed(condition: String) -> void:
	delivery_completed.emit(condition)


func _on_intro_finished(_choice: String) -> void:
	GameState.attendance.finish_intro()
	_back_to_exploration()
	_call_next_patient()


## O paciente agradeceu: o atendimento está concluído e ele vai embora. Com
## sobras, a mochila continua aberta para decidir o que fazer com elas; sem
## sobras, ela fecha. O paciente sai quando o jogo volta a rodar.
func _on_attendance_concluded(_choice: String) -> void:
	var condition := GameState.attendance.conclude()
	GameState.patients.mark_attended(condition)
	_patient_point.enabled = false
	_back_to_delivery()
	if not _surplus_left:
		_backpack_menu.close()
	_walk_patient_out(condition)


func _on_ending_choice(choice: String) -> void:
	if choice == Attendance.CHOICE_GO_HOME:
		_play([Attendance.ENDING_GO_HOME], _on_going_home)
	else:
		_play([Attendance.ENDING_KEEP_HELPING], _on_keep_helping)


## Fim da campanha: Mingau atravessa o portal. A tela de fim vem com a #40; por
## enquanto o jogo volta ao menu inicial.
func _on_going_home(_choice: String) -> void:
	GameState.flow.request(GameFlow.State.COMPLETION)
	# O jogo está congelado na conclusão; a espera roda mesmo assim e some junto
	# com a cabana.
	var wait := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	wait.tween_interval(ending_seconds)
	wait.tween_callback(get_tree().change_scene_to_file.bind(ScenePaths.MENU))


func _on_keep_helping(_choice: String) -> void:
	GameState.attendance.start_continuous()
	_back_to_exploration()
	_call_next_patient()


## Toca as conversas dos tópicos, em sequência, e chama `after` com o id da
## escolha quando terminarem. Sem tópico nenhum, não faz nada.
func _play(topics: Array[String], after: Callable, values: Dictionary = {}) -> void:
	var condition := GameState.attendance.condition
	var lines: Array[DialogueLine] = []
	for topic in topics:
		lines.append_array(DialogueData.get_lines(topic, condition))
	if lines.is_empty():
		return
	if not GameState.flow.is_in(GameFlow.State.DIALOGUE):
		if not GameState.flow.request(GameFlow.State.DIALOGUE):
			return
	_after_dialogue = after
	_dialogue_box.play(lines, values)


func _on_dialogue_finished(choice: String) -> void:
	var after := _after_dialogue
	_after_dialogue = Callable()
	if after.is_valid():
		after.call(choice)
	else:
		_back_to_exploration()


func _back_to_exploration(_choice: String = "") -> void:
	GameState.flow.request(GameFlow.State.EXPLORATION)


func _back_to_delivery(_choice: String = "") -> void:
	GameState.flow.request(GameFlow.State.DELIVERY)


## Chama o próximo paciente, se a cabana está vazia. Depois do último da
## campanha, toca o encerramento.
func _call_next_patient() -> void:
	var attendance := GameState.attendance
	if attendance.phase != Attendance.Phase.NONE:
		return
	if attendance.is_ending_due(GameState.patients):
		_play([Attendance.ENDING], _on_ending_choice)
		return
	var condition := attendance.next_condition(GameState.patients, _rng)
	if condition.is_empty():
		return
	attendance.arrive(condition)
	_walk_patient_in(condition)


## Ao abrir a cena, mostra o paciente que já estava esperando. Um paciente que
## estava saindo quando o Mingau deixou a cabana já foi embora.
func _restore_patient() -> void:
	var attendance := GameState.attendance
	if attendance.phase == Attendance.Phase.LEAVING:
		attendance.patient_left()
	_patient.visible = attendance.has_patient()
	_patient.position = PATIENT_PATH[-1]
	_patient_point.enabled = attendance.has_patient()


func _walk_patient_in(condition: String) -> void:
	_patient.position = PATIENT_PATH[0]
	_patient.visible = true
	_patient_point.enabled = false
	_walk(PATIENT_PATH, _on_patient_arrived.bind(condition))


func _on_patient_arrived(condition: String) -> void:
	_patient_point.enabled = GameState.attendance.has_patient()
	patient_arrived.emit(condition)


func _walk_patient_out(condition: String) -> void:
	var path := PATIENT_PATH.duplicate()
	path.reverse()
	_walk(path, _on_patient_left.bind(condition))


func _on_patient_left(condition: String) -> void:
	_patient.visible = false
	GameState.attendance.patient_left()
	patient_left.emit(condition)
	_call_next_patient()


## Leva o paciente pelos pontos do caminho. A caminhada para junto com o jogo
## (diálogo, menus) e continua quando ele volta a rodar.
func _walk(path: Array, on_done: Callable) -> void:
	if _patient_tween != null:
		_patient_tween.kill()
	if not animate_patient:
		_patient.position = path[-1]
		on_done.call()
		return
	_patient.position = path[0]
	_patient_tween = create_tween()
	for i in range(1, path.size()):
		var distance: float = (path[i] as Vector2).distance_to(path[i - 1])
		_patient_tween.tween_property(_patient, "position", path[i], distance / PATIENT_SPEED)
	_patient_tween.tween_callback(on_done)
