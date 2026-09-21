# The placement check said "blocked" with empty space above

## Context

*Copias* is a 2D puzzle platformer in Godot 4.7 where the player leaves static clones of
themselves and uses them as steps. Placing a copy puts the player standing on top of it,
so before spawning one the game has to answer a question: is the space the player is about
to occupy free?

## The problem

My first answer used `test_move()`, which the docs describe precisely:

```gdscript
# recovery_as_collision = true
return player.test_move(destination, Vector2.ZERO, null, 0.08, true)
```

The documentation for `recovery_as_collision` says it reports "whether the body would
*touch* any other bodies". I read that, decided it was what I needed, and it passed the
case I had in mind — standing under a low ceiling correctly refused placement.

Then it refused placement while standing next to an existing copy, with the entire space
above completely empty. A wall beside the player did the same thing.

Nothing was measured here. This was a correctness bug, not a performance one, and the
project has no profiling data yet.

## What I tried

The failure looked like a tolerance problem, so my first instinct was `safe_margin`. That
was wrong and would have produced a check that worked by luck at one shape size.

The actual mistake was upstream. `test_move()` did exactly what its documentation
promised. My question was whether the destination would be **occupied**; the API answers
whether the body would **touch** something. Those two coincide for a ceiling directly
overhead and diverge for anything flush alongside — which is most of a platformer.

The right tool was a shape query against the physics space:

```gdscript
_space_query.transform = Transform2D(player.global_rotation, stand_position)
var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
return not space.intersect_shape(_space_query, 1).is_empty()
```

`PhysicsShapeQueryParameters2D.margin` defaults to `0.0`, so two bodies touching exactly
are not overlapping. That default *is* the distinction I needed.

## The trade-off

The query object is built once in `_ready()` and reused, with only the transform changing
per call. `intersect_shape` still allocates an array for its results, and the superior
alternative I rejected was collision layers: letting the physics engine filter means no
query and no allocation at all. I rejected it because there is no performance requirement
on this system, and it would trade code-visible logic for editor configuration that breaks
silently. That decision is recorded with its revisit condition — if ignored queries ever
show up in the Profiler, layers win.

## Still unverified

No measurement exists for any of this. `intersect_shape` allocating per key press is
theoretically wasteful and practically unmeasured, and I am not going to "optimise" it
until a profiler says so.

## What I'd do differently

Verifying that an API exists and does what it claims is not the same as verifying it
answers your question. I did the first, quoted the docs verbatim, and felt finished.
Documentation cannot tell you that you are asking the wrong thing — only a case you did
not think of can, and that case came from playing the build, not from reading.
