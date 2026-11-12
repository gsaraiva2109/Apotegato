extends GutTest
## Confere a tela de opções: abas, volumes e interruptores ligados às opções
## (com texto para cada estado), salvamento, Esc fechando só a tela e foco
## inicial. Troca o arquivo de opções dos autoloads por um de teste.

const OptionsMenuScene := preload("res://scenes/ui/options_menu.tscn")
const TEST_SETTINGS := "user://test_options_menu.cfg"

var _menu: OptionsMenu
var _old_audio_path: String
var _old_display_path: String


func before_each() -> void:
	_old_audio_path = AudioSettings.settings_path
	_old_display_path = DisplaySettings.settings_path
	AudioSettings.settings_path = TEST_SETTINGS
	DisplaySettings.settings_path = TEST_SETTINGS
	_remove_test_file()
	AudioSettings.reset_to_defaults()
	_menu = autofree(OptionsMenuScene.instantiate())
	add_child(_menu)


func after_each() -> void:
	_remove_test_file()
	AudioSettings.settings_path = _old_audio_path
	DisplaySettings.settings_path = _old_display_path
	AudioSettings.load_settings()
	AudioSettings.apply()
	DisplaySettings.load_settings()


func _node(path: String) -> Node:
	return _menu.get_node("Root/Center/Panel/Layout/%s" % path)


func _press_cancel() -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	_menu._unhandled_input(event)


func test_starts_closed_and_opens_on_the_sound_tab_with_focus() -> void:
	assert_false(_menu.is_open())
	_menu.open()
	assert_true(_menu.is_open())
	assert_eq(_menu.current_tab(), OptionsMenu.Tab.SOUND)
	assert_true(_node("Tabs/SoundTab").has_focus())


func test_tabs_show_one_page_at_a_time() -> void:
	_menu.open()
	for tab in [OptionsMenu.Tab.VIDEO, OptionsMenu.Tab.ACCESSIBILITY, OptionsMenu.Tab.SOUND]:
		_menu.show_tab(tab)
		var visible_pages := 0
		for page in ["SoundPage", "VideoPage", "AccessPage"]:
			if (_node("Pages/%s" % page) as Control).visible:
				visible_pages += 1
		assert_eq(visible_pages, 1)
		assert_eq(_menu.current_tab(), tab)


func test_pressing_a_tab_button_changes_the_page() -> void:
	_menu.open()
	_node("Tabs/VideoTab").pressed.emit()
	assert_eq(_menu.current_tab(), OptionsMenu.Tab.VIDEO)


func test_sliders_show_the_saved_values() -> void:
	AudioSettings.set_music_volume(35)
	AudioSettings.set_sfx_volume(60)
	_menu.open()
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicSlider").value, 35.0)
	assert_eq(_node("Pages/SoundPage/SfxRow/SfxSlider").value, 60.0)
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicValue").text, "35%")


func test_moving_a_slider_applies_and_saves() -> void:
	_menu.open()
	_node("Pages/SoundPage/MusicRow/MusicSlider").value = 45.0
	assert_eq(AudioSettings.music_volume, 45)
	var saved := ConfigFile.new()
	saved.load(TEST_SETTINGS)
	assert_eq(saved.get_value("audio", "music_volume"), 45)


func test_slider_uses_five_point_steps_from_zero_to_one_hundred() -> void:
	var slider: HSlider = _node("Pages/SoundPage/SfxRow/SfxSlider")
	assert_eq(slider.min_value, 0.0)
	assert_eq(slider.max_value, 100.0)
	assert_eq(slider.step, float(AudioSettings.VOLUME_STEP))


func test_mute_switch_mutes_and_shows_text_and_icon() -> void:
	_menu.open()
	var mute: CheckButton = _node("Pages/SoundPage/MusicMuteRow/MusicMuteSwitch")
	mute.button_pressed = true
	assert_true(AudioSettings.music_muted)
	assert_eq(_node("Pages/SoundPage/MusicMuteRow/MusicMuteState").text, "Ligado")
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicValue").text, "Mudo")
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicIcon").texture, OptionsMenu.ICON_MUTE)
	mute.button_pressed = false
	assert_eq(_node("Pages/SoundPage/MusicMuteRow/MusicMuteState").text, "Desligado")
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicIcon").texture, OptionsMenu.ICON_SOUND)


func test_zero_volume_shows_the_mute_icon_with_text() -> void:
	AudioSettings.set_sfx_volume(0)
	_menu.open()
	assert_eq(_node("Pages/SoundPage/SfxRow/SfxIcon").texture, OptionsMenu.ICON_MUTE)
	assert_eq(_node("Pages/SoundPage/SfxRow/SfxValue").text, "0%")


func test_reduce_effects_switch_updates_the_setting() -> void:
	_menu.open()
	_node("Pages/AccessPage/ReduceRow/ReduceSwitch").button_pressed = true
	assert_true(AudioSettings.reduce_effects)
	assert_eq(_node("Pages/AccessPage/ReduceRow/ReduceState").text, "Ligado")


func test_video_switches_follow_the_display_settings() -> void:
	DisplaySettings.pixel_perfect = true
	_menu.open()
	var pixel: CheckButton = _node("Pages/VideoPage/PixelRow/PixelSwitch")
	assert_true(pixel.button_pressed)
	pixel.button_pressed = false
	assert_false(DisplaySettings.pixel_perfect)
	assert_eq(_node("Pages/VideoPage/PixelRow/PixelState").text, "Desligado")
	DisplaySettings.pixel_perfect = false
	DisplaySettings.set_pixel_perfect(true)
	_menu._process(0.0)
	assert_true(pixel.button_pressed, "F10 com a tela aberta atualiza o interruptor")


func test_reset_button_restores_audio_defaults() -> void:
	AudioSettings.set_music_volume(10)
	AudioSettings.set_sfx_muted(true)
	_menu.open()
	_node("Footer/ResetButton").pressed.emit()
	assert_eq(AudioSettings.music_volume, AudioSettings.DEFAULT_MUSIC_VOLUME)
	assert_false(AudioSettings.sfx_muted)
	assert_eq(_node("Pages/SoundPage/MusicRow/MusicSlider").value, 80.0)


func test_cancel_and_back_close_and_emit_once() -> void:
	watch_signals(_menu)
	_menu.open()
	_press_cancel()
	assert_false(_menu.is_open())
	assert_signal_emit_count(_menu, "closed", 1)
	_menu.open()
	_node("Footer/BackButton").pressed.emit()
	assert_false(_menu.is_open())
	assert_signal_emit_count(_menu, "closed", 2)


func test_cancel_does_nothing_when_closed() -> void:
	watch_signals(_menu)
	_press_cancel()
	assert_signal_not_emitted(_menu, "closed")


func test_every_interactive_control_can_take_keyboard_focus() -> void:
	for path in [
		"Tabs/SoundTab", "Tabs/VideoTab", "Tabs/AccessTab",
		"Pages/SoundPage/MusicRow/MusicSlider", "Pages/SoundPage/SfxRow/SfxSlider",
		"Pages/SoundPage/MusicMuteRow/MusicMuteSwitch", "Pages/SoundPage/SfxMuteRow/SfxMuteSwitch",
		"Pages/VideoPage/FullscreenRow/FullscreenSwitch", "Pages/VideoPage/PixelRow/PixelSwitch",
		"Pages/AccessPage/ReduceRow/ReduceSwitch", "Footer/ResetButton", "Footer/BackButton",
	]:
		assert_ne((_node(path) as Control).focus_mode, Control.FOCUS_NONE, path)


func _remove_test_file() -> void:
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))
