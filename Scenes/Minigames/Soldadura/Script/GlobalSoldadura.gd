extends Node

# Piezas que un jugador hábil completa en la ronda de 30s (~3-4s por pieza).
# Se usa como referencia para normalizar el rendimiento del minijuego a 0.0-1.0.
const PIEZAS_RENDIMIENTO_MAX := 8

var piezas_completadas := 0

var dinero := 0
