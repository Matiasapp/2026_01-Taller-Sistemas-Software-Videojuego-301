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
	$Panel/RichTextLabel,
	$Panel2/RichTextLabel,
	$Panel3/RichTextLabel,
	$Panel4/RichTextLabel,
	$Panel5/RichTextLabel
]

@onready var animaciones = [
	$Panel/AnimationPlayer2,
	$Panel2/AnimationPlayer2,
	$Panel3/AnimationPlayer2,
	$Panel4/AnimationPlayer2,
	$Panel5/AnimationPlayer2
]

@onready var paneles = [
	$Panel,
	$Panel2,
	$Panel3,
	$Panel4,
	$Panel5,
]

@onready var animacion_continuar: AnimationPlayer = $Panel/AnimationPlayer
@onready var animacion_titulo: AnimationPlayer = $Titulo_comentario/AnimationPlayer


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
	
	var contador = 1
	# Reproducir todas las animaciones al mismo tiempo
	for anim in animaciones:
		if contador <= num_comentarios:
			paneles[contador - 1].visible = 1
			anim.play("MostrarTextoAnimado")
			contador +=1
	
	animacion_continuar.play("MasTexto")
	animacion_titulo.play("ColorComentarios")
	
	#se disminuye la reputacion segun la cantidad de comentarios negativos
	DATOSGLOBALES.restar_reputacion(num_comentarios * 5)
	

func _process(float):
	if Input.is_key_pressed(KEY_SPACE):
		get_tree().change_scene_to_file("res://Scenes/Gameplay/GameScreen.tscn")
