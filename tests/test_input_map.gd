extends GutTest
## Confere o Input Map do project.godot e garante que nenhum script do jogo
## lê tecla diretamente. Se o time mudar uma tecla, atualize ACTIONS junto.

## Ação e as teclas físicas esperadas para ela.
const ACTIONS := {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"attack": [KEY_SPACE],
	"interact": [KEY_E],
	"backpack": [KEY_I],
	"journal": [KEY_J],
	"pause": [KEY_ESCAPE],
}
## Pastas com código do jogo. addons/ e tests/ ficam de fora.
const CODE_DIRS := ["res://autoload", "res://scenes", "res://scripts"]
## Trechos que indicam leitura direta de tecla em vez de ação.
const FORBIDDEN := ["is_key_pressed", "is_physical_key_pressed", "InputEventKey", "KEY_"]


func test_actions_exist_with_expected_keys() -> void:
	for action in ACTIONS:
		assert_true(InputMap.has_action(action), "Falta a ação %s" % action)
		if not InputMap.has_action(action):
			continue
		var keys := []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				keys.append(event.physical_keycode)
		keys.sort()
		var expected: Array = ACTIONS[action].duplicate()
		expected.sort()
		assert_eq(keys, expected, "Teclas da ação %s" % action)


func test_no_script_reads_keys_directly() -> void:
	var scripts := _list_scripts()
	if scripts.is_empty():
		pass_test("Ainda não há scripts de jogo para conferir")
	for path in scripts:
		var source := FileAccess.get_file_as_string(path)
		for token in FORBIDDEN:
			assert_false(token in source, "%s usa %s; use uma ação do Input Map" % [path, token])


func _list_scripts() -> Array[String]:
	var found: Array[String] = []
	var pending: Array = CODE_DIRS.duplicate()
	while not pending.is_empty():
		var dir_path: String = pending.pop_back()
		for sub in DirAccess.get_directories_at(dir_path):
			pending.append(dir_path.path_join(sub))
		for file in DirAccess.get_files_at(dir_path):
			if file.get_extension() == "gd":
				found.append(dir_path.path_join(file))
	return found
