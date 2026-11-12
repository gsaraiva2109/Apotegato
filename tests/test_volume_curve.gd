extends GutTest
## Confere a conversão de porcentagem para decibéis dos volumes das opções.


func test_full_volume_is_zero_db() -> void:
	assert_almost_eq(VolumeCurve.to_db(100), 0.0, 0.001)


func test_zero_percent_and_mute_are_silent() -> void:
	assert_eq(VolumeCurve.to_db(0), VolumeCurve.SILENT_DB)
	assert_eq(VolumeCurve.to_db(80, true), VolumeCurve.SILENT_DB)


func test_half_volume_is_about_minus_six_db() -> void:
	assert_almost_eq(VolumeCurve.to_db(50), -6.02, 0.05)


func test_volume_grows_with_the_percentage() -> void:
	var previous := VolumeCurve.to_db(1)
	for percent in range(5, 101, 5):
		var db := VolumeCurve.to_db(percent)
		assert_gt(db, previous, "%d%% deveria ser mais alto" % percent)
		previous = db


func test_values_out_of_range_are_clamped() -> void:
	assert_almost_eq(VolumeCurve.to_db(250), 0.0, 0.001)
	assert_eq(VolumeCurve.to_db(-10), VolumeCurve.SILENT_DB)
