extends Node2D

# Audio
@onready var music_loop = $MusicLoop
@onready var card_flip_sound = $CardFlipSound
@onready var match_sound = $MatchSound
@onready var panel_resumen = $ResumenAtencion
const COLS := 5
const ROWS := 4
const TOTAL_PAIRS := 10

const CARD_W := 96
const CARD_H := 118
const GAP := 12

const BOARD_W := COLS * (CARD_W + GAP) - GAP
const BOARD_H := ROWS * (CARD_H + GAP) - GAP

const TIEMPO_LIMITE := 60.0
const TIEMPO_MEMORIZACION := 2.0
const FONDO_MEMORY_PATH := "res://Assets/Sprites/MemorizeGame/fondo_memory.png"

enum Estado {
	INSTRUCCIONES,
	MEMORIZANDO,
	JUGANDO,
	RESULTADO
}

var estado_actual := Estado.INSTRUCCIONES

var cards: Array[MemoryCard] = []
var selected: Array[MemoryCard] = []

var can_interact := false

var time_elapsed := 0.0
var moves := 0
var matched_pairs := 0
var dinero_final := 0

var bg: Control

@onready var timer_label: Label = $CanvasLayer/HUD/TimerLabel
@onready var moves_label: Label = $CanvasLayer/HUD/MovesLabel
@onready var pairs_label: Label = $CanvasLayer/HUD/PairsLabel

@onready var pantalla_intro: ColorRect = $CanvasLayer/PantallaIntro
@onready var hud: Control = $CanvasLayer/HUD
@onready var btn_iniciar: Button = $CanvasLayer/PantallaIntro/Panel/VBox/BtnIniciar

# Exportamos el panel viejo por si lo tienes en el CanvasLayer y queremos apagarlo
@export var pantalla_final_vieja: Control 

func _ready() -> void:
	randomize()

	if music_loop:
		music_loop.play()

	_configurar_mouse_filters()
	_setup_background()
	build_board()
	_reset_game_values()
	_mostrar_instrucciones()
	
	if not btn_iniciar.pressed.is_connected(_on_btn_iniciar_pressed):
		btn_iniciar.pressed.connect(_on_btn_iniciar_pressed)
	if not btn_iniciar.mouse_entered.is_connected(_on_btn_iniciar_mouse_entered):
		btn_iniciar.mouse_entered.connect(_on_btn_iniciar_mouse_entered)


func _configurar_mouse_filters() -> void:
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pairs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pantalla_intro.mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_background() -> void:
	if ResourceLoader.exists(FONDO_MEMORY_PATH):
		var texture_bg := TextureRect.new()
		texture_bg.texture = load(FONDO_MEMORY_PATH) as Texture2D
		texture_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg = texture_bg
	else:
		var color_bg := ColorRect.new()
		color_bg.color = Color("#0d1117")
		bg = color_bg

	bg.name = "Background"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.position = Vector2.ZERO
	bg.size = get_viewport_rect().size
	bg.z_index = -100

	add_child(bg)
	move_child(bg, 0)


func _reset_game_values() -> void:
	time_elapsed = 0.0
	moves = 0
	matched_pairs = 0
	dinero_final = 0

	selected.clear()
	can_interact = false

	timer_label.text = "01:00"
	moves_label.text = "MOVS: 0"
	pairs_label.text = "PARES: 0/%d" % TOTAL_PAIRS
	timer_label.modulate = Color(0.882, 0.686, 0.18)

	btn_iniciar.disabled = false


func _mostrar_instrucciones() -> void:
	estado_actual = Estado.INSTRUCCIONES
	can_interact = false
	hud.hide()
	pantalla_intro.show()
	
	if pantalla_final_vieja:
		pantalla_final_vieja.hide()


func _on_btn_iniciar_pressed() -> void:
	if estado_actual != Estado.INSTRUCCIONES:
		return

	AUDIOMANAGER.play_ui_click()
	btn_iniciar.disabled = true

	pantalla_intro.hide()
	hud.show()

	estado_actual = Estado.MEMORIZANDO
	can_interact = false

	for card in cards:
		card.flip(false)

	await get_tree().create_timer(TIEMPO_MEMORIZACION).timeout

	if estado_actual != Estado.MEMORIZANDO:
		return

	for card in cards:
		card.flip_back(false)

	await get_tree().create_timer(0.3).timeout

	if estado_actual != Estado.MEMORIZANDO:
		return

	estado_actual = Estado.JUGANDO
	can_interact = true


func build_board() -> void:
	cards.clear()
	selected.clear()

	var total_cards := COLS * ROWS
	var expected_cards := TOTAL_PAIRS * 2

	if total_cards != expected_cards:
		push_warning("El tablero tiene %d espacios, pero necesitas %d cartas." % [total_cards, expected_cards])

	var types: Array[int] = []

	for i in range(TOTAL_PAIRS):
		types.append(i)
		types.append(i)

	types.shuffle()

	var screen := get_viewport_rect().size
	var start_x := (screen.x - BOARD_W) / 2.0
	var start_y := (screen.y - BOARD_H) / 2.0

	for row in range(ROWS):
		for col in range(COLS):
			var idx := row * COLS + col

			if idx >= types.size():
				break

			var card := MemoryCard.new()
			card.setup(types[idx], idx)
			card.position = Vector2(
				start_x + col * (CARD_W + GAP),
				start_y + row * (CARD_H + GAP)
			)

			card.card_clicked.connect(_on_card_clicked)

			add_child(card)
			cards.append(card)


func _on_card_clicked(card: MemoryCard) -> void:
	if estado_actual != Estado.JUGANDO or not can_interact or card in selected:
		return

	if card.is_flipped or card.is_matched:
		return

	if card_flip_sound:
		card_flip_sound.pitch_scale = randf_range(0.95, 1.05)
		card_flip_sound.play()

	await card.flip(true)
	selected.append(card)

	if selected.size() == 2:
		moves += 1
		moves_label.text = "MOVS: %d" % moves
		can_interact = false

		await get_tree().create_timer(0.45).timeout

		if estado_actual != Estado.JUGANDO:
			return

		await check_match()


func check_match() -> void:
	if estado_actual != Estado.JUGANDO or selected.size() < 2:
		return

	var a := selected[0]
	var b := selected[1]

	if a.icon_type == b.icon_type:
		if match_sound:
			match_sound.play()

		a.set_matched()
		b.set_matched()
		matched_pairs += 1
		pairs_label.text = "PARES: %d/%d" % [matched_pairs, TOTAL_PAIRS]

		selected.clear()
		can_interact = true

		if matched_pairs == TOTAL_PAIRS:
			on_victory()
	else:
		await get_tree().create_timer(0.35).timeout

		if estado_actual != Estado.JUGANDO:
			return

		await a.flip_back(true)
		await b.flip_back(true)

		selected.clear()
		can_interact = true


func on_victory() -> void:
	if estado_actual != Estado.JUGANDO:
		return
	_procesar_final(true)


func on_time_out() -> void:
	if estado_actual != Estado.JUGANDO:
		return
	selected.clear()
	_procesar_final(false)


func _procesar_final(gano: bool) -> void:
	estado_actual = Estado.RESULTADO
	can_interact = false
	
	hud.hide()
	pantalla_intro.hide()
	if pantalla_final_vieja:
		pantalla_final_vieja.hide()

	var t_restante: float = maxf(0.0, TIEMPO_LIMITE - time_elapsed)
	var rendimiento: float

	if gano:
		dinero_final = int(matched_pairs * 10 + t_restante * 0.5)
		rendimiento = clampf(0.8 + 0.2 * (t_restante / TIEMPO_LIMITE), 0.0, 1.0)
	else:
		dinero_final = -30
		rendimiento = clampf(float(matched_pairs) / float(TOTAL_PAIRS), 0.0, 1.0) * 0.6

	var nivel_desempeno := DATOSGLOBALES.DESEMPENO_FALLIDO
	if gano:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_EXITOSO
	elif matched_pairs >= 7:
		nivel_desempeno = DATOSGLOBALES.DESEMPENO_ACEPTABLE
	DATOSGLOBALES.reportar_rendimiento_minijuego(
		rendimiento,
		dinero_final,
		nivel_desempeno,
		"Circuito electrico",
		"Pares encontrados: %d/%d." % [matched_pairs, TOTAL_PAIRS]
	)
	
	# FUNDAMENTAL: Prevenir que el panel se autodestruya
	DATOSGLOBALES.volviendo_de_atencion = true 

	# --- CAMBIO AQUI: Usamos el panel que ya está en la escena ---
	if panel_resumen:
		panel_resumen.layer = 100 
		panel_resumen.activar_panel()
		
		# CONECTAMOS EL PANEL EXISTENTE DE FORMA SEGURA
		if not panel_resumen.continuar.is_connected(_on_btn_continuar_pressed):
			panel_resumen.continuar.connect(_on_btn_continuar_pressed)


func _on_btn_continuar_pressed() -> void:
	if estado_actual != Estado.RESULTADO:
		return

	await get_tree().create_timer(0.15, true, false, true).timeout
		
	if music_loop:
		music_loop.stop()
	
	print("Memory terminado. Dinero obtenido: $", dinero_final)
	DATOSGLOBALES.sumar_dinero(dinero_final)

	Engine.time_scale = 1.0
	get_tree().paused = false
	var destino := DATOSGLOBALES.obtener_destino_post_escena(
		"res://Scenes/Gameplay/GameScreen.tscn"
	)
	get_tree().change_scene_to_file(destino)


func _process(delta: float) -> void:
	if estado_actual != Estado.JUGANDO:
		return

	time_elapsed += delta

	var restante: float = maxf(0.0, TIEMPO_LIMITE - time_elapsed)
	var secs: int = int(restante)

	@warning_ignore("integer_division")
	var mins: int = secs / 60
	secs = secs % 60

	timer_label.text = "%02d:%02d" % [mins, secs]

	if restante <= 10.0:
		timer_label.modulate = Color(1.0, 0.3, 0.3)
	elif restante <= 20.0:
		timer_label.modulate = Color(1.0, 0.75, 0.2)
	else:
		timer_label.modulate = Color(0.882, 0.686, 0.18)

	if time_elapsed >= TIEMPO_LIMITE:
		on_time_out()

func _on_btn_iniciar_mouse_entered() -> void:
	AUDIOMANAGER.play_ui_hover()
