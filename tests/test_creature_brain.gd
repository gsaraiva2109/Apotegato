extends GutTest
## Confere a máquina de estados da criatura: não percebeu, perseguindo, as
## distâncias de detecção e de desistência e a histerese entre elas, e o ataque
## com aviso, bote e descanso.

const RANGE := 24.0
const WARNING := 0.4
const LUNGE := 0.12
const REST := 0.7


## Cérebro que já está perseguindo, com os tempos do jogo.
func _chasing_brain() -> CreatureBrain:
	var brain := CreatureBrain.new(160.0, 288.0, RANGE, WARNING, LUNGE, REST)
	brain.update(50.0)
	return brain


func test_starts_unaware() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	assert_eq(brain.state, CreatureBrain.State.UNAWARE)
	assert_false(brain.is_chasing())


func test_far_player_is_not_noticed() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	assert_eq(brain.update(101.0), CreatureBrain.State.UNAWARE)
	assert_eq(brain.update(INF), CreatureBrain.State.UNAWARE)


func test_player_inside_detection_distance_starts_the_chase() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	assert_eq(brain.update(100.0), CreatureBrain.State.CHASING)
	assert_true(brain.is_chasing())


func test_chase_continues_between_detection_and_give_up() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	brain.update(50.0)
	assert_eq(brain.update(150.0), CreatureBrain.State.CHASING, "Ainda não desistiu")
	assert_eq(brain.update(199.0), CreatureBrain.State.CHASING)


func test_creature_gives_up_when_the_player_gets_far_enough() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	brain.update(50.0)
	assert_eq(brain.update(200.0), CreatureBrain.State.UNAWARE)
	assert_eq(brain.update(INF), CreatureBrain.State.UNAWARE)


func test_after_giving_up_it_needs_to_get_close_again() -> void:
	var brain := CreatureBrain.new(100.0, 200.0)
	brain.update(50.0)
	brain.update(300.0)
	assert_eq(brain.update(150.0), CreatureBrain.State.UNAWARE, "Entre as distâncias, segue parada")
	assert_eq(brain.update(80.0), CreatureBrain.State.CHASING)


func test_give_up_distance_is_never_smaller_than_detection() -> void:
	var brain := CreatureBrain.new(100.0, 40.0)
	assert_eq(brain.give_up_distance, 100.0)


func test_distances_are_configurable() -> void:
	var near := CreatureBrain.new(32.0, 64.0)
	var far := CreatureBrain.new(320.0, 640.0)
	assert_eq(near.update(100.0), CreatureBrain.State.UNAWARE)
	assert_eq(far.update(100.0), CreatureBrain.State.CHASING)


func test_no_warning_while_the_player_is_out_of_attack_range() -> void:
	var brain := _chasing_brain()
	assert_eq(brain.tick(0.1, RANGE + 1.0), CreatureBrain.State.CHASING)
	assert_eq(brain.tick(5.0, 100.0), CreatureBrain.State.CHASING)
	assert_false(brain.can_hurt())


func test_warning_starts_inside_the_attack_range() -> void:
	var brain := _chasing_brain()
	assert_eq(brain.tick(0.016, RANGE), CreatureBrain.State.WARNING)
	assert_true(brain.is_attacking())
	assert_true(brain.is_chasing(), "No meio do ataque ela segue ciente do gato")
	assert_false(brain.can_hurt(), "O aviso não machuca")


func test_an_unaware_creature_does_not_warn() -> void:
	var brain := CreatureBrain.new(160.0, 288.0, RANGE, WARNING, LUNGE, REST)
	assert_eq(brain.tick(0.1, 5.0), CreatureBrain.State.UNAWARE)


func test_lunge_comes_after_the_warning_time() -> void:
	var brain := _chasing_brain()
	brain.tick(0.0, RANGE)
	assert_eq(brain.tick(0.3, RANGE), CreatureBrain.State.WARNING, "0,3 s: ainda avisando")
	assert_false(brain.can_hurt())
	assert_eq(brain.tick(0.11, RANGE), CreatureBrain.State.LUNGE, "Passou de 0,4 s")
	assert_true(brain.can_hurt(), "Só o bote machuca")


func test_warning_progress_goes_from_zero_to_one() -> void:
	var brain := _chasing_brain()
	assert_eq(brain.warning_progress(), 0.0, "Fora do aviso")
	brain.tick(0.0, RANGE)
	assert_eq(brain.warning_progress(), 0.0)
	brain.tick(0.2, RANGE)
	assert_almost_eq(brain.warning_progress(), 0.5, 0.001)


func test_rest_comes_after_the_lunge_and_then_the_chase_resumes() -> void:
	var brain := _chasing_brain()
	brain.tick(0.0, RANGE)
	brain.tick(WARNING + 0.01, RANGE)
	assert_eq(brain.tick(LUNGE + 0.01, RANGE), CreatureBrain.State.REST)
	assert_false(brain.can_hurt(), "Descansando não machuca")
	assert_eq(brain.tick(0.6, RANGE), CreatureBrain.State.REST, "0,6 s: ainda descansando")
	assert_eq(brain.tick(0.2, RANGE), CreatureBrain.State.CHASING, "Passou de 0,7 s")


func test_after_resting_with_the_player_still_close_it_warns_again() -> void:
	var brain := _chasing_brain()
	brain.tick(0.0, RANGE)
	brain.tick(WARNING + 0.01, RANGE)
	brain.tick(LUNGE + 0.01, RANGE)
	brain.tick(REST + 0.01, RANGE)
	assert_eq(brain.tick(0.016, RANGE), CreatureBrain.State.WARNING)


func test_scratch_during_the_warning_cancels_the_lunge() -> void:
	var brain := _chasing_brain()
	brain.tick(0.0, RANGE)
	brain.tick(0.2, RANGE)
	brain.scratched()
	assert_eq(brain.state, CreatureBrain.State.REST, "Vai direto para o descanso")
	assert_eq(brain.tick(0.3, RANGE), CreatureBrain.State.REST)
	assert_false(brain.can_hurt(), "O bote não acontece")
	assert_eq(brain.tick(0.5, RANGE), CreatureBrain.State.CHASING, "Descansa os 0,7 s inteiros")


func test_scratch_outside_the_warning_changes_nothing() -> void:
	var brain := _chasing_brain()
	brain.scratched()
	assert_eq(brain.state, CreatureBrain.State.CHASING)
	brain.tick(0.0, RANGE)
	brain.tick(WARNING + 0.01, RANGE)
	brain.scratched()
	assert_eq(brain.state, CreatureBrain.State.LUNGE, "O bote já saiu, o arranhão não cancela")


func test_a_fainted_player_is_not_attacked() -> void:
	var brain := _chasing_brain()
	assert_eq(brain.tick(0.1, 5.0, false), CreatureBrain.State.UNAWARE, "Nem avisa")
	assert_false(brain.is_attacking())
	brain = _chasing_brain()
	brain.tick(0.0, RANGE)
	brain.tick(WARNING + 0.01, RANGE)
	assert_true(brain.can_hurt())
	assert_eq(brain.tick(0.01, RANGE, false), CreatureBrain.State.UNAWARE, "O bote é cancelado")
	assert_false(brain.can_hurt())


func test_update_does_not_interrupt_an_attack() -> void:
	var brain := _chasing_brain()
	brain.tick(0.0, RANGE)
	assert_eq(brain.update(INF), CreatureBrain.State.WARNING, "Desistir só depois do ataque")


func test_attack_times_are_configurable() -> void:
	var brain := CreatureBrain.new(160.0, 288.0, 48.0, 1.0, 0.5, 2.0)
	brain.update(10.0)
	assert_eq(brain.tick(0.0, 40.0), CreatureBrain.State.WARNING, "Alcance maior")
	assert_eq(brain.tick(0.9, 40.0), CreatureBrain.State.WARNING)
	assert_eq(brain.tick(0.2, 40.0), CreatureBrain.State.LUNGE)
