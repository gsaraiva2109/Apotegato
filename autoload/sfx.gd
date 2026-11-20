extends Node
## Toca os efeitos sonoros no barramento "SFX". Cada pedido sorteia uma das
## variações do efeito (para o mesmo som não soar repetido) e usa um player
## livre de um pequeno conjunto, então sons seguidos se sobrepõem sem cortar.
## Se o arquivo não existir (áudio de terceiros vem do repositório privado), o
## jogo segue em silêncio, sem erro. Todo botão do jogo ganha o som de clique
## sozinho, sem cada tela precisar pedir.
##
## Registrado como autoload "Sfx", depois do "AudioSettings". Usa `preload` e
## não o `class_name` pelo mesmo motivo do `Music`.

const Catalog := preload("res://scripts/sfx_catalog.gd")

const BUS_NAME := "SFX"
## Quantos efeitos podem soar ao mesmo tempo.
const POOL_SIZE := 8

var _players: Array[AudioStreamPlayer] = []
var _cache := {}
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_NAME
		add_child(player)
		_players.append(player)
	get_tree().node_added.connect(_on_node_added)


## Ao fechar o jogo, solta os sons carregados para o Godot não avisar de
## recursos ainda em uso na saída.
func _exit_tree() -> void:
	for player in _players:
		player.stop()
		player.stream = null
	_cache.clear()


## Toca o efeito `id` (uma variação sorteada). Devolve true se algum som
## começou; false se o id é desconhecido ou o arquivo não existe.
func play(id: StringName) -> bool:
	var stream := _stream_for(id)
	if stream == null:
		return false
	var player := _free_player()
	player.stream = stream
	player.volume_db = Catalog.gain_of(id)
	player.play()
	return true


## Para todos os efeitos que estão tocando.
func stop_all() -> void:
	for player in _players:
		player.stop()


func _stream_for(id: StringName) -> AudioStream:
	var count := Catalog.variants_of(id)
	if count == 0:
		return null
	var n := _rng.randi_range(1, count)
	var path := Catalog.path_for(id, n)
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	return _cache[path]


## Um player parado; se todos estão ocupados, reaproveita o que está há mais
## tempo tocando (o primeiro da lista, que roda a cada pedido).
func _free_player() -> AudioStreamPlayer:
	for player in _players:
		if not player.playing:
			return player
	var oldest: AudioStreamPlayer = _players.pop_front()
	_players.append(oldest)
	return oldest


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(_on_button_pressed.bind(node))


func _on_button_pressed(button: BaseButton) -> void:
	if button.disabled:
		return
	play(Catalog.CLIQUE)
