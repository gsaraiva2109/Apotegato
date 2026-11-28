extends GutTest
## Confere os botões de controle trocáveis do `InputSettings`: padrões lidos do
## Input Map, troca, conflitos, botões fixos, salvamento, restauração, nomes dos
## botões e o aparelho usado por último. Usa uma instância própria com um
## arquivo de teste e devolve o Input Map ao padrão.

const InputSettingsScript := preload("res://autoload/input_settings.gd")
const TEST_SETTINGS := "user://test_input_settings_pad.cfg"

var _settings: Node


func before_each() -> void:
	_remove_test_file()
	_settings = _make_settings()


func after_each() -> void:
	_settings.reset_to_defaults()
	_remove_test_file()


func _make_settings() -> Node:
	var settings: Node = InputSettingsScript.new()
	settings.settings_path = TEST_SETTINGS
	settings.applies_to_input_map = true
	add_child_autofree(settings)
	settings.capture_defaults()
	settings.load_settings()
	return settings


func _keys_of(action: StringName) -> Array:
	var keys := []
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append(event.physical_keycode)
	return keys


func _pad_buttons_of(action: StringName) -> Array:
	var buttons := []
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			buttons.append(event.button_index)
	return buttons


func test_pad_defaults_come_from_the_input_map() -> void:
	assert_eq(_settings.pad_button_of(&"attack"), JOY_BUTTON_X)
	assert_eq(_settings.pad_button_of(&"interact"), JOY_BUTTON_A)
	assert_eq(_settings.pad_button_of(&"backpack"), JOY_BUTTON_RIGHT_SHOULDER)
	assert_eq(_settings.pad_button_of(&"journal"), JOY_BUTTON_Y)
	assert_eq(_settings.pad_button_of(&"pause"), JOY_BUTTON_START)
	assert_eq(_settings.pad_button_of(&"move_up"), -1)
	assert_true(_settings.is_default(&"attack"))


func test_set_pad_button_changes_the_input_map_and_saves() -> void:
	assert_eq(
		_settings.set_pad_button(&"attack", JOY_BUTTON_LEFT_SHOULDER), InputSettings.Result.OK
	)
	assert_eq(_pad_buttons_of(&"attack"), [JOY_BUTTON_LEFT_SHOULDER])
	assert_false(_settings.is_default(&"attack"))
	var reloaded := _make_settings()
	assert_eq(reloaded.pad_button_of(&"attack"), JOY_BUTTON_LEFT_SHOULDER)


func test_a_pad_button_used_by_another_action_is_refused() -> void:
	var result: int = _settings.set_pad_button(&"attack", JOY_BUTTON_A)
	assert_eq(result, InputSettings.Result.TAKEN)
	assert_eq(_settings.pad_owner_of(JOY_BUTTON_A), &"interact")
	assert_eq(_settings.pad_button_of(&"attack"), JOY_BUTTON_X, "Nada mudou")


func test_fixed_pad_buttons_are_refused() -> void:
	for button in [JOY_BUTTON_B, JOY_BUTTON_START, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]:
		var result: int = _settings.set_pad_button(&"attack", button)
		assert_eq(result, InputSettings.Result.RESERVED_KEY)
	assert_eq(_settings.pad_owner_of(JOY_BUTTON_START), &"pause")
	assert_eq(_settings.pad_owner_of(JOY_BUTTON_B), &"ui_cancel")


func test_invalid_pad_requests_are_refused() -> void:
	assert_eq(_settings.set_pad_button(&"move_up", JOY_BUTTON_X), InputSettings.Result.INVALID)
	assert_eq(_settings.set_pad_button(&"attack", -1), InputSettings.Result.INVALID)
	assert_eq(_settings.set_pad_button(&"attack", 999), InputSettings.Result.INVALID)


func test_applying_keeps_the_stick_and_dpad_of_movement() -> void:
	_settings.set_key(&"move_left", 1, KEY_Q)
	var axes := []
	var buttons := []
	for event in InputMap.action_get_events(&"move_left"):
		if event is InputEventJoypadMotion:
			axes.append([event.axis, event.axis_value])
		elif event is InputEventJoypadButton:
			buttons.append(event.button_index)
	assert_eq(axes, [[JOY_AXIS_LEFT_X, -1.0]])
	assert_eq(buttons, [JOY_BUTTON_DPAD_LEFT])


func test_applying_a_key_keeps_the_pad_button() -> void:
	_settings.set_key(&"attack", 0, KEY_Z)
	assert_eq(_pad_buttons_of(&"attack"), [JOY_BUTTON_X])
	assert_eq(_keys_of(&"attack"), [KEY_Z])


func test_pad_reset_restores_the_default() -> void:
	_settings.set_pad_button(&"journal", JOY_BUTTON_BACK)
	_settings.reset_to_defaults()
	assert_eq(_settings.pad_button_of(&"journal"), JOY_BUTTON_Y)
	assert_eq(_pad_buttons_of(&"journal"), [JOY_BUTTON_Y])


func test_invalid_saved_pad_values_fall_back_to_the_defaults() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "pad_attack", JOY_BUTTON_START)
	config.set_value("input", "pad_interact", "lixo")
	config.set_value("input", "pad_journal", 999)
	config.save(TEST_SETTINGS)
	var settings := _make_settings()
	for action in InputSettings.PAD_REMAPPABLE:
		assert_true(settings.is_default(action), String(action))


func test_a_saved_pad_button_that_collides_with_a_default_resets_the_pad() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "pad_attack", JOY_BUTTON_A)
	config.save(TEST_SETTINGS)
	var settings := _make_settings()
	assert_eq(settings.pad_button_of(&"attack"), JOY_BUTTON_X)
	assert_eq(settings.pad_button_of(&"interact"), JOY_BUTTON_A)


func test_pad_labels_follow_the_controller_style() -> void:
	assert_eq(_settings.pad_label(JOY_BUTTON_A), "A")
	assert_eq(_settings.pad_label(JOY_BUTTON_RIGHT_SHOULDER), "RB")
	_settings.pad_style = InputSettings.PadStyle.PLAYSTATION
	assert_eq(_settings.pad_label(JOY_BUTTON_A), "Cruz")
	assert_eq(_settings.pad_label(JOY_BUTTON_RIGHT_SHOULDER), "R1")
	assert_eq(_settings.pad_label(99), "Botão 99")


func test_style_comes_from_the_controller_name() -> void:
	var script := InputSettingsScript
	assert_eq(script.style_from_name("PS5 Controller"), InputSettings.PadStyle.PLAYSTATION)
	assert_eq(script.style_from_name("Sony DualSense"), InputSettings.PadStyle.PLAYSTATION)
	assert_eq(script.style_from_name("Xbox 360 Controller"), InputSettings.PadStyle.XBOX)
	assert_eq(script.style_from_name(""), InputSettings.PadStyle.XBOX)


func test_prompts_follow_the_last_used_device() -> void:
	assert_eq(_settings.prompt_text(&"interact"), "E")
	assert_eq(_settings.prompt_text(&"pause"), "Esc")
	_settings.device = InputSettings.Device.GAMEPAD
	assert_eq(_settings.prompt_text(&"interact"), "A")
	assert_eq(_settings.prompt_text(&"pause"), "Start")
	assert_eq(_settings.prompt_text(&"move_up"), "Seta cima", "Sem botão, mostra a tecla")


func test_the_device_switches_on_input() -> void:
	watch_signals(_settings)
	var press := InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_A
	press.pressed = true
	_settings._input(press)
	assert_eq(_settings.device, InputSettings.Device.GAMEPAD)
	assert_signal_emit_count(_settings, "device_changed", 1)
	_settings._input(press)
	assert_signal_emit_count(_settings, "device_changed", 1, "Sem mudança, sem sinal")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	_settings._input(key)
	assert_eq(_settings.device, InputSettings.Device.KEYBOARD)
	assert_signal_emit_count(_settings, "device_changed", 2)


func test_a_light_stick_nudge_does_not_switch_the_device() -> void:
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.2
	_settings._input(motion)
	assert_eq(_settings.device, InputSettings.Device.KEYBOARD)
	motion.axis_value = 0.9
	_settings._input(motion)
	assert_eq(_settings.device, InputSettings.Device.GAMEPAD)


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
