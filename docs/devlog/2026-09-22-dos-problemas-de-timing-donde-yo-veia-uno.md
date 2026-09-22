# Dos problemas de timing donde yo veía uno

## Contexto

*Copias* es un plataformero de puzzles 2D en Godot 4.7 donde el límite de copias por nivel
es la restricción principal: con dos no llegás, con tres sí. Ese número vivía solo en el
panel Output del editor. B6 lo puso en pantalla: `CopySystem` emite `copies_changed` y un
HUD escucha y escribe. Nada más.

## El problema

El valor que más importa —el total con el que arranca el nivel— se emite **una sola vez**,
dentro de `CopySystem.setup()`, que `LevelRules` llama en su propio `_ready()`.

Si el HUD se suscribe en su `_ready()`, llega a tiempo o no según dónde esté en el árbol
respecto de `LevelRules`. Y el fallo no es ruidoso: el contador queda vacío hasta que el
jugador coloca la primera copia. En el nivel de prueba, con el HUD arriba en el árbol,
anda. En un nivel armado otro día con los nodos en otro orden, no. Nada se rompe, nada se
imprime, y el bug aparece semanas después.

No medí nada acá. Es correctitud, no performance; este proyecto todavía no tiene una sola
medición de frame.

## Qué intenté

La opción barata era poner el HUD antes que `LevelRules` en el árbol. Funciona y es la
peor: hace que un requisito dependa del orden en que alguien arrastró nodos, sin ningún
error cuando se rompe.

`_enter_tree()` se propaga de arriba hacia abajo antes de que corra cualquier `_ready()`,
así que la suscripción existiría antes de cualquier emisión. Pero eso dependía de que una
referencia `@export` a un nodo ya estuviera resuelta tan temprano, y eso no lo sabía. Antes
de escribir el HUD escribí un probe descartable, con el nodo puesto **primero** en el
árbol, que es el peor caso:

```
[ExportProbe] _enter_tree -> resuelta: CopySystem | ya en el árbol: false
[ExportProbe] _ready      -> resuelta: CopySystem | ya en el árbol: true
```

Resuelta. El matiz que no había pedido es el `ya en el árbol: false`: ahí adentro se puede
suscribir, porque `connect()` necesita el objeto y no su posición en el árbol, pero **no
se puede leer** — `setup()` todavía no corrió y `level_data` es `null`.

Con eso resuelto escribí el HUD, y apareció el segundo problema. Tenía la etiqueta en
`@onready var _label: Label`. `@onready` corre en `_ready()`. Con el HUD después de
`LevelRules`, la señal llega, el handler escribe `_label.text` y `_label` es `null`.
Arreglar el momento de la suscripción no arreglaba el de la etiqueta:

```gdscript
func _enter_tree() -> void:
	_label = $MarginContainer/Label
	copy_system.copies_changed.connect(_on_copies_changed)
```

## El trade-off

Esto se aparta de la convención del propio proyecto, que pide conexiones en `_ready()` y
reserva `_enter_tree()` para registro en sistemas globales. La alternativa superior que
descarté era conectar en `_ready()` y pedir el valor actual con `call_deferred`: respeta la
convención y cuesta apenas un frame con el contador vacío. La descarté porque agrega un
segundo camino de inicialización en paralelo al de la señal — dos maneras distintas de que
el número llegue a la pantalla, y solo una ejercitada en cada arranque.

## Todavía sin verificar

Que el HUD no se desplace con la vista del nivel. Lo garantiza que sea un `CanvasLayer`,
no una prueba: todavía no hay cámara en el proyecto, así que no existe una vista que se
mueva y no hay nada que observar. Quedó escrito en la spec como criterio **no verificado**,
con la condición concreta para saldarlo cuando exista la cámara.

## Qué haría distinto

Verifiqué el timing de la referencia porque estaba anotado como riesgo en el plan. El
timing de la etiqueta no estaba anotado, y era el mismo problema un nivel más abajo — lo
encontré escribiendo, no planificando. Cuando una decisión es "esto tiene que pasar antes
que aquello", lo que hay que listar es **todo lo que el handler va a tocar**, no solo la
pieza que motivó la decisión.

Es pariente de lo que me pasó unos días antes con
[el chequeo de colocación](2026-09-20-el-chequeo-de-colocacion-decia-bloqueado-con-espacio-libre.md):
las dos veces verifiqué con precisión una cosa cierta, y el agujero estaba en lo que no se
me ocurrió preguntar.
