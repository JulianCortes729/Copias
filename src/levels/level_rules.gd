class_name LevelRules
extends Node

## Lo único que decide si un nivel está ganado.
##
## La meta y las zonas de muerte solamente informan que algo las tocó. Toda regla sobre
## qué significa eso —de quién es el cuerpo que cuenta, qué pasa después, qué se ignora
## una vez terminado el nivel— vive acá y en ningún otro lado.

## Se emite una sola vez, cuando el nivel pasa a estar completado.
signal completed

## El jugador cuyo cuerpo es el único que puede completar este nivel.
@export var player: PlayerMotor

## El área que el jugador tiene que alcanzar para terminar el nivel.
@export var goal: Area2D

## Dónde queda parado el jugador cuando este nivel empieza o se reinicia.
@export var start_marker: Marker2D

## Las áreas que matan al jugador en este nivel. R4.4 — un nivel puede declarar ninguna,
## una o muchas. Se cablean a mano en vez de descubrirlas recorriendo el árbol: una lista
## vacía tiene que significar "este nivel no tiene zonas de muerte", no "la búsqueda no
## encontró nada".
@export var death_zones: Array[Area2D] = []

## El sistema de copias de este nivel, que se reinicia junto con todo lo demás.
@export var copy_system: CopySystem

## Las reglas de este nivel. LevelRules es su dueño y se las entrega a quien las necesite,
## así un nivel declara sus datos exactamente una vez.
@export var level_data: LevelData

var _completed: bool = false


func _ready() -> void:
	assert(player != null, "LevelRules: asigná el Player en el Inspector.")
	assert(goal != null, "LevelRules: asigná el Goal en el Inspector.")
	assert(start_marker != null, "LevelRules: asigná el marcador LevelStart en el Inspector.")
	assert(copy_system != null, "LevelRules: asigná el CopySystem en el Inspector.")
	assert(level_data != null, "LevelRules: asigná un recurso LevelData en el Inspector.")

	goal.body_entered.connect(_on_goal_body_entered)

	for zone in death_zones:
		assert(zone != null, "LevelRules: una de las entradas de Death Zones está vacía.")
		zone.body_entered.connect(_on_death_zone_body_entered)

	# D5 — el sistema de copias recibe sus datos desde acá, nunca de su propia casilla del
	# Inspector.
	copy_system.setup(level_data)

	# R3.1, R3.2 — un nivel siempre empieza igual, haya hecho lo que haya hecho el intento
	# anterior y haya quedado donde haya quedado el jugador al construir la escena.
	restart()


func _physics_process(_delta: float) -> void:
	if InputReader.is_restart_level_pressed():
		restart()


## Devuelve el nivel a su estado inicial.
## 📖 R2.4 — a propósito no está protegido por _completed: reiniciar es lo único que tiene
## que seguir funcionando después de ganar el nivel.
func restart() -> void:
	_completed = false
	InputReader.set_enabled(true)

	# R2.1, R2.3 — de vuelta al inicio sin movimiento heredado.
	player.reset_to(start_marker.global_position)
	# R2.2 — se retiran todas las copias colocadas y el total vuelve al valor del nivel.
	copy_system.clear()


func _exit_tree() -> void:
	# 📖 El interruptor sobrevive a este nodo. Salir de un nivel con el input apagado
	# arrastraría un juego congelado a lo que venga después, y el bug parecería input roto.
	InputReader.set_enabled(true)


func _on_goal_body_entered(body: Node2D) -> void:
	# R1.6 — solo el cuerpo del jugador completa un nivel. Una copia que toca la meta se
	# ignora; si no, un puzzle podría ganarse tirando una copia en vez de llegando.
	if body != player:
		return

	# R1.3 — volver a tocar la meta no cambia nada.
	if _completed:
		return

	_complete()


func _on_death_zone_body_entered(body: Node2D) -> void:
	# R4.2 — las copias se caen a los pozos todo el tiempo, y que muriera una reiniciaría
	# el nivel por debajo de un jugador que no hizo nada mal. Solo su propio cuerpo lo mata.
	if body != player:
		return

	# R4.3 — un nivel ya ganado no se puede perder después. Verificado en T4.
	if _completed:
		return

	restart()


func _complete() -> void:
	_completed = true

	# R1.2 — el input se detiene, la simulación no. Un jugador que llegó a la meta en el
	# aire sigue cayendo, porque congelar la física sería un comportamiento que nadie pidió
	# y que la spec no describe.
	InputReader.set_enabled(false)
	completed.emit()

	# R1.5 — se le pasa la posta al nivel siguiente.
	# 📖 Diferido, según D4: esto corre dentro de una señal de Area2D, que se dispara
	# durante el paso de física, y cambiar de escena libera justamente el nodo que hace la
	# llamada. Diferirlo no cuesta nada; equivocarse cuesta un crash intermitente.
	_advance_to_next_level.call_deferred()


func _advance_to_next_level() -> void:
	if level_data.next_level == null:
		# 📖 push_error en vez de un return silencioso: llegar al final de la cadena es una
		# decisión de diseño sin terminar, y tiene que ser imposible de no ver en
		# desarrollo.
		push_error("LevelRules: este nivel no declara nivel siguiente. Ver spec 001, pregunta abierta.")
		return

	get_tree().change_scene_to_packed(level_data.next_level)
