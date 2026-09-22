class_name LevelData
extends Resource

## Las reglas de un nivel, guardadas como dato en vez de como código.
##
## Cada nivel tiene su propio archivo .tres construido a partir de esta clase. Diseñar un
## nivel es editar un recurso en el Inspector, nunca tocar un script — que es justamente
## el punto: el día que un nivel necesite reglas distintas, nadie tiene que recompilar
## una idea.
##
## A propósito mínima. El tiempo par que menciona el GDD no está acá: nadie lo lee hasta
## B20, y un campo que ningún sistema consume es decoración que parece un plan.

## Cuántas copias otorga este nivel al jugador. Es el dial de dificultad del nivel: como
## cada copia levanta al jugador una altura, es literalmente cuántos pisos puede subir.
@export_range(0, 20) var copy_limit: int = 3

## El nivel que sigue a este. Encadenar niveles es editar un .tres, nunca un script.
## 📖 Un nivel sin nivel siguiente es el final de la cadena, que hoy es un error de
## autoría y no un estado soportado — la pregunta abierta de la spec. Falla de forma
## ruidosa en vez de fingir que el juego termina con elegancia.
@export var next_level: PackedScene
