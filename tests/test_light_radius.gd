extends GutTest
## Confere a fórmula da luz: min(0,6 + 0,12 * n; 1,8).


func test_no_defeated_gives_the_base_light() -> void:
	assert_almost_eq(LightRadius.for_defeated(0), 0.6, 0.0001)


func test_one_defeated_adds_a_step() -> void:
	assert_almost_eq(LightRadius.for_defeated(1), 0.72, 0.0001)


func test_ten_defeated_reach_the_cap_exactly() -> void:
	assert_almost_eq(LightRadius.for_defeated(10), 1.8, 0.0001)


func test_light_never_passes_the_cap() -> void:
	assert_almost_eq(LightRadius.for_defeated(11), 1.8, 0.0001)
	assert_almost_eq(LightRadius.for_defeated(1000), 1.8, 0.0001)


func test_light_grows_one_step_at_a_time_until_the_cap() -> void:
	var previous := LightRadius.for_defeated(0)
	for n in range(1, 10):
		var current := LightRadius.for_defeated(n)
		assert_almost_eq(current - previous, 0.12, 0.0001, "n = %d" % n)
		previous = current


func test_negative_count_counts_as_zero() -> void:
	assert_almost_eq(LightRadius.for_defeated(-3), 0.6, 0.0001)


func test_constants_match_the_design_numbers() -> void:
	assert_eq(LightRadius.BASE, 0.6)
	assert_eq(LightRadius.PER_DEFEATED, 0.12)
	assert_eq(LightRadius.MAX, 1.8)
