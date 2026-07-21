extends Node

var genero_jugador: String = ""
var siguiente_evento_dia: String = ""
var mostrar_resumen_dia_al_volver: bool = false

## true una vez que se mostró el modal de bienvenida (día 1, 08:00) en la partida actual.
## Se reinicia a false al empezar una Nueva Partida, para que aparezca una vez por partida.
var modal_bienvenida_mostrado: bool = false

## Índices de los clientes (filas del atlas) que ya aparecieron en la partida.
## Persiste entre escenas para que un mismo cliente no se repita durante todo el juego.
var clientes_usados: Array[int] = []

## Estado de estafa pendiente: el cliente actual es estafador y, al volver del minijuego,
## se revela que pagó con billetes falsos. Persiste a través del cambio de escena al minijuego.
var estafa_pendiente: bool = false
var dinero_antes_estafa: int = 0   # Dinero justo antes del minijuego (para revertir el pago falso)
var nombre_estafador: String = ""

## Evento de Protesta Pendiente: Se activa si se han utilizado 5 piezas defectuosas
var protesta_pendiente: bool = false
var contador_pieza_defectuosa: int = 0
var pieza_limite: int = 5

## Para mostrar en el HUD cuánto cambió el dinero tras atender a un cliente (reparación).
var dinero_antes_atencion: int = 0
var volviendo_de_atencion: bool = false

## Desglose de la atención en curso, para mostrarlo en la pantalla de resultado del
## minijuego (costo de la pieza, penalización de diagnóstico, recompensa del minijuego,
## y los cambios de reputación). Se rellena a medida que avanza la atención; se lee con
## get_resumen_atencion().
var resumen_atencion: Dictionary = {}

var estadisticas_dias: Dictionary = {}

const FINAL_REPUTACION_SCENE := "res://Scenes/Events/FinalMalo/FinalMalo1.tscn"
const FINAL_DEUDA_SCENE := "res://Scenes/Events/FinalMalo/FinalMalo2.tscn"
const FINAL_DESALOJO_SCENE := "res://Scenes/Events/EventoDesalojo/EventoDesalojo.tscn"
const FINAL_VICTORIA_SCENE := "res://Scenes/Events/EventoVictoria/evento_victoria.tscn"
const FINAL_MEDIO_SCENE := "res://Scenes/Events/EventoMedio/evento_medio.tscn"
const GAME_SCREEN_SCENE := "res://Scenes/Gameplay/GameScreen.tscn"

const UMBRAL_DEUDA_EXTREMA: int = -800
const UMBRAL_VICTORIA_DINERO: int = 800
const UMBRAL_VICTORIA_REPUTACION: int = 80
const ULTIMO_DIA: int = 5
const NOMBRE_GASTO_ARRIENDO := "Arriendo del taller"
const ARRIENDOS_POSTERGADOS_PARA_DESALOJO: int = 3

## Los atrasos de arriendo son acumulativos: pagar una jornada posterior no
## elimina las obligaciones que quedaron pendientes en cierres anteriores.
var arriendos_postergados: int = 0

## El final no interrumpe la pantalla donde se perdio el ultimo punto. Se marca
## como pendiente y se lanza apenas esa escena entrega el control a la siguiente.
var final_pendiente_scene := ""
var _escena_origen_final_id := 0
var _cambiando_a_evento_final := false

## Evitan aplicar dos veces la reputacion si un boton de resultado recibe mas
## de un clic antes de que termine el cambio de escena.
var _pieza_reputacion_registrada := false
var _minijuego_reputacion_registrado := false
var _avisos_reputacion_pendientes: Array[String] = []



func _ready() -> void:
	# El vigilante del final debe seguir activo incluso si una pantalla de
	# resultados deja el arbol pausado durante su transicion.
	process_mode = Node.PROCESS_MODE_ALWAYS

# ============================================================
# REPUTACION (única fuente de verdad)
# ------------------------------------------------------------
# La reputación es un único valor global (0-100) que persiste entre días y
# alimenta las estrellas del HUD. Atender clientes, diagnosticar y los eventos
# la modifican directamente; las estadísticas por día solo guardan una FOTO
# de este valor para mostrarla en el resumen.
# ============================================================
const REPUTACION_INICIAL: int = 75
const REP_DIAGNOSTICO_CORRECTO: int = 2
const REP_DIAGNOSTICO_INCORRECTO: int = 10
const REP_PIEZA_BUENA: int = 5
const REP_PIEZA_BARATA: int = 1
const REP_PIEZA_DUDOSA_PENALIZACION: int = 5
const PROBABILIDAD_FALLO_PIEZA_DUDOSA: float = 0.55
const REP_MINIJUEGO_EXITOSO: int = 3
const REP_MINIJUEGO_FALLIDO: int = 8

const DESEMPENO_FALLIDO: int = -1
const DESEMPENO_ACEPTABLE: int = 0
const DESEMPENO_EXITOSO: int = 1

signal dinero_cambiado(nuevo_monto: int)
signal dia_cambiado(nuevo_dia: int)

var dia_actual: int = 1:
	set(value):
		dia_actual = value
		dia_cambiado.emit(dia_actual)

var dinero: int = 500:
	set(value):
		dinero = value
		dinero_cambiado.emit(dinero)
		if dinero <= UMBRAL_DEUDA_EXTREMA:
			_programar_evento_final(FINAL_DEUDA_SCENE)
		elif final_pendiente_scene == FINAL_DEUDA_SCENE:
			# La recompensa del minijuego puede sacar al jugador de la deuda
			# antes de que termine la atencion.
			_limpiar_final_pendiente()

func sumar_dinero(cantidad: int):
	dinero += cantidad
	ingresos_dia += cantidad

func restar_dinero(cantidad: int):
	dinero -= cantidad
	gastos_dia -= cantidad

func asegurar_estadistica_dia(dia: int) -> Dictionary:
	if not estadisticas_dias.has(dia):
		estadisticas_dias[dia] = {
			"dia": dia,
			"clientes_atendidos": 0,
			"clientes_satisfechos": 0,
			"diagnosticos_correctos": 0,
			"diagnosticos_incorrectos": 0,
			"ingresos": 0,
			"gastos": 0,
			"balance": 0,
			"dinero_inicio": dinero,
			"dinero_final": dinero,
			"reputacion": reputacion,
			"eventos": []
		}
	else:
		var stats_existentes: Dictionary = estadisticas_dias[dia]
		if not stats_existentes.has("eventos"):
			stats_existentes["eventos"] = []
		if not stats_existentes.has("clientes_satisfechos"):
			# Migra partidas antiguas con la mejor estimacion disponible.
			var incidentes := (
				int(stats_existentes.get("diagnosticos_incorrectos", 0))
				+ int(stats_existentes.get("minijuegos_fallidos", 0))
			)
			stats_existentes["clientes_satisfechos"] = maxi(
				0,
				int(stats_existentes.get("clientes_atendidos", 0)) - incidentes
			)
		estadisticas_dias[dia] = stats_existentes

	return estadisticas_dias[dia]

func registrar_diagnostico_dia(correcto: bool, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)
	# Un diagnostico abre un nuevo ciclo reparacion -> pieza -> minijuego.
	_pieza_reputacion_registrada = false
	_minijuego_reputacion_registrado = false

	var rep_diag: int
	if correcto:
		stats["diagnosticos_correctos"] += 1
		rep_diag = REP_DIAGNOSTICO_CORRECTO
		rep_diag = ajustar_reputacion(rep_diag, "Diagnostico correcto")
		_agregar_evento_stats(
			stats,
			"Diagnostico correcto: reputacion +%d." % REP_DIAGNOSTICO_CORRECTO
		)
	else:
		stats["diagnosticos_incorrectos"] += 1
		rep_diag = -REP_DIAGNOSTICO_INCORRECTO
		rep_diag = ajustar_reputacion(rep_diag, "Diagnostico incorrecto")
		_agregar_evento_stats(
			stats,
			"Diagnostico incorrecto: reputacion -%d." % REP_DIAGNOSTICO_INCORRECTO
		)

	# Guardamos el detalle para el resumen de la atención (pantalla de resultado del minijuego).
	resumen_atencion["diagnostico_correcto"] = correcto
	resumen_atencion["rep_diagnostico"] = rep_diag

	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

## Registra el efecto de calidad de la pieza elegida. La dudosa no falla siempre,
## pero su riesgo es suficientemente alto para que no sea la opcion dominante.
func registrar_calidad_pieza(tipo: String, dia: int = -1) -> int:
	if _pieza_reputacion_registrada:
		return 0
	_pieza_reputacion_registrada = true

	if dia < 0:
		dia = dia_actual

	var delta := 0
	var mensaje := ""
	var motivo := ""
	match tipo:
		"buena":
			delta = REP_PIEZA_BUENA
			mensaje = "Pieza buena instalada: reputacion +%d." % delta
			motivo = "Pieza buena instalada"
			# Reparacion excelente: no basta con pagar la pieza cara, hay que haber
			# acertado la falla. Solo entonces el cliente se toma el trabajo de
			# escribir algo bueno.
			if bool(resumen_atencion.get("diagnostico_correcto", false)):
				registrar_resena_positiva(dia)
		"barata":
			delta = REP_PIEZA_BARATA
			mensaje = "Pieza barata instalada: reputacion +%d." % delta
			motivo = "Pieza barata instalada"
		"dudosa":
			if randf() < PROBABILIDAD_FALLO_PIEZA_DUDOSA:
				delta = -REP_PIEZA_DUDOSA_PENALIZACION
				mensaje = "La pieza dudosa fallo: reputacion -%d." % absi(delta)
				motivo = "Pieza dudosa defectuosa"
				# El cliente afectado publica una reseña; queda esperando en el PC.
				registrar_resena_negativa(dia)
			else:
				mensaje = "La pieza dudosa no genero reclamos esta vez: reputacion sin cambios."
		_:
			push_warning("Tipo de pieza desconocido para reputacion: %s" % tipo)
			return 0

	var delta_aplicado := delta
	if delta != 0:
		delta_aplicado = ajustar_reputacion(delta, motivo)
	else:
		_registrar_aviso_reputacion(0, "Pieza dudosa sin reclamos")
	resumen_atencion["rep_pieza"] = delta_aplicado

	var stats := asegurar_estadistica_dia(dia)
	var piezas: Dictionary = stats.get("piezas_usadas", {})
	piezas[tipo] = int(piezas.get(tipo, 0)) + 1
	stats["piezas_usadas"] = piezas
	stats["reputacion"] = reputacion
	_agregar_evento_stats(stats, mensaje)
	estadisticas_dias[dia] = stats
	return delta_aplicado

## Unifica el balance de los cinco minijuegos y garantiza que el resultado de
## una reparacion solo afecte la reputacion una vez.
func registrar_desempeno_minijuego(
	nivel: int,
	nombre_minijuego: String,
	detalle: String = "",
	dia: int = -1
) -> int:
	if _minijuego_reputacion_registrado:
		return 0
	_minijuego_reputacion_registrado = true

	if dia < 0:
		dia = dia_actual

	nivel = clampi(nivel, DESEMPENO_FALLIDO, DESEMPENO_EXITOSO)
	var delta := 0
	var estado := "desempeno aceptable"
	var clave := "minijuegos_aceptables"
	if nivel == DESEMPENO_EXITOSO:
		delta = REP_MINIJUEGO_EXITOSO
		estado = "buen desempeno"
		clave = "minijuegos_exitosos"
	elif nivel == DESEMPENO_FALLIDO:
		delta = -REP_MINIJUEGO_FALLIDO
		estado = "mal desempeno"
		clave = "minijuegos_fallidos"

	var delta_aplicado := delta
	if delta != 0:
		delta_aplicado = ajustar_reputacion(
			delta,
			"%s: %s" % [nombre_minijuego, estado]
		)
	else:
		_registrar_aviso_reputacion(0, "%s: %s" % [nombre_minijuego, estado])

	var stats := asegurar_estadistica_dia(dia)
	stats[clave] = int(stats.get(clave, 0)) + 1
	stats["reputacion"] = reputacion

	var texto := "%s: %s; reputacion %s%d." % [
		nombre_minijuego,
		estado,
		"+" if delta_aplicado > 0 else "",
		delta_aplicado,
	]
	if not detalle.is_empty():
		texto += " " + detalle
	_agregar_evento_stats(stats, texto)
	estadisticas_dias[dia] = stats
	return delta_aplicado

func _agregar_evento_stats(stats: Dictionary, texto: String) -> void:
	var eventos: Array = stats.get("eventos", [])
	eventos.append(texto)
	stats["eventos"] = eventos

# =========================
# RESEÑAS DE CLIENTES
# =========================
# Los clientes dejan reseñas publicas segun como les fue:
#   - Negativa: la pieza dudosa que les instalaron fallo.
#   - Positiva: reparacion excelente, o sea diagnostico correcto Y pieza buena.
# Ninguna de las dos toca la reputacion: eso ya lo hizo el evento que las provoca.
# La reseña es la constancia visible, y se lee en el panel RESEÑAS del PC.
# Cada atencion genera como maximo una reseña, asi que un dia nunca pasa de 5.

const RESENA_USUARIOS: Array[String] = [
	"Miguel83",
	"Juancarlos@lospaseo",
	"CaraTrolll",
	"Juaquin",
	"Miguelin2010",
	"IsidoraLabadora",
	"Destructor de Familias"
]

const RESENA_COMENTARIOS_NEGATIVOS: Array[String] = [
	"La atencion de este lugar a sido terrible",
	"Fui por un cambio de aceite y terminaron revisando la suspensión.",
	"Me dijeron que necesitaba cambiar dos motores. Mi auto tiene uno.",
	"Las piezas que ocuparon parecen de jugete",
	"Es una estafa, cobran por hacer nada",
	"Demasiado caro. Además, la persona que atiende no inspira ninguna confianza.",
	"Volvería para el Día de Muertos. Con esos precios, me muero antes de pagar."
]

const RESENA_COMENTARIOS_POSITIVOS: Array[String] = [
	"Me explicaron la falla con paciencia y cobraron lo justo.",
	"Llegué con el auto muerto y salí manejando. Impecable.",
	"Me mostraron la pieza vieja antes de cambiarla. Eso es confianza.",
	"Rápido, honesto y bien hecho. Ojalá todos los talleres fueran así.",
	"Cobraron exactamente lo que dijeron que iban a cobrar.",
	"Quedó mejor que cuando lo compré. Vuelvo sin pensarlo.",
	"Le acertaron a la falla al primer intento. Se nota el oficio."
]

# Cuando se sabe qué falla se reparó, el cliente menciona el trabajo concreto.
# Si ya se usaron todos los de su tipo en el día, se cae a los genéricos de arriba.
const RESENA_POSITIVAS_POR_FALLA: Dictionary = {
	"pinchazo": [
		"Me cambiaron el neumático en minutos y quedó perfecto.",
		"Pinchazo resuelto sin drama y sin cobrarme de más.",
		"La rueda quedó como nueva, ni se nota que estuvo pinchada."
	],
	"soldadura": [
		"La soldadura quedó prolija, no se ve dónde estaba partido.",
		"Soldaron la pieza y dejó de sonar como tractor. Excelente.",
		"Trabajo de soldadura impecable, se nota el oficio."
	],
	"gasolina": [
		"Encontraron la fuga de combustible que otros tres talleres no vieron.",
		"Me arreglaron el tema de la bencina y encima me explicaron por qué pasaba.",
		"El auto dejó de oler a combustible. Por fin alguien lo hizo bien."
	],
	"circuito": [
		"Encontraron el corto eléctrico en media hora. Increíble.",
		"El sistema eléctrico quedó funcionando como el primer día.",
		"Arreglaron el circuito sin cambiar medio auto. Se agradece."
	]
}

const RESENA_POSITIVA := "positiva"
const RESENA_NEGATIVA := "negativa"

# "Sin leer" se guarda en cada reseña (campo 'leida'), no como contador aparte: el
# panel del PC se navega por día, así que abrir la terminal no significa haber
# leído las de todos los días. Los totales se derivan de ahí.


## Deja una reseña negativa (pieza dudosa que falló).
func registrar_resena_negativa(dia: int = -1) -> void:
	_registrar_resena(RESENA_NEGATIVA, RESENA_COMENTARIOS_NEGATIVOS, "#f85149", dia)


## Deja una reseña positiva (reparación excelente). Si se sabe qué falla se reparó,
## el cliente menciona ese trabajo en concreto.
func registrar_resena_positiva(dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var falla: String = str(resumen_atencion.get("falla", ""))
	var especificos: Array = RESENA_POSITIVAS_POR_FALLA.get(falla, [])
	var resenas: Array = get_estadistica_dia(dia).get("resenas", [])

	# Solo se usan los específicos si queda alguno sin repetir ese día.
	var usados: Array = []
	for resena in resenas:
		usados.append(str(resena.get("comentario", "")))
	var libres: Array = especificos.filter(func(c): return not usados.has(c))

	var pool: Array = libres if not libres.is_empty() else RESENA_COMENTARIOS_POSITIVOS
	_registrar_resena(RESENA_POSITIVA, pool, "#3fb950", dia)


## Guarda qué falla se está reparando, para que la reseña pueda mencionarla.
func registrar_falla_atencion(falla: String) -> void:
	resumen_atencion["falla"] = falla


## Guarda la reseña estructurada (usuario, comentario y tono) para poder pintarla
## en el panel del PC, y además como línea de color en la bitácora.
func _registrar_resena(tipo: String, comentarios: Array, color: String, dia: int) -> void:
	if dia < 0:
		dia = dia_actual

	var stats: Dictionary = asegurar_estadistica_dia(dia)
	var resenas: Array = stats.get("resenas", [])

	# Sin repetir dentro del mismo día: dos clientes distintos opinando con las
	# mismas palabras exactas se nota mucho en el panel del PC.
	var usuario: String = _elegir_sin_repetir(RESENA_USUARIOS, resenas, "usuario")
	var comentario: String = _elegir_sin_repetir(comentarios, resenas, "comentario")

	resenas.append({
		"usuario": usuario, "comentario": comentario, "tipo": tipo, "leida": false
	})
	stats["resenas"] = resenas
	estadisticas_dias[dia] = stats

	registrar_evento_dia(
		'[color=%s]Resena de %s:[/color] "%s"' % [color, usuario, comentario],
		dia
	)


## Elige un valor de 'opciones' que no esté ya usado en ese campo de 'resenas'.
## Si ya se agotaron todas, vuelve a permitir repetidos.
func _elegir_sin_repetir(opciones: Array, resenas: Array, campo: String) -> String:
	var usados: Array = []
	for resena in resenas:
		usados.append(str(resena.get(campo, "")))

	var disponibles: Array = opciones.filter(func(o): return not usados.has(o))
	if disponibles.is_empty():
		disponibles = opciones

	return str(disponibles.pick_random())


## True mientras se juega un minijuego lanzado como easter egg desde el menú.
## En ese modo el minijuego no toca el estado de la partida (ni dinero, ni
## reputación, ni el resumen de atención) y al terminar vuelve al menú.
## No se guarda: es transitorio, solo dura lo que dura la partida suelta.
var easter_egg_activo: bool = false


## Reseñas publicadas en un día concreto (array de {usuario, comentario}).
func get_resenas_dia(dia: int) -> Array:
	return get_estadistica_dia(dia).get("resenas", [])


## El jugador miró el panel de reseñas de ese día: solo esas dejan de estar pendientes.
func marcar_resenas_leidas(dia: int) -> void:
	var stats: Dictionary = estadisticas_dias.get(dia, {})
	var resenas: Array = stats.get("resenas", [])
	if resenas.is_empty():
		return

	for resena in resenas:
		resena["leida"] = true
	stats["resenas"] = resenas
	estadisticas_dias[dia] = stats


## Reseñas pendientes de leer en toda la partida. Con 'solo_positivas' cuenta
## únicamente los elogios, para poder anticipar el tono en el aviso del HUD.
func contar_resenas_sin_leer(solo_positivas: bool = false) -> int:
	var total: int = 0
	for dia in estadisticas_dias:
		for resena in estadisticas_dias[dia].get("resenas", []):
			# Las reseñas guardadas antes de existir este campo ya se dan por leídas.
			if bool(resena.get("leida", true)):
				continue
			if solo_positivas and str(resena.get("tipo", RESENA_NEGATIVA)) != RESENA_POSITIVA:
				continue
			total += 1
	return total


func registrar_evento_dia(texto: String, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats: Dictionary = asegurar_estadistica_dia(dia)
	var eventos: Array = stats.get("eventos", [])
	eventos.append(texto)

	stats["eventos"] = eventos
	stats["dinero_final"] = dinero
	estadisticas_dias[dia] = stats

## Registra una perdida monetaria externa (robo, multa, accidente) sin contarla
## como atencion de cliente. Tambien permite una penalizacion reputacional menor.
func registrar_perdida_evento(
	cantidad: int,
	texto: String,
	penalizacion_reputacion: int = 0,
	dia: int = -1
) -> void:
	if dia < 0:
		dia = dia_actual

	dinero -= cantidad
	if penalizacion_reputacion > 0:
		ajustar_reputacion(-penalizacion_reputacion, texto)

	var stats := asegurar_estadistica_dia(dia)
	stats["gastos"] = int(stats.get("gastos", 0)) + cantidad
	stats["balance"] = int(stats.get("balance", 0)) - cantidad
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion
	_agregar_evento_stats(stats, texto)
	estadisticas_dias[dia] = stats

## Reinicia el desglose de la atención (lo llama GameScreen al iniciar una atención,
## antes de mandar al cliente al diagnóstico + minijuego).
func iniciar_resumen_atencion() -> void:
	resumen_atencion = {
		"diagnostico_correcto": true,
		"rep_diagnostico": 0,
		"rep_pieza": 0,
		"rep_desempeno": 0,
		"penalizacion_diagnostico": 0,
		"costo_pieza": 0,
		"tipo_pieza": "",
		"recompensa_minijuego": 0,
		"rendimiento": 0.5,
		"nivel_desempeno": DESEMPENO_ACEPTABLE,
		"resultado_minijuego_registrado": false,
	}
## Los minijuegos reportan tanto el porcentaje visual como el nivel de desempeño
## balanceado. El nivel aplica la reputación una sola vez y alimenta el resumen.
func reportar_rendimiento_minijuego(
	rendimiento: float,
	recompensa: int = 0,
	nivel_desempeno: int = DESEMPENO_ACEPTABLE,
	nombre_minijuego: String = "Minijuego",
	detalle: String = ""
) -> int:
	resumen_atencion["rendimiento"] = clampf(rendimiento, 0.0, 1.0)
	resumen_atencion["recompensa_minijuego"] = recompensa
	resumen_atencion["nivel_desempeno"] = clampi(
		nivel_desempeno,
		DESEMPENO_FALLIDO,
		DESEMPENO_EXITOSO
	)
	resumen_atencion["resultado_minijuego_registrado"] = true
	var rep_desempeno := registrar_desempeno_minijuego(
		nivel_desempeno,
		nombre_minijuego,
		detalle
	)
	resumen_atencion["rep_desempeno"] = rep_desempeno
	return rep_desempeno

## Prepara el resumen para una partida suelta (easter egg): deja a la vista el
## marcador del minijuego y nada más. A diferencia de reportar_rendimiento_minijuego(),
## no mueve reputación ni escribe eventos en la bitácora del día, así que jugar
## fuera del taller no deja rastro en la partida.
func reportar_marcador_suelto(
	rendimiento: float,
	recompensa: int,
	nivel_desempeno: int = DESEMPENO_ACEPTABLE
) -> void:
	iniciar_resumen_atencion()
	resumen_atencion["rendimiento"] = clampf(rendimiento, 0.0, 1.0)
	resumen_atencion["recompensa_minijuego"] = recompensa
	resumen_atencion["nivel_desempeno"] = clampi(
		nivel_desempeno,
		DESEMPENO_FALLIDO,
		DESEMPENO_EXITOSO
	)
	resumen_atencion["resultado_minijuego_registrado"] = true


## Devuelve el desglose completo de la atención para mostrarlo en la pantalla de
## resultado del minijuego: cuánto dinero varió (recompensa, costos, balance neto) y
## cuánta reputación (diagnóstico + desempeño + total).
func get_resumen_atencion() -> Dictionary:
	var r: Dictionary = resumen_atencion.duplicate()
	var recompensa: int = int(r.get("recompensa_minijuego", 0))
	var costo_pieza: int = int(r.get("costo_pieza", 0))
	var penal_diag: int = int(r.get("penalizacion_diagnostico", 0))
	var rep_diag: int = int(r.get("rep_diagnostico", 0))
	var rep_pieza: int = int(r.get("rep_pieza", 0))
	var rep_desempeno: int = int(r.get("rep_desempeno", 0))

	r["balance_dinero"] = recompensa - costo_pieza - penal_diag
	r["rep_pieza"] = rep_pieza
	r["rep_desempeno"] = rep_desempeno
	r["rep_total"] = rep_diag + rep_pieza + rep_desempeno
	return r

func registrar_atencion_dia(delta_dinero: int, dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)

	stats["clientes_atendidos"] += 1
	if _atencion_actual_fue_satisfactoria():
		stats["clientes_satisfechos"] = int(stats.get("clientes_satisfechos", 0)) + 1
	stats["balance"] += delta_dinero

	if delta_dinero >= 0:
		stats["ingresos"] += delta_dinero
	else:
		stats["gastos"] += abs(delta_dinero)

	# La reputación ya se resolvió por diagnóstico, pieza y nivel del minijuego.

	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats


## Un cliente queda satisfecho si el diagnostico fue correcto y el minijuego
## termino con un desempeno aceptable o exitoso. Se evalua una sola vez al
## consolidar la atencion, evitando descontar dos veces al mismo cliente.
func _atencion_actual_fue_satisfactoria() -> bool:
	if not bool(resumen_atencion.get("resultado_minijuego_registrado", false)):
		return false

	return (
		bool(resumen_atencion.get("diagnostico_correcto", false))
		and int(resumen_atencion.get("nivel_desempeno", DESEMPENO_FALLIDO))
			>= DESEMPENO_ACEPTABLE
	)


## Registra la atencion que quedo pendiente al salir de un minijuego. Tambien
## lo llaman los finales criticos, que pueden saltarse el regreso a GameScreen.
## Devuelve si registro algo y el cambio monetario real de esa atencion.
func consolidar_atencion_pendiente() -> Dictionary:
	if not volviendo_de_atencion:
		return {"registrada": false, "delta_dinero": 0}

	volviendo_de_atencion = false
	var delta_dinero := dinero - dinero_antes_atencion
	registrar_atencion_dia(delta_dinero)
	registrar_evento_dia(
		"Atencion finalizada. Balance de la reparacion: %s."
		% formatear_monto(delta_dinero)
	)
	return {"registrada": true, "delta_dinero": delta_dinero}

func registrar_cierre_dia(dia: int = -1) -> void:
	if dia < 0:
		dia = dia_actual

	var stats := asegurar_estadistica_dia(dia)
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion
	estadisticas_dias[dia] = stats

## Aplica una sola vez las decisiones de la libreta de gastos del cierre.
## Devuelve false si ese día ya había sido procesado, evitando cobros duplicados.
func registrar_gastos_diarios(
	dia: int,
	pagados: Array[String],
	postergados: Array[String],
	total_pagado: int,
	_penalizacion_reputacion: int
) -> bool:
	var stats := asegurar_estadistica_dia(dia)
	if bool(stats.get("gastos_diarios_procesados", false)):
		return false

	dinero -= total_pagado

	stats["gastos_diarios_procesados"] = true
	stats["gastos_diarios_total"] = total_pagado
	stats["gastos_diarios_pagados"] = pagados.duplicate()
	stats["gastos_diarios_postergados"] = postergados.duplicate()
	if postergados.has(NOMBRE_GASTO_ARRIENDO):
		arriendos_postergados += 1
	stats["arriendos_postergados_acumulados"] = arriendos_postergados
	stats["gastos"] = int(stats.get("gastos", 0)) + total_pagado
	stats["balance"] = int(stats.get("balance", 0)) - total_pagado
	stats["dinero_final"] = dinero
	stats["reputacion"] = reputacion

	var eventos: Array = stats.get("eventos", [])
	if total_pagado > 0:
		eventos.append("Gastos de cierre pagados: -$%d." % total_pagado)
	if not postergados.is_empty():
		eventos.append(
			"Pagos postergados: %s. Sin cambio de reputacion."
			% ", ".join(PackedStringArray(postergados))
		)
	if postergados.has(NOMBRE_GASTO_ARRIENDO):
		eventos.append(
			"Arriendo postergado: %d de %d atrasos para el desalojo."
			% [arriendos_postergados, ARRIENDOS_POSTERGADOS_PARA_DESALOJO]
		)
	stats["eventos"] = eventos

	estadisticas_dias[dia] = stats
	if dia >= ULTIMO_DIA and arriendos_postergados >= ARRIENDOS_POSTERGADOS_PARA_DESALOJO:
		_programar_evento_final(FINAL_DESALOJO_SCENE)
	return true

func get_estadistica_dia(dia: int) -> Dictionary:
	return asegurar_estadistica_dia(dia)

func get_dias_con_estadisticas() -> Array:
	var dias := estadisticas_dias.keys()
	dias.sort()
	return dias

func get_estadisticas_generales() -> Dictionary:
	var total_clientes := 0
	var total_clientes_satisfechos := 0
	var total_correctos := 0
	var total_incorrectos := 0
	var total_ingresos := 0
	var total_gastos := 0
	var total_balance := 0
	var total_minijuegos_exitosos := 0
	var total_minijuegos_aceptables := 0
	var total_minijuegos_fallidos := 0

	for dia in get_dias_con_estadisticas():
		var stats: Dictionary = estadisticas_dias[dia]
		var clientes_dia := int(stats.get("clientes_atendidos", 0))
		total_clientes += clientes_dia
		if stats.has("clientes_satisfechos"):
			total_clientes_satisfechos += int(stats["clientes_satisfechos"])
		else:
			# Compatibilidad con partidas guardadas antes de registrar este dato.
			var incidentes := (
				int(stats.get("diagnosticos_incorrectos", 0))
				+ int(stats.get("minijuegos_fallidos", 0))
			)
			total_clientes_satisfechos += maxi(0, clientes_dia - incidentes)
		total_correctos += int(stats.get("diagnosticos_correctos", 0))
		total_incorrectos += int(stats.get("diagnosticos_incorrectos", 0))
		total_ingresos += int(stats.get("ingresos", 0))
		total_gastos += int(stats.get("gastos", 0))
		total_balance += int(stats.get("balance", 0))
		total_minijuegos_exitosos += int(stats.get("minijuegos_exitosos", 0))
		total_minijuegos_aceptables += int(stats.get("minijuegos_aceptables", 0))
		total_minijuegos_fallidos += int(stats.get("minijuegos_fallidos", 0))

	return {
		"clientes_atendidos": total_clientes,
		"clientes_satisfechos": total_clientes_satisfechos,
		"diagnosticos_correctos": total_correctos,
		"diagnosticos_incorrectos": total_incorrectos,
		"ingresos": total_ingresos,
		"gastos": total_gastos,
		"balance": total_balance,
		"minijuegos_exitosos": total_minijuegos_exitosos,
		"minijuegos_aceptables": total_minijuegos_aceptables,
		"minijuegos_fallidos": total_minijuegos_fallidos,
		"dinero_actual": dinero,
		"dinero_final": dinero,
		"reputacion": reputacion
	}


## Foto unica de los valores que deben mostrar todos los desenlaces.
func get_resumen_final() -> Dictionary:
	consolidar_atencion_pendiente()
	return get_estadisticas_generales()

func formatear_monto(monto: int) -> String:
	if monto >= 0:
		return "+$%d" % monto

	return "-$%d" % absi(monto)

## Reinicia todo el estado de la partida a los valores iniciales (Nueva Partida).
func reiniciar() -> void:
	final_pendiente_scene = ""
	_escena_origen_final_id = 0
	_cambiando_a_evento_final = false
	_pieza_reputacion_registrada = false
	_minijuego_reputacion_registrado = false
	_avisos_reputacion_pendientes.clear()
	arriendos_postergados = 0
	dia_actual = 1
	dinero = 500
	reputacion = REPUTACION_INICIAL
	genero_jugador = ""
	siguiente_evento_dia = ""
	mostrar_resumen_dia_al_volver = false
	modal_bienvenida_mostrado = false
	clientes_usados.clear()
	estafa_pendiente = false
	dinero_antes_estafa = 0
	nombre_estafador = ""
	dinero_antes_atencion = 0
	volviendo_de_atencion = false
	resumen_atencion.clear()
	estadisticas_dias.clear()
	protesta_pendiente = false
	contador_pieza_defectuosa = 0

# Datos asociados a la reputacion
signal reputacion_cambiado(nuevo_reputacion:int)

var reputacion: int = REPUTACION_INICIAL:
	set(value):
		reputacion = clampi(value, 0, 100)
		reputacion_cambiado.emit(reputacion)
		if reputacion == 0:
			_programar_evento_final(FINAL_REPUTACION_SCENE)
		elif final_pendiente_scene == FINAL_REPUTACION_SCENE:
			# La pieza o el minijuego pueden recuperar reputacion antes de que
			# termine la atencion; en ese caso el final deja de corresponder.
			_limpiar_final_pendiente()


func sumar_reputacion(cantidad: int, motivo: String = "") -> void:
	ajustar_reputacion(cantidad, motivo)

func restar_reputacion(cantidad: int, motivo: String = "") -> void:
	ajustar_reputacion(-cantidad, motivo)

## Ajusta la reputación con una cantidad con signo (+ sube, - baja). El setter
## se encarga de mantenerla dentro de 0-100.
func ajustar_reputacion(cantidad: int, motivo: String = "") -> int:
	var anterior := reputacion
	reputacion += cantidad
	var cambio_real := reputacion - anterior
	if not motivo.is_empty() and cambio_real != 0:
		_registrar_aviso_reputacion(cambio_real, motivo)
	return cambio_real

func _registrar_aviso_reputacion(cambio: int, motivo: String) -> void:
	var color := "#8b949e"
	var valor := "0"
	if cambio > 0:
		color = "#3fb950"
		valor = "+%d" % cambio
	elif cambio < 0:
		color = "#f85149"
		valor = str(cambio)
	_avisos_reputacion_pendientes.append(
		"[color=%s]%s reputacion[/color] - %s" % [color, valor, motivo]
	)

func consumir_avisos_reputacion() -> Array[String]:
	var avisos: Array[String] = _avisos_reputacion_pendientes.duplicate()
	_avisos_reputacion_pendientes.clear()
	return avisos

func limpiar_avisos_reputacion() -> void:
	_avisos_reputacion_pendientes.clear()

## Devuelve la escena que debe seguir a la actual. Los finales criticos tienen
## prioridad; la evaluacion semanal solo ocurre una vez terminado el dia 5.
func obtener_destino_post_escena(destino_normal: String) -> String:
	# Si la reputacion o el dinero alcanzaron un limite terminal durante una
	# atencion, primero se completa el minijuego. Su resultado todavia puede
	# compensar la perdida.
	if (
		volviendo_de_atencion
		and destino_normal != GAME_SCREEN_SCENE
		and final_pendiente_scene in [FINAL_REPUTACION_SCENE, FINAL_DEUDA_SCENE]
	):
		return destino_normal

	var destino := _obtener_final_critico()

	if destino.is_empty() and dia_actual > ULTIMO_DIA:
		if dinero >= UMBRAL_VICTORIA_DINERO and reputacion >= UMBRAL_VICTORIA_REPUTACION:
			destino = FINAL_VICTORIA_SCENE
		else:
			destino = FINAL_MEDIO_SCENE

	if destino.is_empty():
		return destino_normal

	consolidar_atencion_pendiente()
	_limpiar_final_pendiente()
	PARTIDA.guardar()
	return destino

func _obtener_final_critico() -> String:
	# Reputacion tiene prioridad si ambas condiciones terminales se cumplen.
	if reputacion <= 0:
		return FINAL_REPUTACION_SCENE
	if dinero <= UMBRAL_DEUDA_EXTREMA:
		return FINAL_DEUDA_SCENE
	if (
		final_pendiente_scene == FINAL_DESALOJO_SCENE
		or (
			dia_actual > ULTIMO_DIA
			and arriendos_postergados >= ARRIENDOS_POSTERGADOS_PARA_DESALOJO
		)
	):
		return FINAL_DESALOJO_SCENE
	return ""

func _programar_evento_final(ruta: String) -> void:
	if _cambiando_a_evento_final:
		return

	# Una caida a reputacion cero prevalece sobre la quiebra si coinciden.
	if final_pendiente_scene.is_empty() or ruta == FINAL_REPUTACION_SCENE:
		final_pendiente_scene = ruta

	if is_inside_tree() and get_tree().current_scene and _escena_origen_final_id == 0:
		_escena_origen_final_id = get_tree().current_scene.get_instance_id()

func _limpiar_final_pendiente() -> void:
	final_pendiente_scene = ""
	_escena_origen_final_id = 0

## Respaldo para escenas antiguas que aun cambien directamente: evita perder
## un final, aunque las rutas principales usan obtener_destino_post_escena y
## por ello no llegan a mostrar una escena intermedia.
func _process(_delta: float) -> void:
	# No interrumpir una reparacion por reputacion o deuda: ambas se reevalúan
	# al salir del resumen del minijuego, con el balance completo disponible.
	if (
		volviendo_de_atencion
		and final_pendiente_scene in [FINAL_REPUTACION_SCENE, FINAL_DEUDA_SCENE]
	):
		return

	if final_pendiente_scene.is_empty() or _cambiando_a_evento_final:
		return

	var escena_actual := get_tree().current_scene
	if escena_actual == null:
		return
	if escena_actual.scene_file_path == final_pendiente_scene:
		_limpiar_final_pendiente()
		return

	if _escena_origen_final_id == 0:
		_escena_origen_final_id = escena_actual.get_instance_id()
		return

	if escena_actual.get_instance_id() != _escena_origen_final_id:
		_cambiando_a_evento_final = true
		call_deferred("_ejecutar_evento_final_pendiente")

func _ejecutar_evento_final_pendiente() -> void:
	var destino := _obtener_final_critico()
	_limpiar_final_pendiente()
	get_tree().paused = false
	Engine.time_scale = 1.0
	if not destino.is_empty():
		consolidar_atencion_pendiente()
		PARTIDA.guardar()
		# El cambio es asincrono: la escena anterior sigue viva y jugandose unos
		# frames mas. Mantenemos el guardia puesto hasta llegar al final (lo
		# libera reiniciar() al empezar otra partida) para que el juego no
		# vuelva a programar un final mientras la carga esta en curso.
		if CARGADOR.cambiar_escena(destino):
			return
	_cambiando_a_evento_final = false

# Ingreso y Gastos realizados

signal ingresos_dia_cambiado(nuevo_ingreso:int)
signal gastos_dia_cambiado(nuevo_gasto:int)

# Contenedor de datos diarios
var historial_dias = []

# Dinero ingresado por dia
var ingresos_dia:int = 6:
	set(value):
		ingresos_dia = value
		ingresos_dia_cambiado.emit(ingresos_dia)

# Gastos por compra de piezas
var gastos_dia:int = 100:
	set(value):
		gastos_dia = value
		gastos_dia_cambiado.emit(gastos_dia)

#reinicia los gastos diarios
func reiniciar_estadisticas_dia():
	print("Reiniciando estadisticas diarias")
	ingresos_dia = 0
	gastos_dia = 0

# Guardar una copia de los datos diarios en un Diccionario
func guardar_dia():
	print("Guardando datos diarios")

	var datos = {
		"dia": dia_actual,
		"ingresos": ingresos_dia,
		"gastos": gastos_dia,
		"clientes": CLIENTMANAGER.clientes_atendidos,
		"reputacion": reputacion,
		"dinero": dinero
	}

	historial_dias.append(datos)
	reiniciar_estadisticas_dia()

	print("Guardado:")
	print(datos)
	print("Total días:", historial_dias.size())

func condicion_protesta():
	if contador_pieza_defectuosa >= pieza_limite and protesta_pendiente == false:
		protesta_pendiente = true
		return true
	else:
		return false
