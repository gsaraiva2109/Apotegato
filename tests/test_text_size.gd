extends GutTest
## Confere o "Texto grande": o tema e os tamanhos definidos em cada nó crescem
## com a opção e voltam ao normal sem ela, inclusive em nós criados depois.

const TEST_SETTINGS := "user://test_text_size.cfg"

var _old_path: String
## Lido com `load` (e não `const preload`): o mesmo tema que o autoload altera.
var _theme: Theme = load("res://scenes/ui/game_theme.tres")


func before_each() -> void:
	_old_path = AudioSettings.settings_path
	AudioSettings.settings_path = TEST_SETTINGS
	AudioSettings.set_large_text(false)


func after_each() -> void:
	AudioSettings.set_large_text(false)
	AudioSettings.settings_path = _old_path
	AudioSettings.load_settings()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _label_with_size(size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	return label


func test_factor_follows_the_option() -> void:
	assert_eq(TextSize.factor(), 1.0)
	AudioSettings.set_large_text(true)
	assert_eq(TextSize.factor(), TextSize.LARGE_FACTOR)


func test_theme_default_size_grows_and_returns() -> void:
	var normal := _theme.default_font_size
	AudioSettings.set_large_text(true)
	assert_eq(_theme.default_font_size, roundi(normal * TextSize.LARGE_FACTOR))
	AudioSettings.set_large_text(false)
	assert_eq(_theme.default_font_size, normal)


func test_node_overrides_are_scaled_and_restored() -> void:
	var label := _label_with_size(20)
	add_child_autofree(label)
	AudioSettings.set_large_text(true)
	assert_eq(label.get_theme_font_size("font_size"), 25)
	AudioSettings.set_large_text(false)
	assert_eq(label.get_theme_font_size("font_size"), 20)


func test_nodes_added_while_large_are_scaled() -> void:
	AudioSettings.set_large_text(true)
	var label := _label_with_size(16)
	add_child_autofree(label)
	assert_eq(label.get_theme_font_size("font_size"), 20)
	AudioSettings.set_large_text(false)
	assert_eq(label.get_theme_font_size("font_size"), 16)


func test_toggling_twice_does_not_compound() -> void:
	var label := _label_with_size(16)
	add_child_autofree(label)
	for i in 3:
		AudioSettings.set_large_text(true)
		AudioSettings.set_large_text(false)
	assert_eq(label.get_theme_font_size("font_size"), 16)
	AudioSettings.set_large_text(true)
	assert_eq(label.get_theme_font_size("font_size"), 20)


func test_theme_type_sizes_are_scaled() -> void:
	var normal := _theme.get_font_size("font_size", "ParchmentTitle")
	AudioSettings.set_large_text(true)
	assert_eq(_theme.get_font_size("font_size", "ParchmentTitle"), roundi(normal * 1.25))
	AudioSettings.set_large_text(false)
	assert_eq(_theme.get_font_size("font_size", "ParchmentTitle"), normal)
