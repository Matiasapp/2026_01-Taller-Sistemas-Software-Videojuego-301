extends Node2D

const GOTA = preload("res://Scenes/Minigames/Catch/GotaAceite.tscn")
const VOLUMEN_SILENCIO_DB := -40.0
const DURACION_FADE_IN := 0.1
const DURACION_FADE_OUT := 0.15
const AUDIO_MINIMO_RESTANTE := 0.4
const PITCH_GOTA_MIN := 0.9
const PITCH_GOTA_MAX := 1.1
const PITCH_GOTA_PERDIDA := 0.7491535 # Cinco semitonos bajo el tono original.

enum Estado{
	INSTRUCCIONES,
	JUGANDO,
	RESULTADO
}

@onready var balde: Area2D = $Balde
@onready var contenedor_gotas = $ContenedorGotas
@onready var spawn_timer = $SpawnTimer

@onready var hud = $CanvasLayer
@onready var tutorial = $Hud/Tutorial
@onready var panel_resumen = $Hud/ResumenAtencion

@onready var label_tiempo = $CanvasLayer/TiempoRestante
@onready var label_dinero = $CanvasLayer/DineroGanado

@onready var titulo = $Hud/Tutorial/PanelTutorial/Titulo
@onready var instrucciones = $Hud/Tutorial/PanelTutorial/Instrucciones
@onready var reglas = $Hud/Tutorial/PanelTutorial/Reglas
@onready var comenzar = $Hud/Tutorial/PanelTutorial/Comenzar
@onready var audio_recoger: AudioStreamPlayer2D = $AudioRecoger
@onready var audio_gota_perdida: AudioStreamPlayer2D = $AudioGotaPerdida
@onready var audio_arrastre: AudioStreamPlayer = $AudioArrastre

@export var velocidad_balde := 500.0

var estado_actual := Estado.INSTRUCCIONES

var dinero_ganado := 0
var tiempo_restante := 30

var gotas_atrapadas := 0
var gotas_perdidas := 0

var balde_en_movimiento := false
var tween_audio_arrastre: Tween


func _ready():

	randomize()

	label_tiempo.text = str(tiempo_restante)
	label_dinero.text = "$0"
	hud.hide()
	tutorial.show()

	spawn_timer.stop()

	if panel_resumen:
		panel_resumen.hide()


func _process(delta: float):

	match estado_actual:

		Estado.INSTRUCCIONES:

			if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_D):

				tutorial.hide()
				hud.show()

				estado_actual = Estado.JUGANDO

				spawn_timer.start()

				var timer := Timer.new()
				timer.name = "TimerJuego"
				timer.wait_time = 1.0
				timer.one_shot = false
				timer.autostart = true
				add_child(timer)

				timer.timeout.connect(_on_timer_juego_timeout)

		Estado.JUGANDO:

			var direccion := 0

			if Input.is_key_pressed(KEY_A):
				direccion -= 1

			if Input.is_key_pressed(KEY_D):
				direccion += 1

			var posicion_anterior: float = balde.position.x

			balde.position.x += direccion * velocidad_balde * delta

			balde.position.x = clamp(balde.position.x,40,1112)

			actualizar_audio_arrastre(
				not is_equal_approx(balde.position.x, posicion_anterior)
			)

		Estado.RESULTADO:
			pass


func actualizar_audio_arrastre(en_movimiento: bool) -> void:

	if en_movimiento:

		if not balde_en_movimiento or not audio_arrastre.playing:
			iniciar_audio_arrastre()

	elif balde_en_movimiento:
		desvanecer_audio_arrastre()

	balde_en_movimiento = en_movimiento


func iniciar_audio_arrastre() -> void:

	if tween_audio_arrastre:
		tween_audio_arrastre.kill()

	var duracion_audio: float = audio_arrastre.stream.get_length()
	var ultimo_inicio: float = maxf(0.0, duracion_audio - AUDIO_MINIMO_RESTANTE)
	var posicion_inicio: float = randf_range(0.0, ultimo_inicio)

	audio_arrastre.volume_db = VOLUMEN_SILENCIO_DB
	audio_arrastre.play(posicion_inicio)

	tween_audio_arrastre = create_tween()
	tween_audio_arrastre.tween_property(
		audio_arrastre,
		"volume_db",
		0.0,
		DURACION_FADE_IN
	)


func desvanecer_audio_arrastre() -> void:

	if not audio_arrastre.playing:
		return

	if tween_audio_arrastre:
		tween_audio_arrastre.kill()

	tween_audio_arrastre = create_tween()
	tween_audio_arrastre.tween_property(
		audio_arrastre,
		"volume_db",
		VOLUMEN_SILENCIO_DB,
		DURACION_FADE_OUT
	)
	tween_audio_arrastre.tween_callback(finalizar_audio_arrastre)


func finalizar_audio_arrastre() -> void:

	if balde_en_movimiento:
		return

	audio_arrastre.stop()
	audio_arrastre.volume_db = VOLUMEN_SILENCIO_DB

func crear_gota():

	var gota = GOTA.instantiate()

	gota.position = Vector2(
		randf_range(40,1112),
		-20
	)

	gota.gota_perdida.connect(_on_gota_perdida)

	contenedor_gotas.add_child(gota)


func _on_spawn_timer_timeout():

	if estado_actual != Estado.JUGANDO:
		return

	crear_gota()


func _on_balde_area_entered(area):

	if area.is_in_group("gotas"):

		audio_recoger.pitch_scale = randf_range(PITCH_GOTA_MIN, PITCH_GOTA_MAX)
		audio_recoger.play()

		gotas_atrapadas += 1

		dinero_ganado += 10
		label_dinero.text = "$" + str(dinero_ganado)


		animar_label_dinero(Color.GREEN)

		area.queue_free()


func _on_gota_perdida():

	if estado_actual != Estado.JUGANDO:
		return

	audio_gota_perdida.pitch_scale = PITCH_GOTA_PERDIDA
	audio_gota_perdida.play()

	gotas_perdidas += 1
	dinero_ganado -= 15

	label_dinero.text = "$" + str(dinero_ganado)

	animar_label_dinero(Color.RED)


func _on_timer_juego_timeout():

	if estado_actual != Estado.JUGANDO:
		return

	tiempo_restante -= 1

	label_tiempo.text = str(tiempo_restante)

	if tiempo_restante > 0:
		return

	estado_actual = Estado.RESULTADO
	actualizar_audio_arrastre(false)

	spawn_timer.stop()

	var timer := get_node_or_null("TimerJuego")

	if timer:
		timer.stop()

	var rendimiento := clampf(
		float(gotas_atrapadas) / max(1.0, float(gotas_atrapadas + gotas_perdidas)),
		0.0,
		1.0
	)

	var nivel_desempeno := DATOSGLOBALES.DESEMPENO_FALLIDO

	if rendimiento >= 0.90:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_EXITOSO
	elif rendimiento >= 0.60:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_ACEPTABLE

	DATOSGLOBALES.reportar_rendimiento_minijuego(
		rendimiento,
		dinero_ganado,
		nivel_desempeno,
		"Recolección de aceite",
		"Gotas atrapadas: %d | Perdidas: %d" % [gotas_atrapadas, gotas_perdidas]
	)

	DATOSGLOBALES.volviendo_de_atencion = true

	if panel_resumen:

		panel_resumen.layer = 100

		panel_resumen.activar_panel()

		if not panel_resumen.continuar.is_connected(_on_btn_continuar_pressed):
			panel_resumen.continuar.connect(_on_btn_continuar_pressed)


func _on_btn_continuar_pressed():

	if estado_actual != Estado.RESULTADO:
		return

	await get_tree().create_timer(0.15, true, false, true).timeout

	DATOSGLOBALES.sumar_dinero(dinero_ganado)

	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)

	CARGADOR.cambiar_escena(destino)


func animar_label_dinero(color: Color):

	label_dinero.modulate = color

	var tween := create_tween()

	label_dinero.scale = Vector2.ONE

	tween.tween_property(label_dinero, "scale", Vector2(1.2,1.2),0.08)
	tween.tween_property(label_dinero, "scale", Vector2.ONE,0.08)

	await tween.finished

	label_dinero.modulate = Color.WHITE
