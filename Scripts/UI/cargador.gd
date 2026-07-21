extends CanvasLayer
## Sistema centralizado de cambio de escena asíncrono (Autoload: CARGADOR).
##
## TODO cambio de escena del juego debe pasar por aquí:
##
##     CARGADOR.cambiar_escena("res://Scenes/Gameplay/GameScreen.tscn")
##
## Nunca se usa `load()` ni `change_scene_to_file()`, porque ambos cargan la
## escena de golpe en el hilo principal y congelan la imagen (y el audio) hasta
## que terminan. Aquí la escena se pide con `ResourceLoader.load_threaded_request()`
## —que carga en un hilo aparte— y se consulta una vez por frame con
## `load_threaded_get_status()`, que devuelve además el progreso real. El hilo
## principal nunca se bloquea: sigue dibujando la pantalla de carga y moviendo
## la barra mientras el recurso llega.

## Se emite justo cuando se acepta una petición de carga.
signal carga_iniciada(ruta: String)
## Progreso real de ResourceLoader, de 0.0 a 1.0.
signal progreso_cambiado(progreso: float)
## La escena ya está activa en el árbol.
signal carga_completada(ruta: String)
## La carga se abandonó: recurso inexistente, corrupto o tiempo agotado.
signal carga_fallida(ruta: String, motivo: String)

const PANTALLA_CARGA := "res://Scenes/UI/PantallaCarga.tscn"
const ESCENA_MENU := "res://Scenes/UI/MainMenu.tscn"

## Si la carga supera este tiempo se da por fallida y se ofrece reintentar,
## en lugar de dejar al jugador mirando una barra congelada para siempre.
const SEGUNDOS_LIMITE := 30.0
## Tiempo mínimo en pantalla: evita el parpadeo cuando la escena ya está en caché.
const SEGUNDOS_MINIMOS := 0.25
## Fracción de barra por segundo. La barra persigue al progreso real en vez de
## saltar a él, para que se vea fluida aunque ResourceLoader avance a tirones.
const VELOCIDAD_BARRA := 4.0
const DURACION_FUNDIDO := 0.3

enum Estado {
	INACTIVO,   ## Sin carga en curso; la pantalla está oculta.
	CARGANDO,   ## Hilo de carga trabajando; se consulta el estado cada frame.
	REVELANDO,  ## Escena ya activa; se está desvaneciendo la pantalla de carga.
	ERROR,      ## Carga abortada; la pantalla muestra el mensaje y las acciones.
}

var _estado: int = Estado.INACTIVO
var _ruta: String = ""
var _progreso_real: float = 0.0
var _progreso_mostrado: float = 0.0
var _tiempo: float = 0.0
var _pantalla: PantallaCarga = null
var _fundido: Tween = null
var _con_pantalla: bool = true


func _ready() -> void:
	layer = 128
	# El cargador tiene que funcionar con el árbol pausado: se sale al menú
	# desde el menú de pausa sin despausar antes.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_asegurar_pantalla()
	visible = false
	set_process(false)


# =========================
# API PÚBLICA
# =========================

## Carga `ruta` en segundo plano, mostrando la pantalla de carga, y cambia a
## ella al terminar. Es la forma normal de cambiar de escena.
## Devuelve false si la petición no se aceptó (ya hay una carga en curso).
func cambiar_escena(ruta: String) -> bool:
	return _iniciar(ruta, true)


## Igual que `cambiar_escena()`, pero sin mostrar la pantalla de carga: la
## escena se sigue cargando en segundo plano (el hilo principal nunca se
## bloquea), solo que la transición es directa.
##
## Es para los saltos internos de un mismo minijuego —por ejemplo tutorial →
## taller → resultados en Soldadura—, donde ver la pantalla de carga en cada
## paso resulta repetitivo. La entrada al minijuego y la vuelta al taller sí
## deben usar `cambiar_escena()`, que es donde la espera se nota.
func cambiar_escena_sin_pantalla(ruta: String) -> bool:
	return _iniciar(ruta, false)


func _iniciar(ruta: String, con_pantalla: bool) -> bool:
	if _estado != Estado.INACTIVO:
		# Dos botones pulsados casi a la vez, o un temporizador que dispara
		# mientras ya se está cambiando: gana la primera petición.
		push_warning("CARGADOR: ya se está cargando '%s', se ignora '%s'." % [_ruta, ruta])
		return false

	_asegurar_pantalla()
	_ruta = ruta
	_con_pantalla = con_pantalla
	_progreso_real = 0.0
	_progreso_mostrado = 0.0
	_tiempo = 0.0
	if _con_pantalla:
		_mostrar_pantalla()

	# La escena anterior sigue viva hasta que la nueva esté lista. Se congela
	# para que no siga jugándose (ni disparando temporizadores o eventos) por
	# debajo de la pantalla de carga; al ser opaca, el jugador no lo nota.
	# La despausa la hace _completar() justo antes del cambio.
	get_tree().paused = true

	# Los minijuegos usan cámara lenta (Engine.time_scale). Si una escena cambia
	# sin restaurarla, el delta de _process viene escalado y la carga entera —
	# barra, tiempo mínimo y tiempo límite— iría igual de lenta, además de
	# heredarse en la escena nueva. Se normaliza aquí para todos.
	Engine.time_scale = 1.0

	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		_fallar("La escena no existe en el proyecto:\n%s" % ruta)
		return false

	# use_sub_threads = false a propósito: repartir la carga en varios hilos la
	# acelera, pero según la documentación puede afectar al hilo principal y
	# provocar tirones, que es justo lo que se quiere evitar aquí.
	var error := ResourceLoader.load_threaded_request(
		ruta, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE
	)
	if error != OK:
		_fallar("No se pudo iniciar la carga (error %d)." % error)
		return false

	_estado = Estado.CARGANDO
	set_process(true)
	carga_iniciada.emit(ruta)
	return true


## Pide una escena por adelantado sin mostrar nada, para que un `cambiar_escena()`
## posterior sea instantáneo. Útil, por ejemplo, para adelantar el taller
## mientras el jugador todavía está leyendo la introducción.
func precargar(ruta: String) -> void:
	if ruta.is_empty() or not ResourceLoader.exists(ruta):
		push_warning("CARGADOR: no se puede precargar una ruta inexistente: %s" % ruta)
		return
	ResourceLoader.load_threaded_request(
		ruta, "PackedScene", false, ResourceLoader.CACHE_MODE_REUSE
	)


func esta_cargando() -> bool:
	return _estado == Estado.CARGANDO or _estado == Estado.REVELANDO


## Progreso real reportado por ResourceLoader (0.0 - 1.0).
func progreso() -> float:
	return _progreso_real


# =========================
# BUCLE DE CARGA
# =========================

func _process(delta: float) -> void:
	_tiempo += delta

	if _estado == Estado.CARGANDO:
		_consultar_estado()

	# La barra se mueve siempre que hay algo que mostrar, también mientras se
	# revela la escena nueva, para que llegue al 100 % de forma continua.
	if _con_pantalla and _progreso_mostrado != _progreso_real:
		_progreso_mostrado = move_toward(_progreso_mostrado, _progreso_real, VELOCIDAD_BARRA * delta)
		_pantalla.set_progreso(_progreso_mostrado)


func _consultar_estado() -> void:
	var progreso_hilo: Array = []
	var estado := ResourceLoader.load_threaded_get_status(_ruta, progreso_hilo)

	match estado:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			if not progreso_hilo.is_empty():
				_fijar_progreso(float(progreso_hilo[0]))
			if _tiempo > SEGUNDOS_LIMITE:
				_fallar("La carga tardó más de %d segundos y se canceló." % int(SEGUNDOS_LIMITE))
		ResourceLoader.THREAD_LOAD_LOADED:
			_fijar_progreso(1.0)
			_completar()
		ResourceLoader.THREAD_LOAD_FAILED:
			_fallar("El archivo de la escena está dañado o falta un recurso suyo.")
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fallar("La ruta no corresponde a un recurso válido.")


func _fijar_progreso(valor: float) -> void:
	var nuevo := clampf(valor, 0.0, 1.0)
	if is_equal_approx(nuevo, _progreso_real):
		return
	_progreso_real = nuevo
	progreso_cambiado.emit(_progreso_real)


func _completar() -> void:
	var recurso := ResourceLoader.load_threaded_get(_ruta)
	var escena := recurso as PackedScene
	if escena == null:
		_fallar("El recurso cargado no es una escena (PackedScene).")
		return

	_estado = Estado.REVELANDO

	# Se espera a que la barra alcance el 100 % y a que se cumpla el tiempo
	# mínimo: si no, una escena en caché haría parpadear la pantalla de carga.
	# Sin pantalla no hay nada que esperar: se cambia en cuanto está lista.
	while _con_pantalla and (_progreso_mostrado < 1.0 or _tiempo < SEGUNDOS_MINIMOS):
		await get_tree().process_frame
		if _estado != Estado.REVELANDO:
			return  # Se canceló o falló mientras esperábamos.

	# Una escena nueva nunca debe heredar la pausa de la anterior.
	get_tree().paused = false

	var error := get_tree().change_scene_to_packed(escena)
	if error != OK:
		_fallar("No se pudo instanciar la escena (error %d)." % error)
		return

	carga_completada.emit(_ruta)
	await _revelar()


## Espera a que la escena nueva se instancie y desvanece la pantalla de carga.
func _revelar() -> void:
	if not _con_pantalla:
		# No había nada tapando: la escena nueva ya está en pantalla.
		_estado = Estado.INACTIVO
		set_process(false)
		return

	# change_scene_to_packed cambia la escena al final del frame: hacen falta dos
	# frames para que la nueva esté instanciada y dibujada antes de destapar.
	await get_tree().process_frame
	await get_tree().process_frame

	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
	_fundido = create_tween()
	_fundido.tween_property(_pantalla, "modulate:a", 0.0, DURACION_FUNDIDO)
	await _fundido.finished

	_ocultar_pantalla()
	_estado = Estado.INACTIVO


# =========================
# ERRORES
# =========================

func _fallar(motivo: String) -> void:
	push_error("CARGADOR: %s [%s]" % [motivo, _ruta])
	_estado = Estado.ERROR
	set_process(false)
	# El jugador se queda en la pantalla de carga con el error y una salida:
	# antes el juego se quedaba mudo en la escena anterior. Un fallo se muestra
	# siempre, aunque la transición fuera silenciosa: si no, el juego se
	# quedaría congelado en la escena anterior sin ninguna explicación.
	if not _con_pantalla:
		_mostrar_pantalla()
	_pantalla.mostrar_error(motivo, _ruta != ESCENA_MENU)
	carga_fallida.emit(_ruta, motivo)


func _reintentar() -> void:
	if _estado != Estado.ERROR:
		return
	var ruta := _ruta
	_estado = Estado.INACTIVO
	cambiar_escena(ruta)


func _volver_al_menu() -> void:
	if _estado != Estado.ERROR:
		return
	_estado = Estado.INACTIVO
	cambiar_escena(ESCENA_MENU)


# =========================
# PANTALLA
# =========================

func _asegurar_pantalla() -> void:
	if _pantalla != null:
		return
	# Carga bloqueante, pero solo del propio marco de carga: es una escena
	# mínima y ocurre una única vez al arrancar el juego.
	var empaquetada: PackedScene = load(PANTALLA_CARGA)
	_pantalla = empaquetada.instantiate() as PantallaCarga
	add_child(_pantalla)
	_pantalla.reintentar_pedido.connect(_reintentar)
	_pantalla.volver_al_menu_pedido.connect(_volver_al_menu)


func _mostrar_pantalla() -> void:
	if _fundido != null and _fundido.is_valid():
		_fundido.kill()
	_pantalla.mostrar_carga()
	visible = true


func _ocultar_pantalla() -> void:
	visible = false
	set_process(false)
