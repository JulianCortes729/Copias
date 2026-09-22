class_name PlayerMotor
extends CharacterBody2D

## Las reglas de movimiento del jugador. Solo simulación: este script decide dónde está el
## jugador, nunca cómo se ve.

# 📖 Los estados son explícitos desde el día uno. El coyote time y el input buffering (B8)
# son reglas sobre *en qué estado estás*, así que darles una casa ahora evita una pila de
# booleanos sueltos.
enum State {
	IDLE, ## En el piso, quieto.
	RUN, ## En el piso, moviéndose en horizontal.
	AIR, ## Sin contacto con el piso: subiendo o cayendo.
}

@export_group("Movimiento en piso")

## Velocidad horizontal máxima, en píxeles por segundo.
@export var max_speed: float = 180.0

## Qué tan rápido se llega a max_speed, en píxeles por segundo al cuadrado.
@export var acceleration: float = 1200.0

## Qué tan rápido frena el jugador al soltar el input, en píxeles por segundo al cuadrado.
@export var friction: float = 1600.0

@export_group("Salto")

## Velocidad hacia arriba que se aplica en el instante en que arranca el salto, en píxeles
## por segundo.
@export var jump_velocity: float = 400.0

var _state: State = State.AIR


func _physics_process(delta: float) -> void:
	# 📖 La simulación corre en _physics_process porque es de paso fijo: mismo input, mismo
	# resultado, sin importar el framerate.
	# 📖 El motor pregunta qué quiere hacer el jugador, no qué tecla está apretada. Los
	# nombres de acción viven en InputReader, así que remapear o reproducir input grabado
	# nunca llega a este archivo.
	var direction: float = InputReader.get_move_axis()

	match _state:
		State.IDLE:
			_tick_idle(delta, direction)
		State.RUN:
			_tick_run(delta, direction)
		State.AIR:
			_tick_air(delta, direction)

	move_and_slide()


func _tick_idle(delta: float, direction: float) -> void:
	# 📖 is_on_floor() informa el resultado del move_and_slide() anterior, así que leerlo al
	# principio del frame es el orden buscado, no un error.
	_apply_horizontal(delta, direction)

	if not is_on_floor():
		_transition_to(State.AIR)
		return

	if _try_jump():
		return

	if not is_zero_approx(direction):
		_transition_to(State.RUN)


func _tick_run(delta: float, direction: float) -> void:
	_apply_horizontal(delta, direction)

	if not is_on_floor():
		_transition_to(State.AIR)
		return

	if _try_jump():
		return

	if is_zero_approx(direction) and is_zero_approx(velocity.x):
		# 📖 Salir de RUN espera a que la velocidad llegue de verdad a cero, no solo a que
		# se suelte la tecla: si no, el estado estaría mintiendo sobre un jugador que
		# todavía se desliza.
		_transition_to(State.IDLE)


func _tick_air(delta: float, direction: float) -> void:
	# 📖 get_gravity() se hereda de PhysicsBody2D y ya tiene en cuenta la gravedad del
	# proyecto más cualquier override de un Area2D, así que en este archivo no hay ninguna
	# constante de gravedad.
	velocity += get_gravity() * delta
	_apply_horizontal(delta, direction)

	if is_on_floor():
		_transition_to(State.RUN if not is_zero_approx(direction) else State.IDLE)


## La forma de colisión del jugador, para que otros sistemas puedan probar si un destino
## le entraría sin duplicar sus dimensiones.
## Lee el hijo directamente en vez de cachearlo en @onready: quien pregunte puede hacerlo
## durante su propio _ready(), y el orden de _ready() entre hermanos no es algo en lo que
## apoyarse.
func get_collision_shape() -> Shape2D:
	var collision: CollisionShape2D = $CollisionShape2D
	return collision.shape


## Devuelve al jugador a una posición sin nada de movimiento. Se usa cuando un nivel
## empieza o se reinicia.
## 📖 Limpia los dos ejes, a diferencia de land_at(), que solo cancela la caída: un
## reinicio no puede heredar la carrera horizontal que el jugador traía al morir.
func reset_to(target: Vector2) -> void:
	global_position = target
	velocity = Vector2.ZERO
	# 📖 AIR y no IDLE: el punto de inicio puede estar perfectamente arriba del piso, y AIR
	# se autocorrige a IDLE en el primer tick que encuentre suelo.
	_transition_to(State.AIR)


## Deja al jugador parado en la posición dada y cancela cualquier caída. Lo usa CopySystem
## para subirlo arriba de una copia en el momento en que se coloca.
## 📖 Sin limpiar la velocidad vertical, el jugador conservaría el impulso de la caída en
## la que venía y atravesaría la copia en el tick siguiente.
func land_at(target: Vector2) -> void:
	global_position = target
	velocity.y = 0.0
	# 📖 is_on_floor() todavía refleja el move_and_slide() anterior, así que acá se asume el
	# estado de "en el piso" y se autocorrige a AIR el tick siguiente si no hay nada debajo.
	_transition_to(State.IDLE if is_zero_approx(velocity.x) else State.RUN)


## Arranca un salto si la acción se presionó este tick. Devuelve true cuando lo hizo, para
## que el estado que llamó pueda dejar de evaluar sus otras transiciones.
func _try_jump() -> bool:
	# 📖 Solo lo llaman los estados de piso, así que "estar en el suelo" ya está garantizado
	# acá. Dejar que AIR lo llame es lo que se convertiría en un doble salto accidental.
	if not InputReader.is_jump_pressed():
		return false

	# 📖 En las coordenadas 2D de Godot la Y crece hacia abajo, así que arriba es negativo.
	velocity.y = -jump_velocity
	_transition_to(State.AIR)
	return true


## Mueve velocity.x hacia la velocidad objetivo, o hacia cero cuando no hay input.
func _apply_horizontal(delta: float, direction: float) -> void:
	if is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)


func _transition_to(next: State) -> void:
	if next == _state:
		return

	_state = next
	# Temporal: H1-H3 no tienen visuales, así que el panel Output es la única forma de
	# observar el estado. Este print desaparece cuando exista PlayerView.
	print("[PlayerMotor] -> ", State.keys()[_state])
