class_name EndingScreen
extends Control
## Tela de fim da história: aparece quando o jogador escolhe "Voltar para a
## Unifor" no encerramento da campanha. Fecha a história, mostra quantos
## pacientes o Mingau ajudou e leva de volta ao menu inicial.

const STORY := (
	"Mingau atravessou o portal e voltou para a Unifor. Na cabana, a apotecária, "
	+ "já recuperada, segue cuidando de quem chega e guarda no diário tudo o que "
	+ "os dois descobriram juntos."
)
const THANKS := "Obrigado por jogar Apotegato!"

@onready var _story: Label = %Story
@onready var _count: Label = %Count
@onready var _thanks: Label = %Thanks
@onready var _menu_button: Button = %MenuButton


func _ready() -> void:
	# A conclusão congela o jogo; a tela de fim precisa responder mesmo assim.
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.flow.reset()
	Music.play(Music.MENU)
	_story.text = STORY
	_count.text = count_text(GameState.patients.attended_count())
	_thanks.text = THANKS
	_menu_button.pressed.connect(_back_to_menu)
	_menu_button.grab_focus()


## Texto com o número de pacientes ajudados. Fica separado para ser testado.
static func count_text(attended: int) -> String:
	if attended == 1:
		return "1 paciente atendido"
	return "%d pacientes atendidos" % attended


func _back_to_menu() -> void:
	get_tree().change_scene_to_file(ScenePaths.MENU)
