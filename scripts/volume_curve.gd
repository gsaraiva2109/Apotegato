class_name VolumeCurve
extends RefCounted
## Conversão do volume das opções (porcentagem de 0 a 100) para decibéis dos
## barramentos de áudio. Lógica pura, sem cena, para os testes conferirem.

## Volume em dB de um barramento silenciado.
const SILENT_DB := -80.0
const MIN_PERCENT := 0
const MAX_PERCENT := 100


## Porcentagem de 0 a 100 (valores fora da faixa são limitados) para dB. Zero
## por cento e o mudo dão `SILENT_DB`; 100% dá 0 dB.
static func to_db(percent: int, muted: bool = false) -> float:
	var clamped := clampi(percent, MIN_PERCENT, MAX_PERCENT)
	if muted or clamped == 0:
		return SILENT_DB
	return maxf(linear_to_db(clamped / 100.0), SILENT_DB)
