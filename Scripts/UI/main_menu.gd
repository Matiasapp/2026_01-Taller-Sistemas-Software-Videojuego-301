extends Node2D

@onready var en_desarrollo = $en_desarrollo
@onready var confirmar_nueva_partida = $ConfirmarNuevaPartida
@onready var creditos_link: Button = $CanvasLayer/CreditosLink
@onready var creditos_resplandor: Label = $CanvasLayer/CreditosResplandor
@onready var creditos_overlay: Control = $CanvasLayer/CreditosOverlay
@onready var creditos_fondo: ColorRect = $CanvasLayer/CreditosOverlay/Fondo
@onready var creditos_panel: NinePatchRect = $CanvasLayer/CreditosOverlay/CreditosPanel
@onready var creditos_scroll: ScrollContainer = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/Rollo
@onready var creditos_barra: VScrollBar = creditos_scroll.get_v_scroll_bar()
@onready var creditos_cerrar: Button = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/BtnVolver
@onready var creditos_contenido: Control = $CanvasLayer/CreditosOverlay/CreditosPanel/Contenido/Rollo/Creditos
@onready var seccion_equipo: VBoxContainer = creditos_contenido.get_node("SeccionEquipo")
@onready var fade_nueva_partida: ColorRect = $CanvasLayer/FadeNuevaPartida
@onready var nueva_partida_whoosh: AudioStreamPlayer = $NuevaPartidaWhoosh

const VELOCIDAD_CREDITOS := 18.0
const ESPERA_INICIAL_CREDITOS := 0.8

# =========================
# EQUIPO (créditos detallados)
# =========================
# Una entrada por persona, en el orden en que aparecen en pantalla.
# 'foto' es la ruta a una imagen cuadrada (basta 128x128, se dibuja a 48x48);
# si se deja vacía se ve el marco vacío, así la lista funciona sin fotos.
# El rol se dibuja en una sola línea: si no entra, se corta con puntos suspensivos.
const EQUIPO: Array[Dictionary] = [
	{
		"nombre": "Fernanda Durandeau",
		"rol": "Product Owner",
		"foto": "res://Assets/Creditos/Equipo/FernandaDurandeau.jpeg"
	},
	{"nombre": "Ignacio Saavedra", "rol": "QA", "foto": ""},
	{
		"nombre": "Matías Ponce",
		"rol": "Tech Lead · Infraestructura y seguridad · Desarrollador",
		"foto": "res://Assets/Creditos/Equipo/MatiasPonce.png"
	},
	{
		"nombre": "Bruno Bernardo Roque Mendoza",
		"rol": "Música y diseño de audio · Desarrollador",
		"foto": "res://Assets/Creditos/Equipo/BrunoRoque.png",
		"easter_egg": true
	},
	{"nombre": "Diego Constanzo", "rol": "Desarrollador", "foto": ""},
	{"nombre": "Cristopher González", "rol": "Desarrollador", "foto": ""},
	{"nombre": "Gabriel Araya", "rol": "Desarrollador", "foto": ""},
]

const FOTO_LADO := 48

## Easter egg: doble clic en la foto marcada abre un minijuego que quedó fuera
## del taller. No lleva ninguna pista visual a propósito.
const EASTER_EGG_SCENE := "res://Scenes/Minigames/TheFloorIsLava/the_floor_is_lava.tscn"
## Los créditos se maquetan con posiciones absolutas: todo lo que empiece a esta
## altura o más abajo se corre hacia abajo al insertar la lista del equipo.
const ANCLA_EQUIPO_Y := 535.0
const MARGEN_TRAS_EQUIPO := 30.0

var creditos_scroll_pos := 0.0
var creditos_scroll_espera := 0.0
var creditos_scroll_activo := false
var creditos_scroll_arrastrando := false
var creditos_scroll_actualizando := false
var iniciando_nueva_partida := false

@export var click_sound: AudioStreamPlayer
@export var hover_sound: AudioStreamPlayer
@export var menu_music: AudioStream


# =========================
# AUDIO
# =========================

func play_click() -> void:
	if click_sound:
		var semitones = randf_range(-2.0, 2.0)
		click_sound.pitch_scale = pow(2.0, semitones / 12.0)
		click_sound.play()


func play_hover() -> void:
	if hover_sound:
		var semitones = randf_range(-5.0, 5.0)
		hover_sound.pitch_scale = pow(2.0, semitones / 12.0)
		hover_sound.play()


# =========================
# READY
# =========================

func _ready() -> void:
	randomize()

	if menu_music:
		GlobalMusic.play_music(menu_music)
		GlobalMusic.set_menu_volume()
	else:
		push_warning("No hay música asignada en Menu Music.")

	# En navegador no se puede cerrar la pestaña desde el juego, así que ocultamos "Salir".
	if OS.has_feature("web"):
		$CanvasLayer/VBoxContainer/button_exit.hide()

	# Si no hay partida guardada, atenuamos (deshabilitamos) "Cargar Partida".
	$CanvasLayer/VBoxContainer/button_load_game.disabled = not PARTIDA.hay_partida()

	confirmar_nueva_partida.confirmado.connect(_on_confirmar_nueva_partida_confirmed)
	creditos_barra.value_changed.connect(_on_creditos_barra_value_changed)

	_construir_equipo()


# ========================= 
# BOTONES
# =========================

func _on_button_new_game_pressed() -> void:
	play_click()

	# Si ya hay una partida guardada, confirmamos antes de sobrescribirla.
	if PARTIDA.hay_partida():
		confirmar_nueva_partida.abrir(
			"Nueva Partida",
			"Ya tienes una partida guardada. Si empiezas una nueva, la sobrescribirás. ¿Continuar?",
			"Sí, empezar",
			"Cancelar"
		)
		return

	_iniciar_nueva_partida()


func _on_confirmar_nueva_partida_confirmed() -> void:
	_iniciar_nueva_partida()


func _iniciar_nueva_partida() -> void:
	if iniciando_nueva_partida:
		return
	iniciando_nueva_partida = true

	# Nueva partida: borramos el guardado anterior y reiniciamos todo el estado.
	PARTIDA.borrar()
	DATOSGLOBALES.reiniciar()
	if CLIENTMANAGER:
		CLIENTMANAGER.reiniciar()
	if TIEMPOMANAGER:
		TIEMPOMANAGER.reset_day()

	await get_tree().create_timer(0.12).timeout
	await _transicion_a_intro()

	print("Iniciando el nivel...")
	CARGADOR.cambiar_escena("res://Scenes/Gameplay/IntroScreen.tscn")


func _transicion_a_intro() -> void:
	fade_nueva_partida.visible = true
	fade_nueva_partida.modulate.a = 0.0
	fade_nueva_partida.mouse_filter = Control.MOUSE_FILTER_STOP

	if nueva_partida_whoosh:
		nueva_partida_whoosh.pitch_scale = 1.0
		nueva_partida_whoosh.play()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(fade_nueva_partida, "modulate:a", 1.0, 0.55)
	await tween.finished

	if nueva_partida_whoosh and nueva_partida_whoosh.playing:
		await nueva_partida_whoosh.finished


func _on_button_load_game_pressed() -> void:
	play_click()

	if not PARTIDA.hay_partida():
		en_desarrollo.dialog_text = "No hay ninguna partida guardada."
		en_desarrollo.popup_centered()
		return

	if not PARTIDA.cargar():
		en_desarrollo.dialog_text = "No se pudo cargar la partida."
		en_desarrollo.popup_centered()
		return

	await get_tree().create_timer(0.15).timeout
	# Cargar partida salta la introducción, que normalmente es la encargada de
	# apagar la música persistente del menú antes de entrar al taller.
	await GlobalMusic.fade_out_and_stop(0.35)
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	CARGADOR.cambiar_escena(destino)


func _on_button_exit_pressed() -> void:
	play_click()

	await get_tree().create_timer(0.15).timeout
	get_tree().quit()


func _on_button_options_pressed() -> void:
	play_click()
	var opciones := preload("res://Scenes/UI/Opciones.tscn").instantiate()
	add_child(opciones)


# =========================
# EQUIPO EN LOS CRÉDITOS
# =========================

## Construye la lista del equipo y corre hacia abajo el resto de los créditos,
## que están posicionados a mano. Así agregar o quitar gente no descuadra nada.
func _construir_equipo() -> void:
	for datos in EQUIPO:
		seccion_equipo.add_child(_crear_fila_integrante(datos))

	var alto: float = seccion_equipo.get_combined_minimum_size().y
	seccion_equipo.size = Vector2(seccion_equipo.size.x, alto)

	var desplazamiento: float = alto + MARGEN_TRAS_EQUIPO
	for hijo in creditos_contenido.get_children():
		if hijo == seccion_equipo or not hijo is Control:
			continue
		var control := hijo as Control
		if control.offset_top >= ANCLA_EQUIPO_Y:
			control.offset_top += desplazamiento
			control.offset_bottom += desplazamiento

	creditos_contenido.custom_minimum_size.y += desplazamiento


## Una fila: marco con la foto (o vacío si todavía no hay) y, al lado, el nombre
## sobre lo que hizo esa persona.
func _crear_fila_integrante(datos: Dictionary) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 12)
	fila.custom_minimum_size = Vector2(0, FOTO_LADO)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var marco := _crear_marco_foto(str(datos.get("foto", "")))
	if bool(datos.get("easter_egg", false)):
		marco.mouse_filter = Control.MOUSE_FILTER_STOP
		marco.gui_input.connect(_on_foto_easter_egg_input)
	fila.add_child(marco)

	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	textos.add_theme_constant_override("separation", 2)
	textos.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var nombre := Label.new()
	nombre.text = str(datos.get("nombre", ""))
	nombre.add_theme_color_override("font_color", Color(0.95, 0.86, 0.64))
	nombre.add_theme_font_size_override("font_size", 14)
	textos.add_child(nombre)

	var rol := Label.new()
	rol.text = str(datos.get("rol", ""))
	rol.add_theme_color_override("font_color", Color(0.82, 0.79, 0.73))
	rol.add_theme_font_size_override("font_size", 12)
	# Sin autowrap a propósito: una etiqueta que ajusta líneas mide su altura
	# contra el ancho que le asigne el contenedor, y los créditos viven en un
	# overlay oculto, donde no corre el layout. Con una sola línea la altura es
	# predecible; si el rol no entra, se corta con puntos suspensivos.
	rol.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(rol)

	fila.add_child(textos)
	return fila


func _on_foto_easter_egg_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var clic := event as InputEventMouseButton
	if clic.button_index == MOUSE_BUTTON_LEFT and clic.double_click:
		_lanzar_easter_egg()


## Abre el minijuego suelto, sin tocar la partida: al terminar vuelve al menú.
func _lanzar_easter_egg() -> void:
	if CARGADOR.esta_cargando():
		return

	play_click()
	DATOSGLOBALES.easter_egg_activo = true
	_cerrar_creditos()

	# GlobalMusic es autoload: si no se apaga acá, la música del menú se
	# superpone con la del minijuego. Al volver, el _ready del menú la reanuda.
	await GlobalMusic.fade_out_and_stop(0.35)

	CARGADOR.cambiar_escena(EASTER_EGG_SCENE)


func _crear_marco_foto(ruta: String) -> Panel:
	var marco := Panel.new()
	marco.custom_minimum_size = Vector2(FOTO_LADO, FOTO_LADO)
	marco.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marco.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(0.09, 0.06, 0.04, 0.9)
	estilo.border_color = Color(0.882, 0.686, 0.18, 0.35)
	estilo.set_border_width_all(1)
	estilo.set_corner_radius_all(3)
	marco.add_theme_stylebox_override("panel", estilo)

	# Sin foto se deja el marco vacío: la lista se ve igual de ordenada y las
	# imágenes se pueden ir agregando de a una.
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		if not ruta.is_empty():
			push_warning("Creditos: no existe la foto '%s'." % ruta)
		return marco

	var foto := TextureRect.new()
	foto.texture = load(ruta)
	foto.set_anchors_preset(Control.PRESET_FULL_RECT)
	foto.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foto.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	foto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# El proyecto filtra en Nearest para el pixel art, pero una foto reducida a
	# 48 px con ese filtro sale dentada: estas van suavizadas y con mipmaps.
	foto.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	marco.add_child(foto)
	return marco


# =========================
# CRÉDITOS
# =========================

## El enlace de créditos usa la variante suave del sonido de UI, para
## diferenciarse de los botones principales del menú.
func _on_creditos_link_pressed() -> void:
	AUDIOMANAGER.play_ui_soft_click()
	_animar_resplandor_creditos()
	_abrir_creditos()


func _on_cerrar_creditos_pressed() -> void:
	play_click()
	_cerrar_creditos()


## Apertura: el panel crece desde el centro con un pequeño rebote mientras el fondo
## aparece con un fundido. Es la misma animación que usa el menú de Opciones
## (ver _animar_entrada en opciones.gd); si se ajusta una, ajustar la otra.
func _abrir_creditos() -> void:
	if creditos_overlay.visible:
		return

	creditos_link.release_focus()
	creditos_cerrar.disabled = false
	creditos_overlay.visible = true
	# El fundido lo hace el fondo, no el overlay completo: así el panel solo escala.
	creditos_overlay.modulate.a = 1.0
	creditos_fondo.modulate.a = 0.0
	creditos_panel.pivot_offset = creditos_panel.size / 2.0
	creditos_panel.scale = Vector2.ZERO
	creditos_scroll_actualizando = true
	creditos_scroll.scroll_vertical = 0
	creditos_scroll_actualizando = false
	creditos_scroll_pos = 0.0
	creditos_scroll_espera = ESPERA_INICIAL_CREDITOS
	creditos_scroll_activo = true
	creditos_scroll_arrastrando = false

	var tween := create_tween().set_parallel(true)
	tween.tween_property(creditos_fondo, "modulate:a", 1.0, 0.25)
	var t := tween.tween_property(creditos_panel, "scale", Vector2.ONE, 0.32)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)
	creditos_cerrar.grab_focus()


## Cierre: el panel se encoge hacia el centro mientras el fondo se desvanece.
func _cerrar_creditos() -> void:
	if not creditos_overlay.visible:
		return

	creditos_scroll_activo = false
	creditos_scroll_arrastrando = false

	creditos_panel.pivot_offset = creditos_panel.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(creditos_fondo, "modulate:a", 0.0, 0.2)
	var t := tween.tween_property(creditos_panel, "scale", Vector2.ZERO, 0.22)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_IN)
	await tween.finished

	creditos_overlay.visible = false
	creditos_panel.scale = Vector2.ONE
	creditos_fondo.modulate.a = 1.0
	creditos_cerrar.release_focus()
	creditos_link.release_focus()


func _process(delta: float) -> void:
	if not creditos_scroll_activo or not creditos_overlay.visible:
		return

	if creditos_scroll_arrastrando:
		creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
		return

	if creditos_scroll_espera > 0.0:
		creditos_scroll_espera -= delta
		return

	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	if creditos_scroll_pos >= limite:
		creditos_scroll_activo = false
		return

	creditos_scroll_pos = minf(creditos_scroll_pos + VELOCIDAD_CREDITOS * delta, limite)
	creditos_scroll_actualizando = true
	creditos_scroll.scroll_vertical = roundi(creditos_scroll_pos)
	creditos_scroll_actualizando = false


func _on_creditos_barra_value_changed(valor: float) -> void:
	if creditos_scroll_actualizando or not creditos_overlay.visible:
		return

	creditos_scroll_pos = valor
	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	creditos_scroll_activo = valor < limite


func _input(event: InputEvent) -> void:
	if not creditos_overlay.visible or not event is InputEventMouseButton:
		return

	var evento_mouse := event as InputEventMouseButton
	if evento_mouse.button_index != MOUSE_BUTTON_LEFT:
		return

	if evento_mouse.pressed and creditos_barra.get_global_rect().has_point(evento_mouse.position):
		creditos_scroll_arrastrando = true
		creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
	elif not evento_mouse.pressed and creditos_scroll_arrastrando:
		creditos_scroll_arrastrando = false
		call_deferred("_reanudar_creditos_desde_barra")


func _reanudar_creditos_desde_barra() -> void:
	creditos_scroll_pos = float(creditos_scroll.scroll_vertical)
	creditos_scroll_espera = 0.0
	var limite := maxf(0.0, creditos_barra.max_value - creditos_barra.page)
	creditos_scroll_activo = creditos_scroll_pos < limite


func _animar_resplandor_creditos() -> void:
	creditos_resplandor.modulate.a = 0.0
	creditos_resplandor.scale = Vector2(0.98, 0.98)

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(creditos_resplandor, "modulate:a", 0.9, 0.08)
	tween.tween_property(creditos_resplandor, "scale", Vector2(1.035, 1.035), 0.16)
	await tween.finished

	tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(creditos_resplandor, "modulate:a", 0.0, 0.28)
	tween.tween_property(creditos_resplandor, "scale", Vector2.ONE, 0.28)


func _unhandled_input(event: InputEvent) -> void:
	if creditos_overlay.visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cerrar_creditos()


# =========================
# HOVER
# =========================

func _on_button_new_game_mouse_entered() -> void:
	play_hover()


func _on_button_load_game_mouse_entered() -> void:
	play_hover()


func _on_button_options_mouse_entered() -> void:
	play_hover()


func _on_button_exit_mouse_entered() -> void:
	play_hover()


func _on_creditos_link_mouse_entered() -> void:
	AUDIOMANAGER.play_ui_soft_hover()


func _on_creditos_volver_mouse_entered() -> void:
	if not creditos_cerrar.disabled and creditos_overlay.visible:
		play_hover()
