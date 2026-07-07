extends CanvasLayer
## Carga escenas de forma asíncrona mostrando una pantalla de carga con spinner,
## para que las escenas pesadas no congelen ni muestren el fondo mientras cargan.
## Autoload: CARGADOR.  Uso:  CARGADOR.cambiar_escena("res://ruta/escena.tscn")

var _cargando: bool = false
var _ruta: String = ""
var _fondo: ColorRect
var _spinner: Control
var _label: Label


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	_construir()
	visible = false
	set_process(false)


func _construir() -> void:
	_fondo = ColorRect.new()
	_fondo.color = Color(0, 0, 0, 1)
	_fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fondo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_fondo)

	_spinner = Control.new()
	_spinner.set_script(load("res://Scripts/UI/spinner.gd"))
	_spinner.anchor_left = 0.5
	_spinner.anchor_top = 0.5
	_spinner.anchor_right = 0.5
	_spinner.anchor_bottom = 0.5
	add_child(_spinner)
	_spinner.set_process(false)

	_label = Label.new()
	_label.text = "Cargando..."
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.anchor_left = 0.5
	_label.anchor_top = 0.5
	_label.anchor_right = 0.5
	_label.anchor_bottom = 0.5
	_label.offset_left = -120.0
	_label.offset_right = 120.0
	_label.offset_top = 48.0
	_label.offset_bottom = 72.0
	add_child(_label)


## Carga la escena de `ruta` en segundo plano y cambia a ella al terminar.
func cambiar_escena(ruta: String) -> void:
	if _cargando:
		return
	_cargando = true
	_ruta = ruta

	_fondo.modulate.a = 1.0
	_spinner.modulate.a = 1.0
	_label.modulate.a = 1.0
	visible = true
	_spinner.set_process(true)
	set_process(true)

	ResourceLoader.load_threaded_request(ruta)


func _process(_delta: float) -> void:
	if not _cargando:
		return

	var progreso: Array = []
	var estado := ResourceLoader.load_threaded_get_status(_ruta, progreso)

	match estado:
		ResourceLoader.THREAD_LOAD_LOADED:
			_cargando = false
			var escena: PackedScene = ResourceLoader.load_threaded_get(_ruta)
			get_tree().change_scene_to_packed(escena)
			_revelar()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("CARGADOR: no se pudo cargar la escena: " + _ruta)
			_cargando = false
			_ocultar()
		_:
			pass  # THREAD_LOAD_IN_PROGRESS: seguimos esperando (el spinner gira).


## Espera a que la nueva escena inicialice y desvanece la pantalla de carga.
func _revelar() -> void:
	# Dos frames para que la nueva escena instancie y renderice antes de revelar.
	await get_tree().process_frame
	await get_tree().process_frame

	var tw := create_tween().set_parallel(true)
	tw.tween_property(_fondo, "modulate:a", 0.0, 0.3)
	tw.tween_property(_spinner, "modulate:a", 0.0, 0.3)
	tw.tween_property(_label, "modulate:a", 0.0, 0.3)
	await tw.finished

	_ocultar()


func _ocultar() -> void:
	visible = false
	_spinner.set_process(false)
	set_process(false)
