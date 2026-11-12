extends GutTest
## Confere a aba Teclas da tela de opções: mostrar as teclas, trocar uma ação,
## recusar tecla já usada, cancelar com Esc, limpar a alternativa com Delete e
## restaurar tudo. Usa um arquivo de opções de teste.

const OptionsMenuScene := preload("res://scenes/ui/options_menu.tscn")
const TEST_SETTINGS := "user://test_options_keys.cfg"

var _menu: OptionsMenu
var _old_audio_path: String
var _old_display_path: String


func before_each() -> void:
	_old_audio_path = AudioSettings.settings_path
	_old_display_path = DisplaySettings.settings_path
	AudioSettings.settings_path = TEST_SETTINGS
	DisplaySettings.settings_path = TEST_SETTINGS
	InputSettings.settings_path = TEST_SETTINGS
	_remove_test_file()
	InputSettings.reset_to_defaults()
	_menu = autofree(OptionsMenuScene.instantiate())
	add_child(_menu)


func after_each() -> void:
	# Sem arquivo salvo, o carregamento não desfaz o que o teste mudou: volta ao padrão.
	AudioSettings.reset_to_defaults()
	DisplaySettings.pixel_perfect = true
	DisplaySettings.fullscreen = false
	InputSettings.reset_to_defaults()
	_remove_test_file()
	AudioSettings.settings_path = _old_audio_path
	DisplaySettings.settings_path = _old_display_path
	InputSettings.settings_path = InputSettings.SETTINGS_PATH
	AudioSettings.load_settings()
	AudioSettings.apply()
	DisplaySettings.load_settings()


func _node(path: String) -> Node:
	return _menu.get_node("Root/Center/Panel/Layout/%s" % path)


func _key_event(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code as Key
	event.pressed = true
	return event


func test_keys_tab_shows_the_current_keys() -> void:
	_menu.open()
	_menu.show_tab(OptionsMenu.Tab.KEYS)
	assert_eq(_menu.key_button(&"move_up", 0).text, "Seta cima")
	assert_eq(_menu.key_button(&"move_up", 1).text, "W")
	assert_eq(_menu.key_button(&"attack", 0).text, "Espaço")
	assert_eq(_menu.key_button(&"attack", 1).text, "Vazio")


func test_choosing_a_key_remaps_the_action() -> void:
	_menu.open()
	_menu.key_button(&"interact", 0).pressed.emit()
	assert_true(_menu.is_capturing())
	assert_eq(_menu.key_button(&"interact", 0).text, "Aperte...")
	_menu._input(_key_event(KEY_F))
	assert_false(_menu.is_capturing())
	assert_eq(InputSettings.key_in_slot(&"interact", 0), KEY_F)
	assert_eq(_menu.key_button(&"interact", 0).text, "F")


func test_a_taken_key_keeps_the_old_one_and_explains() -> void:
	_menu.open()
	_menu.key_button(&"attack", 0).pressed.emit()
	_menu._input(_key_event(KEY_E))
	assert_eq(InputSettings.key_in_slot(&"attack", 0), KEY_SPACE)
	var status: Label = _node("Pages/KeysPage/KeysStatus")
	assert_true("Interagir" in status.text, status.text)


func test_escape_cancels_the_capture_without_closing() -> void:
	_menu.open()
	_menu.key_button(&"attack", 0).pressed.emit()
	_menu._input(_key_event(KEY_ESCAPE))
	assert_false(_menu.is_capturing())
	assert_true(_menu.is_open())
	assert_eq(InputSettings.key_in_slot(&"attack", 0), KEY_SPACE)


func test_delete_clears_the_alternative_key() -> void:
	_menu.open()
	_menu.key_button(&"move_up", 1).pressed.emit()
	_menu._input(_key_event(KEY_DELETE))
	assert_eq(InputSettings.key_in_slot(&"move_up", 1), 0)
	assert_eq(_menu.key_button(&"move_up", 1).text, "Vazio")


func test_changing_tab_cancels_the_capture() -> void:
	_menu.open()
	_menu.key_button(&"attack", 0).pressed.emit()
	_menu.show_tab(OptionsMenu.Tab.SOUND)
	assert_false(_menu.is_capturing())


func test_reset_button_also_restores_the_keys_and_video() -> void:
	InputSettings.set_key(&"interact", 0, KEY_F)
	AudioSettings.set_large_text(true)
	_menu.open()
	_node("Footer/ResetButton").pressed.emit()
	assert_eq(InputSettings.key_in_slot(&"interact", 0), KEY_E)
	assert_false(AudioSettings.large_text)
	assert_true(DisplaySettings.pixel_perfect)
	assert_false(DisplaySettings.fullscreen)


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
