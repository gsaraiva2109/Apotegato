extends GutTest
## Confere a vida em meios corações: 7 corações = 14 meios, golpes tiram, a cura
## não passa do máximo e cada ícone fica cheio, pela metade ou vazio.

var _hearts: Hearts


func before_each() -> void:
	_hearts = Hearts.new()


func test_constants_describe_seven_hearts_in_halves() -> void:
	assert_eq(Hearts.MAX_HEARTS, 7)
	assert_eq(Hearts.HALVES_PER_HEART, 2)
	assert_eq(Hearts.MAX, 14)


func test_starts_full() -> void:
	assert_eq(_hearts.current, 14)
	assert_true(_hearts.is_full())
	assert_false(_hearts.is_empty())
	assert_eq(_hearts.missing(), 0)


func test_hurt_takes_a_half_heart() -> void:
	_hearts.hurt(1)
	assert_eq(_hearts.current, 13)
	assert_eq(_hearts.missing(), 1)
	assert_false(_hearts.is_full())


func test_hurt_takes_a_whole_heart() -> void:
	_hearts.hurt(2)
	assert_eq(_hearts.current, 12)


func test_fourteen_halves_empty_the_hearts() -> void:
	for i in 14:
		_hearts.hurt(1)
	assert_true(_hearts.is_empty())
	assert_eq(_hearts.current, 0)


func test_hearts_never_go_below_zero() -> void:
	_hearts.hurt(40)
	assert_eq(_hearts.current, 0)
	_hearts.hurt(1)
	assert_eq(_hearts.current, 0)


func test_hurt_ignores_zero_and_negative() -> void:
	_hearts.hurt(0)
	_hearts.hurt(-3)
	assert_eq(_hearts.current, 14)


func test_heal_recovers_halves() -> void:
	_hearts.hurt(6)
	assert_eq(_hearts.heal(1), 1)
	assert_eq(_hearts.current, 9)
	assert_eq(_hearts.heal(2), 2)
	assert_eq(_hearts.current, 11)


func test_heal_never_passes_the_maximum() -> void:
	assert_eq(_hearts.heal(2), 0, "Já cheio, nada a recuperar")
	assert_eq(_hearts.current, 14)
	_hearts.hurt(1)
	assert_eq(_hearts.heal(5), 1, "Devolve só o que coube")
	assert_eq(_hearts.current, 14)


func test_restore_goes_back_to_full() -> void:
	_hearts.hurt(14)
	_hearts.restore()
	assert_eq(_hearts.current, 14)


func test_changed_is_emitted_with_current_and_max_in_halves() -> void:
	watch_signals(_hearts)
	_hearts.hurt(1)
	assert_signal_emitted_with_parameters(_hearts, "changed", [13, 14])
	_hearts.heal(1)
	assert_signal_emitted_with_parameters(_hearts, "changed", [14, 14])
	_hearts.heal(1)
	assert_signal_emit_count(_hearts, "changed", 2, "Cura com a vida cheia não emite")


func _fills(halves: int) -> Array[Hearts.Fill]:
	var result: Array[Hearts.Fill] = []
	for i in Hearts.MAX_HEARTS:
		result.append(Hearts.fill_of(i, halves))
	return result


func test_fill_with_zero_halves_is_all_empty() -> void:
	for fill in _fills(0):
		assert_eq(fill, Hearts.Fill.EMPTY)


func test_fill_with_one_half_has_only_the_first_heart_half() -> void:
	var fills := _fills(1)
	assert_eq(fills[0], Hearts.Fill.HALF)
	for i in range(1, 7):
		assert_eq(fills[i], Hearts.Fill.EMPTY)


func test_fill_with_seven_halves_has_three_full_and_one_half() -> void:
	var fills := _fills(7)
	for i in 3:
		assert_eq(fills[i], Hearts.Fill.FULL)
	assert_eq(fills[3], Hearts.Fill.HALF)
	for i in range(4, 7):
		assert_eq(fills[i], Hearts.Fill.EMPTY)


func test_fill_with_thirteen_halves_has_the_last_heart_half() -> void:
	var fills := _fills(13)
	for i in 6:
		assert_eq(fills[i], Hearts.Fill.FULL)
	assert_eq(fills[6], Hearts.Fill.HALF)


func test_fill_with_fourteen_halves_is_all_full() -> void:
	for fill in _fills(14):
		assert_eq(fill, Hearts.Fill.FULL)
