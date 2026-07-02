extends Control
class_name Pause_menu

@onready var contenedor: Control = $Contenedor
@onready var dim: ColorRect = $ColorRect

# Evita que se dispare el cierre más de una vez.
var _cerrando := false


## Muestra el menú con una animación: el marco y los botones crecen desde el centro
## hacia los bordes mientras el fondo atenuado aparece con un fundido.
func abrir() -> void:
	_cerrando = false
	contenedor.scale = Vector2.ZERO
	dim.modulate.a = 0.0
	visible = true

	# Esperamos un frame para conocer el tamaño real y fijar el pivote en el centro.
	await get_tree().process_frame
	contenedor.pivot_offset = contenedor.size / 2.0

	var tw := create_tween().set_parallel(true)
	tw.tween_property(dim, "modulate:a", 1.0, 0.25)
	var t := tw.tween_property(contenedor, "scale", Vector2.ONE, 0.32)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_OUT)


## Animación de cierre: el marco y los botones se encogen hacia el centro
## mientras el fondo atenuado se desvanece.
func cerrar() -> void:
	contenedor.pivot_offset = contenedor.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(dim, "modulate:a", 0.0, 0.2)
	var t := tw.tween_property(contenedor, "scale", Vector2.ZERO, 0.22)
	t.set_trans(Tween.TRANS_BACK)
	t.set_ease(Tween.EASE_IN)
	await tw.finished


func _on_continuar_pressed() -> void:
	if _cerrando:
		return
	_cerrando = true
	await cerrar()
	visible = false
	SceneManager.pause_game(false)


func _on_configuracion_pressed() -> void:
	var opciones := preload("res://Scenes/UI/Opciones.tscn").instantiate()
	add_child(opciones)


func _on_salir_pressed() -> void:
	if _cerrando:
		return
	_cerrando = true
	await cerrar()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/UI/MainMenu.tscn")
