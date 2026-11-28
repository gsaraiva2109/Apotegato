extends Node
## Teclas e botões de controle do jogo que o jogador pode trocar. Cada ação
## mapeável (andar, atacar, interagir, mochila e diário) tem duas teclas, a
## principal e a alternativa; nas de andar, as setas e o WASD. As ações de botão
## (arranhar, interagir, mochila e diário) também têm um botão de controle. Andar
## usa o analógico esquerdo e o direcional, que são fixos, assim como Start
## (pausa) e B (voltar). As escolhas ficam em `user://settings.cfg` (seção
## `[input]`) e são aplicadas ao Input Map ao abrir o jogo. Pausa (Esc), tela
## cheia (F11) e escala (F10) não são mapeáveis, e uma tecla ou um botão só pode
## servir a uma ação.
##
## Também acompanha o último aparelho usado (teclado ou controle), para as dicas
## na tela mostrarem a tecla ou o botão certo.
##
## É o único script do jogo que lê eventos de tecla, porque remapear exige isso
## (ver a exceção em `tests/test_input_map.gd`); o resto usa só nomes de ação.
##
## Com o jogo sem janela (testes e CI em modo headless) as escolhas salvas não
## mexem no Input Map, para o teste do Input Map ver sempre as teclas padrão.
##
## Registrado como autoload "InputSettings".

## Emitido quando alguma tecla ou botão muda (ou volta ao padrão).
signal bindings_changed
## Emitido quando o jogador passa a usar outro aparelho (teclado ou controle).
signal device_changed

## Resultado de `set_key` e `set_pad_button`.
enum Result { OK, RESERVED_KEY, TAKEN, INVALID }
## Aparelho que o jogador usou por último.
enum Device { KEYBOARD, GAMEPAD }
## Desenho dos botões do controle, para os nomes nas dicas.
enum PadStyle { XBOX, PLAYSTATION }

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "input"
## Teclas por ação: a principal (0) e a alternativa (1).
const SLOTS := 2
## Prefixo da chave do botão de controle no arquivo (`pad_attack`).
const PAD_KEY_PREFIX := "pad_"
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
## Ações que também têm um botão de controle trocável (as de andar usam o
## analógico e o direcional, fixos).
const PAD_REMAPPABLE: Array[StringName] = [&"attack", &"interact", &"backpack", &"journal"]
## Botões fixos do controle e a ação que usa cada um. Não podem ser dados a
## outra ação.
const PAD_RESERVED := {
	JOY_BUTTON_B: &"ui_cancel",
	JOY_BUTTON_GUIDE: &"pause",
	JOY_BUTTON_START: &"pause",
	JOY_BUTTON_DPAD_UP: &"move_up",
	JOY_BUTTON_DPAD_DOWN: &"move_down",
	JOY_BUTTON_DPAD_LEFT: &"move_left",
	JOY_BUTTON_DPAD_RIGHT: &"move_right",
}
## Eixo do analógico esquerdo: a partir daqui o jogador conta como usando o
## controle.
const STICK_THRESHOLD := 0.5
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
	&"ui_cancel": "Voltar",
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
## Nomes dos botões do controle no desenho do Xbox (os do Godot seguem esse
## layout: A embaixo, B à direita, X à esquerda, Y em cima).
const PAD_LABELS_XBOX := {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Select",
	JOY_BUTTON_GUIDE: "Guia",
	JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad cima",
	JOY_BUTTON_DPAD_DOWN: "D-pad baixo",
	JOY_BUTTON_DPAD_LEFT: "D-pad esquerda",
	JOY_BUTTON_DPAD_RIGHT: "D-pad direita",
}
## Nomes dos botões do controle no desenho do PlayStation.
const PAD_LABELS_PLAYSTATION := {
	JOY_BUTTON_A: "Cruz",
	JOY_BUTTON_B: "Círculo",
	JOY_BUTTON_X: "Quadrado",
	JOY_BUTTON_Y: "Triângulo",
	JOY_BUTTON_BACK: "Share",
	JOY_BUTTON_GUIDE: "PS",
	JOY_BUTTON_START: "Options",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "L1",
	JOY_BUTTON_RIGHT_SHOULDER: "R1",
	JOY_BUTTON_DPAD_UP: "D-pad cima",
	JOY_BUTTON_DPAD_DOWN: "D-pad baixo",
	JOY_BUTTON_DPAD_LEFT: "D-pad esquerda",
	JOY_BUTTON_DPAD_RIGHT: "D-pad direita",
}
## Trechos (em minúsculas) do nome do controle que indicam desenho PlayStation.
const PLAYSTATION_NAMES: Array[String] = [
	"playstation", "ps3", "ps4", "ps5", "dualshock", "dualsense", "sony"
]
## Arquivo de opções lido e gravado. Só muda nos testes.
var settings_path := SETTINGS_PATH
## Se as escolhas são aplicadas ao Input Map (desligado sem janela).
var applies_to_input_map := DisplayServer.get_name() != "headless"
## Ação -> teclas físicas (`SLOTS` valores, 0 = vazio).
var bindings := {}
## Ação -> botão do controle (índice do `JoyButton`; -1 = sem botão). Só as
## ações de `PAD_REMAPPABLE`.
var pad_bindings := {}
## Aparelho usado por último. O jogo começa no teclado.
var device := Device.KEYBOARD
## Desenho do último controle usado.
var pad_style := PadStyle.XBOX

var _defaults := {}
var _pad_defaults := {}
## Ação -> eventos de controle fixos (analógico e direcional), que o `apply`
## devolve ao Input Map depois de apagar os eventos da ação.
var _fixed_events := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture_defaults()
	load_settings()
	apply()


## Teclas e botões padrão do project.godot de cada ação mapeável.
func capture_defaults() -> void:
	_capture_defaults()


## Acompanha o aparelho usado: apertar botão ou empurrar o analógico passa para o
## controle; apertar tecla ou clicar passa para o teclado e o mouse.
func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_use_device(Device.GAMEPAD, event.device)
	elif event is InputEventJoypadMotion and absf(event.axis_value) >= STICK_THRESHOLD:
		_use_device(Device.GAMEPAD, event.device)
	elif is_key_press(event) or (event is InputEventMouseButton and event.pressed):
		_use_device(Device.KEYBOARD, -1)


## Passa a considerar o aparelho como o último usado. Para o controle, `joy_id` é
## o aparelho, de onde sai o desenho dos botões.
func _use_device(new_device: Device, joy_id: int) -> void:
	var changed := new_device != device
	if new_device == Device.GAMEPAD:
		var style := style_from_name(Input.get_joy_name(joy_id))
		changed = changed or style != pad_style
		pad_style = style
	device = new_device
	if changed:
		device_changed.emit()


## Desenho dos botões de um controle, pelo nome que o sistema dá a ele.
static func style_from_name(joy_name: String) -> PadStyle:
	var lowered := joy_name.to_lower()
	for part in PLAYSTATION_NAMES:
		if part in lowered:
			return PadStyle.PLAYSTATION
	return PadStyle.XBOX


## Botão do controle da ação (índice do `JoyButton`): o trocável das ações de
## botão, Start na pausa e -1 nas demais.
func pad_button_of(action: StringName) -> int:
	if pad_bindings.has(action):
		return pad_bindings[action]
	if action == &"pause":
		return JOY_BUTTON_START
	return -1


## Nome do botão do controle ("A", "RB", "Cruz"), no desenho do último controle.
func pad_label(button: int) -> String:
	var labels := PAD_LABELS_PLAYSTATION if pad_style == PadStyle.PLAYSTATION else PAD_LABELS_XBOX
	return labels.get(button, "Botão %d" % button)


## Texto da dica de uma ação: o botão do controle se o jogador usa o controle e a
## ação tem botão, senão a tecla principal. "" se a ação não tem nenhum dos dois.
func prompt_text(action: StringName) -> String:
	if device == Device.GAMEPAD and pad_button_of(action) >= 0:
		return pad_label(pad_button_of(action))
	var code := _first_key(action)
	return key_label(code) if code != 0 else ""


## Botão do controle de um evento de botão.
static func is_pad_press(event: InputEvent) -> bool:
	return event is InputEventJoypadButton and event.pressed


## Índice do botão de um evento de botão do controle.
static func button_of(event: InputEvent) -> int:
	return (event as InputEventJoypadButton).button_index


## Nome da ação que já usa o botão (outra ação de botão ou um botão fixo), ou ""
## se está livre. Ignora a própria `action`.
func pad_owner_of(button: int, action: StringName = &"") -> StringName:
	if PAD_RESERVED.has(button):
		return PAD_RESERVED[button]
	for other in PAD_REMAPPABLE:
		if other != action and pad_bindings[other] == button:
			return other
	return &""


## Troca o botão do controle da ação. Recusa botão fixo (B, Start, direcional),
## botão já usado por outra ação e índice inválido. Aplica ao Input Map e salva.
func set_pad_button(action: StringName, button: int) -> Result:
	if not action in PAD_REMAPPABLE or button < 0 or button >= JOY_BUTTON_SDL_MAX:
		return Result.INVALID
	var holder := pad_owner_of(button, action)
	if holder != &"":
		return Result.RESERVED_KEY if PAD_RESERVED.has(button) else Result.TAKEN
	pad_bindings[action] = button
	_commit()
	return Result.OK


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
	var holder := owner_of(keycode, action, slot)
	if holder != &"":
		return Result.RESERVED_KEY if holder in RESERVED else Result.TAKEN
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
	pad_bindings = _pad_defaults.duplicate()
	_commit()


## Se a ação está com as teclas padrão.
func is_default(action: StringName) -> bool:
	if pad_bindings.has(action) and pad_bindings[action] != _pad_defaults[action]:
		return false
	return bindings[action] == _defaults[action]


## Aplica as teclas e os botões ao Input Map (refaz os eventos de cada ação,
## mantendo o analógico e o direcional das ações de andar).
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
		for fixed: InputEvent in _fixed_events.get(action, []):
			InputMap.action_add_event(action, fixed.duplicate())
		if pad_bindings.has(action) and pad_bindings[action] >= 0:
			var pad_event := InputEventJoypadButton.new()
			pad_event.button_index = pad_bindings[action] as JoyButton
			InputMap.action_add_event(action, pad_event)


## Lê as teclas salvas. Sem arquivo ou com valor inválido, vale o padrão.
func load_settings() -> void:
	for action in REMAPPABLE:
		bindings[action] = (_defaults[action] as Array).duplicate()
	pad_bindings = _pad_defaults.duplicate()
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
	_load_pad_settings(config)


## Grava as teclas, mantendo as outras seções do arquivo.
func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	for action in REMAPPABLE:
		config.set_value(SECTION, String(action), bindings[action])
	for action in PAD_REMAPPABLE:
		config.set_value(SECTION, PAD_KEY_PREFIX + String(action), pad_bindings[action])
	config.save(settings_path)


func _capture_defaults() -> void:
	_defaults.clear()
	_pad_defaults.clear()
	_fixed_events.clear()
	pad_bindings.clear()
	for action in REMAPPABLE:
		var codes: Array = []
		var fixed: Array[InputEvent] = []
		var pad_button := -1
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				if codes.size() < SLOTS:
					codes.append(event.physical_keycode)
			elif event is InputEventJoypadButton and action in PAD_REMAPPABLE:
				if pad_button < 0:
					pad_button = event.button_index
			else:
				fixed.append(event.duplicate())
		while codes.size() < SLOTS:
			codes.append(0)
		_defaults[action] = codes
		bindings[action] = codes.duplicate()
		_fixed_events[action] = fixed
		if action in PAD_REMAPPABLE:
			_pad_defaults[action] = pad_button
			pad_bindings[action] = pad_button


## Lê os botões de controle salvos. Um botão salvo vale se é um índice válido, não
## é fixo e não repete o de outra ação; senão, vale o padrão.
func _load_pad_settings(config: ConfigFile) -> void:
	var seen := {}
	for action in PAD_REMAPPABLE:
		var key := PAD_KEY_PREFIX + String(action)
		if not config.has_section_key(SECTION, key):
			continue
		var saved: Variant = config.get_value(SECTION, key)
		if not (saved is int or saved is float):
			continue
		var button := int(saved)
		if (
			button < 0
			or button >= JOY_BUTTON_SDL_MAX
			or PAD_RESERVED.has(button)
			or seen.has(button)
		):
			continue
		pad_bindings[action] = button
		seen[button] = true
	var used := {}
	for action in PAD_REMAPPABLE:
		var button: int = pad_bindings[action]
		if button >= 0 and used.has(button):
			# Um botão salvo bate com o padrão de outra ação: volta tudo ao padrão.
			pad_bindings = _pad_defaults.duplicate()
			return
		used[button] = true


## Tecla principal da ação: a de `bindings` se é trocável, senão a primeira do
## Input Map. 0 se não tem.
func _first_key(action: StringName) -> int:
	if bindings.has(action):
		for code: int in bindings[action]:
			if code != 0:
				return code
		return 0
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return 0


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
