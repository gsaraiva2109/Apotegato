extends GutTest
## Confere que a interface se navega com as setas e também com WASD: as ações
## `ui_*` do Input Map aceitam as duas e o foco passa entre os botões.

const PAIRS := {
	"ui_up": [KEY_UP, KEY_W],
	"ui_down": [KEY_DOWN, KEY_S],
	"ui_left": [KEY_LEFT, KEY_A],
	"ui_right": [KEY_RIGHT, KEY_D],
}

var _first: Button
var _second: Button


func before_each() -> void:
	var box: VBoxContainer = autofree(VBoxContainer.new())
	add_child(box)
	_first = Button.new()
	_second = Button.new()
	box.add_child(_first)
	box.add_child(_second)
	await wait_physics_frames(2)


func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	return event


func test_ui_actions_accept_arrows_and_wasd() -> void:
	for action: String in PAIRS:
		for code: Key in PAIRS[action]:
			assert_true(
				InputMap.event_is_action(_key(code), action), "%s deve aceitar %s" % [action, code]
			)


func test_wasd_moves_the_focus_like_the_arrows() -> void:
	for pair in [[KEY_DOWN, KEY_UP], [KEY_S, KEY_W]]:
		_first.grab_focus()
		Input.parse_input_event(_key(pair[0]))
		Input.flush_buffered_events()
		await wait_physics_frames(2)
		assert_true(_second.has_focus(), "%s desce o foco" % pair[0])
		Input.parse_input_event(_key(pair[1]))
		Input.flush_buffered_events()
		await wait_physics_frames(2)
		assert_true(_first.has_focus(), "%s sobe o foco" % pair[1])
