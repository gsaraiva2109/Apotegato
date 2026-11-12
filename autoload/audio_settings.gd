extends Node
## Opções de som e de acessibilidade: volume da música e dos efeitos (0 a 100%),
## mudo de cada um e "reduzir efeitos visuais". Os volumes são aplicados nos
## barramentos "Music" e "SFX" e tudo fica salvo em `user://settings.cfg`, no
## mesmo arquivo do `DisplaySettings` (cada um mexe só nas suas seções).
##
## Aplica as escolhas ao abrir o jogo, então valem desde o menu inicial. Os
## barramentos são criados aqui se não existirem (o projeto não tem layout de
## barramentos salvo). Registrado como autoload "AudioSettings", depois do
## "Music". Usa `preload` e não o `class_name` pelo mesmo motivo do `Music`.

## Emitido quando qualquer opção muda (volume, mudo ou efeitos reduzidos).
signal changed

const VolumeCurveScript := preload("res://scripts/volume_curve.gd")

const SETTINGS_PATH := "user://settings.cfg"
const SECTION_AUDIO := "audio"
const SECTION_ACCESSIBILITY := "accessibility"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

const DEFAULT_MUSIC_VOLUME := 80
const DEFAULT_SFX_VOLUME := 100
## Passo dos controles de volume, em pontos percentuais.
const VOLUME_STEP := 5

## Arquivo de opções lido e gravado. Só muda nos testes.
var settings_path := SETTINGS_PATH
var music_volume := DEFAULT_MUSIC_VOLUME
var sfx_volume := DEFAULT_SFX_VOLUME
var music_muted := false
var sfx_muted := false
## Troca piscadas e oscilações por versões estáticas (acessibilidade).
var reduce_effects := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func set_music_volume(percent: int, persist: bool = true) -> void:
	music_volume = clampi(percent, VolumeCurveScript.MIN_PERCENT, VolumeCurveScript.MAX_PERCENT)
	_commit(persist)


func set_sfx_volume(percent: int, persist: bool = true) -> void:
	sfx_volume = clampi(percent, VolumeCurveScript.MIN_PERCENT, VolumeCurveScript.MAX_PERCENT)
	_commit(persist)


func set_music_muted(value: bool) -> void:
	music_muted = value
	_commit(true)


func set_sfx_muted(value: bool) -> void:
	sfx_muted = value
	_commit(true)


func set_reduce_effects(value: bool) -> void:
	reduce_effects = value
	_commit(true)


## Volta tudo ao padrão e salva. Não mexe nas opções de vídeo.
func reset_to_defaults() -> void:
	music_volume = DEFAULT_MUSIC_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	music_muted = false
	sfx_muted = false
	reduce_effects = false
	_commit(true)


## Aplica volume e mudo nos barramentos de áudio.
func apply() -> void:
	_set_bus(MUSIC_BUS, VolumeCurveScript.to_db(music_volume, music_muted))
	_set_bus(SFX_BUS, VolumeCurveScript.to_db(sfx_volume, sfx_muted))


## Lê as escolhas salvas. Sem arquivo, valem os padrões.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	music_volume = clampi(
		int(config.get_value(SECTION_AUDIO, "music_volume", DEFAULT_MUSIC_VOLUME)),
		VolumeCurveScript.MIN_PERCENT,
		VolumeCurveScript.MAX_PERCENT
	)
	sfx_volume = clampi(
		int(config.get_value(SECTION_AUDIO, "sfx_volume", DEFAULT_SFX_VOLUME)),
		VolumeCurveScript.MIN_PERCENT,
		VolumeCurveScript.MAX_PERCENT
	)
	music_muted = bool(config.get_value(SECTION_AUDIO, "music_muted", false))
	sfx_muted = bool(config.get_value(SECTION_AUDIO, "sfx_muted", false))
	reduce_effects = bool(config.get_value(SECTION_ACCESSIBILITY, "reduce_effects", false))


## Grava as escolhas, mantendo as outras seções do arquivo (ex.: vídeo).
func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(SECTION_AUDIO, "music_volume", music_volume)
	config.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)
	config.set_value(SECTION_AUDIO, "music_muted", music_muted)
	config.set_value(SECTION_AUDIO, "sfx_muted", sfx_muted)
	config.set_value(SECTION_ACCESSIBILITY, "reduce_effects", reduce_effects)
	config.save(settings_path)


func _commit(persist: bool) -> void:
	apply()
	if persist:
		save_settings()
	changed.emit()


func _set_bus(bus_name: String, db: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")
	AudioServer.set_bus_volume_db(index, db)
