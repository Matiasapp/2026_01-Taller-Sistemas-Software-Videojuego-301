extends TextureRect

# ============================================================
# PANTALLA CRT (input)
# ------------------------------------------------------------
# Este nodo muestra la interfaz del SubViewport %Contenido con el
# shader de curvatura (ModalPC.gdshader). Aquí reenviamos el input
# del mouse al SubViewport aplicando LA MISMA distorsión de barril
# + margen del shader, para que botones y hover respondan exacto
# donde la interfaz SE VE en el tubo curvo.
# ============================================================

@onready var _contenido: SubViewport = %Contenido


func _ready() -> void:
	mouse_exited.connect(_limpiar_hover)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouse:
		var e: InputEventMouse = event.duplicate()
		e.position = _a_coordenadas_interfaz(event.position)
		if e is InputEventMouseMotion and size.x > 0.0 and size.y > 0.0:
			(e as InputEventMouseMotion).relative *= Vector2(_contenido.size) / size
		_contenido.push_input(e, true)
		accept_event()


## Al salir el mouse del vidrio, un movimiento lejano limpia el hover
## de los botones dentro del viewport.
func _limpiar_hover() -> void:
	var e := InputEventMouseMotion.new()
	e.position = Vector2(-4096.0, -4096.0)
	_contenido.push_input(e, true)


## Posición local sobre el vidrio -> coordenadas de la interfaz.
## Replica barrel() + inset del shader (la MISMA fórmula, misma dirección):
## el píxel visible en 'pos' es el que la interfaz tiene en el UV distorsionado.
func _a_coordenadas_interfaz(pos: Vector2) -> Vector2:
	var mat := material as ShaderMaterial
	var curva: float = 0.0
	var margen: float = 0.0
	if mat:
		curva = mat.get_shader_parameter("curve")
		margen = mat.get_shader_parameter("inset")

	var uv := pos / size
	var p := uv - Vector2(0.5, 0.5)
	p *= 1.0 + curva * p.dot(p)
	var duv := p + Vector2(0.5, 0.5)
	var ui_uv := (duv - Vector2(margen, margen)) / (1.0 - 2.0 * margen)
	return ui_uv * Vector2(_contenido.size)
