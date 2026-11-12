extends GutTest
## Confere o autoload AudioSettings: padrões, salvamento sem apagar as outras
## seções, mudo, barramentos de áudio e restaurar padrões. Usa uma instância
## própria com um arquivo de teste, para não ler nem gravar as opções reais.

const AudioSettingsScript := preload("res://autoload/audio_settings.gd")
const TEST_SETTINGS := "user://test_audio_settings.cfg"

var _settings: Node


func before_each() -> void:
	_remove_test_file()
	_settings = _make_settings()


func after_each() -> void:
	_remove_test_file()
	# Devolve aos barramentos as opções reais.
	AudioSettings.apply()


func test_defaults_without_file() -> void:
	assert_eq(_settings.music_volume, 80)
	assert_eq(_settings.sfx_volume, 100)
	assert_false(_settings.music_muted)
	assert_false(_settings.sfx_muted)
	assert_false(_settings.reduce_effects)


func test_choices_are_saved_and_loaded() -> void:
	_settings.set_music_volume(35)
	_settings.set_sfx_volume(60)
	_settings.set_music_muted(true)
	_settings.set_reduce_effects(true)
	var reloaded := _make_settings()
	assert_eq(reloaded.music_volume, 35)
	assert_eq(reloaded.sfx_volume, 60)
	assert_true(reloaded.music_muted)
	assert_false(reloaded.sfx_muted)
	assert_true(reloaded.reduce_effects)


func test_saving_keeps_other_sections() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "fullscreen", true)
	config.save(TEST_SETTINGS)
	var settings := _make_settings()
	settings.set_sfx_volume(10)
	var saved := ConfigFile.new()
	saved.load(TEST_SETTINGS)
	assert_true(saved.get_value("display", "fullscreen"))
	assert_eq(saved.get_value("audio", "sfx_volume"), 10)


func test_volume_is_applied_to_the_buses() -> void:
	_settings.set_music_volume(50)
	_settings.set_sfx_volume(100)
	var music := AudioServer.get_bus_index("Music")
	var sfx := AudioServer.get_bus_index("SFX")
	assert_ne(music, -1)
	assert_ne(sfx, -1)
	assert_almost_eq(AudioServer.get_bus_volume_db(music), -6.02, 0.05)
	assert_almost_eq(AudioServer.get_bus_volume_db(sfx), 0.0, 0.001)


func test_mute_silences_the_bus_but_keeps_the_volume() -> void:
	_settings.set_music_volume(70)
	_settings.set_music_muted(true)
	assert_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), VolumeCurve.SILENT_DB)
	_settings.set_music_muted(false)
	assert_eq(_settings.music_volume, 70)
	assert_gt(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music")), -10.0)


func test_volume_is_clamped_to_zero_and_one_hundred() -> void:
	_settings.set_music_volume(500)
	assert_eq(_settings.music_volume, 100)
	_settings.set_sfx_volume(-4)
	assert_eq(_settings.sfx_volume, 0)


func test_drag_does_not_write_the_file_until_persisted() -> void:
	_settings.set_music_volume(20, false)
	assert_false(FileAccess.file_exists(TEST_SETTINGS))
	_settings.save_settings()
	assert_true(FileAccess.file_exists(TEST_SETTINGS))


func test_reset_restores_defaults_and_saves() -> void:
	_settings.set_music_volume(5)
	_settings.set_sfx_muted(true)
	_settings.set_reduce_effects(true)
	_settings.reset_to_defaults()
	var reloaded := _make_settings()
	assert_eq(reloaded.music_volume, 80)
	assert_false(reloaded.sfx_muted)
	assert_false(reloaded.reduce_effects)


func test_changed_signal_is_emitted() -> void:
	watch_signals(_settings)
	_settings.set_reduce_effects(true)
	assert_signal_emitted(_settings, "changed")


func _make_settings() -> Node:
	var settings: Node = AudioSettingsScript.new()
	settings.settings_path = TEST_SETTINGS
	settings.load_settings()
	add_child_autofree(settings)
	return settings


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
