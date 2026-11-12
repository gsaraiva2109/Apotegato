extends Node
## Teclas do jogo que o jogador pode trocar. Cada ação mapeável (andar, atacar,
## interagir, mochila e diário) tem duas teclas, a principal e a alternativa;
## nas de andar, as setas e o WASD. As escolhas ficam em `user://settings.cfg`
## (seção `[input]`) e são aplicadas ao Input Map ao abrir o jogo. Pausa (Esc),
## tela cheia (F11) e escala (F10) não são mapeáveis, e uma tecla só pode servir
## a uma ação.
##
## É o único script do jogo que lê eventos de tecla, porque remapear exige isso
## (ver a exceção em `tests/test_input_map.gd`); o resto usa só nomes de ação.
##
## Com o jogo sem janela (testes e CI em modo headless) as escolhas salvas não
## mexem no Input Map, para o teste do Input Map ver sempre as teclas padrão.
##
## Registrado como autoload "InputSettings".

## Emitido quando alguma tecla muda (ou volta ao padrão).
signal bindings_changed

## Resultado de `set_key`.
enum Result { OK, RESERVED_KEY, TAKEN, INVALID }

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "input"
## Teclas por ação: a principal (0) e a alternativa (1).
const SLOTS := 2
## Ações mapeáveis, na ordem em que aparecem na tela.
const REMAPPABLE: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"attack",
	&"interact",
	&"backpack",
	&"journal",
]
## Ações com tecla fixa: nenhuma tecla delas pode ser usada em outra ação.
const RESERVED: Array[StringName] = [&"pause", &"toggle_fullscreen", &"toggle_scale_mode"]
const ACTION_LABELS := {
	&"move_up": "Mover: cima",
	&"move_down": "Mover: baixo",
	&"move_left": "Mover: esquerda",
	&"move_right": "Mover: direita",
	&"attack": "Arranhar",
	&"interact": "Interagir",
	&"backpack": "Mochila",
	&"journal": "Diário",
	&"pause": "Pausa",
	&"toggle_fullscreen": "Tela cheia",
	&"toggle_scale_mode": "Escala da tela",
}
## Nomes em português das teclas que o Godot nomeia em inglês.
const KEY_LABELS := {
	KEY_UP: "Seta cima",
	KEY_DOWN: "Seta baixo",
	KEY_LEFT: "Seta esquerda",
	KEY_RIGHT: "Seta direita",
	KEY_SPACE: "Espaço",
	KEY_ENTER: "Enter",
	KEY_KP_ENTER: "Enter (num.)",
	KEY_TAB: "Tab",
	KEY_BACKSPACE: "Backspace",
	KEY_SHIFT: "Shift",
	KEY_CTRL: "Ctrl",
	KEY_ALT: "Alt",
	KEY_ESCAPE: "Esc",
	KEY_DELETE: "Delete",
}
## Arquivo de opções lido e gravado. Só muda nos testes.
var settings_path := SETTINGS_PATH
## Se as escolhas são aplicadas ao Input Map (desligado sem janela).
var applies_to_input_map := DisplayServer.get_name() != "headless"
## Ação -> teclas físicas (`SLOTS` valores, 0 = vazio).
var bindings := {}

var _defaults := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture_defaults()
	load_settings()
	apply()


## Teclas padrão do project.godot de cada ação mapeável.
func capture_defaults() -> void:
	_capture_defaults()


## Tecla física (código) na posição `slot` da ação; 0 se vazia.
func key_in_slot(action: StringName, slot: int) -> int:
	return bindings[action][slot]


## Nome para mostrar de uma tecla física ("W", "Seta cima", "Espaço"); "Vazio"
## para 0.
func key_label(keycode: int) -> String:
	if keycode == 0:
		return "Vazio"
	if KEY_LABELS.has(keycode):
		return KEY_LABELS[keycode]
	return OS.get_keycode_string(keycode)


## Se o evento é o apertar de uma tecla (sem repetição).
static func is_key_press(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo


## Esc: cancela a escolha de uma tecla nova.
static func is_cancel_key(keycode: int) -> bool:
	return keycode == KEY_ESCAPE


## Delete: limpa a tecla alternativa.
static func is_clear_key(keycode: int) -> bool:
	return keycode == KEY_DELETE


## Código da tecla física de um evento de tecla.
static func keycode_of(event: InputEvent) -> int:
	var key := event as InputEventKey
	return key.physical_keycode if key.physical_keycode != 0 else key.keycode


## Nome da ação (mapeável ou fixa) que já usa a tecla, ou "" se está livre.
## Ignora a posição `slot` da própria ação, onde a tecla vai entrar.
func owner_of(keycode: int, action: StringName = &"", slot: int = -1) -> StringName:
	for other in REMAPPABLE:
		for i in SLOTS:
			if other == action and i == slot:
				continue
			if bindings[other][i] == keycode:
				return other
	for reserved in RESERVED:
		for event in InputMap.action_get_events(reserved):
			if event is InputEventKey and event.physical_keycode == keycode:
				return reserved
	return &""


## Troca a tecla da posição `slot` da ação. Recusa tecla de ação fixa, tecla já
## usada por outra posição e código inválido. Aplica ao Input Map e salva.
func set_key(action: StringName, slot: int, keycode: int) -> Result:
	if not action in REMAPPABLE or slot < 0 or slot >= SLOTS or keycode <= 0:
		return Result.INVALID
	var owner := owner_of(keycode, action, slot)
	if owner != &"":
		return Result.RESERVED_KEY if owner in RESERVED else Result.TAKEN
	bindings[action][slot] = keycode
	_commit()
	return Result.OK


## Esvazia a posição. Só vale para a alternativa se a ação ficar com ao menos uma
## tecla; devolve false se recusou.
func clear_slot(action: StringName, slot: int) -> bool:
	if not action in REMAPPABLE or slot < 0 or slot >= SLOTS:
		return false
	var remaining := 0
	for i in SLOTS:
		if i != slot and bindings[action][i] != 0:
			remaining += 1
	if remaining == 0:
		return false
	bindings[action][slot] = 0
	_commit()
	return true


## Volta todas as teclas ao padrão e salva.
func reset_to_defaults() -> void:
	for action in REMAPPABLE:
		bindings[action] = (_defaults[action] as Array).duplicate()
	_commit()


## Se a ação está com as teclas padrão.
func is_default(action: StringName) -> bool:
	return bindings[action] == _defaults[action]


## Aplica as teclas ao Input Map (substitui os eventos de tecla de cada ação).
func apply() -> void:
	if not applies_to_input_map:
		return
	for action in REMAPPABLE:
		InputMap.action_erase_events(action)
		for keycode: int in bindings[action]:
			if keycode != 0:
				var event := InputEventKey.new()
				event.physical_keycode = keycode as Key
				InputMap.action_add_event(action, event)


## Lê as teclas salvas. Sem arquivo ou com valor inválido, vale o padrão.
func load_settings() -> void:
	for action in REMAPPABLE:
		bindings[action] = (_defaults[action] as Array).duplicate()
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var seen := {}
	for action in REMAPPABLE:
		if not config.has_section_key(SECTION, String(action)):
			continue
		var saved: Variant = config.get_value(SECTION, String(action))
		if not saved is Array or saved.size() != SLOTS:
			continue
		var codes: Array = []
		for value in saved:
			codes.append(int(value))
		if _valid(codes, seen):
			bindings[action] = codes
			for code: int in codes:
				if code != 0:
					seen[code] = true


## Grava as teclas, mantendo as outras seções do arquivo.
func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	for action in REMAPPABLE:
		config.set_value(SECTION, String(action), bindings[action])
	config.save(settings_path)


func _capture_defaults() -> void:
	_defaults.clear()
	for action in REMAPPABLE:
		var codes: Array = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and codes.size() < SLOTS:
				codes.append(event.physical_keycode)
		while codes.size() < SLOTS:
			codes.append(0)
		_defaults[action] = codes
		bindings[action] = codes.duplicate()


## Uma ação salva vale se tem ao menos uma tecla, sem repetir tecla já salva em
## outra ação nem tecla de ação fixa.
func _valid(codes: Array, seen: Dictionary) -> bool:
	if codes.all(func(code: int) -> bool: return code == 0):
		return false
	for code: int in codes:
		if code < 0 or (code != 0 and (seen.has(code) or owner_of(code, &"", -1) in RESERVED)):
			return false
	return not (codes[0] != 0 and codes[0] == codes[1])


func _commit() -> void:
	apply()
	save_settings()
	bindings_changed.emit()
