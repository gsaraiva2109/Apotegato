extends SceneTree
## Abre todos os scripts e cenas do projeto (menos addons/) e falha se algum
## não carregar. Pega erro de sintaxe e referência quebrada que os testes não
## cobrem, porque o GUT só avisa e segue em frente nesses casos.
##
## Uso: godot --headless -s res://tools/check_project.gd

const IGNORED_DIRS := ["res://addons", "res://.godot"]
const EXTENSIONS := ["gd", "tscn", "tres"]


func _initialize() -> void:
	var files := _list_files("res://")
	var failures := 0
	for path in files:
		var resource := load(path)
		var ok := resource != null
		if ok and resource is GDScript:
			ok = (resource as GDScript).can_instantiate()
		if not ok:
			failures += 1
			printerr("FALHOU: %s" % path)
	print("%d arquivo(s) verificado(s), %d com problema." % [files.size(), failures])
	quit(1 if failures > 0 else 0)


func _list_files(dir: String) -> PackedStringArray:
	var found := PackedStringArray()
	for file_name in DirAccess.get_files_at(dir):
		if file_name.get_extension() in EXTENSIONS:
			found.append(dir.path_join(file_name))
	for dir_name in DirAccess.get_directories_at(dir):
		var sub := dir.path_join(dir_name)
		if sub not in IGNORED_DIRS:
			found.append_array(_list_files(sub))
	return found
