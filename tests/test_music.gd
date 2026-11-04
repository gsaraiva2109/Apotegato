extends GutTest
## Confere o autoload Music: cria o barramento, não quebra sem os arquivos de
## música e guarda a faixa pedida.


func after_each() -> void:
	Music.stop()


func test_creates_music_bus() -> void:
	assert_ne(AudioServer.get_bus_index(Music.BUS_NAME), -1)


func test_play_without_file_stays_silent() -> void:
	Music.play(MusicCatalog.MENU)
	assert_eq(Music.current_track, MusicCatalog.MENU)
	assert_false(Music.is_playing())


func test_play_region_uses_region_track() -> void:
	Music.play_region(Regions.CERRADO)
	assert_eq(Music.current_track, Regions.CERRADO)


func test_invalid_region_stops_music() -> void:
	Music.play(MusicCatalog.CABIN)
	Music.play_region("marte")
	assert_eq(Music.current_track, "")


func test_stop_clears_current_track() -> void:
	Music.play(MusicCatalog.CABIN)
	Music.stop()
	assert_eq(Music.current_track, "")
