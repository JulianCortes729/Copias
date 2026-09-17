class_name PlayerMotor
extends CharacterBody2D

## Player movement rules. Simulation only: this script decides where the player is,
## never how it looks.

# 📖 States are explicit from day one. Coyote time and input buffering (B8) are rules
# about *which state you are in*, so giving them a home now avoids a pile of booleans.
enum State {
	IDLE, ## On the floor, not moving.
	RUN, ## On the floor, moving horizontally.
	AIR, ## No floor contact: rising or falling.
}

@export_group("Ground movement")

## Top horizontal speed, in pixels per second.
@export var max_speed: float = 180.0

## How quickly max_speed is reached, in pixels per second squared.
@export var acceleration: float = 1200.0

## How quickly the player stops once input is released, in pixels per second squared.
@export var friction: float = 1600.0

@export_group("Jump")

## Upward speed applied the instant a jump starts, in pixels per second.
@export var jump_velocity: float = 400.0

var _state: State = State.AIR


func _physics_process(delta: float) -> void:
	# 📖 Simulation runs in _physics_process because it is a fixed timestep: same input,
	# same result, regardless of framerate.
	# 📖 The motor asks what the player intends, not which key is down. Action names live
	# in InputReader, so remapping or replaying input never reaches this file.
	var direction: float = InputReader.get_move_axis()

	match _state:
		State.IDLE:
			_tick_idle(delta, direction)
		State.RUN:
			_tick_run(delta, direction)
		State.AIR:
			_tick_air(delta, direction)

	move_and_slide()


func _tick_idle(delta: float, direction: float) -> void:
	# 📖 is_on_floor() reports the result of the previous move_and_slide(), so reading it
	# at the top of the frame is the intended order, not a bug.
	_apply_horizontal(delta, direction)

	if not is_on_floor():
		_transition_to(State.AIR)
		return

	if _try_jump():
		return

	if not is_zero_approx(direction):
		_transition_to(State.RUN)


func _tick_run(delta: float, direction: float) -> void:
	_apply_horizontal(delta, direction)

	if not is_on_floor():
		_transition_to(State.AIR)
		return

	if _try_jump():
		return

	if is_zero_approx(direction) and is_zero_approx(velocity.x):
		# 📖 Leaving RUN waits for the speed to actually reach zero, not just for the key
		# release: otherwise the state would lie about the player still sliding.
		_transition_to(State.IDLE)


func _tick_air(delta: float, direction: float) -> void:
	# 📖 get_gravity() is inherited from PhysicsBody2D and already accounts for project
	# gravity plus any Area2D override, so there is no gravity constant in this file.
	velocity += get_gravity() * delta
	_apply_horizontal(delta, direction)

	if is_on_floor():
		_transition_to(State.RUN if not is_zero_approx(direction) else State.IDLE)


## The player's collision shape, so other systems can test whether a destination would
## fit this player without duplicating its dimensions.
## Reads the child directly instead of caching in @onready: callers may ask during their
## own _ready(), and node _ready() order between siblings is not something to rely on.
func get_collision_shape() -> Shape2D:
	var collision: CollisionShape2D = $CollisionShape2D
	return collision.shape


## Puts the player standing at the given position and cancels any fall. Used by
## CopySystem to lift the player onto a copy the moment it is placed.
func land_at(target: Vector2) -> void:
	global_position = target
	# 📖 Without clearing vertical speed the player would keep the momentum of the fall
	# they were in, and shoot through the copy on the very next tick.
	velocity.y = 0.0
	# 📖 is_on_floor() still reflects the previous move_and_slide(), so the grounded
	# state is assumed here and self-corrects to AIR next tick if nothing is below.
	_transition_to(State.IDLE if is_zero_approx(velocity.x) else State.RUN)


## Starts a jump if the action was pressed this tick. Returns true when it did, so the
## calling state can stop evaluating its other transitions.
func _try_jump() -> bool:
	# 📖 Only called from grounded states, so "on the floor" is already guaranteed here.
	# Letting AIR call this is what would turn into an accidental double jump.
	if not InputReader.is_jump_pressed():
		return false

	# 📖 In Godot's 2D coordinates Y grows downward, so up is negative.
	velocity.y = -jump_velocity
	_transition_to(State.AIR)
	return true


## Moves velocity.x toward the target speed, or toward zero when there is no input.
func _apply_horizontal(delta: float, direction: float) -> void:
	if is_zero_approx(direction):
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	else:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)


func _transition_to(next: State) -> void:
	if next == _state:
		return

	_state = next
	# Temporary: H1-H3 have no visuals, so the Output panel is the only way to observe
	# state. This print goes away once PlayerView exists.
	print("[PlayerMotor] -> ", State.keys()[_state])
