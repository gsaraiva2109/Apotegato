extends GutTest
## Confere as teclas trocáveis: padrões lidos do Input Map, troca, conflitos,
## teclas reservadas, limpar a alternativa, salvamento e restauração. Usa uma
## instância própria com um arquivo de teste e devolve o Input Map ao padrão.

const InputSettingsScript := preload("res://autoload/input_settings.gd")
const TEST_SETTINGS := "user://test_input_settings.cfg"

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


func test_defaults_come_from_the_input_map() -> void:
	assert_eq(_settings.key_in_slot(&"move_up", 0), KEY_UP)
	assert_eq(_settings.key_in_slot(&"move_up", 1), KEY_W)
	assert_eq(_settings.key_in_slot(&"attack", 0), KEY_SPACE)
	assert_eq(_settings.key_in_slot(&"attack", 1), 0)
	assert_true(_settings.is_default(&"journal"))


func test_set_key_changes_the_input_map_and_saves() -> void:
	assert_eq(_settings.set_key(&"interact", 0, KEY_F), InputSettings.Result.OK)
	assert_eq(_keys_of(&"interact"), [KEY_F])
	assert_false(_settings.is_default(&"interact"))
	var reloaded := _make_settings()
	assert_eq(reloaded.key_in_slot(&"interact", 0), KEY_F)


func test_the_alternative_slot_can_be_filled() -> void:
	assert_eq(_settings.set_key(&"attack", 1, KEY_Z), InputSettings.Result.OK)
	assert_eq(_keys_of(&"attack").size(), 2)
	assert_true(KEY_Z in _keys_of(&"attack"))


func test_a_key_used_by_another_action_is_refused() -> void:
	assert_eq(_settings.owner_of(KEY_E), &"interact")
	assert_eq(_settings.set_key(&"attack", 0, KEY_E), InputSettings.Result.TAKEN)
	assert_eq(_settings.key_in_slot(&"attack", 0), KEY_SPACE, "Nada mudou")


func test_reserved_keys_are_refused() -> void:
	for code in [KEY_ESCAPE, KEY_F10, KEY_F11]:
		assert_eq(_settings.set_key(&"attack", 1, code), InputSettings.Result.RESERVED_KEY)
	assert_eq(_settings.owner_of(KEY_ESCAPE), &"pause")


func test_the_same_key_can_be_reentered_in_its_own_slot() -> void:
	assert_eq(_settings.set_key(&"interact", 0, KEY_E), InputSettings.Result.OK)


func test_invalid_requests_are_refused() -> void:
	assert_eq(_settings.set_key(&"pause", 0, KEY_Q), InputSettings.Result.INVALID)
	assert_eq(_settings.set_key(&"attack", 5, KEY_Q), InputSettings.Result.INVALID)
	assert_eq(_settings.set_key(&"attack", 0, 0), InputSettings.Result.INVALID)


func test_clear_slot_keeps_at_least_one_key() -> void:
	assert_true(_settings.clear_slot(&"move_up", 1))
	assert_eq(_keys_of(&"move_up"), [KEY_UP])
	assert_false(_settings.clear_slot(&"move_up", 0), "Ficaria sem tecla")
	assert_false(_settings.clear_slot(&"attack", 0), "Só tem uma")


func test_reset_restores_defaults() -> void:
	_settings.set_key(&"interact", 0, KEY_F)
	_settings.clear_slot(&"move_up", 1)
	_settings.reset_to_defaults()
	assert_true(_settings.is_default(&"interact"))
	assert_eq(_keys_of(&"move_up").size(), 2)
	assert_eq(_keys_of(&"interact"), [KEY_E])


func test_invalid_saved_values_fall_back_to_the_defaults() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "attack", [KEY_ESCAPE, 0])
	config.set_value("input", "interact", [0, 0])
	config.set_value("input", "journal", [KEY_Q, KEY_Q])
	config.set_value("input", "backpack", "lixo")
	config.save(TEST_SETTINGS)
	var settings := _make_settings()
	for action in [&"attack", &"interact", &"journal", &"backpack"]:
		assert_true(settings.is_default(action), String(action))


func test_saving_keeps_other_sections() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", true)
	config.save(TEST_SETTINGS)
	var settings := _make_settings()
	settings.set_key(&"journal", 0, KEY_Q)
	var saved := ConfigFile.new()
	saved.load(TEST_SETTINGS)
	assert_true(saved.get_value("display", "fullscreen"))
	assert_eq(saved.get_value("input", "journal")[0], KEY_Q)


func test_labels_are_in_portuguese() -> void:
	assert_eq(_settings.key_label(KEY_UP), "Seta cima")
	assert_eq(_settings.key_label(KEY_SPACE), "Espaço")
	assert_eq(_settings.key_label(0), "Vazio")
	assert_eq(_settings.key_label(KEY_W), "W")


func test_without_a_window_the_input_map_is_left_alone() -> void:
	_settings.reset_to_defaults()
	var settings: Node = InputSettingsScript.new()
	settings.settings_path = TEST_SETTINGS
	settings.applies_to_input_map = false
	add_child_autofree(settings)
	settings.capture_defaults()
	settings.set_key(&"journal", 0, KEY_Q)
	assert_eq(_keys_of(&"journal"), [KEY_J])


func test_bindings_changed_is_emitted() -> void:
	watch_signals(_settings)
	_settings.set_key(&"journal", 0, KEY_Q)
	assert_signal_emitted(_settings, "bindings_changed")


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
