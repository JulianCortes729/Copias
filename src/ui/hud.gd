class_name LevelHud
extends CanvasLayer

## El HUD de un nivel: muestra cuántas copias le quedan al jugador por colocar.
##
## Presentación pura. No calcula nada y no guarda nada: cada aviso de CopySystem trae el
## valor completo, nunca un incremento, así que no hay estado propio que pueda quedar
## desfasado de la verdad.
##
## Spec 002 — requisitos R1.1 a R1.5 y R4.1.

## El sistema de copias de este nivel, asignado en el Inspector como el resto de las
## referencias del proyecto.
## 📖 El HUD conoce al sistema de copias y nunca al revés: la capa de presentación mira a
## la de simulación, jamás en el otro sentido.
@export var copy_system: CopySystem

## Cómo se escribe el número en pantalla. R1.1 pide mostrar cuántas copias quedan y no
## fija el texto, así que el formato se afina en el Inspector sin tocar este script — es
## lo que decide T4, probándolo.
@export var label_format: String = "%d"

# 📖 Se toma en _enter_tree() y no con @onready. @onready corre en _ready(), y para
# entonces el primer aviso ya puede haber llegado: con este nodo después de LevelRules en
# el árbol, la etiqueta sería null justo cuando hay que escribirla. Resolver el momento de
# la suscripción (D3) no resolvía el de la etiqueta — son dos problemas distintos.
# Los hijos de esta escena ya existen como objetos al entrar al árbol, así que pedirlos
# acá es válido: verificado en T2 con el HUD puesto último, que es el peor caso.
var _label: Label


func _enter_tree() -> void:
	# R4.1 — un HUD sin su sistema de copias no puede mostrar nada verdadero, y eso tiene
	# que notarse en desarrollo en vez de quedar como una pantalla en blanco.
	assert(copy_system != null, "LevelHud: asigná el Copy System en el Inspector.")

	_label = $MarginContainer/Label
	assert(_label != null, "LevelHud: falta el nodo MarginContainer/Label en la escena.")

	# 📖 D3 — la suscripción va acá y no en _ready(). CopySystem emite el primer conteo
	# durante el _ready() de LevelRules (R1.3), y _enter_tree() corre antes que cualquier
	# _ready() del árbol, así que llegar a tiempo deja de depender del orden entre
	# hermanos. Verificado en T1.
	# 📖 Acá solo se puede *suscribir*, nunca leer: en este momento CopySystem todavía no
	# recibió su LevelData, así que preguntarle cuántas copias quedan fallaría.
	copy_system.copies_changed.connect(_on_copies_changed)


func _exit_tree() -> void:
	# 📖 El emisor puede sobrevivir a este nodo, así que la conexión se deshace a mano.
	# is_instance_valid() porque al cambiar de escena el orden de liberación no está
	# garantizado, y desconectarse de algo ya liberado es un error.
	if is_instance_valid(copy_system):
		copy_system.copies_changed.disconnect(_on_copies_changed)


## R1.2 — el único punto por el que cambia el número, venga de colocar, deshacer, borrar
## todo, reiniciar el nivel o arrancarlo.
## 📖 El total llega y se ignora a propósito: la spec decidió mostrar solo el restante.
## El parámetro se recibe igual porque la señal lo manda, y B20 lo va a querer.
func _on_copies_changed(remaining: int, _total: int) -> void:
	# R1.5 — cuando no quedan copias esto escribe "0". No se oculta ni se reemplaza: cero
	# copias es información, no ausencia de información.
	_label.text = label_format % remaining
