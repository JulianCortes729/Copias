class_name LevelRules
extends Node

## The only thing that decides whether a level is won.
##
## The goal and, later, the death zones merely report that something touched them. Every
## rule about what that means — whose body counts, what happens next, what is ignored
## once the level is over — lives here and nowhere else.

## Emitted once, when the level becomes completed.
signal completed

## The player whose body is the only one that can complete this level.
@export var player: PlayerMotor

## The area the player has to reach to finish the level.
@export var goal: Area2D

var _completed: bool = false


func _ready() -> void:
	assert(player != null, "LevelRules: assign the Player in the Inspector.")
	assert(goal != null, "LevelRules: assign the Goal in the Inspector.")

	# R3.2 — a level never starts completed. The input switch is global and survives
	# scene changes, so a level also cannot assume it was left enabled.
	_completed = false
	InputReader.set_enabled(true)

	goal.body_entered.connect(_on_goal_body_entered)


func _exit_tree() -> void:
	# 📖 The switch outlives this node. Leaving a level while it is off would carry a
	# frozen game into whatever comes next, and the bug would look like broken input.
	InputReader.set_enabled(true)


## Whether the player has already finished this level.
func is_completed() -> bool:
	return _completed


func _on_goal_body_entered(body: Node2D) -> void:
	# R1.6 — only the player's body completes a level. A copy touching the goal is
	# ignored, otherwise a puzzle could be won by throwing a copy instead of arriving.
	if body != player:
		return

	# R1.3 — touching the goal again changes nothing.
	if _completed:
		return

	_complete()


func _complete() -> void:
	_completed = true

	# R1.2 — input stops, the simulation does not. A player who reached the goal in
	# mid-air keeps falling, because freezing physics would be a behaviour nobody asked
	# for and the spec does not describe.
	InputReader.set_enabled(false)
	completed.emit()

	# Temporary readout until the level actually leads somewhere (T5).
	print("[LevelRules] level completed")
