extends Node
## Toca a trilha sonora: uma faixa em loop por cena (menu, cabana e cada
## região). Ao trocar de faixa, a antiga some e a nova entra aos poucos, sem
## corte brusco. Pedir a faixa que já está tocando não reinicia a música, então
## subir de andar na mesma região não interrompe nada. Se o arquivo da faixa
## não existir (arte e áudio de terceiros vêm do repositório privado), o jogo
## segue em silêncio, sem erro.
##
## Registrado como autoload "Music".

## Catálogo carregado por `preload`, e não pelo `class_name`, porque o autoload
## é lido antes de o Godot registrar as classes globais novas.
const Catalog := preload("res://scripts/music_catalog.gd")
## Ids das faixas fixas, para as cenas pedirem sem depender do catálogo.
const MENU := Catalog.MENU
const CABIN := Catalog.CABIN

## Nome do barramento de áudio das músicas (criado sozinho se não existir).
const BUS_NAME := "Music"
## Duração da transição entre faixas, em segundos.
const FADE_TIME := 1.0
## Volume de uma faixa tocando, em dB.
const PLAYING_DB := 0.0
## Volume de uma faixa silenciada, em dB.
const SILENT_DB := -60.0

## Id da faixa pedida no momento (vazio se nenhuma ou se está parada).
var current_track: String = ""

var _player: AudioStreamPlayer
## Faixa cujo arquivo está de fato tocando (vazio se parada ou sem arquivo).
var _loaded_track: String = ""
var _fade: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus()
	_player = _make_player()


## Ao fechar o jogo, solta as faixas carregadas para o Godot não avisar de
## recursos ainda em uso na saída.
func _exit_tree() -> void:
	_kill_fade()
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null


## Toca a faixa com o id dado, com transição. Id vazio ou desconhecido para a
## música com fade out.
func play(track: String) -> void:
	if track == current_track:
		return
	current_track = track
	var stream := _load_stream(track)
	if stream == null:
		stop()
		current_track = track
		return
	_loaded_track = track
	_crossfade_to(stream)


## Toca a faixa da região (ou fica em silêncio se a região for inválida).
func play_region(region: String) -> void:
	play(Catalog.track_for_region(region))


## Para a música com fade out.
func stop() -> void:
	current_track = ""
	_loaded_track = ""
	_kill_fade()
	if _player.playing:
		_fade = create_tween()
		_fade.tween_property(_player, "volume_db", SILENT_DB, FADE_TIME)
		_fade.tween_callback(_player.stop)


## Se há uma faixa pedida tocando. Durante o fade out de uma faixa que acabou de
## ser parada, devolve falso.
func is_playing() -> bool:
	return _loaded_track != "" and _player.playing


func _crossfade_to(stream: AudioStream) -> void:
	_kill_fade()
	var old := _player
	_player = _make_player()
	_player.stream = stream
	_player.volume_db = SILENT_DB
	_player.play()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(_player, "volume_db", PLAYING_DB, FADE_TIME)
	if old.playing:
		_fade.tween_property(old, "volume_db", SILENT_DB, FADE_TIME)
	_fade.chain().tween_callback(old.queue_free)


func _kill_fade() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()


func _make_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = BUS_NAME
	add_child(player)
	return player


func _load_stream(track: String) -> AudioStream:
	if track.is_empty():
		return null
	var path: String = Catalog.path_for(track)
	if not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	return stream


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS_NAME) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS_NAME)
	AudioServer.set_bus_send(index, &"Master")
