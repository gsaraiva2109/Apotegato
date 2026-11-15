extends GutTest
## Confere o arquivo de campanha sem depender de trocas de cena.

const TEST_SAVE := "user://test_campaign_save.json"


func before_each() -> void:
	GameState.new_game()


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	GameState.new_game()


func test_a_new_checkpoint_replaces_the_previous_one() -> void:
	GameState.backpack.add("mel")
	assert_eq(SaveGame.write(TEST_SAVE, Hearts.MAX), OK)
	GameState.backpack.add("mel")
	assert_eq(SaveGame.write(TEST_SAVE, Hearts.MAX - 1), OK)
	GameState.new_game()
	assert_true(SaveGame.restore(TEST_SAVE))
	assert_eq(GameState.backpack.count("mel"), 2)
	assert_eq(GameState.cabin_entry_hearts, Hearts.MAX - 1)
	assert_false(FileAccess.file_exists(TEST_SAVE + ".tmp"))


func test_invalid_or_missing_save_leaves_the_campaign_intact() -> void:
	GameState.backpack.add("mel", 2)
	assert_false(SaveGame.restore(TEST_SAVE))
	assert_eq(SaveGame.write(TEST_SAVE, Hearts.MAX), OK)
	var valid := SaveGame.read(TEST_SAVE)
	var unsupported_version := valid.duplicate(true)
	unsupported_version["versao"] = SaveGame.VERSION + 1
	var fractional_count := valid.duplicate(true)
	fractional_count["backpack"]["mel"] = 1.5
	for contents: String in [
		"{", "{}", JSON.stringify(unsupported_version), JSON.stringify(fractional_count)
	]:
		var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
		file.store_string(contents)
		file.close()
		assert_false(SaveGame.restore(TEST_SAVE))
		assert_eq(GameState.backpack.count("mel"), 2)
