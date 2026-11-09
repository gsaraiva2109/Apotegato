extends CanvasLayer

const JOURNAL_DATA_PATH := "res://data/diario.json"

const REGION_NAMES := {
	"amazonia": "Amazônia",
	"caatinga": "Caatinga",
	"campos_rios": "Campos e Rios",
	"cerrado": "Cerrado",
	"litoral": "Litoral Brasileiro",
	"mata_atlantica": "Mata Atlântica",
}

const PARITY_NAMES := {
	"par": "pares",
	"impar": "ímpares",
}

# =====================================================
# CONTROLE DO DIÁRIO
# =====================================================

var _paused_before_open: bool = false
var _current_page: int = 0

var _journal_data: Dictionary = {}
var _pages: Array[Dictionary] = []

# =====================================================
# REFERÊNCIAS AOS ELEMENTOS DA INTERFACE
# =====================================================

@onready var _root: Control = $Root

@onready var _page_title: Label = $Root/Center/Panel/Layout/Title
@onready var _page_subtitle: Label = $Root/Center/Panel/Layout/Subtitle
@onready var _page_content: Label = $Root/Center/Panel/Layout/Scroll/PageContent
@onready var _page_image: TextureRect = $Root/Center/Panel/Layout/PageImage

@onready var _page_counter: Label = $Root/Center/Panel/Layout/Footer/PageCounter

@onready var _previous_button: Button = $Root/Center/Panel/Layout/Footer/PreviousButton
@onready var _next_button: Button = $Root/Center/Panel/Layout/Footer/NextButton
@onready var _close_button: Button = $Root/Center/Panel/Layout/Footer/CloseButton

# =====================================================
# INICIALIZAÇÃO
# =====================================================


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_root.hide()

	_page_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_page_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_page_image.custom_minimum_size = Vector2(0, 140)
	_page_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_previous_button.pressed.connect(_go_to_previous_page)
	_next_button.pressed.connect(_go_to_next_page)
	_close_button.pressed.connect(close)

	if _load_journal_data():
		_build_pages()

	_update_page()


# =====================================================
# CARREGAMENTO DO JSON
# =====================================================


func _load_journal_data() -> bool:
	if not FileAccess.file_exists(JOURNAL_DATA_PATH):
		push_error("Diário: arquivo não encontrado: " + JOURNAL_DATA_PATH)
		return false

	var file := FileAccess.open(JOURNAL_DATA_PATH, FileAccess.READ)

	if file == null:
		push_error("Diário: não foi possível abrir o arquivo JSON.")
		return false

	var parsed_data: Variant = JSON.parse_string(file.get_as_text())

	if typeof(parsed_data) != TYPE_DICTIONARY:
		push_error("Diário: o arquivo JSON possui uma estrutura inválida.")
		return false

	_journal_data = parsed_data

	return true


# =====================================================
# CONSTRUÇÃO DAS PÁGINAS
# =====================================================


func _build_pages() -> void:
	_pages.clear()

	_build_introduction_pages()
	_build_region_pages()
	_build_condition_pages()
	_build_ingredient_pages()

	_current_page = 0

	print("Diário carregado: %d páginas." % _pages.size())


# =====================================================
# INTRODUÇÃO
# =====================================================


func _build_introduction_pages() -> void:
	var introduction_pages: Variant = _journal_data.get("introduction", [])

	if typeof(introduction_pages) != TYPE_ARRAY:
		return

	for page_data: Variant in introduction_pages:
		if typeof(page_data) != TYPE_DICTIONARY:
			continue

		_pages.append(_make_static_page(page_data))


# =====================================================
# REGIÕES
# =====================================================


func _build_region_pages() -> void:
	var regions: Variant = _journal_data.get("regions", {})
	var region_order: Variant = _journal_data.get("region_order", [])

	if typeof(regions) != TYPE_DICTIONARY:
		return

	if typeof(region_order) != TYPE_ARRAY:
		return

	for region_id_value: Variant in region_order:
		var region_id := str(region_id_value)

		if not regions.has(region_id):
			push_warning("Diário: região sem descrição: " + region_id)
			continue

		var region_data: Dictionary = regions[region_id]

		_pages.append(_make_region_page(region_id, region_data))


func _make_region_page(region_id: String, region_data: Dictionary) -> Dictionary:
	var content_before := str(region_data.get("content_before", ""))
	var content_after := str(region_data.get("content_after", ""))
	var ingredient_notes: Dictionary = region_data.get("ingredient_notes", {})

	var item_lines := PackedStringArray()
	var item_number := 1

	for parity: String in ["par", "impar"]:
		var ingredients: Array[Ingredient] = IngredientData.get_ingredients_in(region_id, parity)

		for ingredient: Ingredient in ingredients:
			var parity_name: String = PARITY_NAMES.get(parity, parity)

			var line := (
				"%d. %s — andares %s."
				% [
					item_number,
					_get_ingredient_title(ingredient.id, ingredient),
					parity_name,
				]
			)

			var note := str(ingredient_notes.get(ingredient.id, ""))

			if not note.is_empty():
				line += " " + note

			item_lines.append(line)
			item_number += 1

	var content := content_before

	content += "\n\nItens encontrados nesta região:\n"

	if item_lines.is_empty():
		content += "Nenhum ingrediente cadastrado nesta região."
	else:
		content += "\n".join(item_lines)

	if not content_after.is_empty():
		content += "\n\n" + content_after

	return {
		"id": region_id,
		"title": str(region_data.get("title", "")),
		"subtitle": str(region_data.get("subtitle", "Região")),
		"content": content.strip_edges(),
		"image": str(region_data.get("image", "")),
		"category": "region",
	}


# =====================================================
# CONDIÇÕES
# =====================================================


func _build_condition_pages() -> void:
	var conditions: Variant = _journal_data.get("conditions", {})
	var condition_order: Variant = _journal_data.get("condition_order", [])

	if typeof(conditions) != TYPE_DICTIONARY:
		return

	if typeof(condition_order) != TYPE_ARRAY:
		return

	for condition_id_value: Variant in condition_order:
		var condition_id := str(condition_id_value)

		if not conditions.has(condition_id):
			push_warning("Diário: condição sem descrição: " + condition_id)
			continue

		var condition_data: Dictionary = conditions[condition_id]

		_pages.append(_make_condition_page(condition_id, condition_data))


func _make_condition_page(condition_id: String, condition_data: Dictionary) -> Dictionary:
	var content_before := str(condition_data.get("content_before", ""))
	var content_after := str(condition_data.get("content_after", ""))

	var ingredient_notes: Dictionary = condition_data.get("ingredient_notes", {})

	var requirements: Array[PackedStringArray] = IngredientData.get_requirements(condition_id)

	var ingredient_lines := PackedStringArray()
	var requirement_number := 1

	for group: PackedStringArray in requirements:
		var choices := PackedStringArray()
		var note := ""

		for ingredient_id: String in group:
			var ingredient: Ingredient = IngredientData.get_ingredient(ingredient_id)

			if ingredient == null:
				continue

			var ingredient_title := _get_ingredient_title(ingredient_id, ingredient)

			var region_name := _get_region_name(ingredient.region)

			choices.append("%s — %s" % [ingredient_title, region_name])

			if note.is_empty():
				note = str(ingredient_notes.get(ingredient_id, ""))

		if choices.is_empty():
			continue

		var choice_text := " ou ".join(choices)

		var line := (
			"%d. %s"
			% [
				requirement_number,
				choice_text,
			]
		)

		if not note.is_empty():
			line += ". " + note
		else:
			line += "."

		ingredient_lines.append(line)
		requirement_number += 1

	var content := content_before
	content += "\n\nIngredientes associados:\n"

	if ingredient_lines.is_empty():
		content += "Nenhum ingrediente cadastrado para esta condição."
	else:
		content += "\n".join(ingredient_lines)

	if not content_after.is_empty():
		content += "\n\n" + content_after

	return {
		"id": condition_id,
		"title": str(condition_data.get("title", "")),
		"subtitle": str(condition_data.get("subtitle", "Condição")),
		"content": content.strip_edges(),
		"image": str(condition_data.get("image", "")),
		"category": "condition",
	}


# =====================================================
# INGREDIENTES
# =====================================================


func _build_ingredient_pages() -> void:
	var ingredient_pages: Variant = _journal_data.get("ingredients", {})

	if typeof(ingredient_pages) != TYPE_DICTIONARY:
		push_error("Diário: seção de ingredientes inválida.")
		return

	var all_ingredients: Array[Ingredient] = IngredientData.get_all_ingredients()

	for ingredient: Ingredient in all_ingredients:
		var ingredient_id := ingredient.id

		var raw_page: Variant = ingredient_pages.get(ingredient_id, {})

		var ingredient_data: Dictionary = {}

		if typeof(raw_page) == TYPE_DICTIONARY:
			ingredient_data = raw_page
		else:
			push_warning("Diário: descrição não cadastrada: " + ingredient_id)

		_pages.append(_make_ingredient_page(ingredient_id, ingredient, ingredient_data))


func _make_ingredient_page(
	ingredient_id: String, ingredient: Ingredient, ingredient_data: Dictionary
) -> Dictionary:
	var content_before := str(ingredient_data.get("content_before", ""))

	var content_after := str(ingredient_data.get("content_after", ""))

	if content_before.is_empty():
		content_before = "Descrição ainda não cadastrada."

	var region_name := _get_region_name(ingredient.region)

	var content := content_before
	content += "\n\nOnde encontrar:\n" + region_name + "."

	if not content_after.is_empty():
		content += "\n\n" + content_after

	var image_path := str(ingredient_data.get("image", ""))

	return {
		"id": ingredient_id,
		"title": str(ingredient_data.get("title", ingredient.display_name)),
		"subtitle": str(ingredient_data.get("subtitle", "Item")),
		"content": content.strip_edges(),
		"image": image_path,
		"category": "item",
	}


# =====================================================
# PÁGINAS ESTÁTICAS
# =====================================================


func _make_static_page(source: Dictionary) -> Dictionary:
	return {
		"title": str(source.get("title", "")),
		"subtitle": str(source.get("subtitle", "")),
		"content": str(source.get("content", "")),
		"image": str(source.get("image", "")),
		"category": str(source.get("category", "")),
	}


# =====================================================
# NOMES DOS INGREDIENTES E REGIÕES
# =====================================================


func _get_ingredient_title(ingredient_id: String, ingredient: Ingredient) -> String:
	var ingredients_data: Dictionary = _journal_data.get("ingredients", {})

	var ingredient_data: Variant = ingredients_data.get(ingredient_id, {})

	if typeof(ingredient_data) == TYPE_DICTIONARY:
		var title := str(ingredient_data.get("title", ""))

		if not title.is_empty():
			return title

	return ingredient.display_name


func _get_region_name(region_id: String) -> String:
	return str(REGION_NAMES.get(region_id, region_id))


# =====================================================
# ENTRADAS DO JOGADOR
# =====================================================


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		if _root.visible:
			close()
		else:
			open()

		get_viewport().set_input_as_handled()

	elif _root.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# =====================================================
# VERIFICAÇÃO DE OUTROS MENUS
# =====================================================


func _has_other_menu_open() -> bool:
	var scene_parent := get_parent()

	if scene_parent == null:
		return false

	for sibling: Node in scene_parent.get_children():
		if sibling == self:
			continue

		if not sibling.has_method("is_open"):
			continue

		if bool(sibling.call("is_open")):
			return true

	return false


# =====================================================
# ABRIR E FECHAR O DIÁRIO
# =====================================================


func open() -> void:
	if _root.visible:
		return

	if _has_other_menu_open():
		return

	_paused_before_open = get_tree().paused

	_root.show()
	get_tree().paused = true


func close() -> void:
	if not _root.visible:
		return

	_root.hide()
	get_tree().paused = _paused_before_open


func is_open() -> bool:
	return _root.visible


# =====================================================
# NAVEGAÇÃO ENTRE PÁGINAS
# =====================================================


func _go_to_next_page() -> void:
	if _current_page < _pages.size() - 1:
		_current_page += 1
		_update_page()


func _go_to_previous_page() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_page()


# =====================================================
# CARREGAMENTO DA IMAGEM
# =====================================================


func _update_page_image(image_path: String) -> void:
	_page_image.texture = null
	_page_image.hide()

	if image_path.is_empty():
		return

	if not ResourceLoader.exists(image_path):
		push_warning("Imagem não encontrada: " + image_path)
		return

	var loaded_texture := load(image_path) as Texture2D

	if loaded_texture == null:
		push_warning("Não foi possível carregar a imagem: " + image_path)
		return

	_page_image.texture = loaded_texture
	_page_image.show()


# =====================================================
# ATUALIZAÇÃO DA PÁGINA
# =====================================================


func _update_page() -> void:
	if _pages.is_empty():
		_page_title.text = "Diário da Apotecária"
		_page_subtitle.text = ""
		_page_content.text = "Nenhuma página cadastrada."
		_page_counter.text = "Diário vazio"

		_page_image.texture = null
		_page_image.hide()

		_previous_button.disabled = true
		_next_button.disabled = true
		return

	_current_page = clampi(_current_page, 0, _pages.size() - 1)

	var page: Dictionary = _pages[_current_page]

	_page_title.text = str(page.get("title", "Sem título"))
	_page_subtitle.text = str(page.get("subtitle", ""))
	_page_content.text = str(page.get("content", ""))

	var image_path := str(page.get("image", ""))
	_update_page_image(image_path)

	_page_counter.text = (
		"Página %d / %d"
		% [
			_current_page + 1,
			_pages.size(),
		]
	)

	_previous_button.disabled = _current_page == 0
	_next_button.disabled = _current_page >= _pages.size() - 1
