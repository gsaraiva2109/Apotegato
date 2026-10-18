extends SceneTree
## Abre todos os scripts e cenas do projeto (menos addons/) e falha se algum
## não carregar. Pega erro de sintaxe e referência quebrada que os testes não
## cobrem, porque o GUT só avisa e segue em frente nesses casos.
##
## Uso: godot --headless -s res://tools/checar_projeto.gd

const IGNORAR := ["res://addons", "res://.godot"]
const EXTENSOES := ["gd", "tscn", "tres"]


func _initialize() -> void:
	var arquivos := _listar("res://")
	var falhas := 0
	for caminho in arquivos:
		var recurso := load(caminho)
		var ok := recurso != null
		if ok and recurso is GDScript:
			ok = (recurso as GDScript).can_instantiate()
		if not ok:
			falhas += 1
			printerr("FALHOU: %s" % caminho)
	print("%d arquivo(s) verificado(s), %d com problema." % [arquivos.size(), falhas])
	quit(1 if falhas > 0 else 0)


func _listar(pasta: String) -> PackedStringArray:
	var encontrados := PackedStringArray()
	for nome in DirAccess.get_files_at(pasta):
		if nome.get_extension() in EXTENSOES:
			encontrados.append(pasta.path_join(nome))
	for nome in DirAccess.get_directories_at(pasta):
		var sub := pasta.path_join(nome)
		if sub not in IGNORAR:
			encontrados.append_array(_listar(sub))
	return encontrados
