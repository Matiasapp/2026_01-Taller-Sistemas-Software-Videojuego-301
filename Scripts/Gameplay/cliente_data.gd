class_name ClienteData
extends Resource

## Datos de un cliente que llega al taller.
## Crea un archivo .tres por cada cliente distinto (clic derecho > New Resource > ClienteData).
## Agregar clientes nuevos NO requiere tocar la escena ni el código: solo crear más recursos.

## Nombre del cliente (para mostrar o depurar).
@export var nombre: String = ""

## Animaciones del cliente. Crea un SpriteFrames .tres por cliente y asígnalo aquí.
@export var frames: SpriteFrames

## Animación a reproducir (debe existir dentro de "frames"). Si no existe, se usa la primera disponible.
@export var animacion: StringName = &"movimiento"

## Texto/diálogo que dice el cliente al ser atendido.
@export_multiline var dialogo: String = ""

## Tipo de falla del auto del cliente. Valores válidos:
## "generica", "pinchazo", "soldadura", "gasolina", "circuito".
@export var falla: String = "generica"

## Si es true, este cliente es un estafador: tras la reparación se revela que pagó
## con billetes falsos y se pierde lo que "pagó".
@export var estafador: bool = false
