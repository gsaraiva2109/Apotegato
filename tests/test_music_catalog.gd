extends GutTest
## Confere o catálogo de faixas: oito ao todo, uma por região mais menu e cabana.


func test_has_eight_tracks() -> void:
	assert_eq(MusicCatalog.all_ids().size(), 8)


func test_every_region_has_its_own_track() -> void:
	for region in Regions.IDS:
		assert_eq(MusicCatalog.track_for_region(region), region)


func test_unknown_region_has_no_track() -> void:
	assert_eq(MusicCatalog.track_for_region("marte"), "")
	assert_eq(MusicCatalog.track_for_region(""), "")


func test_track_ids_are_unique() -> void:
	var ids := MusicCatalog.all_ids()
	for id in ids:
		assert_eq(ids.count(id), 1, id)


func test_path_points_to_ogg_in_music_dir() -> void:
	assert_eq(MusicCatalog.path_for("menu"), "res://assets/audio/third_party/music/menu.ogg")
