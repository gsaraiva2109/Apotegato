class_name SaveGame
extends RefCounted
## Arquivo local da campanha. O ponto de retomada é sempre a cabana.

const PATH := "user://save.json"
const VERSION := 1
## Maior inteiro que o JSON do Godot consegue ler sem perder precisão.
const MAX_EXACT_INTEGER := 9007199254740991


static func write(path: String, hearts: int) -> Error:
	var backpack := {}
	for id in GameState.backpack.ids():
		backpack[id] = GameState.backpack.count(id)
	var stock := {}
	for id in GameState.stock.ids():
		stock[id] = GameState.stock.count(id)
	var attendance := GameState.attendance
	var data := {
		"versao": VERSION,
		"hearts": hearts,
		"backpack": backpack,
		"stock": stock,
		"attended": GameState.patients.attended(),
		"attendance":
		{
			"intro_done": attendance.intro_done,
			"condition": attendance.condition,
			"phase": attendance.phase,
			"continuous": attendance.continuous,
			"last_condition": attendance.last_condition,
		},
	}
	# O arquivo anterior só é substituído depois que o novo for gravado.
	var temporary_path := path + ".tmp"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "", false))
	file.flush()
	var result := file.get_error()
	file.close()
	if result == OK:
		result = DirAccess.rename_absolute(temporary_path, path)
	if result != OK:
		DirAccess.remove_absolute(temporary_path)
	return result


## Arquivo ausente, inválido ou de versão desconhecida devolve um dicionário vazio.
static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data: Variant = json.data
	if not data is Dictionary:
		return {}
	var conditions := IngredientData.get_conditions()
	if (
		not _is_integer(data.get("versao"), VERSION, VERSION)
		or not _is_integer(data.get("hearts"), 1, Hearts.MAX)
		or not _valid_items(data.get("backpack"), Backpack.MAX_SLOTS)
		or not _valid_items(data.get("stock"))
		or not _valid_attended(data.get("attended"), conditions)
		or not _valid_attendance(data.get("attendance"), conditions)
	):
		return {}
	return data


## Valida tudo antes de alterar a campanha em memória.
static func restore(path: String) -> bool:
	var data := read(path)
	if data.is_empty():
		return false
	GameState.new_game()
	# A validação já garantiu IDs, quantidades e espaço para todos os itens.
	for id: String in data["backpack"]:
		GameState.backpack.add(id, int(data["backpack"][id]))
	for id: String in data["stock"]:
		GameState.stock.store(id, int(data["stock"][id]))
	for condition: String in data["attended"]:
		GameState.patients.mark_attended(condition)
	var saved_attendance: Dictionary = data["attendance"]
	var attendance := GameState.attendance
	attendance.intro_done = saved_attendance["intro_done"]
	attendance.condition = saved_attendance["condition"]
	attendance.phase = int(saved_attendance["phase"]) as Attendance.Phase
	attendance.continuous = saved_attendance["continuous"]
	attendance.last_condition = saved_attendance["last_condition"]
	attendance.changed.emit()
	GameState.cabin_entry_hearts = int(data["hearts"])
	return true


static func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float):
		return false
	return value >= minimum and value <= maximum and value == floor(value)


static func _valid_items(items: Variant, max_slots: int = -1) -> bool:
	if not items is Dictionary or (max_slots >= 0 and items.size() > max_slots):
		return false
	for id: Variant in items:
		if not id is String or IngredientData.get_ingredient(id) == null:
			return false
		if not _is_integer(items[id], 1, MAX_EXACT_INTEGER):
			return false
	return true


static func _valid_attended(attended: Variant, conditions: Array[String]) -> bool:
	if not attended is Array:
		return false
	var seen := {}
	for condition: Variant in attended:
		if not condition is String or condition not in conditions or seen.has(condition):
			return false
		seen[condition] = true
	return true


static func _valid_attendance(attendance: Variant, conditions: Array[String]) -> bool:
	if not attendance is Dictionary:
		return false
	var phase: Variant = attendance.get("phase")
	var condition: Variant = attendance.get("condition")
	var last_condition: Variant = attendance.get("last_condition")
	if (
		not attendance.get("intro_done") is bool
		or not attendance.get("continuous") is bool
		or not _is_integer(phase, -MAX_EXACT_INTEGER, MAX_EXACT_INTEGER)
		or int(phase) not in Attendance.Phase.values()
		or not condition is String
		or not last_condition is String
		or (last_condition != "" and last_condition not in conditions)
	):
		return false
	return condition == "" if int(phase) == Attendance.Phase.NONE else condition in conditions
