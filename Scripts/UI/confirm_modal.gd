extends CanvasLayer
## Modal de confirmación reutilizable con el estilo metálico del juego y animación
## de entrada/salida (crece desde el centro). Emite `confirmado` o `cancelado`.
## Uso:  modal.abrir("Título", "Mensaje", "Sí", "Cancelar")  y conectar sus señales.

signal confirmado
signal cancelado

@onready var fondo: ColorRect = $Fondo
@onready var marco: NinePatchRect = $Marco
@onready var titulo: Label = %Titulo
@onready var mensaje: Label = %Mensaje
@onready var btn_confirmar: Button = %BtnConfirmar
@onready var btn_cancelar: Button = %BtnCancelar

var _cerrando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	btn_confirmar.pressed.connect(_on_confirmar)
	btn_cancelar.pressed.connect(_on_cancelar)
	for b in [btn_confirmar, btn_cancelar]:
		b.mouse_entered.connect(AUDIOMANAGER.play_ui_hover)


## Muestra el modal con los textos indicados y lo anima creciendo desde el centro.
func abrir(titulo_txt: String, mensaje_txt: String, texto_confirmar := "Sí", texto_cancelar := "Cancelar") -> void:
	titulo.text = titulo_txt
	mensaje.text = mensaje_txt
	btn_confirmar.text = texto_confirmar
	btn_cancelar.text = texto_cancelar
	_cerrando = false

	marco.scale = Vector2.ZERO
	fondo.modulate.a = 0.0
	visible = true

	await get_tree().process_frame
	marco.pivot_offset = marco.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 1.0, 0.25)
	var t := tw.tween_property(marco, "scale", Vector2.ONE, 0.32)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)


## Animación de cierre: se encoge hacia el centro mientras el fondo se desvanece.
func _cerrar_anim() -> void:
	marco.pivot_offset = marco.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 0.0, 0.2)
	var t := tw.tween_property(marco, "scale", Vector2.ZERO, 0.22)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_IN)
	await tw.finished
	visible = false


func _on_confirmar() -> void:
	if _cerrando:
		return
	_cerrando = true
	AUDIOMANAGER.play_ui_click()
	await _cerrar_anim()
	confirmado.emit()


func _on_cancelar() -> void:
	if _cerrando:
		return
	_cerrando = true
	AUDIOMANAGER.play_ui_click()
	await _cerrar_anim()
	cancelado.emit()
