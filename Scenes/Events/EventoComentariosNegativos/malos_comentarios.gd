extends Control
## Panel de reseñas de clientes.
##
## Vive dentro de la terminal del PC del taller (SubViewport de ModalPC) y muestra
## las reseñas del día que se está consultando. No aplica castigos: la reputación
## ya se descontó en el momento en que falló la pieza dudosa; acá solo se ve la
## consecuencia. Las reseñas las genera DATOSGLOBALES.registrar_resena_negativa().

signal cerrado

# El marco va de (200,70) a (960,570), pero su hueco oscuro NO coincide con los
# márgenes del NinePatch: la franja oxidada del encabezado llega hasta y≈143 y el
# hueco real es 213..945 en x y 143..551 en y (medido sobre el render sin el
# shader CRT). Las tarjetas se ubican dentro de ese hueco.
const MARGEN_IZQUIERDO := 250.0
const ANCHO_PANEL := 660.0
const ALTO_PANEL := 64.0
const SEPARACION := 8.0
const PRIMER_PANEL_Y := 158.0
# Relleno del texto dentro de cada tarjeta.
const PADDING_X := 18.0
const PADDING_Y := 6.0

# Tinte de la tarjeta segun el tono de la reseña. Van oscuros y translucidos para
# que el texto claro siga leyendose sobre ellos.
const FONDO_POSITIVO := Color(0.09, 0.18, 0.10, 0.9)
const BORDE_POSITIVO := Color(0.247, 0.729, 0.314, 0.55)
const FONDO_NEGATIVO := Color(0.20, 0.08, 0.07, 0.9)
const BORDE_NEGATIVO := Color(0.973, 0.318, 0.286, 0.55)

# Estilo original de las tarjetas, del que se parte para teñir cada una.
var _estilo_base: StyleBoxFlat

@onready var titulo: Label = $Label
@onready var sin_resenas: Label = $SinResenas
@onready var fondo_monitor: Sprite2D = $Sprite2D
@onready var pista_espacio: Control = $Control
@onready var animacion: AnimationPlayer = $AnimationPlayer
@onready var boton_volver: Button = $BtnVolver

@onready var paneles: Array[Panel] = [
	$Comentario_1, $Comentario_2, $Comentario_3, $Comentario_4, $Comentario_5
]

@onready var labels: Array[RichTextLabel] = [
	$Comentario_1/RichTextLabel,
	$Comentario_2/RichTextLabel,
	$Comentario_3/RichTextLabel,
	$Comentario_4/RichTextLabel,
	$Comentario_5/RichTextLabel
]


func _ready() -> void:
	# Dentro del PC sobran el marco del monitor (el PC ya tiene el suyo) y la
	# pista de "pulsa Espacio": ahora se sale con el botón Volver.
	fondo_monitor.visible = false
	pista_espacio.visible = false

	# Se guarda antes de aplicar cualquier override: si no, cada repintado partiría
	# del tinte anterior en vez del estilo limpio.
	_estilo_base = paneles[0].get_theme_stylebox("panel") as StyleBoxFlat

	for i in paneles.size():
		var panel: Panel = paneles[i]
		panel.position = Vector2(MARGEN_IZQUIERDO, PRIMER_PANEL_Y + i * (ALTO_PANEL + SEPARACION))
		panel.size = Vector2(ANCHO_PANEL, ALTO_PANEL)
		panel.visible = false

		var label: RichTextLabel = labels[i]
		label.offset_left = PADDING_X
		label.offset_top = PADDING_Y
		label.offset_right = -PADDING_X
		label.offset_bottom = -PADDING_Y

	boton_volver.pressed.connect(_on_volver_pressed)
	boton_volver.mouse_entered.connect(AUDIOMANAGER.play_ui_soft_hover)


## Pinta las reseñas recibidas (array de {usuario, comentario}). Muestra tantas
## tarjetas como reseñas haya, hasta el máximo de la escena.
func mostrar_resenas(resenas: Array) -> void:
	var cantidad: int = mini(resenas.size(), paneles.size())

	for i in paneles.size():
		paneles[i].visible = i < cantidad

	for i in cantidad:
		var resena: Dictionary = resenas[i]
		labels[i].text = "[b]%s[/b]\n%s" % [
			str(resena.get("usuario", "Anonimo")),
			str(resena.get("comentario", ""))
		]
		# Las reseñas guardadas antes de existir las positivas no traen tono.
		_tenir_tarjeta(paneles[i], str(resena.get("tipo", DATOSGLOBALES.RESENA_NEGATIVA)))

	# El día sin reseñas se avisa con una línea dentro del marco, igual que hace la
	# bitácora del tablero: el título del panel no cambia.
	sin_resenas.visible = cantidad == 0

	if cantidad > 0:
		# La animación escribe el texto de a poco. Ojo: hay dos animaciones en la
		# librería y llamarlas seguidas hace que la segunda cancele a la primera.
		animacion.stop()
		animacion.play("mostrarTexto")
	else:
		animacion.stop()


## Pinta la tarjeta de verde o rojo según el tono de la reseña.
func _tenir_tarjeta(panel: Panel, tipo: String) -> void:
	if _estilo_base == null:
		return

	var estilo: StyleBoxFlat = _estilo_base.duplicate()
	if tipo == DATOSGLOBALES.RESENA_POSITIVA:
		estilo.bg_color = FONDO_POSITIVO
		estilo.border_color = BORDE_POSITIVO
	else:
		estilo.bg_color = FONDO_NEGATIVO
		estilo.border_color = BORDE_NEGATIVO

	panel.add_theme_stylebox_override("panel", estilo)


func _on_volver_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()
	cerrado.emit()
