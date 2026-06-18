extends Node2D

#Audio
@onready var music_loop = $MusicLoop
@onready var card_flip_sound = $CardFlipSound
@onready var match_sound = $MatchSound

const COLS := 5
const ROWS := 4
const TOTAL_PAIRS := 10

const CARD_W := 90
const CARD_H := 120
const GAP := 12

const BOARD_W := COLS * (CARD_W + GAP) - GAP
const BOARD_H := ROWS * (CARD_H + GAP) - GAP

const TIEMPO_LIMITE := 60.0
const TIEMPO_MEMORIZACION := 2.0

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

var bg: ColorRect

@onready var timer_label: Label = $CanvasLayer/HUD/TimerLabel
@onready var moves_label: Label = $CanvasLayer/HUD/MovesLabel
@onready var pairs_label: Label = $CanvasLayer/HUD/PairsLabel

@onready var pantalla_intro: ColorRect = $CanvasLayer/PantallaIntro
@onready var pantalla_result: ColorRect = $CanvasLayer/PantallaResultado
@onready var hud: Control = $CanvasLayer/HUD

@onready var btn_iniciar: Button = $CanvasLayer/PantallaIntro/Panel/VBox/BtnIniciar
@onready var btn_continuar: Button = $CanvasLayer/PantallaResultado/Panel/VBox/BtnContinuar


func _ready() -> void:
	randomize()

	if music_loop:
		music_loop.play()

	_configurar_mouse_filters()
	_setup_background()
	build_board()
	_reset_game_values()
	_mostrar_instrucciones()
	_conectar_botones()


func _configurar_mouse_filters() -> void:
	# El HUD solo muestra información, no debe bloquear clicks sobre las cartas.
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	moves_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pairs_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Las pantallas sí deben bloquear las cartas mientras están visibles.
	pantalla_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	pantalla_result.mouse_filter = Control.MOUSE_FILTER_STOP


func _setup_background() -> void:
	bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color("#0d1117")
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.position = Vector2.ZERO
	bg.size = get_viewport_rect().size
	bg.z_index = -100

	add_child(bg)
	move_child(bg, 0)


func _conectar_botones() -> void:
	if not btn_iniciar.pressed.is_connected(_on_btn_iniciar_pressed):
		btn_iniciar.pressed.connect(_on_btn_iniciar_pressed)

	if not btn_continuar.pressed.is_connected(_on_btn_continuar_pressed):
		btn_continuar.pressed.connect(_on_btn_continuar_pressed)


func _reset_game_values() -> void:
	time_elapsed = 0.0
	moves = 0
	matched_pairs = 0

	selected.clear()
	can_interact = false

	timer_label.text = "01:00"
	moves_label.text = "MOVS: 0"
	pairs_label.text = "PARES: 0/%d" % TOTAL_PAIRS
	timer_label.modulate = Color(0.882, 0.686, 0.18)

	btn_iniciar.disabled = false
	btn_continuar.hide()


func _mostrar_instrucciones() -> void:
	estado_actual = Estado.INSTRUCCIONES
	can_interact = false

	hud.hide()
	pantalla_result.hide()
	pantalla_intro.show()


func _on_btn_iniciar_pressed() -> void:
	if estado_actual != Estado.INSTRUCCIONES:
		return

	btn_iniciar.disabled = true

	pantalla_intro.hide()
	pantalla_result.hide()
	hud.show()

	estado_actual = Estado.MEMORIZANDO
	can_interact = false

	# Fase de memorización: mostrar todas las cartas.
	for card in cards:
		card.flip(false)

	await get_tree().create_timer(TIEMPO_MEMORIZACION).timeout

	if estado_actual != Estado.MEMORIZANDO:
		return

	# Ocultar cartas antes de empezar.
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
	if estado_actual != Estado.JUGANDO:
		return

	if not can_interact:
		return

	if card in selected:
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
	if estado_actual != Estado.JUGANDO:
		return

	if selected.size() < 2:
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

	estado_actual = Estado.RESULTADO
	can_interact = false

	var tiempo_restante: float = maxf(0.0, TIEMPO_LIMITE - time_elapsed)
	var recompensa: int = int(matched_pairs * 10 + tiempo_restante * 0.5)

	_mostrar_resultado(true, matched_pairs, tiempo_restante, recompensa)


func on_time_out() -> void:
	if estado_actual != Estado.JUGANDO:
		return

	estado_actual = Estado.RESULTADO
	can_interact = false
	selected.clear()

	_mostrar_resultado(false, matched_pairs, 0.0, -30)


func _mostrar_resultado(gano: bool, pares: int, t_restante: float, monto: int) -> void:
	hud.hide()
	pantalla_intro.hide()
	pantalla_result.show()

	btn_continuar.hide()

	var lbl_titulo: Label = pantalla_result.get_node("Panel/VBox/LblTitulo")
	var lbl_pares: Label = pantalla_result.get_node("Panel/VBox/LblPares")
	var lbl_tiempo: Label = pantalla_result.get_node("Panel/VBox/LblTiempo")
	var lbl_formula: Label = pantalla_result.get_node("Panel/VBox/LblFormula")
	var lbl_total: Label = pantalla_result.get_node("Panel/VBox/LblTotal")

	if gano:
		lbl_titulo.text = "¡TALLER REPARADO!"
		lbl_titulo.modulate = Color("#3fb950")

		lbl_formula.text = "(%d × 10) + (%.1fs × 0.5)" % [pares, t_restante]

		lbl_total.text = "RECOMPENSA: +$%d" % monto
		lbl_total.modulate = Color("#3fb950")
	else:
		lbl_titulo.text = "¡REPARACIÓN FALLIDA!"
		lbl_titulo.modulate = Color("#f85149")

		lbl_formula.text = "No completaste todos los pares."

		lbl_total.text = "PENITENCIA: -$30"
		lbl_total.modulate = Color("#f85149")

	lbl_pares.text = "Pares encontrados: %d / %d" % [pares, TOTAL_PAIRS]
	lbl_tiempo.text = "Tiempo restante: %.1f s" % t_restante

	await get_tree().create_timer(0.5).timeout

	if estado_actual == Estado.RESULTADO:
		btn_continuar.show()


func _on_btn_continuar_pressed() -> void:
	if estado_actual != Estado.RESULTADO:
		return
		
	if music_loop:
		music_loop.stop()
	

	btn_continuar.disabled = true

	var gano := matched_pairs == TOTAL_PAIRS
	var tiempo_restante: float = maxf(0.0, TIEMPO_LIMITE - time_elapsed)

	var monto: int

	if gano:
		monto = int(matched_pairs * 10 + tiempo_restante * 0.5)
	else:
		monto = -30

	EVENTMANAGER.minigame_completed(gano, monto)
	queue_free()


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
