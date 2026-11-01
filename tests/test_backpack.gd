extends GutTest
## Confere a mochila de 6 espaços: empilhar, encher, recusar e esvaziar.

var _backpack: Backpack


func before_each() -> void:
	_backpack = Backpack.new()


## Enche os 6 espaços com ingredientes diferentes.
func _fill() -> void:
	for id in ["buriti", "camu_camu", "mel", "sardinha", "pequi", "licuri"]:
		_backpack.add(id)


func test_starts_empty_with_six_slots() -> void:
	assert_eq(Backpack.MAX_SLOTS, 6)
	assert_true(_backpack.is_empty())
	assert_eq(_backpack.free_slots(), 6)
	assert_eq(_backpack.count("buriti"), 0)


func test_add_and_count() -> void:
	assert_true(_backpack.add("buriti"))
	assert_eq(_backpack.count("buriti"), 1)
	assert_eq(_backpack.used_slots(), 1)
	assert_false(_backpack.is_empty())


func test_equal_items_stack_in_the_same_slot() -> void:
	_backpack.add("buriti")
	_backpack.add("buriti")
	_backpack.add("buriti", 3)
	assert_eq(_backpack.count("buriti"), 5)
	assert_eq(_backpack.used_slots(), 1)
	assert_eq(_backpack.total_count(), 5)


func test_different_items_use_different_slots() -> void:
	_backpack.add("buriti")
	_backpack.add("mel")
	assert_eq(_backpack.used_slots(), 2)
	assert_eq(_backpack.ids(), ["buriti", "mel"])


func test_a_new_item_is_refused_when_all_slots_are_taken() -> void:
	_fill()
	assert_true(_backpack.is_full())
	watch_signals(_backpack)
	assert_false(_backpack.add("acerola"))
	assert_eq(_backpack.count("acerola"), 0)
	assert_eq(_backpack.used_slots(), 6)
	assert_signal_emitted_with_parameters(_backpack, "rejected", ["acerola"])
	assert_signal_not_emitted(_backpack, "changed")


func test_a_full_backpack_still_stacks_an_item_it_already_has() -> void:
	_fill()
	assert_true(_backpack.can_add("buriti"))
	assert_true(_backpack.add("buriti"))
	assert_eq(_backpack.count("buriti"), 2)
	assert_eq(_backpack.used_slots(), 6)


func test_removing_frees_the_slot_only_when_it_reaches_zero() -> void:
	_backpack.add("buriti", 2)
	assert_true(_backpack.remove("buriti"))
	assert_eq(_backpack.count("buriti"), 1)
	assert_eq(_backpack.used_slots(), 1)
	assert_true(_backpack.remove("buriti"))
	assert_eq(_backpack.count("buriti"), 0)
	assert_eq(_backpack.used_slots(), 0)


func test_removing_more_than_there_is_changes_nothing() -> void:
	_backpack.add("buriti", 2)
	assert_false(_backpack.remove("buriti", 3))
	assert_false(_backpack.remove("mel"))
	assert_eq(_backpack.count("buriti"), 2)


func test_emptying_after_filling_accepts_new_items() -> void:
	_fill()
	for id in _backpack.ids():
		assert_true(_backpack.remove(id))
	assert_true(_backpack.is_empty())
	assert_true(_backpack.add("acerola"))


func test_clear_empties_the_backpack() -> void:
	_fill()
	_backpack.clear()
	assert_true(_backpack.is_empty())
	assert_eq(_backpack.total_count(), 0)


func test_invalid_amounts_and_ids_are_ignored() -> void:
	assert_false(_backpack.add("buriti", 0))
	assert_false(_backpack.add("buriti", -1))
	assert_false(_backpack.add(""))
	assert_true(_backpack.is_empty())


func test_changed_is_emitted_on_every_change() -> void:
	watch_signals(_backpack)
	_backpack.add("buriti")
	_backpack.remove("buriti")
	assert_signal_emit_count(_backpack, "changed", 2)
