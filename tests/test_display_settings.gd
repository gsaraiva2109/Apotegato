extends GutTest
## Confere o autoload DisplaySettings sem janela de verdade (modo headless):
## as escolhas salvas, os atalhos e o modo de escala aplicado à janela do jogo.
## Usa uma instância própria com um arquivo de teste, para não ler nem gravar as
## opções de quem roda os testes.

const DisplaySettingsScript := preload("res://autoload/display_settings.gd")
const TEST_SETTINGS := "user://test_display_settings.cfg"

var _settings: Node


func before_each() -> void:
	_remove_test_file()
	_settings = _make_settings()


func after_each() -> void:
	_remove_test_file()
	# Devolve à janela o modo de escala das opções reais.
	DisplaySettings.apply_scale()


func test_defaults_without_file() -> void:
	assert_false(_settings.fullscreen)
	assert_true(_settings.pixel_perfect)


func test_choices_are_saved_and_loaded() -> void:
	_settings.set_pixel_perfect(false)
	_settings.set_fullscreen(true)
	var reloaded := _make_settings()
	assert_false(reloaded.pixel_perfect)
	assert_true(reloaded.fullscreen)


func test_saving_keeps_other_sections() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", 0.5)
	config.save(TEST_SETTINGS)
	_settings.set_pixel_perfect(false)
	config = ConfigFile.new()
	config.load(TEST_SETTINGS)
	assert_eq(config.get_value("audio", "music_volume"), 0.5)


func test_project_starts_in_pixel_perfect_with_black_borders() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep")


## Sem tela, a janela do Godot tem 100 x 100, menor que o jogo: mesmo no pixel
## perfeito a imagem é reduzida em vez de cortada.
func test_window_smaller_than_game_shrinks_even_in_pixel_perfect() -> void:
	assert_lt(get_window().size.y, 544)
	_settings.set_pixel_perfect(true)
	assert_eq(get_window().content_scale_stretch, Window.CONTENT_SCALE_STRETCH_FRACTIONAL)
	assert_lt(_settings.current_scale, 1.0)


func test_fill_uses_fractional_stretch() -> void:
	_settings.set_pixel_perfect(false)
	assert_eq(get_window().content_scale_stretch, Window.CONTENT_SCALE_STRETCH_FRACTIONAL)


func test_scale_mode_shortcut_toggles() -> void:
	_settings._unhandled_input(_action("toggle_scale_mode"))
	assert_false(_settings.pixel_perfect)
	_settings._unhandled_input(_action("toggle_scale_mode"))
	assert_true(_settings.pixel_perfect)


func test_fullscreen_shortcut_toggles() -> void:
	_settings._unhandled_input(_action("toggle_fullscreen"))
	assert_true(_settings.fullscreen)


func test_shortcuts_work_while_paused() -> void:
	assert_eq(_settings.process_mode, Node.PROCESS_MODE_ALWAYS)


func test_does_not_touch_the_window_without_display() -> void:
	assert_false(_settings.controls_window())


func test_scale_signal_reports_the_new_scale() -> void:
	watch_signals(_settings)
	_settings.current_scale = 0.0
	_settings.apply_scale()
	assert_signal_emitted(_settings, "scale_changed")
	assert_gt(_settings.current_scale, 0.0)


func _make_settings() -> Node:
	var settings: Node = DisplaySettingsScript.new()
	settings.settings_path = TEST_SETTINGS
	add_child_autofree(settings)
	return settings


func _action(action_name: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = true
	return event


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
