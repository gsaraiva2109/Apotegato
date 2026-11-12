extends Node
## Aplica a opção "Texto grande" à interface: com ela ligada, todos os textos
## dos menus, do HUD e dos diálogos ficam `LARGE_FACTOR` vezes maiores. Escala os
## tamanhos de fonte do tema único (`game_theme.tres`) e os tamanhos que cada nó
## define por conta própria (`theme_override_font_sizes`), inclusive nós criados
## depois. Guarda o tamanho original de cada um para voltar ao normal.
##
## Registrado como autoload "TextSize", depois do "AudioSettings".

## Quanto os textos crescem com "Texto grande".
const LARGE_FACTOR := 1.25
const BASE_META := &"base_font_size"
const DEFAULT_KEY := "default"

## Tamanhos de fonte originais do tema: "Tipo/nome" -> tamanho.
var _theme: Theme = preload("res://scenes/ui/game_theme.tres")
var _theme_base := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_theme_base[DEFAULT_KEY] = _theme.default_font_size
	for type_name in _theme.get_font_size_type_list():
		for item in _theme.get_font_size_list(type_name):
			_theme_base["%s/%s" % [type_name, item]] = _theme.get_font_size(item, type_name)
	get_tree().node_added.connect(_on_node_added)
	AudioSettings.changed.connect(apply)
	apply()


## Fator de escala atual (1.0 no texto normal).
func factor() -> float:
	return LARGE_FACTOR if AudioSettings.large_text else 1.0


## Aplica o fator ao tema e a todos os nós que já estão na cena.
func apply() -> void:
	_theme.default_font_size = scaled(_theme_base[DEFAULT_KEY])
	for key: String in _theme_base:
		if key != DEFAULT_KEY:
			var parts := key.split("/")
			_theme.set_font_size(parts[1], parts[0], scaled(_theme_base[key]))
	_scale_tree(get_tree().root)


## Tamanho `base` multiplicado pelo fator atual.
func scaled(base: int) -> int:
	return roundi(base * factor())


func _scale_tree(node: Node) -> void:
	_scale_node(node)
	for child in node.get_children():
		_scale_tree(child)


func _on_node_added(node: Node) -> void:
	_scale_node(node)


func _scale_node(node: Node) -> void:
	if not node is Control:
		return
	var control := node as Control
	if not control.has_theme_font_size_override("font_size"):
		return
	if not control.has_meta(BASE_META):
		control.set_meta(BASE_META, control.get_theme_font_size("font_size"))
	control.add_theme_font_size_override("font_size", scaled(control.get_meta(BASE_META)))
