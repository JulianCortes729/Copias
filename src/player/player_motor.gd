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

# 📖 StringName (&"") instead of a plain String: input actions are compared every frame,
# and StringName compares by pointer instead of character by character.
const ACTION_LEFT: StringName = &"move_left"
const ACTION_RIGHT: StringName = &"move_right"

@export_group("Ground movement")

## Top horizontal speed, in pixels per second.
@export var max_speed: float = 180.0

## How quickly max_speed is reached, in pixels per second squared.
@export var acceleration: float = 1200.0

## How quickly the player stops once input is released, in pixels per second squared.
@export var friction: float = 1600.0

var _state: State = State.AIR


func _physics_process(delta: float) -> void:
	# 📖 Simulation runs in _physics_process because it is a fixed timestep: same input,
	# same result, regardless of framerate.
	# get_axis returns a float in [-1, 1] and allocates nothing.
	var direction: float = Input.get_axis(ACTION_LEFT, ACTION_RIGHT)

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
	elif not is_zero_approx(direction):
		_transition_to(State.RUN)


func _tick_run(delta: float, direction: float) -> void:
	_apply_horizontal(delta, direction)

	if not is_on_floor():
		_transition_to(State.AIR)
	elif is_zero_approx(direction) and is_zero_approx(velocity.x):
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
