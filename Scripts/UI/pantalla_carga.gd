extends Control
class_name PantallaCarga
## Vista de la pantalla de carga. No sabe nada de ResourceLoader: solo dibuja lo
## que le pasa el autoload CARGADOR (Scripts/UI/cargador.gd), que es quien hace
## la carga asíncrona y decide cuándo mostrar el error.

## El jugador pulsó "Reintentar" en la pantalla de error.
signal reintentar_pedido
## El jugador pulsó "Volver al menú" en la pantalla de error.
signal volver_al_menu_pedido

var _spinner: Control
var _titulo: Label
var _barra: ProgressBar
var _porcentaje: Label
var _grupo_carga: Control
var _grupo_error: Control
var _mensaje_error: Label
var _btn_reintentar: Button
var _btn_menu: Button

var _nodos_listos := false


func _ready() -> void:
	# La pantalla vive dentro de un autoload: debe seguir animándose aunque el
	# árbol esté pausado (el CARGADOR pausa el juego mientras carga).
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolver_nodos()
	mostrar_carga()


## Se resuelven los nodos a mano en vez de con @onready porque esta escena se
## instancia desde un autoload durante el arranque: ahí _ready() puede quedar
## diferido al primer frame, y un cambio de escena muy temprano encontraría
## todas las referencias en null.
func _resolver_nodos() -> void:
	if _nodos_listos:
		return
	_nodos_listos = true

	_spinner = %Spinner
	_titulo = %Titulo
	_barra = %Barra
	_porcentaje = %Porcentaje
	_grupo_carga = %GrupoCarga
	_grupo_error = %GrupoError
	_mensaje_error = %MensajeError
	_btn_reintentar = %BtnReintentar
	_btn_menu = %BtnMenu

	_btn_reintentar.pressed.connect(func() -> void: reintentar_pedido.emit())
	_btn_menu.pressed.connect(func() -> void: volver_al_menu_pedido.emit())


## Deja la pantalla lista para una carga nueva (barra a cero, sin error).
func mostrar_carga() -> void:
	_resolver_nodos()
	modulate.a = 1.0
	_grupo_carga.visible = true
	_grupo_error.visible = false
	_titulo.text = "Cargando..."
	_spinner.set_process(true)
	set_progreso(0.0)


## `progreso` va de 0.0 a 1.0; es el valor real que reporta ResourceLoader,
## ya suavizado por el CARGADOR para que la barra no dé saltos.
func set_progreso(progreso: float) -> void:
	_resolver_nodos()
	var p := clampf(progreso, 0.0, 1.0)
	_barra.value = p * 100.0
	_porcentaje.text = "%d %%" % roundi(p * 100.0)


## Sustituye la vista de carga por el mensaje de error y sus acciones.
## `permitir_menu` se desactiva cuando lo que falló es el propio menú principal.
func mostrar_error(mensaje: String, permitir_menu: bool = true) -> void:
	_resolver_nodos()
	modulate.a = 1.0
	_spinner.set_process(false)
	_grupo_carga.visible = false
	_grupo_error.visible = true
	_mensaje_error.text = mensaje
	_btn_menu.visible = permitir_menu
	if _btn_reintentar.is_inside_tree():
		_btn_reintentar.grab_focus()
