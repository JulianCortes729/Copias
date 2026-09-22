class_name PlayerCopy
extends StaticBody2D

## Un clon que el jugador deja atrás y usa como plataforma.
##
## Deliberadamente sin lógica. Como al colocar una copia el jugador queda parado encima al
## instante, una copia nunca se solapa con nadie, y las excepciones de colisión y el probe
## de proximidad que esta clase supo tener ya no existen. Sigue siendo un tipo con nombre
## para que un nivel pueda otorgar otra clase de copia más adelante (B19) sin que
## CopySystem tenga que enterarse de cuál.


## Altura de esta copia en píxeles. Sirve para calcular dónde termina parado el jugador.
## Se puede llamar antes de que la copia entre al árbol: instantiate() ya construyó los
## hijos.
func get_height() -> float:
	var collision: CollisionShape2D = $CollisionShape2D
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	assert(shape != null, "PlayerCopy espera un RectangleShape2D en CollisionShape2D.")
	return shape.size.y
