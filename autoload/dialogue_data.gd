extends Node
## Fonte única das falas do jogo. Lê uma vez, ao iniciar:
## - `data/dialogos.json`: conversas gerais (introdução, lembrete, entrega,
##   encerramento), por id;
## - `data/atendimentos.json`: as quatro partes do atendimento de cada condição
##   (`complaint`, `request`, `guidance`, `thanks`);
## - `data/elenco.csv`: o nome de cada paciente, mostrado quando ele fala.
##
## Registrado como autoload "DialogueData". Nenhum outro script abre esses
## arquivos.

const DIALOGUES_PATH := "res://data/dialogos.json"
const TREATMENTS_PATH := "res://data/atendimentos.json"
const CAST_PATH := "res://data/elenco.csv"

const SPEAKER_APOTHECARY := "apothecary"
const SPEAKER_MINGAU := "mingau"
const SPEAKER_PATIENT := "patient"
const SPEAKERS := [SPEAKER_APOTHECARY, SPEAKER_MINGAU, SPEAKER_PATIENT]

## Nome mostrado para cada falante. O do paciente vem do elenco; este é o reserva.
const SPEAKER_NAMES := {
	SPEAKER_APOTHECARY: "Apotecária",
	SPEAKER_MINGAU: "Mingau",
	SPEAKER_PATIENT: "Paciente",
}

## Partes do atendimento de cada condição.
const CONDITION_PARTS := ["complaint", "request", "guidance", "thanks"]

## Texto mostrado quando falta a fala pedida, para o jogo não travar.
const MISSING_TEXT := "..."

## id da conversa -> Array de falas (Dictionary do JSON).
var _conversations: Dictionary = {}
## id da condição -> {parte -> Array de falas}.
var _conditions: Dictionary = {}
## id da condição -> nome do paciente.
var _patient_names: Dictionary = {}


func _ready() -> void:
	load_files(DIALOGUES_PATH, TREATMENTS_PATH, CAST_PATH)


## Lê os três arquivos e substitui o que estava carregado. Avisa (sem parar o
## jogo) se algum não abrir.
func load_files(dialogues_path: String, treatments_path: String, cast_path: String) -> void:
	_conversations = _read_json(dialogues_path).get("conversations", {})
	_conditions = _read_json(treatments_path).get("conditions", {})
	_patient_names = _read_cast(cast_path)


## Ids das conversas gerais carregadas.
func get_conversation_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_conversations.keys())
	return ids


func has_conversation(id: String) -> bool:
	return _conversations.has(id)


## Falas de uma conversa geral. `condition` só decide o nome do paciente, se
## ele falar.
func get_conversation(id: String, condition: String = "") -> Array[DialogueLine]:
	if not _conversations.has(id):
		push_warning("DialogueData: conversa desconhecida: %s" % id)
		return _fallback()
	return _to_lines(_conversations[id], condition)


func has_condition_part(condition: String, part: String) -> bool:
	return _conditions.has(condition) and _conditions[condition].has(part)


## Falas de uma parte do atendimento ("complaint", "request", "guidance" ou
## "thanks") da condição.
func get_condition_part(condition: String, part: String) -> Array[DialogueLine]:
	if not has_condition_part(condition, part):
		push_warning("DialogueData: sem falas de %s para %s" % [part, condition])
		return _fallback()
	return _to_lines(_conditions[condition][part], condition)


## Falas de um tópico do atendimento (`Attendance`): uma parte da condição ou
## uma conversa geral.
func get_lines(topic: String, condition: String = "") -> Array[DialogueLine]:
	if topic in CONDITION_PARTS:
		return get_condition_part(condition, topic)
	return get_conversation(topic, condition)


## Nome mostrado para quem fala. O paciente aparece com o nome do elenco da
## condição; sem elenco, "Paciente".
func speaker_name(speaker: String, condition: String = "") -> String:
	if speaker == SPEAKER_PATIENT and _patient_names.has(condition):
		return _patient_names[condition]
	return SPEAKER_NAMES.get(speaker, speaker)


func _to_lines(raw_lines: Array, condition: String) -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	for raw: Dictionary in raw_lines:
		var speaker: String = raw.get("speaker", "")
		var choices: Array[Dictionary] = []
		for choice: Dictionary in raw.get("choices", []):
			choices.append({"id": str(choice.get("id", "")), "text": str(choice.get("text", ""))})
		lines.append(
			DialogueLine.new(
				speaker, speaker_name(speaker, condition), str(raw.get("text", "")), choices
			)
		)
	return lines


func _fallback() -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = [DialogueLine.new("", "", MISSING_TEXT)]
	return lines


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueData: não foi possível abrir %s" % path)
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is not Dictionary:
		push_error("DialogueData: JSON inválido em %s" % path)
		return {}
	return data


## Elenco: id, nome, condicao, descricao. A apotecária não tem condição e fica de
## fora (o nome dela na caixa é sempre "Apotecária").
func _read_cast(path: String) -> Dictionary:
	var names := {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("DialogueData: não foi possível abrir %s" % path)
		return names
	file.get_csv_line()
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 3:
			continue
		if not row[2].strip_edges().is_empty():
			names[row[2]] = row[1]
	return names
