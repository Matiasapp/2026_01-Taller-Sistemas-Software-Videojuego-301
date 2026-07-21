extends Control

var usuarios = [
	"Miguel83",
	"Juancarlos@lospaseo",
	"CaraTrolll",
	"Juaquin",
	"Miguelin2010",
	"IsidoraLabadora",
	"Destructor de Familias"
]


var comentarios = [
	"La atencion de este lugar a sido terrible",
	"Fui por cambio de aceite y me cambiaron la suspencion",
	"Me dijeron que necesitaban 2 motores",
	"Las piezas que ocuparon parecen de jugete",
	"Es una estafa, cobran por hacer nada",
	"Es demasiado Caro, Ademas la persona a cargo tiene cara horrible",
	"Volveria para el día de muertos, con los precios y el servicio me muero enseguida"
]

@onready var labels = [
	$Comentario_1/RichTextLabel,
	$Comentario_2/RichTextLabel,
	$Comentario_3/RichTextLabel,
	$Comentario_4/RichTextLabel,
	$Comentario_5/RichTextLabel
]

@onready var animacion = $AnimationPlayer

@onready var paneles = [
	$Comentario_1,
	$Comentario_2,
	$Comentario_3,
	$Comentario_4,
	$Comentario_5
]

var rng = RandomNumberGenerator.new()

func _ready():
	
	var num_comentarios = rng.randi_range(1,labels.size())
	
	# Ocultar los paneles
	for ver in paneles:
		ver.visible = 0 
	
	# Mezclar comentarios
	var comentarios_mezclados = comentarios.duplicate()
	comentarios_mezclados.shuffle()
	
	# Mezclar Nombre de usuarios
	var usuarios_mezclados = usuarios.duplicate()
	usuarios_mezclados.shuffle()

	# Ajustar tamaño y separación
	var y_offset = 1   # distancia vertical entre paneles
	var panel_height = 90
	var panel_width = 700
	

	
	#Separacion de Paneles
	for i in range(paneles.size()):
		var panel = paneles[i]
		panel.position = Vector2(200, i * (panel_height + y_offset) + 100)
		panel.size = Vector2(panel_width, panel_height)

	# Asignar comentarios a cada panel
	for i in range(num_comentarios):
		labels[i].text = usuarios_mezclados[i] + ": " + comentarios_mezclados[i]
	
	# Reproducir todas las animaciones al mismo tiempo
	for i in range(num_comentarios):
		paneles[i].visible = 1
	
	animacion.play("mostrarTexto")
	animacion.play("Barra_espacio")
	#se disminuye la reputacion segun la cantidad de comentarios negativos
	DATOSGLOBALES.restar_reputacion(
		num_comentarios * 5,
		"Comentarios negativos de clientes"
	)
	

func _process(float):
	if Input.is_key_pressed(KEY_SPACE):
		var destino := DATOSGLOBALES.obtener_destino_post_escena(
			"res://Scenes/Gameplay/GameScreen.tscn"
		)
		CARGADOR.cambiar_escena(destino)
