extends GutTest
## Confere os corações: 7 no máximo, golpes tiram, a cura não passa de 7.

var _hearts: Hearts


func before_each() -> void:
	_hearts = Hearts.new()


func test_starts_with_seven_full_hearts() -> void:
	assert_eq(Hearts.MAX, 7)
	assert_eq(_hearts.current, 7)
	assert_true(_hearts.is_full())
	assert_false(_hearts.is_empty())


func test_hurt_takes_one_heart() -> void:
	_hearts.hurt()
	assert_eq(_hearts.current, 6)
	assert_false(_hearts.is_full())


func test_seven_hits_empty_the_hearts() -> void:
	for i in 7:
		_hearts.hurt()
	assert_true(_hearts.is_empty())
	assert_eq(_hearts.current, 0)


func test_hearts_never_go_below_zero() -> void:
	_hearts.hurt(20)
	assert_eq(_hearts.current, 0)
	_hearts.hurt()
	assert_eq(_hearts.current, 0)


func test_heal_recovers_one_heart() -> void:
	_hearts.hurt(3)
	assert_eq(_hearts.heal(), 1)
	assert_eq(_hearts.current, 5)


func test_heal_never_passes_seven() -> void:
	assert_eq(_hearts.heal(), 0, "Já cheio, nada a recuperar")
	assert_eq(_hearts.current, 7)
	_hearts.hurt()
	assert_eq(_hearts.heal(5), 1)
	assert_eq(_hearts.current, 7)


func test_restore_goes_back_to_seven() -> void:
	_hearts.hurt(7)
	_hearts.restore()
	assert_eq(_hearts.current, 7)


func test_changed_is_emitted_with_current_and_max() -> void:
	watch_signals(_hearts)
	_hearts.hurt()
	assert_signal_emitted_with_parameters(_hearts, "changed", [6, 7])
	_hearts.heal()
	assert_signal_emitted_with_parameters(_hearts, "changed", [7, 7])
	_hearts.heal()
	assert_signal_emit_count(_hearts, "changed", 2, "Cura com o coração cheio não emite")
