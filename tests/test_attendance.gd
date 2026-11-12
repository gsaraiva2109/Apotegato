extends GutTest
## Confere o atendimento na cabana (Attendance) contra o roteiro: introdução uma
## vez só, lembrete antes da queixa, pedido depois dela, as respostas da entrega,
## a saída do paciente e o encerramento depois do último atendimento.

var _attendance: Attendance
var _patients: PatientPicker
var _rng: RandomNumberGenerator


func before_each() -> void:
	_attendance = Attendance.new()
	_patients = PatientPicker.new()
	_rng = RandomNumberGenerator.new()
	_rng.seed = 25


func test_intro_plays_only_once() -> void:
	assert_true(_attendance.needs_intro())
	_attendance.finish_intro()
	assert_false(_attendance.needs_intro())


func test_no_patient_means_no_conversation() -> void:
	assert_eq(_attendance.talk_to_patient(), [] as Array[String])
	assert_eq(_attendance.talk_to_apothecary(), [] as Array[String])
	assert_false(_attendance.can_deliver())
	assert_eq(_attendance.delivery_condition(), "")


func test_apothecary_reminds_until_mingau_hears_the_patient() -> void:
	_attendance.arrive("gastrite")
	for i in 2:
		assert_eq(_attendance.talk_to_apothecary(), [Attendance.PATIENT_REMINDER] as Array[String])
		assert_eq(_attendance.phase, Attendance.Phase.ARRIVED)
	assert_eq(_attendance.talk_to_patient(), [Attendance.COMPLAINT] as Array[String])
	assert_eq(_attendance.phase, Attendance.Phase.HEARD)
	assert_eq(_attendance.talk_to_apothecary(), [Attendance.REQUEST] as Array[String])
	assert_eq(_attendance.phase, Attendance.Phase.REQUESTED)


func test_patient_repeats_the_complaint_until_the_end() -> void:
	_attendance.arrive("insonia")
	_attendance.talk_to_patient()
	_attendance.talk_to_apothecary()
	assert_eq(_attendance.talk_to_patient(), [Attendance.COMPLAINT] as Array[String])
	assert_eq(_attendance.phase, Attendance.Phase.REQUESTED, "Repetir a queixa não volta a fase")


func test_delivery_opens_only_after_the_request() -> void:
	_attendance.arrive("diarreia")
	assert_false(_attendance.can_deliver())
	_attendance.talk_to_patient()
	assert_false(_attendance.can_deliver())
	_attendance.talk_to_apothecary()
	assert_true(_attendance.can_deliver())
	assert_eq(_attendance.delivery_condition(), "diarreia")


func test_delivery_topics_follow_the_script() -> void:
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.EMPTY_BACKPACK, false, false),
		[Attendance.DELIVERY_EMPTY] as Array[String],
		"Mochila vazia"
	)
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.PARTIAL, true, false),
		[Attendance.DELIVERY_PARTIAL] as Array[String],
		"Parte dos ingredientes"
	)
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.PARTIAL, false, true),
		[Attendance.DELIVERY_EXTRAS] as Array[String],
		"Só ingredientes que não servem a este paciente"
	)
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.PARTIAL, true, true),
		[Attendance.DELIVERY_EXTRAS, Attendance.DELIVERY_PARTIAL] as Array[String],
		"Sobras e ainda faltando"
	)
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.COMPLETE, true, false),
		[Attendance.GUIDANCE, Attendance.THANKS] as Array[String],
		"Tudo entregue: orientação e agradecimento"
	)
	assert_eq(
		_attendance.delivery_topics(Delivery.Outcome.COMPLETE, true, true),
		[Attendance.DELIVERY_EXTRAS, Attendance.GUIDANCE, Attendance.THANKS] as Array[String],
		"O agradecimento é sempre a última fala"
	)


func test_conclusion_makes_the_patient_leave_without_more_talk() -> void:
	_attendance.arrive("resfriado")
	_attendance.talk_to_patient()
	_attendance.talk_to_apothecary()
	assert_eq(_attendance.conclude(), "resfriado")
	assert_eq(_attendance.phase, Attendance.Phase.LEAVING)
	assert_false(_attendance.has_patient())
	assert_eq(_attendance.talk_to_patient(), [] as Array[String], "Não repete falas")
	assert_eq(_attendance.talk_to_apothecary(), [] as Array[String])
	assert_eq(_attendance.conclude(), "", "Não conclui duas vezes")
	_attendance.patient_left()
	assert_eq(_attendance.phase, Attendance.Phase.NONE)
	assert_eq(_attendance.condition, "")
	assert_eq(_attendance.last_condition, "resfriado")


func test_next_patient_comes_from_the_unattended_conditions() -> void:
	_patients.mark_attended("gastrite")
	for i in 20:
		var condition := _attendance.next_condition(_patients, _rng)
		assert_ne(condition, "gastrite")
		assert_true(condition in IngredientData.get_conditions())


func test_ending_is_due_after_the_last_patient_leaves() -> void:
	_attendance.finish_intro()
	for condition in IngredientData.get_conditions():
		assert_false(_attendance.is_ending_due(_patients))
		_attendance.arrive(condition)
		_attendance.conclude()
		_patients.mark_attended(condition)
		assert_false(_attendance.is_ending_due(_patients), "Ainda saindo")
		_attendance.patient_left()
	assert_true(_attendance.is_ending_due(_patients))
	assert_eq(_attendance.next_condition(_patients, _rng), "", "Campanha sem novos pacientes")


func test_keep_helping_switches_to_the_continuous_draw() -> void:
	_attendance.finish_intro()
	for condition in IngredientData.get_conditions():
		_patients.mark_attended(condition)
	_attendance.start_continuous()
	assert_false(_attendance.is_ending_due(_patients), "O encerramento não volta")
	_attendance.last_condition = "gastrite"
	for i in 20:
		var condition := _attendance.next_condition(_patients, _rng)
		assert_true(condition in IngredientData.get_conditions())
		assert_ne(condition, "gastrite", "Não repete o paciente anterior em seguida")


func test_reset_starts_a_new_campaign() -> void:
	_attendance.finish_intro()
	_attendance.arrive("escorbuto")
	_attendance.start_continuous()
	_attendance.reset()
	assert_true(_attendance.needs_intro())
	assert_eq(_attendance.phase, Attendance.Phase.NONE)
	assert_eq(_attendance.condition, "")
	assert_false(_attendance.continuous)
