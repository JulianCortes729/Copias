class_name LevelData
extends Resource

## The rules of a single level, stored as data rather than code.
##
## Each level owns a .tres file built from this class. Designing a level means editing a
## resource in the Inspector, never touching a script — which is the whole point: the
## day a level needs different rules, nobody has to recompile an idea.
##
## Intentionally minimal. The target scene and par time from the GDD land here in B4,
## when something actually reads them; fields nothing consumes are just clutter that
## looks like a plan.

## How many copies the player is granted in this level. This is the level's difficulty
## dial: with copies lifting the player one height each, it is literally how many floors
## they can climb.
@export_range(0, 20) var copy_limit: int = 3
