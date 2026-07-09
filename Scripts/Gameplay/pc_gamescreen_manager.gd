extends Area2D

@onready var panel_pc = $CanvasLayer/ModalPc
@onready var hud = $"../Hud"
var tween_actual : Tween # Guardamos una referencia a la animación

func _ready() -> void:
	GLOBALSIGNALS.abrir_pc.connect(_on_abrir_pc)
	if not GLOBALSIGNALS.cerrar_pc.is_connected(_on_cerrar_pc):
		GLOBALSIGNALS.cerrar_pc.connect(_on_cerrar_pc)
	panel_pc.visible = false
	panel_pc.process_mode = Node.PROCESS_MODE_ALWAYS # Vital para que funcione en pausa

func _on_abrir_pc():
	# 1. EL ESCUDO: Si el panel ya está visible, ignoramos el spam por completo
	if panel_pc.visible:
		return
	panel_pc.visible = true

	# El HUD (dinero, hora, reputación, avisos) no debe verse mientras se usa el PC.
	if hud:
		hud.visible = false

	# 2. Mata cualquier animación previa que se haya quedado pegada por seguridad
	if tween_actual and tween_actual.is_valid():
		tween_actual.kill()

	panel_pc.visible = true
	panel_pc.modulate.a = 0  # Transparente
	panel_pc.scale = Vector2(0.8, 0.8) # Un poco más pequeño
	get_tree().paused = true

	# 3. Creamos la nueva animación asignándola a nuestra variable
	tween_actual = create_tween()
	tween_actual.set_parallel(true)
	tween_actual.tween_property(panel_pc, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_QUAD)
	tween_actual.tween_property(panel_pc, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## Al cerrar el PC (botón X del monitor) volvemos a mostrar el HUD.
func _on_cerrar_pc():
	if hud:
		hud.visible = true


