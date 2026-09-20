class_name InputReader
extends RefCounted

## The single place where gameplay input is named. Systems ask this class what the
## player intends; they never touch Input or raw action names themselves.
##
## Static on purpose: this layer holds no state, so there is nothing to instantiate or
## wire. The day the game needs replays or an AI-driven player, these become instance
## methods on an injected interface — that is the point where the indirection pays.

const ACTION_LEFT: StringName = &"move_left"
const ACTION_RIGHT: StringName = &"move_right"
const ACTION_JUMP: StringName = &"jump"
const ACTION_PLACE_COPY: StringName = &"place_copy"
const ACTION_UNDO_COPY: StringName = &"undo_copy"
const ACTION_CLEAR_COPIES: StringName = &"clear_copies"
const ACTION_RESTART_LEVEL: StringName = &"restart_level"

# ⚠️SOLID Global mutable state in a layer that was deliberately stateless. The cost is
# argued in plan.md, decision D1: one switch here freezes every system at once, which is
# the reason this layer exists — and it is the first thing to break the day there are two
# players or a recorded replay. It survives scene changes, so whoever turns it off is
# responsible for turning it back on.
static var _enabled: bool = true


## Turns every gameplay input on or off at once. Reading stays valid either way: a
## disabled reader reports "the player is doing nothing", never stale values.
static func set_enabled(value: bool) -> void:
	_enabled = value


## Horizontal intent, in the range [-1, 1].
static func get_move_axis() -> float:
	if not _enabled:
		return 0.0
	return Input.get_axis(ACTION_LEFT, ACTION_RIGHT)


## True only on the tick the jump was pressed, never while it is held.
static func is_jump_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_JUMP)


## True only on the tick the place-copy action was pressed.
static func is_place_copy_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_PLACE_COPY)


## True only on the tick the undo action was pressed.
static func is_undo_copy_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_UNDO_COPY)


## True only on the tick the clear-all action was pressed.
static func is_clear_copies_pressed() -> bool:
	return _enabled and Input.is_action_just_pressed(ACTION_CLEAR_COPIES)


## True only on the tick the restart action was pressed.
## 📖 The only reader that ignores the enabled switch, and it has to: restarting is how a
## player leaves a finished or hopeless level, so it must work exactly when gameplay
## input does not. R1.2 freezes movement, jump and copies — never this.
static func is_restart_level_pressed() -> bool:
	return Input.is_action_just_pressed(ACTION_RESTART_LEVEL)
