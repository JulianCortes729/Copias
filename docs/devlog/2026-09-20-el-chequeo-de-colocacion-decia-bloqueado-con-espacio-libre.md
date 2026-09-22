# El chequeo de colocación decía "bloqueado" con el espacio de arriba vacío

## Contexto

*Copias* es un plataformero de puzzles 2D en Godot 4.7 donde el jugador deja clones
estáticos de sí mismo y los usa como escalones. Colocar una copia deja al jugador parado
encima, así que antes de crear una el juego tiene que responder una pregunta: ¿está libre
el espacio que el jugador está por ocupar?

## El problema

Mi primera respuesta usaba `test_move()`, que la documentación describe con precisión:

```gdscript
# recovery_as_collision = true
return player.test_move(destination, Vector2.ZERO, null, 0.08, true)
```

La documentación de `recovery_as_collision` dice que informa si el cuerpo *tocaría* otros
cuerpos. Lo leí, decidí que era lo que necesitaba, y pasó el caso que tenía en la cabeza:
parado bajo un techo bajo, la colocación se rechazaba correctamente.

Después rechazó la colocación estando parado al lado de una copia existente, con todo el
espacio de arriba completamente vacío. Una pared al costado del jugador hacía lo mismo.

Acá no se midió nada. Era un bug de correctitud, no de performance, y el proyecto todavía
no tiene ningún dato de profiling.

## Qué intenté

La falla parecía un problema de tolerancia, así que mi primer instinto fue `safe_margin`.
Estaba equivocado y habría producido un chequeo que funcionaba de casualidad para un solo
tamaño de forma.

El error real estaba más arriba. `test_move()` hacía exactamente lo que su documentación
prometía. Mi pregunta era si el destino estaría **ocupado**; la API responde si el cuerpo
**tocaría** algo. Esas dos cosas coinciden con un techo justo encima y se separan con
cualquier cosa apoyada al ras del costado — que es la mayor parte de un plataformero.

La herramienta correcta era una consulta de forma contra el espacio físico:

```gdscript
_space_query.transform = Transform2D(player.global_rotation, stand_position)
var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
return not space.intersect_shape(_space_query, 1).is_empty()
```

`PhysicsShapeQueryParameters2D.margin` vale `0.0` por defecto, así que dos cuerpos que se
tocan exactamente no se están solapando. Ese valor por defecto *es* la distinción que
necesitaba.

## El trade-off

El objeto de consulta se construye una vez en `_ready()` y se reusa; lo único que cambia
por llamada es la transformación. `intersect_shape` igual aloca un array para sus
resultados, y la alternativa superior que descarté eran las capas de colisión: dejar que
el motor de física filtre significa ninguna consulta y ninguna allocation. La descarté
porque este sistema no tiene ningún requisito de performance, y cambiaría lógica visible
en el código por configuración de editor que se rompe en silencio. Esa decisión quedó
registrada con su condición de revisión: si alguna vez aparecen consultas ignoradas en el
Profiler, ganan las capas.

## Todavía sin verificar

No existe ninguna medición de nada de esto. Que `intersect_shape` aloque por cada tecla
apretada es teóricamente un desperdicio y prácticamente algo que nadie midió, y no lo voy
a "optimizar" hasta que un profiler lo diga.

## Qué haría distinto

Verificar que una API existe y hace lo que dice no es lo mismo que verificar que responde
*tu* pregunta. Hice lo primero, cité la documentación textual, y me sentí terminado. La
documentación no te puede avisar que estás preguntando lo que no es — eso solo lo puede
hacer un caso que no pensaste, y ese caso salió de jugar la build, no de leer.
