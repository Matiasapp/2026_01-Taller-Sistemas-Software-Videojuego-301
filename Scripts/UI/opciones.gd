extends CanvasLayer
## Menú de Opciones (Audio / Video / Juego). La UI vive en Opciones.tscn;
## aquí solo se inicializan los valores de los nodos existentes y se conecta la lógica.
## Funciona también con el juego en pausa (process_mode = ALWAYS).

@onready var slider_master: HSlider = %SliderMaster
@onready var slider_music: HSlider = %SliderMusica
@onready var slider_sfx: HSlider = %SliderEfectos
@onready var porc_master: Label = %PorcMaster
@onready var porc_music: Label = %PorcMusica
@onready var porc_sfx: Label = %PorcEfectos

@onready var check_pantalla: CheckButton = %CheckPantalla
@onready var check_vsync: CheckButton = %CheckVsync

@onready var btn_restablecer: Button = %BtnRestablecer
@onready var btn_volver: Button = %BtnVolver

@onready var marco: NinePatchRect = $Marco
@onready var fondo: ColorRect = $Fondo

# Acción del InputMap -> botón que muestra su tecla (según las filas del .tscn).
var _botones_control := {}
# Acción que está esperando una tecla nueva (remapeo).
var _accion_esperando := ""
var _boton_esperando: Button = null
# Evita que se dispare la salida más de una vez.
var _cerrando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_botones_control = {
		"mover_arriba": %BtnMoverArriba,
		"mover_abajo": %BtnMoverAbajo,
		"mover_izquierda": %BtnMoverIzquierda,
		"mover_derecha": %BtnMoverDerecha,
		"interactuar": %BtnInteractuar,
		"correr": %BtnCorrer,
	}

	# --- Audio ---
	_conf_slider(slider_master, porc_master, "Master")
	_conf_slider(slider_music, porc_music, "Music")
	_conf_slider(slider_sfx, porc_sfx, "SFX")

	# --- Video ---
	check_pantalla.button_pressed = AJUSTES.fullscreen
	check_vsync.button_pressed = AJUSTES.vsync
	check_pantalla.toggled.connect(func(activo: bool) -> void: AJUSTES.set_pantalla_completa(activo))
	check_vsync.toggled.connect(func(activo: bool) -> void: AJUSTES.set_vsync(activo))

	# --- Controles ---
	for accion in _botones_control:
		var btn: Button = _botones_control[accion]
		btn.text = AJUSTES.nombre_tecla(accion)
		btn.pressed.connect(_iniciar_remapeo.bind(accion, btn))

	# --- Botones inferiores ---
	btn_restablecer.pressed.connect(_on_restablecer)
	btn_volver.pressed.connect(_on_volver)
	for b in [btn_restablecer, btn_volver]:
		b.mouse_entered.connect(AUDIOMANAGER.play_ui_hover)

	_animar_entrada()


## Animación de apertura: el marco crece desde el centro hacia los bordes
## mientras el fondo aparece con un fundido.
func _animar_entrada() -> void:
	# Ocultamos el tamaño desde ya para que no se vea un fotograma "de golpe".
	marco.scale = Vector2.ZERO
	fondo.modulate.a = 0.0

	# Esperamos un frame para que el layout calcule el tamaño real del marco.
	await get_tree().process_frame
	marco.pivot_offset = marco.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 1.0, 0.25)
	var t := tw.tween_property(marco, "scale", Vector2.ONE, 0.32)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)


func _conf_slider(slider: HSlider, pct: Label, bus: String) -> void:
	slider.value = AJUSTES.get_volumen(bus)
	pct.text = "%d%%" % roundi(slider.value * 100.0)
	slider.value_changed.connect(func(v: float) -> void:
		AJUSTES.set_volumen(bus, v)
		pct.text = "%d%%" % roundi(v * 100.0)
	)


# =========================
# REMAPEO DE CONTROLES
# =========================

func _iniciar_remapeo(accion: String, btn: Button) -> void:
	# Si ya esperábamos otra tecla, restauramos ese botón.
	if _boton_esperando != null and is_instance_valid(_boton_esperando):
		_boton_esperando.text = AJUSTES.nombre_tecla(_accion_esperando)

	_accion_esperando = accion
	_boton_esperando = btn
	btn.text = "Presiona una tecla..."


func _input(event: InputEvent) -> void:
	if _accion_esperando == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		get_viewport().set_input_as_handled()

		if event.keycode != KEY_ESCAPE:
			var nuevo := InputEventKey.new()
			nuevo.physical_keycode = event.physical_keycode
			AJUSTES.set_tecla(_accion_esperando, nuevo)

		if is_instance_valid(_boton_esperando):
			_boton_esperando.text = AJUSTES.nombre_tecla(_accion_esperando)

		_accion_esperando = ""
		_boton_esperando = null


# =========================
# ACCIONES
# =========================

func _on_restablecer() -> void:
	AUDIOMANAGER.play_ui_click()
	AJUSTES.restablecer()

	# Refrescamos la UI con los valores por defecto (sin reconectar señales).
	slider_master.value = AJUSTES.get_volumen("Master")
	slider_music.value = AJUSTES.get_volumen("Music")
	slider_sfx.value = AJUSTES.get_volumen("SFX")
	check_pantalla.button_pressed = AJUSTES.fullscreen
	check_vsync.button_pressed = AJUSTES.vsync
	for accion in _botones_control:
		_botones_control[accion].text = AJUSTES.nombre_tecla(accion)


func _on_volver() -> void:
	if _cerrando:
		return
	_cerrando = true
	AUDIOMANAGER.play_ui_click()
	await _animar_salida()
	queue_free()


## Animación de cierre: el marco se encoge hacia el centro mientras el fondo se desvanece.
func _animar_salida() -> void:
	marco.pivot_offset = marco.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fondo, "modulate:a", 0.0, 0.2)
	var t := tw.tween_property(marco, "scale", Vector2.ZERO, 0.22)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_IN)
	await tw.finished
