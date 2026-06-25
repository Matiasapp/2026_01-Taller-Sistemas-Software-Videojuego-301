extends Control

## Modal de diagnóstico: muestra una pregunta con 4 frases de diagnóstico y avisa si se acertó.
## Úsalo llamando a abrir(falla_real) y escuchando la señal diagnostico_resuelto(correcto).
signal diagnostico_resuelto(correcto: bool)

## Frase de diagnóstico (lo que ve el jugador) por cada tipo de falla.
const DIAGNOSTICOS: Dictionary = {
	"generica": "No hay un patrón claro... conviene una revisión general del auto.",
	"pinchazo": "Parece un problema en las ruedas o los neumáticos.",
	"soldadura": "Suena a una pieza suelta o quebrada: hay que soldarla.",
	"gasolina": "Todo apunta al sistema de combustible.",
	"circuito": "Es algo del sistema eléctrico del auto.",
}

const TIEMPO_FEEDBACK_CORRECTO: float = 1.3     # Segundos de feedback al acertar
const TIEMPO_FEEDBACK_INCORRECTO: float = 3.0   # Más tiempo al fallar (mensaje más largo)

@onready var label_pregunta: Label = $Panel/LabelPregunta
@onready var label_feedback: Label = $Panel/LabelFeedback
@onready var boton_volver: Button = $Panel/BotonVolver
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

## Cierra el modal sin responder, volviendo a la pantalla con la pista del cliente.
func cerrar() -> void:
	hide()

## Arma la pregunta (correcta + 3 distractoras al azar) y muestra el modal.
func abrir(falla: String) -> void:
	falla_real = falla
	resuelto = false
	label_feedback.text = ""

	# 4 opciones: la falla real + 3 distractoras aleatorias de las otras categorías.
	var otras: Array = DIAGNOSTICOS.keys()
	otras.erase(falla)
	otras.shuffle()

	fallas_opciones = [falla, otras[0], otras[1], otras[2]]
	fallas_opciones.shuffle()

	for i in botones.size():
		botones[i].text = DIAGNOSTICOS.get(fallas_opciones[i], "")
		botones[i].disabled = false
		botones[i].modulate = Color.WHITE  # Limpiamos el tinte del intento anterior

	boton_volver.disabled = false
	boton_volver.modulate.a = 1.0

	show()

func _on_opcion_pressed(indice: int) -> void:
	if resuelto:
		return
	resuelto = true

	# Ya no se puede volver: el diagnóstico está hecho y se lanzará el minijuego.
	boton_volver.disabled = true
	boton_volver.modulate.a = 0.35

	var elegida: String = fallas_opciones[indice]
	var correcto: bool = elegida == falla_real

	# Feedback de color (sin deshabilitar para evitar el gris feo):
	# verde la correcta, roja la elegida si se equivocó.
	for i in botones.size():
		if fallas_opciones[i] == falla_real:
			botones[i].modulate = Color(0.55, 1.0, 0.55)
		elif i == indice:
			botones[i].modulate = Color(1.0, 0.55, 0.55)

	if correcto:
		label_feedback.text = "¡Diagnóstico correcto!"
	else:
		label_feedback.text = "Diagnóstico incorrecto. Igual atenderás el auto, pero te costará."

	var espera: float = TIEMPO_FEEDBACK_CORRECTO if correcto else TIEMPO_FEEDBACK_INCORRECTO
	await get_tree().create_timer(espera).timeout

	hide()
	diagnostico_resuelto.emit(correcto)
