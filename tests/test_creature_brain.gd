extends GutTest
## Confere a máquina de estados da criatura: não percebeu, perseguindo, as
## distâncias de detecção e de desistência e a histerese entre elas.


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
