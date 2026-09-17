class_name PlayerCopy
extends StaticBody2D

## A clone left behind by the player, used as a platform.
##
## Deliberately logic-free. Because the player is lifted on top of a copy the instant it
## is placed, a copy never overlaps anybody, and the collision exceptions and proximity
## probe this class used to carry are gone. It stays a named type so a level can grant a
## different kind of copy later (B19) without CopySystem caring which.


## Height of this copy in pixels. Used to work out where the player ends up standing.
## Safe to call before the copy enters the tree: instantiate() already built the children.
func get_height() -> float:
	var collision: CollisionShape2D = $CollisionShape2D
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	assert(shape != null, "PlayerCopy expects a RectangleShape2D in CollisionShape2D.")
	return shape.size.y
