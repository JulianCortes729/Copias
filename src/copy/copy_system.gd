class_name CopySystem
extends Node

## Dueño de las copias colocadas en un nivel: cuántas quedan, dónde van, cuál se saca. El
## jugador no sabe nada de este sistema — las copias se colocan *en* el jugador, no las
## coloca *él*.

## Se emite cada vez que cambia la cantidad de copias disponibles. El HUD (B6) escucha
## esto en vez de meter la mano en el sistema para pedir el número.
signal copies_changed(remaining: int, total: int)

## El jugador del que nacen las copias, y a quien se sube arriba de cada copia nueva.
@export var player: PlayerMotor

## La escena que se instancia por cada copia. Exportada en vez de precargada para que
## algún día un nivel pueda otorgar otra clase de copia sin tocar este script.
@export var copy_scene: PackedScene

## Las reglas de este nivel, entregadas por LevelRules al arrancar — ver setup().
## 📖 No es @export: un nivel tiene que declarar sus datos en exactamente un lugar. Dos
## casillas del Inspector apuntando a recursos distintos no daría error, produciría en
## silencio un nivel cuyas reglas se contradicen.
var level_data: LevelData

## Cuántas copias otorga este nivel, leído directo de su recurso de datos.
var copy_limit: int:
	get:
		return level_data.copy_limit

var _placed: Array[PlayerCopy] = []
var _copy_height: float = 0.0

# 📖 Se construye una vez y se reusa: rehacer el objeto de consulta en cada colocación
# alocaría sin motivo, y el único campo que cambia de verdad es la transformación.
var _space_query := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	# 📖 assert() se elimina en las builds de release, así que estos no cuestan nada en el
	# juego publicado y siguen fallando ruidosamente en el momento en que un nivel queda
	# mal cableado.
	assert(player != null, "CopySystem: asigná el Player en el Inspector.")
	assert(copy_scene != null, "CopySystem: asigná la escena de copia en el Inspector.")

	_copy_height = _measure_copy_height()

	var exclusions: Array[RID] = [player.get_rid()]
	_space_query.shape = player.get_collision_shape()
	_space_query.collision_mask = player.collision_mask
	# 📖 margin se queda en su default de 0.0 a propósito: con cualquier margen, una copia
	# apoyada al ras del destino contaría como que lo ocupa.
	_space_query.margin = 0.0
	_space_query.exclude = exclusions


## Le entrega a este sistema el nivel al que pertenece. Lo llama LevelRules mientras el
## nivel arranca.
## 📖 No se hace en _ready(): el orden de _ready() entre hermanos sigue al árbol de
## escena, así que este sistema puede correr —y corre— antes de que LevelRules exista para
## entregarle nada. Todo lo que necesite los datos del nivel espera esta llamada en vez de
## confiar en un orden favorable.
func setup(data: LevelData) -> void:
	assert(data != null, "CopySystem.setup: LevelRules entregó un LevelData nulo.")

	level_data = data
	copies_changed.emit(remaining(), copy_limit)


func _physics_process(_delta: float) -> void:
	# 📖 elif, no tres ifs: dos acciones presionadas en el mismo tick se ejecutarían las
	# dos, y "colocar y después deshacer" en un frame nunca es lo que el jugador quiso.
	if InputReader.is_place_copy_pressed():
		try_place()
	elif InputReader.is_undo_copy_pressed():
		undo()
	elif InputReader.is_clear_copies_pressed():
		clear()


## Coloca una copia a los pies del jugador y lo sube encima. Devuelve true cuando la copia
## se colocó de verdad.
func try_place() -> bool:
	if remaining() <= 0:
		return false

	var copy_position: Vector2 = player.global_position
	# 📖 El jugador y la copia miden lo mismo, así que quedar parado encima es subir exacto
	# una altura de copia: los pies del jugador aterrizan en el techo de la copia.
	var stand_position: Vector2 = copy_position + Vector2.UP * _copy_height

	if _is_occupied(stand_position):
		# Lectura provisoria hasta que B12 lo convierta en feedback real dentro del juego.
		print("[CopySystem] bloqueado: no hay lugar arriba")
		return false

	var copy: PlayerCopy = copy_scene.instantiate()
	# 📖 add_child() primero: global_position recién significa algo cuando el nodo tiene un
	# padre respecto del cual ser global.
	add_child(copy)
	copy.global_position = copy_position

	player.land_at(stand_position)

	_placed.append(copy)
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] colocada, quedan ", remaining(), "/", copy_limit)
	return true


## Saca la copia colocada más recientemente. Devuelve true cuando sacó una.
## 📖 Al jugador no se lo mueve de vuelta: si estaba parado sobre esa copia simplemente
## cae, que es el resultado que la física daría igual y el que puede predecir.
func undo() -> bool:
	if _placed.is_empty():
		return false

	var copy: PlayerCopy = _placed.pop_back()
	# 📖 queue_free(), no free(): la copia puede estar en plena colisión este mismo frame, y
	# liberarla ahora mismo es cómo se consigue un crash en vez de un bug.
	copy.queue_free()
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] deshecha, quedan ", remaining(), "/", copy_limit)
	return true


## Saca todas las copias colocadas. Devuelve cuántas sacó.
func clear() -> int:
	if _placed.is_empty():
		return 0

	var removed: int = _placed.size()
	for copy in _placed:
		copy.queue_free()
	_placed.clear()
	copies_changed.emit(remaining(), copy_limit)

	print("[CopySystem] borradas ", removed, ", quedan ", remaining(), "/", copy_limit)
	return removed


## Cuántas copias le quedan al jugador por colocar.
func remaining() -> int:
	return copy_limit - _placed.size()


## True cuando algo ya ocupa el espacio en el que el jugador quedaría parado.
## 📖 Esto pregunta por *solapamiento*, no por contacto. test_move() con
## recovery_as_collision responde "¿este cuerpo tocaría algo?", que cuenta una copia o una
## pared apoyada al ras del destino — y esas dejan el espacio perfectamente libre.
func _is_occupied(stand_position: Vector2) -> bool:
	_space_query.transform = Transform2D(player.global_rotation, stand_position)
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	# 📖 max_results = 1: la pregunta es si hay algo ahí, no qué. El array que devuelve
	# aloca, pero esto corre al apretar una tecla, nunca por frame.
	return not space.intersect_shape(_space_query, 1).is_empty()


## Instancia una copia al cargar, solo para leerle la altura, así una colocación bloqueada
## más adelante no cuesta ninguna allocation.
func _measure_copy_height() -> float:
	var probe: PlayerCopy = copy_scene.instantiate()
	var height: float = probe.get_height()
	probe.queue_free()
	return height
