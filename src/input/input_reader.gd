class_name InputReader
extends RefCounted

## El único lugar donde se nombra el input del juego. Los sistemas le preguntan a esta
## clase qué intención tiene el jugador; nunca tocan Input ni los nombres de acción
## directamente.
##
## Estática a propósito: esta capa no guarda estado, así que no hay nada que instanciar ni
## cablear. El día que el juego necesite replays o un jugador controlado por IA, estos
## métodos pasan a ser de instancia sobre una interfaz inyectada — ese es el punto en que
## la indirección se paga.

const ACTION_LEFT: StringName = &"move_left"
const ACTION_RIGHT: StringName = &"move_right"
const ACTION_JUMP: StringName = &"jump"
const ACTION_PLACE_COPY: StringName = &"place_copy"
const ACTION_UNDO_COPY: StringName = &"undo_copy"
const ACTION_CLEAR_COPIES: StringName = &"clear_copies"
const ACTION_RESTART_LEVEL: StringName = &"restart_level"

# ⚠️SOLID Estado global mutable en una capa que era deliberadamente sin estado. El costo
# está argumentado en plan.md, decisión D1: un solo interruptor acá congela todos los
# sistemas a la vez, que es la razón de que esta capa exista — y es lo primero que se
# rompe el día que haya dos jugadores o un replay grabado. Sobrevive a los cambios de
# escena, así que quien lo apaga es responsable de volver a prenderlo.
static var _enabled: bool = true


## Prende o apaga todo el input de juego de una vez. Leer sigue siendo válido en
## cualquiera de los dos casos: un lector apagado informa "el jugador no está haciendo
## nada", nunca valores viejos.
static func set_enabled(value: bool) -> void:
	_enabled = value


## Intención horizontal, en el rango [-1, 1].
static func get_move_axis() -> float:
	if not _enabled:
		return 0.0
	return Input.get_axis(ACTION_LEFT, ACTION_RIGHT)


## Verdadero solo en el tick en que se presionó el salto, nunca mientras se mantiene.
static func is_jump_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_JUMP)


## Verdadero solo en el tick en que se presionó colocar copia.
static func is_place_copy_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_PLACE_COPY)


## Verdadero solo en el tick en que se presionó deshacer.
static func is_undo_copy_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_UNDO_COPY)


## Verdadero solo en el tick en que se presionó borrar todo.
static func is_clear_copies_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_CLEAR_COPIES)


## Verdadero solo en el tick en que se presionó el reinicio.
## 📖 El único lector que ignora el interruptor, y tiene que hacerlo: reiniciar es cómo el
## jugador sale de un nivel terminado o trabado, así que debe funcionar exactamente cuando
## el input de juego no funciona. R1.2 congela movimiento, salto y copias — nunca esto.
static func is_restart_level_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_RESTART_LEVEL)
