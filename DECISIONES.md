# Architecture decisions

Decisions other features have to respect. Choices that only affect one feature live in
that feature's `docs/specs/NNN-.../plan.md` and are not repeated here.

---

## 2026-09-16 — Player movement is an explicit state machine, not flags

**Context.** A 2D platformer needs coyote time, input buffering, jump cut and variable
jump height. Each of those is a rule about *which state the player is in*. The shortest
path — a single `_physics_process` driven by `velocity` and `is_on_floor()` — expresses
those rules as loose booleans, and three booleans describe eight states while only four
were ever considered.

**Decision.** `PlayerMotor` is a `CharacterBody2D` with an `enum` + `match` state machine
in one file: `IDLE`, `RUN`, `AIR`. Every state answers how it is entered, what interrupts
it and where it exits.

**Alternatives rejected.**
- *No state machine at all.* Shorter today, and the known route to a 400-line player
  script where nobody can say why the character sometimes double-jumps.
- *Pure simulation in a `RefCounted`, testable without a `SceneTree`.* Rejected because
  `move_and_slide()` and `is_on_floor()` belong to the node. Splitting the simulation out
  would leave collision inside and rules outside, with two positions to keep in sync. The
  separation pays where logic does not depend on engine physics — not here.

**Consequences.** Game feel work lands as fields inside a state instead of a refactor.
Costs one layer of ceremony while there are only three states. A state-per-node machine
is still available later if entry/exit logic grows.

**Status.** accepted

---

## 2026-09-17 — All gameplay input goes through one static `InputReader`

**Context.** Systems calling `Input` directly spread action names across the codebase,
and remapping (B21) would then mean touching every system.

**Decision.** `InputReader` is the only place that names input actions. Systems ask what
the player intends, never which key is down. It is static: the layer holds no state, so
there is nothing to instantiate or wire. Introduced only once a second consumer existed
(`place_copy`), per the project's complexity budget.

**Alternatives rejected.**
- *Calling `Input` from each system.* One consumer made this defensible; two did not.
- *An injectable instance behind an interface.* Correct in principle and unpaid for:
  there are no tests, no replays and no AI player. That is the trigger to revisit.

**Consequences.** Remapping and replay have a single seam. Makes it trivial to freeze all
input at once — see the next entry, which is also this decision's main cost.

**Status.** accepted

---

## 2026-09-18 — One global switch freezes gameplay input

**Context.** Completing a level must stop the player acting (spec 001, R1.2) without
stopping physics: someone who reaches the goal in mid-air should keep falling.

**Decision.** `InputReader` carries a static `_enabled` flag. `LevelRules` turns it off on
completion and back on when leaving the tree. Readers return neutral values while off.
The restart action deliberately ignores the flag: restarting is how a player leaves a
finished or unwinnable level, so it has to work exactly when gameplay input does not.

**Alternatives rejected.**
- *Disabling `_physics_process` on the player and copy system.* Does more than asked: it
  would stop gravity too, inventing a behaviour no requirement describes.
- *A `FINISHED` state in the player's state machine.* Solves the player and not the copy
  system, so a second mechanism would be needed anyway.

**Consequences.** ⚠️ This puts global mutable state in a deliberately stateless layer — a
singleton by another name. It breaks the day there are two players, a recorded replay, or
a pause menu that needs input while the game is frozen (B10). It also survives scene
changes, so whoever turns it off owns turning it back on.

**Status.** accepted

---

## 2026-09-17 — Placing a copy lifts the player on top of it

**Context.** Copies spawn where the player stands, so player and copy overlap. The first
implementation made a copy intangible to its owner until they stepped clear. Playing it
exposed the flaw: a copy placed while falling solidifies *above* the player, useless as a
step.

**Decision.** Placing a copy puts the player standing on top of it, always — on the ground
and in the air. Placement is refused, and the copy not spent, when the destination is
occupied.

**Alternatives rejected.**
- *Intangible copies that solidify on exit.* Superseded. Only worked when placing during
  a jump's ascent.
- *Rejecting placement on overlap.* The most obvious action in the game — leaving a step
  where you stand — would be the one that fails.
- *One-way platforms.* Removes the problem but bans copies as walls, cutting puzzle space.

**Consequences.** Deleted ~50 lines: collision exceptions, the proximity probe and a
signal. Every copy is worth exactly one floor of height, so reachable height is arithmetic
rather than a test of jump skill, and the per-level copy limit becomes the puzzle's main
constraint. Level design (B11) must treat it as such. Copies and the player must stay the
same size for the lift to line up.

**Status.** accepted

---

## 2026-09-17 — Occupancy is tested by shape overlap, not by contact

**Context.** Refusing a blocked placement first used `test_move()` with
`recovery_as_collision`. It reported any *touch*, so standing beside an existing copy
blocked placement even with the space above completely free.

**Decision.** Occupancy is a `intersect_shape()` query against the space state with
`margin = 0`, using the player's own collision shape. Bodies that merely touch do not
count as occupying.

**Alternatives rejected.**
- *`test_move()` with `recovery_as_collision`.* Superseded. It answers a different
  question than the one being asked.

**Consequences.** Any future "does this fit here" check should use the same query rather
than a movement test. Allocates an `Array` per query; acceptable because it runs on a key
press, never per frame, and unmeasured either way.

**Status.** accepted

---

## 2026-09-20 — A level restarts in place instead of reloading the scene

**Context.** Spec 001 requires restart to return the player to the start, withdraw placed
copies and cancel velocity (R2.1–R2.3). A puzzle game restarts many times per minute.

**Decision.** `LevelRules.restart()` performs those three actions on the live scene.

**Alternatives rejected.**
- *`get_tree().reload_current_scene()`.* Three lines, and impossible to forget any state.
  It was the cheaper and safer option; this is the most debatable decision in the project
  so far. It lost because per-attempt state that must survive a restart — an attempt
  counter (B20), a transition effect (B17) — would force undoing it later.

**Consequences.** Anything stateful added to a level must be reset explicitly in
`restart()`, and forgetting shows up only on a second attempt. If that list grows past
three or four entries, scene reload becomes the right answer and this should be reverted.

**Status.** accepted

---

## 2026-09-20 — A level declares its data once, owned by `LevelRules`

**Context.** `CopySystem` exported its own `LevelData` slot. Adding a second system that
needed the same resource would give a level two Inspector slots that could point at
different resources — a mismatch that raises no error and produces contradictory rules.

**Decision.** `LevelRules` owns the level's `LevelData` and hands it to whoever needs it
during startup. `CopySystem` receives it through `setup()` rather than exporting it.
Handover happens explicitly because sibling `_ready()` order follows the scene tree and
cannot be relied on.

**Alternatives rejected.**
- *Each system exporting its own slot.* Silent misconfiguration.
- *An autoload holding the current level's data.* Global state for a problem that a single
  owner solves.

**Consequences.** New systems needing level data get it from `LevelRules`, not from their
own Inspector slot. Adding a level means editing a `.tres`, never a script. The handover
chain gets longer with each consumer; if it becomes unwieldy, revisit.

**Status.** accepted

---

## 2026-09-20 — The player's body is identified by injected reference

**Context.** Goals and death zones must react to the player's body and ignore their
copies (spec 001, R1.6 and R4.2).

**Decision.** Handlers compare the reported body against the player reference already
injected into `LevelRules`.

**Alternatives rejected.**
- *Collision layers.* Strictly better for performance — the engine filters and the signal
  never fires — but it buys layer configuration invisible from the code in exchange for a
  saving nobody measured. Revisit if ignored signals ever show up in the Profiler.
- *Groups (`is_in_group("player")`).* Banned by the project standards: a group standing in
  for a reference is a global lookup in disguise.

**Consequences.** Every area that reacts to the player needs that reference wired in the
Inspector. Explicit, and it fails loudly via `assert` when missing.

**Status.** accepted

---

## 2026-09-21 — The HUD lives inside each level

**Context.** Spec 002 puts a copy counter on screen. Something has to own it, and the
choice reaches past this feature: B7 wants a HUD that survives a transition, B10 wants one
that stays alive during a pause.

**Decision.** `hud.tscn` is added to a level like any other node and dies with it. It takes
a reference to its own level's `CopySystem` through the Inspector, subscribes to
`copies_changed`, and writes what it receives. No global state, no lookup, no registry.

**Alternatives rejected.**
- *A single HUD surviving scene changes.* Better for B7 and B10, and that is exactly why
  it is recorded here rather than dismissed. It loses today because it would have to learn
  which level just loaded and rewire itself on every change — the problem a single owner
  already solved for level data — and because a second piece of global state would deepen
  the debt the `InputReader` switch already carries.
- *Loose nodes copied into each level.* Twelve levels means changing the typography in
  twelve places.

**Consequences.** Every level must wire its own HUD, and a level that forgets fails loudly
via `assert`. The HUD is rebuilt on every level change, which will be visible as a flicker
once B7 adds transitions — that, or B10 needing the HUD alive while paused, is the trigger
to revisit this.

**Status.** accepted
