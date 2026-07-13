extends CanvasLayer
## Panel de resumen de la ATENCIÓN: muestra en la pantalla de resultado de cada
## minijuego el detalle de cuánto dinero y reputación variaron con la reparación.
##
## Toda la interfaz vive en la escena (ResumenAtencion.tscn), editable en el editor.
## Este script solo la rellena leyendo DATOSGLOBALES.get_resumen_atencion() y colorea
## los valores (verde/rojo). Si no hay una atención en curso (p. ej. el minijuego
## aleatorio de easter egg), se elimina solo y no muestra nada.

const COL_VERDE := Color(0.247, 0.729, 0.314)
const COL_ROJO := Color(0.9, 0.35, 0.3)

## Se emite al pulsar "Continuar". El minijuego que instancia este panel lo conecta
## a su propia lógica de regreso al taller (dinero, audio, cambio de escena).
signal continuar

@onready var marco: NinePatchRect = $Marco
@onready var margin: MarginContainer = $Marco/Margin
@onready var vbox: VBoxContainer = $Marco/Margin/VBox
@onready var boton_continuar: Button = %BotonContinuar

@onready var recompensa_valor: Label = %RecompensaValor
@onready var pieza_fila: HBoxContainer = %PiezaFila
@onready var pieza_concepto: Label = %PiezaConcepto
@onready var pieza_valor: Label = %PiezaValor
@onready var diag_penal_fila: HBoxContainer = %DiagPenalFila
@onready var diag_penal_valor: Label = %DiagPenalValor
@onready var balance_valor: Label = %BalanceValor
@onready var rep_diag_valor: Label = %RepDiagValor
@onready var rep_desempeno_valor: Label = %RepDesempenoValor
@onready var rep_total_valor: Label = %RepTotalValor


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Solo tiene sentido dentro del flujo de atención a un cliente (no en el
	# minijuego aleatorio de prueba, que no pasa por atender_cliente()).
	hide() # Nace oculto en lugar de destruirse
	boton_continuar.pressed.connect(_on_continuar_pressed)

	_poblar(DATOSGLOBALES.get_resumen_atencion())
	boton_continuar.pressed.connect(_on_continuar_pressed)

	# El Marco (NinePatchRect) no se autoajusta: le fijamos la altura al contenido
	# real, para que calce igual con o sin la fila "Diagnóstico erróneo".
	await get_tree().process_frame
	_ajustar_marco()


func _on_continuar_pressed() -> void:
	# El sonido de click y el regreso al taller los maneja el minijuego que
	# conectó la señal 'continuar' a su propia lógica de retorno.
	boton_continuar.disabled = true
	continuar.emit()


## Ajusta la altura del Marco a la del contenido (VBox) más los márgenes internos.
func _ajustar_marco() -> void:
	var alto_contenido: float = vbox.get_combined_minimum_size().y
	var borde_v: float = margin.offset_top - margin.offset_bottom
	var margenes_v: float = margin.get_theme_constant("margin_top") + margin.get_theme_constant("margin_bottom")
	marco.size.y = alto_contenido + borde_v + margenes_v


func _poblar(r: Dictionary) -> void:
	var recompensa: int = int(r.get("recompensa_minijuego", 0))
	var costo_pieza: int = int(r.get("costo_pieza", 0))
	var penal_diag: int = int(r.get("penalizacion_diagnostico", 0))
	var tipo_pieza: String = str(r.get("tipo_pieza", ""))
	var balance: int = int(r.get("balance_dinero", 0))
	var rep_diag: int = int(r.get("rep_diagnostico", 0))
	var rep_desempeno: int = int(r.get("rep_desempeno", 0))
	var rep_total: int = int(r.get("rep_total", 0))

	_dinero(recompensa_valor, recompensa)

	pieza_fila.visible = costo_pieza > 0
	pieza_concepto.text = "Pieza (%s)" % tipo_pieza if not tipo_pieza.is_empty() else "Pieza"
	_dinero(pieza_valor, -costo_pieza)

	diag_penal_fila.visible = penal_diag > 0
	_dinero(diag_penal_valor, -penal_diag)

	_dinero(balance_valor, balance)

	_rep(rep_diag_valor, rep_diag)
	_rep(rep_desempeno_valor, rep_desempeno)
	_rep(rep_total_valor, rep_total)


func _dinero(etiqueta: Label, monto: int) -> void:
	etiqueta.text = DATOSGLOBALES.formatear_monto(monto)
	etiqueta.add_theme_color_override("font_color", COL_VERDE if monto >= 0 else COL_ROJO)


func _rep(etiqueta: Label, valor: int) -> void:
	etiqueta.text = "%+d" % valor
	etiqueta.add_theme_color_override("font_color", COL_VERDE if valor >= 0 else COL_ROJO)

func activar_panel() -> void:
	_poblar(DATOSGLOBALES.get_resumen_atencion())
	show()
	await get_tree().process_frame
	_ajustar_marco()
