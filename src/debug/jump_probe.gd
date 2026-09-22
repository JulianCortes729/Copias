extends Node

## Instrumento de medición: informa, en píxeles, hasta dónde llegan de verdad un salto y
## una pila de copias.
##
## Escrito para B5, para zanjar un número que el GDD tenía mal: una copia vale 32 px
## colocada parado y ~115 px colocada en pleno salto, no un piso fijo. Se conservó después
## porque B8 mueve exactamente estos números, y un coyote time afinado a ojo es una
## feature que después nadie puede defender.
##
## No es parte del juego. Se agrega a mano a un nivel mientras se mide y se saca antes de
## commitear ese nivel — nada del juego depende de que exista.

## El jugador que se está midiendo.
@export var player: PlayerMotor

## Altura del piso en el que arranca este nivel, en coordenadas globales. Se captura una
## sola vez, en el primer contacto real con el suelo.
var _floor_y: float = 0.0
var _has_floor: bool = false

var _airborne: bool = false
var _takeoff: Vector2 = Vector2.ZERO
var _peak_y: float = 0.0

## Última posición en la que se vio al jugador parado sobre algo.
## 📖 El despegue no se puede leer en el primer frame en el aire: para entonces el salto ya
## subió al jugador un tick entero de física (400 px/s ÷ 60 Hz ≈ 7 px), y toda subida
## informada quedaría corta por esa diferencia. La última muestra en el piso es la buena.
var _last_grounded: Vector2 = Vector2.ZERO


func _ready() -> void:
	assert(player != null, "JumpProbe: asigná el Player en el Inspector.")
	# 📖 El muestreo tiene que pasar después del _physics_process del propio jugador, o cada
	# lectura estaría atrasada un tick de física. La prioridad es explícita porque el orden
	# entre hermanos del árbol de escena es una convención, no un contrato.
	process_physics_priority = 10


func _physics_process(_delta: float) -> void:
	var on_floor: bool = player.is_on_floor()

	if not _has_floor:
		# 📖 Espera el contacto real con el suelo en vez de leer el marcador de inicio: el
		# marcador puede estar perfectamente en el aire, y todos los números de acá son
		# relativos al piso desde el que el jugador salta.
		if on_floor:
			_has_floor = true
			_floor_y = player.global_position.y
			_last_grounded = player.global_position
			print("[JumpProbe] piso en y = ", roundi(_floor_y))
		return

	if on_floor:
		_last_grounded = player.global_position

	if _airborne:
		_peak_y = minf(_peak_y, player.global_position.y)

	if not on_floor and not _airborne:
		_airborne = true
		_takeoff = _last_grounded
		_peak_y = player.global_position.y
		return

	if on_floor and _airborne:
		_airborne = false
		_report()


## Imprime los tres números que produjo un vuelo.
## 📖 "aire", no "salto": colocar una copia en pleno vuelo teletransporta al jugador hacia
## arriba y termina el vuelo ahí, así que esto informa lo que se ganó en el aire, sea como
## sea que se haya ganado. Medí primero saltos limpios y después encadenados, o los dos
## terminan en un mismo número.
func _report() -> void:
	var rise: int = roundi(_takeoff.y - _peak_y)
	var run: int = roundi(absf(player.global_position.x - _takeoff.x))
	var above_ground: int = roundi(_floor_y - _peak_y)
	print(
		"[JumpProbe] subida en aire: ", rise,
		" px | avance: ", run,
		" px | pico sobre el piso: ", above_ground, " px"
	)
