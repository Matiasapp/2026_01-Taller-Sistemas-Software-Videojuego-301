extends Node2D

# Audio
@onready var click_sound: AudioStreamPlayer = $ClickSound
@onready var hover_sound: AudioStreamPlayer = $HoverSound

# --- Configuración del atlas de clientes (ss.png) ---
const ATLAS_CLIENTES: Texture2D = preload("res://Assets/Sprites/clientes_atendidos/ss.png")
const TAMANO_FRAME: int = 200            # Cada frame mide 200x200
const FRAMES_POR_CLIENTE: int = 4        # Columnas (frames de animación) por fila
const NOMBRE_ANIMACION: StringName = &"movimiento"
const VELOCIDAD_ANIMACION: float = 1.0   # FPS de la animación
const DIALOGO_POR_DEFECTO: String = "Hola, necesito que reparen mi auto."
const FALLA_POR_DEFECTO: String = "generica"
const VELOCIDAD_TEXTO: float = 35.0   # Caracteres por segundo del efecto máquina de escribir
const PENALIZACION_DIAGNOSTICO: int = 50   # Dinero perdido al diagnosticar mal la falla

## Minijuego (reparación) que se lanza según la falla del cliente.
const FALLA_A_MINIJUEGO: Dictionary = {
	"generica": "res://Scenes/Minigames/Crossy_Road/Crossy Road.tscn",
	"pinchazo": "res://Scenes/Minigames/Neumaticos/MinijuegoNeumatico.tscn",
	"soldadura": "res://Scenes/Minigames/Soldadura/Game_start.tscn",
	"gasolina": "res://Scenes/Minigames/TheFloorIsLava/the_floor_is_lava.tscn",
	"circuito": "res://Scenes/Minigames/MemoryGame/MemoryGame.tscn",
}

## Datos por cliente, en orden de fila del atlas (índice = fila; 0 = primera).
## Campos por entrada:
##   "nombre"  (String)
##   "dialogo" (String): da indicios de la falla SIN que el cliente la sepa con certeza.
##   "falla"   (String): "generica", "pinchazo", "soldadura", "gasolina" o "circuito".
##   "frames"  (int, opcional): para usar si la fila tiene menos columnas que las 4 normales.
## Las fallas están balanceadas: 5 clientes por cada una de las 5 categorías.
const DATOS_CLIENTES: Array[Dictionary] = [
	{"nombre": "anciano_chaqueta_verde",
	 "falla": "generica",
	 "dialogo": "No sabría explicarle, joven... siento que ya no anda como antes. Algo no está bien, pero no logro decir qué."},

	{"nombre": "hombre_mustacho",
	 "falla": "pinchazo",
	 "dialogo": "A cierta velocidad el volante me vibra y el auto se va solo hacia un costado. ¿Será la dirección?"},

	{"nombre": "joven_estudioso",
	 "frames": 3,
	 "falla": "circuito",
	 "dialogo": "A veces hace cosas raras: se reinicia algo solo y vuelve a la normalidad. Es intermitente, no logro reproducirlo."},

	{"nombre": "mujer_rubia",
	 "falla": "gasolina",
	 "dialogo": "Cuando me detengo en un semáforo el motor se ahoga y se apaga. Al retomar tose un poco antes de reaccionar."},

	{"nombre": "heisenberg",
	 "falla": "soldadura",
	 "dialogo": "Cada vez que tomo un bache escucho un golpe seco abajo. Lo quiero impecable, sin medias tintas."},

	{"nombre": "joven_mecanico",
	 "falla": "generica",
	 "dialogo": "Yo ya revisé lo obvio y nada. Hay algo raro pero no logro aislarlo; te dejo el diagnóstico a ti."},

	{"nombre": "señora_generica",
	 "falla": "circuito",
	 "dialogo": "Hay mañanas en que no quiere partir, y otras arranca sin problema. No le encuentro ninguna lógica."},

	{"nombre": "katniss_everdeen",
	 "falla": "pinchazo",
	 "dialogo": "Venía por un camino de piedras y desde entonces el auto va inestable, como desnivelado de una esquina."},

	{"nombre": "señor_dudoso",
	 "falla": "gasolina",
	 "estafador": true,
	 "dialogo": "Mmm... mire, no rinde como antes y a veces da unos tirones al acelerar. No sé, usted dirá."},

	{"nombre": "messi",
	 "falla": "pinchazo",
	 "dialogo": "Andaba bien y de golpe sentí un saque feo de un lado; ahora va como rengueando, viste."},

	{"nombre": "jim_halpert",
	 "falla": "generica",
	 "dialogo": "Hace un ruido... raro. ¿Cómo lo describo? Raro. No sabría ni ubicarlo, confío en que tú sí."},

	{"nombre": "rintaro",
	 "falla": "circuito",
	 "dialogo": "Falla de forma intermitente, como una línea temporal inestable: a veces responde, a veces no, sin patrón alguno."},

	{"nombre": "corxea",
	 "falla": "soldadura",
	 "dialogo": "Algo abajo suena suelto y golpea al pasar los topes, suena entero mal hermano. Cachái que da miedo manejarlo."},

	{"nombre": "saul_goodman",
	 "falla": "gasolina",
	 "dialogo": "Mire, no soy mecánico, pero pierde fuerza y se me apaga en lo mejor. Usted arréglelo y yo no vi nada."},

	{"nombre": "german_garmendia",
	 "falla": "generica",
	 "dialogo": "¡Ho-ola soy germán y te apue- Digo... hola. El auto hace algo raro y ni idea qué será, ayúdame, porfis."},

	{"nombre": "gregory_house",
	 "falla": "circuito",
	 "dialogo": "Todos asumen que es el motor. Nunca es el motor. El síntoma aparece y desaparece solo... eso siempre miente."},

	{"nombre": "hayley_williams",
	 "falla": "soldadura",
	 "dialogo": "Hay una resonancia metálica fea cuando acelero, como algo trizado que vibra. Igual que un feedback en vivo."},

	{"nombre": "abuela_generica",
	 "falla": "generica",
	 "dialogo": "Mijo, el autito ya no anda como antes. No sé qué será, revíselo con cariño y me cuenta."},

	{"nombre": "michonne_hawthorne",
	 "frames": 3,
	 "falla": "soldadura",
	 "dialogo": "Algo cede ahí abajo cuando exijo el auto, lo siento poco firme. Lo necesito sólido, sin juego."},

	{"nombre": "Abuelo_Generico",
	 "falla": "gasolina",
	 "dialogo": "En mis tiempos esto no pasaba... le cuesta tomar fuerza y de a poco se va apagando solo."},

	{"nombre": "Pam_Beesly",
	 "falla": "circuito",
	 "dialogo": "Hay cosas que a veces responden y a veces no, sin razón aparente. Es de lo más extraño, ¿no?"},

	{"nombre": "Hugo_Reyes",
	 "falla": "pinchazo",
	 "dialogo": "Viejo, sentí un golpe feo y ahora el auto rebota y tira para un lado. Qué mala suerte, hermano."},

	{"nombre": "Mujer_Maravilla",
	 "falla": "soldadura",
	 "dialogo": "Percibo algo que cede bajo el chasis, resuena con cada impacto. Requiere mano firme."},

	{"nombre": "paty_maldonado",
	 "falla": "gasolina",
	 "dialogo": "Yo se lo digo derechito: no rinde nada y da tirones cuando acelero. Arréglemelo y punto."},

	{"nombre": "patrick_jane",
	 "falla": "pinchazo",
	 "dialogo": "Observe: cómo tira a la izquierda, el desgaste disparejo de un solo costado... no hace falta ser mentalista para deducir de dónde viene."},
]

@onready var anim: AnimatedSprite2D = $CanvasLayer/AnimatedSprite2D
@onready var label_dialogo: RichTextLabel = $CanvasLayer/PanelDialogo/RichTextLabel
@onready var talking_sound: AudioStreamPlayer = $TalkingSound
@onready var modal_diagnostico = $CanvasLayer/DiagnosticoModal
@onready var boton_atender: Button = $CanvasLayer/BotonAtender

var clientes: Array[ClienteData] = []
var indice_actual: int = 0
var cliente_actual: ClienteData = null
var tween_texto: Tween = null
var escribiendo: bool = false
var ruta_minijuego_pendiente := ""

func _ready() -> void:
	if modal_diagnostico:
		modal_diagnostico.diagnostico_resuelto.connect(_on_diagnostico_resuelto)

	conectar_sonidos_botones(self)

	generar_clientes()

	if clientes.is_empty():
		push_warning("AtencionCliente: no se generó ningún cliente desde el atlas.")
		return

	_mostrar_cliente_aleatorio()

## Elige un cliente al azar que NO haya aparecido aún en la partida y lo muestra.
## Si ya aparecieron todos, reinicia el registro para poder seguir (evita quedarse sin clientes).
func _mostrar_cliente_aleatorio() -> void:
	var disponibles: Array[int] = []
	for i in clientes.size():
		if not DATOSGLOBALES.clientes_usados.has(i):
			disponibles.append(i)

	if disponibles.is_empty():
		DATOSGLOBALES.clientes_usados.clear()
		for i in clientes.size():
			disponibles.append(i)

	indice_actual = disponibles.pick_random()
	DATOSGLOBALES.clientes_usados.append(indice_actual)
	mostrar_cliente(clientes[indice_actual])

## Construye la lista de clientes recorriendo las filas del atlas ss.png.
func generar_clientes() -> void:
	clientes.clear()
	if ATLAS_CLIENTES == null:
		return

	var num_filas: int = ATLAS_CLIENTES.get_height() / TAMANO_FRAME
	for fila in num_filas:
		var datos: Dictionary = DATOS_CLIENTES[fila] if fila < DATOS_CLIENTES.size() else {}

		var data := ClienteData.new()
		data.nombre = datos.get("nombre", "cliente_%d" % fila)
		data.dialogo = datos.get("dialogo", DIALOGO_POR_DEFECTO)
		data.falla = datos.get("falla", FALLA_POR_DEFECTO)
		data.estafador = datos.get("estafador", false)
		data.animacion = NOMBRE_ANIMACION
		data.frames = _crear_frames_fila(fila, datos.get("frames", FRAMES_POR_CLIENTE))
		clientes.append(data)

## Crea un SpriteFrames recortando una fila del atlas en 'cantidad_frames' columnas.
func _crear_frames_fila(fila: int, cantidad_frames: int) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.add_animation(NOMBRE_ANIMACION)
	sf.set_animation_loop(NOMBRE_ANIMACION, true)
	sf.set_animation_speed(NOMBRE_ANIMACION, VELOCIDAD_ANIMACION)
	# SpriteFrames incluye una animación "default" de fábrica; la quitamos.
	if sf.has_animation(&"default"):
		sf.remove_animation(&"default")

	for col in cantidad_frames:
		var atlas := AtlasTexture.new()
		atlas.atlas = ATLAS_CLIENTES
		atlas.region = Rect2(col * TAMANO_FRAME, fila * TAMANO_FRAME, TAMANO_FRAME, TAMANO_FRAME)
		sf.add_frame(NOMBRE_ANIMACION, atlas)

	return sf

func mostrar_cliente(data: ClienteData) -> void:
	if data == null or not anim:
		return

	cliente_actual = data

	# Mostramos nombre (en negrita) y diálogo del cliente actual con efecto máquina de escribir.
	if label_dialogo:
		_animar_texto("[b]%s[/b]\n\n%s" % [data.nombre.capitalize(), data.dialogo])

	if data.frames:
		anim.sprite_frames = data.frames

	if not anim.sprite_frames:
		return

	# Si la animación indicada no existe, usamos la primera disponible como respaldo.
	var anim_a_reproducir := data.animacion
	if not anim.sprite_frames.has_animation(anim_a_reproducir):
		var nombres := anim.sprite_frames.get_animation_names()
		if nombres.size() == 0:
			return
		anim_a_reproducir = nombres[0]

	anim.play(anim_a_reproducir)

## Revela el texto del diálogo con efecto máquina de escribir (como en IntroScreen).
func _animar_texto(texto: String) -> void:
	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	label_dialogo.text = texto
	label_dialogo.visible_ratio = 0.0

	var total: int = label_dialogo.get_total_character_count()
	var duracion: float = clamp(total / VELOCIDAD_TEXTO, 0.3, 4.0)

	escribiendo = true
	_start_talking()

	# Bloqueamos "Atender" hasta que termine de salir el texto (estilo IntroScreen: atenuado).
	if boton_atender:
		boton_atender.disabled = true
		boton_atender.modulate.a = 0.35

	tween_texto = create_tween()
	tween_texto.tween_property(label_dialogo, "visible_ratio", 1.0, duracion)
	tween_texto.finished.connect(func():
		escribiendo = false
		_stop_talking()
		if boton_atender:
			boton_atender.disabled = false
			boton_atender.modulate.a = 1.0
	)

## Completa el texto al instante (clic mientras escribe).
func saltar_animacion() -> void:
	if tween_texto and tween_texto.is_valid():
		tween_texto.kill()

	label_dialogo.visible_ratio = 1.0
	escribiendo = false
	_stop_talking()

	if boton_atender:
		boton_atender.disabled = false
		boton_atender.modulate.a = 1.0

## Un clic izquierdo salta la animación si aún está escribiendo.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if escribiendo:
			saltar_animacion()
			get_viewport().set_input_as_handled()

func _start_talking() -> void:
	if not talking_sound:
		return

	talking_sound.stop()
	talking_sound.pitch_scale = randf_range(0.95, 1.05)
	talking_sound.play()


func _stop_talking() -> void:
	if talking_sound:
		talking_sound.stop()

## Abre el modal de diagnóstico para el cliente actual.
func atender_cliente() -> void:
	if cliente_actual == null:
		return
	modal_diagnostico.abrir(cliente_actual.falla)

## Tras el diagnóstico: si fue incorrecto se penaliza, y en ambos casos se lanza
## el minijuego de la falla REAL del cliente.
func _on_diagnostico_resuelto(correcto: bool) -> void:
	if cliente_actual == null:
		return

	if not correcto:
		DATOSGLOBALES.restar_dinero(PENALIZACION_DIAGNOSTICO)

	DATOSGLOBALES.registrar_diagnostico_dia(correcto)

	var resultado_diagnostico: String = "correcto" if correcto else "incorrecto"
	DATOSGLOBALES.registrar_evento_dia(
		"Diagnostico %s: %s tenia falla de tipo %s."
		% [resultado_diagnostico, cliente_actual.nombre.capitalize(), cliente_actual.falla]
	)

	var ruta: String = FALLA_A_MINIJUEGO.get(cliente_actual.falla, "")
	if ruta.is_empty():
		push_warning("AtencionCliente: no hay minijuego mapeado para la falla '%s'." % cliente_actual.falla)
		return

	ruta_minijuego_pendiente = ruta

	DATOSGLOBALES.estafa_pendiente = cliente_actual.estafador
	if cliente_actual.estafador:
		DATOSGLOBALES.dinero_antes_estafa = DATOSGLOBALES.dinero
		DATOSGLOBALES.nombre_estafador = cliente_actual.nombre.capitalize()

	var seleccion = preload(
		"res://Scenes/UI/seleccion_pieza.tscn"
	).instantiate()

	add_child(seleccion)
	seleccion.pieza_elegida.connect(_on_pieza_elegida)

func _on_pieza_elegida(tipo: String) -> void:

	print("Pieza elegida:", tipo)

	get_tree().change_scene_to_file(
		ruta_minijuego_pendiente
	)
	
func play_click() -> void:
	if not click_sound:
		return

	var semitones := randf_range(-2.0, 2.0)
	click_sound.pitch_scale = pow(2.0, semitones / 12.0)

	click_sound.volume_db = -7.0
	click_sound.play()


func play_hover() -> void:
	if escribiendo:
		return

	if not hover_sound:
		return

	var semitones := randf_range(-1.5, 1.5)
	hover_sound.pitch_scale = pow(2.0, semitones / 12.0)

	hover_sound.volume_db = -15.0
	hover_sound.play()

func conectar_sonidos_botones(nodo: Node) -> void:
	for hijo in nodo.get_children():
		if hijo is Button:
			hijo.pressed.connect(play_click)
			hijo.mouse_entered.connect(play_hover)

		conectar_sonidos_botones(hijo)
