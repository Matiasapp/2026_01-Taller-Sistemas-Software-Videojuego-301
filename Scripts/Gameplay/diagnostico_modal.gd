extends Control

signal diagnostico_resuelto(correcto: bool)

const DIAGNOSTICOS: Dictionary = {
	"generica": "No hay un patrón claro... conviene una revisión general del auto.",
	"pinchazo": "Parece un problema en las ruedas o los neumáticos.",
	"soldadura": "Suena a una pieza suelta o quebrada: hay que soldarla.",
	"gasolina": "Todo apunta al sistema de combustible.",
	"circuito": "Es algo del sistema eléctrico del auto.",
}

const TIEMPO_FEEDBACK_CORRECTO: float = 1.3
const TIEMPO_FEEDBACK_INCORRECTO: float = 3.0

@onready var label_pregunta: Label = $Panel/LabelPregunta
@onready var label_feedback: Label = $Panel/LabelFeedback
@onready var boton_volver: Button = $Panel/BotonVolver
@onready var correct_sound: AudioStreamPlayer = $CorrectSound
@onready var wrong_sound: AudioStreamPlayer = $WrongSound

@onready var botones: Array[Button] = [
	$Panel/VBox/Boton1,
	$Panel/VBox/Boton2,
	$Panel/VBox/Boton3,
	$Panel/VBox/Boton4,
]

var falla_real: String = ""
var fallas_opciones: Array = []
var resuelto: bool = false


func _ready() -> void:
	hide()

	for i in botones.size():
		botones[i].pressed.connect(_on_opcion_pressed.bind(i))

	boton_volver.pressed.connect(cerrar)


func cerrar() -> void:
	hide()


func abrir(falla: String) -> void:
	falla_real = falla
	resuelto = false
	label_feedback.text = ""

	var otras: Array = DIAGNOSTICOS.keys()
	otras.erase(falla)
	otras.shuffle()

	fallas_opciones = [falla, otras[0], otras[1], otras[2]]
	fallas_opciones.shuffle()

	for i in botones.size():
		botones[i].text = DIAGNOSTICOS.get(fallas_opciones[i], "")
		botones[i].disabled = false
		botones[i].modulate = Color.WHITE

	boton_volver.disabled = false
	boton_volver.modulate.a = 1.0

	show()


func _on_opcion_pressed(indice: int) -> void:
	if resuelto:
		return

	resuelto = true

	boton_volver.disabled = true
	boton_volver.modulate.a = 0.35

	var elegida: String = fallas_opciones[indice]
	var correcto: bool = elegida == falla_real

	for i in botones.size():
		if fallas_opciones[i] == falla_real:
			botones[i].modulate = Color(0.55, 1.0, 0.55)
		elif i == indice:
			botones[i].modulate = Color(1.0, 0.55, 0.55)

	if correcto:
		label_feedback.text = "¡Diagnóstico correcto!"
		play_correct()
	else:
		label_feedback.text = "Diagnóstico incorrecto. Igual atenderás el auto, pero te costará."
		play_wrong()

	var espera: float = TIEMPO_FEEDBACK_CORRECTO if correcto else TIEMPO_FEEDBACK_INCORRECTO
	await get_tree().create_timer(espera).timeout

	hide()
	diagnostico_resuelto.emit(correcto)


func play_correct() -> void:
	if not correct_sound:
		return

	correct_sound.volume_db = -10.0
	correct_sound.pitch_scale = randf_range(0.98, 1.04)
	correct_sound.play()


func play_wrong() -> void:
	if not wrong_sound:
		return

	wrong_sound.volume_db = -6.0
	wrong_sound.pitch_scale = randf_range(0.96, 1.02)
	wrong_sound.play()
